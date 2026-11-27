-- =====================================================================
--  MODULE 4 — momentum_analysis
--
--  Two non-redundant measures:
--    * MACD histogram / ATR  -> direction, strength, acceleration
--    * RSI(14)               -> exhaustion levels and divergence only
--  analyze(f, cfg) -> {
--     dir        sign of hist[n]
--     strength   0..1   |hist| / ATR, saturating at hist_strong_atr
--     accel      +1 hist rising two bars in a row, -1 falling, 0 mixed
--     rsi        RSI[n]
--     side[s]    for s = 1 (CALL) / -1 (PUT):
--        aligned      hist on side s
--        accelerating hist moving toward s on the last two bars
--        decelerating |hist| on side s shrinking two bars in a row
--        turning      hist moved toward s on the last bar (any sign)
--        exhausted    RSI beyond the exhaust level on side s, or
--                     >= exhaust_run consecutive candles toward s, or
--                     climax body >= climax_body_atr * ATR toward s
--        divergence   divergence AGAINST s (bearish div for CALL):
--                     newest two confirmed swing highs make a higher high
--                     while RSI at those pivots falls by >= div_min_rsi;
--                     newest pivot no older than div_max_age bars
--  }
-- =====================================================================
local util = require ("util")
local M = {}

local function divergence (swings, rsi, n, sgn, cfg)
    local k = #swings
    if k < 2 then return false end
    local a, b = swings[k - 1], swings[k]
    if n - b.i > cfg.momentum.div_max_age then return false end
    local ra, rb = rsi[a.i], rsi[b.i]
    if ra == nil or rb == nil then return false end
    return sgn * (b.price - a.price) > 0 and sgn * (ra - rb) >= cfg.momentum.div_min_rsi
end
M.divergence = divergence

function M.analyze (f, cfg)
    local n, mc = f.n, cfg.momentum
    local h0, h1, h2 = f.hist[n], f.hist[n - 1], f.hist[n - 2]
    local atr, rsi = f.atr[n - 1] or f.atr[n], f.rsi[n]
    local out = { available = false, side = {} }
    if h0 == nil or h1 == nil or h2 == nil or atr == nil or atr <= 0 or rsi == nil then return out end
    out.available, out.rsi = true, rsi
    out.dir = util.sign (h0)
    out.hist_atr = h0 / atr
    out.strength = util.unit (math.abs (h0) / atr / mc.hist_strong_atr)
    out.accel = (h0 > h1 and h1 > h2) and 1 or ((h0 < h1 and h1 < h2) and -1 or 0)
    for _, s in ipairs ({ 1, -1 }) do
        local x = {}
        x.aligned = s * h0 > 0
        x.accelerating = s * (h0 - h1) > 0 and s * (h1 - h2) > 0
        x.decelerating = x.aligned and s * h1 > 0 and s * (h0 - h1) < 0 and s * (h1 - h2) < 0
        x.turning = s * (h0 - h1) > 0
        local run = 0
        for i = n, math.max (1, n - mc.exhaust_run), -1 do
            if s * (f.C[i] - f.O[i]) > 0 then run = run + 1 else break end
        end
        local body = s * (f.C[n] - f.O[n])
        x.run = run
        x.exhausted = (s == 1 and rsi >= mc.exhaust_rsi_high) or (s == -1 and rsi <= mc.exhaust_rsi_low)
            or run >= mc.exhaust_run or body >= mc.climax_body_atr * atr
        -- against CALL: bearish divergence on swing highs; against PUT: bullish on swing lows
        if s == 1 then x.divergence = divergence (f.swing_highs, f.rsi, n, 1, cfg)
        else x.divergence = divergence (f.swing_lows, f.rsi, n, -1, cfg) end
        out.side[s] = x
    end
    return out
end

return M
