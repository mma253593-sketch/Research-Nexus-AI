-- =====================================================================
--  MODULE 3 — trend_context
--
--  m5_bias(f5, cfg) -> { bias = 1|-1|0, strength 0..1, available }
--     bias  1: EMA_fast > EMA_slow, slope of EMA_slow (3 bars, in M5 ATR) > 0
--              and close > EMA_slow.  -1 mirrored.  0 otherwise.
--  analyze(f, f5, cfg) -> {
--     m1_dir      1|-1|0  EMA9/21/50 stack with matching EMA50 slope sign
--     m1_strength 0..1    stack spread + slope
--     consistency 0..1    share of the last 10 closes on the m1_dir side of EMA21
--     structure   1|-1|0  last two confirmed swings: HH+HL / LH+LL
--     reversal    { [1]=bool, [-1]=bool } structure break against side s:
--                 EMA21 on side s of EMA50 but close beyond the last swing on the other side
--     m5          m5_bias(...)
--     conflict    true when M1 direction and M5 bias are opposite
--  }
--  M5 is CONTEXT: it adds/removes score and only blocks continuation
--  setups when strongly opposite (see signal_engine).
-- =====================================================================
local util = require ("util")
local M = {}

function M.m5_bias (f5, cfg)
    local n = f5.n
    local out = { bias = 0, strength = 0, available = false }
    local ef, es, es3, atr, c = f5.ema_f[n], f5.ema_s[n], f5.ema_s[n - 3], f5.atr[n], f5.C[n]
    if ef == nil or es == nil or es3 == nil or atr == nil or atr <= 0 then return out end
    out.available = true
    local slope = (es - es3) / (3 * atr)
    out.slope, out.spread = slope, (ef - es) / atr
    if ef > es and slope > 0 and c > es then out.bias = 1
    elseif ef < es and slope < 0 and c < es then out.bias = -1 end
    if out.bias ~= 0 then
        out.strength = 0.5 * util.unit (math.abs (out.spread) / 1.0) + 0.5 * util.unit (math.abs (slope) / 0.1)
    end
    return out
end

function M.structure (f)
    local hs, ls = f.swing_highs, f.swing_lows
    if #hs < 2 or #ls < 2 then return 0 end
    local hh, hl = hs[#hs].price > hs[#hs - 1].price, ls[#ls].price > ls[#ls - 1].price
    local lh, ll = hs[#hs].price < hs[#hs - 1].price, ls[#ls].price < ls[#ls - 1].price
    if hh and hl then return 1 elseif lh and ll then return -1 end
    return 0
end

function M.analyze (f, f5, cfg)
    local n = f.n
    local ef, em, es, c, atr = f.ema_f[n], f.ema_m[n], f.ema_s[n], f.C[n], f.atr[n]
    local es5 = f.ema_s[n - 5]
    local out = { m1_dir = 0, m1_strength = 0, consistency = 0, structure = M.structure (f), reversal = { [1] = false, [-1] = false } }
    if ef and em and es and es5 and atr and atr > 0 then
        local slope = (es - es5) / (5 * atr)
        out.slope = slope
        if ef > em and em > es and slope > 0 then out.m1_dir = 1
        elseif ef < em and em < es and slope < 0 then out.m1_dir = -1 end
        if out.m1_dir ~= 0 then
            out.m1_strength = 0.5 * util.unit (math.abs (ef - es) / atr / 1.5)
                + 0.5 * util.unit (math.abs (slope) / (3 * math.max (cfg.regime.slope_min, 1e-4)))
        end
        local side, k = (out.m1_dir ~= 0) and out.m1_dir or ((em > es) and 1 or -1), 0
        for i = n - 9, n do
            if f.ema_m[i] and (f.C[i] - f.ema_m[i]) * side > 0 then k = k + 1 end
        end
        out.consistency = k / 10
        local lo, hi = f.swing_lows[#f.swing_lows], f.swing_highs[#f.swing_highs]
        out.reversal[1] = em > es and lo ~= nil and c < lo.price
        out.reversal[-1] = em < es and hi ~= nil and c > hi.price
    end
    out.m5 = f5 and M.m5_bias (f5, cfg) or { bias = 0, strength = 0, available = false }
    out.conflict = out.m1_dir ~= 0 and out.m5.bias ~= 0 and out.m1_dir ~= out.m5.bias
    return out
end

return M
