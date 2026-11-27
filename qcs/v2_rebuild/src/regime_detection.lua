-- =====================================================================
--  MODULE 2 — regime_detection
--
--  raw_at(f, i, cfg) -> regime, metrics     (uses features at index <= i)
--  detect(f, cfg)    -> { regime, raw, direction, sub, metrics }
--
--  Regimes (priority order):
--    HIGH_VOL  ATR/baseline >= hv_atr_ratio
--    LOW_VOL   ATR/baseline <= lv_atr_ratio
--    UNSTABLE  >= whipsaw_crosses EMA9/EMA21 crosses in whipsaw_lookback (sub WHIPSAW)
--    TRENDING  ER >= er_trend, |EMA50 slope| >= slope_min, EMA9/21/50 stacked
--              in the slope direction and close on that side of EMA50
--    RANGING   ER <= er_range and |slope| < slope_min
--    UNSTABLE  otherwise (sub UNCLEAR)
--  Confirmation (stateless, no repaint): the confirmed regime is the raw
--  regime of the newest closed candle only if the raw regime of the last
--  confirm_bars candles agrees; HIGH_VOL is confirmed immediately
--  (safety). Otherwise UNSTABLE/TRANSITION.
-- =====================================================================
local M = {}

local function slope_at (f, i)
    local a, b, atr = f.ema_s[i], f.ema_s[i - 5], f.atr[i]
    if a == nil or b == nil or atr == nil or atr <= 0 then return nil end
    return (a - b) / (5 * atr)
end
M.slope_at = slope_at

function M.crosses (f, i, n)
    local cnt, prev = 0, nil
    for j = i - n + 1, i do
        local a, b = f.ema_f[j], f.ema_m[j]
        if a ~= nil and b ~= nil and a ~= b then
            local s = a > b and 1 or -1
            if prev ~= nil and s ~= prev then cnt = cnt + 1 end
            prev = s
        end
    end
    return cnt
end

function M.raw_at (f, i, cfg)
    local r = cfg.regime
    local atr, base, er = f.atr[i], f.atr_base[i], f.er[i]
    local slope = slope_at (f, i)
    local ef, em, es, c = f.ema_f[i], f.ema_m[i], f.ema_s[i], f.C[i]
    if atr == nil or base == nil or base <= 0 or er == nil or slope == nil or ef == nil or em == nil or es == nil then
        return "UNSTABLE", { sub = "NO_DATA" }
    end
    local m = { atr_ratio = atr / base, er = er, slope = slope, crosses = M.crosses (f, i, cfg.regime.whipsaw_lookback) }
    if m.atr_ratio >= r.hv_atr_ratio then return "HIGH_VOL", m end
    if m.atr_ratio <= r.lv_atr_ratio then return "LOW_VOL", m end
    if m.crosses >= r.whipsaw_crosses then m.sub = "WHIPSAW"; return "UNSTABLE", m end
    local up = ef > em and em > es and c > es and slope >= r.slope_min
    local dn = ef < em and em < es and c < es and slope <= -r.slope_min
    if er >= r.er_trend and (up or dn) then m.dir = up and 1 or -1; return "TRENDING", m end
    if er <= r.er_range and math.abs (slope) < r.slope_min then return "RANGING", m end
    m.sub = "UNCLEAR"
    return "UNSTABLE", m
end

function M.detect (f, cfg)
    local n = f.n
    local raw, m = M.raw_at (f, n, cfg)
    local out = { raw = raw, metrics = m, direction = m.dir or 0, sub = m.sub }
    if raw == "HIGH_VOL" then out.regime = "HIGH_VOL"; return out end
    local agree = true
    for k = 1, cfg.regime.confirm_bars - 1 do
        local r2, m2 = M.raw_at (f, n - k, cfg)
        if r2 ~= raw or (raw == "TRENDING" and m2.dir ~= m.dir) then agree = false; break end
    end
    if agree then out.regime = raw
    else out.regime, out.sub, out.direction = "UNSTABLE", "TRANSITION", 0 end
    return out
end

return M
