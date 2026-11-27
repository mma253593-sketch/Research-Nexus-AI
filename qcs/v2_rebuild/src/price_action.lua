-- =====================================================================
--  MODULE 5 — price_action
--
--  analyze(f, cfg) -> { side = { [1] = P, [-1] = P }, structure_levels }
--  Everything is measured on CLOSED candles n (newest) and n-1, in the
--  frame of side s: PUT mirrors prices (x -> -x, high <-> low), so one
--  rule set serves both sides. ATR reference = ATR[n-1] (before the
--  trigger candle, so a large candle cannot inflate its own threshold).
--
--  Pattern definitions (CALL frame; points used by the scorer):
--   ENGULF (20)      n bullish, n-1 bearish, C[n] >= O[n-1], O[n] <= C[n-1],
--                    body[n] >= 1.1 body[n-1], body[n] >= engulf_min_body_atr ATR,
--                    body[n-1] >= 0.1 ATR, close location >= 0.65
--   REJECTION_CONF (18) n-1 has lower wick >= pin_wick_ratio of range, range
--                    >= 0.5 ATR; n bullish, closes above n-1 body, cl.loc >= 0.6
--   FAILED_BREAK (17) low[n] < support - buffer ATR, close[n] > support, cl.loc >= 0.6
--   BREAKOUT (16)    nearest resistance R above close[n-1]: close[n] > R + buffer ATR,
--                    bullish, body >= 0.5 range, cl.loc >= strong_close,
--                    body <= max_trigger_body_atr ATR
--   REJECTION (15)   n: lower wick >= pin_wick_ratio range, upper wick <= 0.25
--                    range, range >= 0.5 ATR, cl.loc >= 0.6
--   STRONG_CLOSE (12) bullish, body >= 0.55 range, cl.loc >= 0.75,
--                    0.35 <= body/ATR <= max_trigger_body_atr
--  Levels: confirmed swing pivots (indicators.pivots) + range extremes of
--  the range_lookback candles before n.
-- =====================================================================
local util = require ("util")
local M = {}

M.POINTS = { ENGULF = 20, REJECTION_CONF = 18, FAILED_BREAK = 17, BREAKOUT = 16, REJECTION = 15, STRONG_CLOSE = 12 }

local function frame (f, s)
    local H, L, O, C = f.H, f.L, f.O, f.C
    if s == 1 then
        return function (i) return H[i] end, function (i) return L[i] end,
               function (i) return O[i] end, function (i) return C[i] end
    end
    return function (i) return -L[i] end, function (i) return -H[i] end,
           function (i) return -O[i] end, function (i) return -C[i] end
end

function M.geometry (hi, lo, op, cl, i)
    local h, l, o, c = hi (i), lo (i), op (i), cl (i)
    local rng = math.max (h - l, 1e-9)
    return { rng = rng, body = math.abs (c - o), bull = c > o, bear = c < o,
             upw = h - math.max (c, o), loww = math.min (c, o) - l, cpos = (c - l) / rng }
end

function M.analyze_side (f, s, cfg)
    local pa, en = cfg.price_action, cfg.entry
    local n = f.n
    local atr = f.atr[n - 1]
    local hi, lo, op, cl = frame (f, s)
    local g, g1 = M.geometry (hi, lo, op, cl, n), M.geometry (hi, lo, op, cl, n - 1)
    local c, c1 = cl (n), cl (n - 1)
    local out = { geom = g, patterns = {}, best = "NONE", points = 0 }

    -- levels in this frame: ahead (obstacles in trade direction) and behind
    local ahead, behind = {}, {}
    local A = s == 1 and f.swing_highs or f.swing_lows
    local B = s == 1 and f.swing_lows or f.swing_highs
    for _, p in ipairs (A) do ahead[#ahead + 1] = s * p.price end
    for _, p in ipairs (B) do behind[#behind + 1] = s * p.price end
    local rhi, rlo = -math.huge, math.huge
    for i = math.max (1, n - pa.range_lookback), n - 1 do rhi = math.max (rhi, hi (i)); rlo = math.min (rlo, lo (i)) end
    ahead[#ahead + 1], behind[#behind + 1] = rhi, rlo
    out.range_hi, out.range_lo = rhi, rlo
    out.range_pos = (rhi > rlo) and util.unit ((c - rlo) / (rhi - rlo)) or 0.5

    -- room to the nearest obstacle ahead of the close
    local room = en.room_cap_atr
    for _, x in ipairs (ahead) do if x > c then room = math.min (room, (x - c) / atr) end end
    out.room_atr = room
    -- nearest level behind the close (support in CALL frame)
    local sup = nil
    for _, x in ipairs (behind) do if x <= c and (sup == nil or x > sup) then sup = x end end
    out.support = sup
    out.at_support = sup ~= nil and math.min (lo (n), lo (n - 1)) <= sup + pa.level_touch_atr * atr
    out.at_range_low = math.min (lo (n), lo (n - 1)) <= rlo + pa.level_touch_atr * atr

    local function take (name)
        out.patterns[#out.patterns + 1] = name
        if M.POINTS[name] > out.points then out.points, out.best = M.POINTS[name], name end
    end
    if g.bull and g1.bear and c >= op (n - 1) and op (n) <= c1 and g.body >= 1.1 * g1.body
       and g.body >= pa.engulf_min_body_atr * atr and g1.body >= 0.1 * atr and g.cpos >= 0.65 then take ("ENGULF") end
    if g1.loww >= pa.pin_wick_ratio * g1.rng and g1.rng >= 0.5 * atr and g.bull
       and c > math.max (op (n - 1), c1) and g.cpos >= 0.6 then take ("REJECTION_CONF") end
    -- failed break: sweep of the most recent level behind (swing or range low) and reclaim
    local swept = nil
    for _, x in ipairs (behind) do
        if lo (n) < x - pa.breakout_buffer_atr * atr and c > x and (swept == nil or x > swept) then swept = x end
    end
    if swept ~= nil and g.cpos >= 0.6 then take ("FAILED_BREAK"); out.swept_level = swept end
    -- breakout through the nearest level that was above the previous close
    local lvl = nil
    for _, x in ipairs (ahead) do if x >= c1 and (lvl == nil or x < lvl) then lvl = x end end
    if lvl ~= nil and c > lvl + pa.breakout_buffer_atr * atr and g.bull and g.body >= 0.5 * g.rng
       and g.cpos >= pa.strong_close and g.body <= en.max_trigger_body_atr * atr then
        take ("BREAKOUT"); out.breakout_level = lvl
    end
    if g.loww >= pa.pin_wick_ratio * g.rng and g.upw <= 0.25 * g.rng and g.rng >= 0.5 * atr and g.cpos >= 0.6 then
        take ("REJECTION") end
    if g.bull and g.body >= 0.55 * g.rng and g.cpos >= 0.75 and g.body >= 0.35 * atr
       and g.body <= en.max_trigger_body_atr * atr then take ("STRONG_CLOSE") end

    local run = 0
    for i = n, 1, -1 do if cl (i) > op (i) then run = run + 1 else break end end
    out.run = run
    out.wick_against = g.upw / g.rng
    return out
end

function M.analyze (f, cfg)
    return { side = { [1] = M.analyze_side (f, 1, cfg), [-1] = M.analyze_side (f, -1, cfg) } }
end

return M
