-- =====================================================================
--  MODULE 6 — entry_timing
--
--  analyze_side(f, s, pa, prof, cfg) -> { [SETUP] = E, ... } for the
--  setups allowed by the profile. E = {
--     present   setup conditions met on the closed candles
--     trigger   price-action pattern used
--     ext       extension in ATR from the setup's reference (ext_ref):
--               PULLBACK -> EMA9 (the mean price pulled back to; FAST_ENTRY_AUDIT §2),
--               TREND -> EMA21, BREAKOUT -> the broken level, RANGE -> EMA21 (info)
--     room      ATR to the nearest obstacle ahead
--     late      true when the move is already extended (late_why says why)
--     no_room   room < profile.min_room_atr
--     quality   0..1 timing quality (room beyond minimum + closeness to EMA21)
--  }
--  The entry is the OPEN of the candle after the newest closed candle n;
--  nothing here reads a candle that has not closed.
--
--  Setup rules (CALL frame, PUT mirrored):
--   PULLBACK_CONTINUATION  EMA21 > EMA50 and EMA50 slope > 0; within the
--      pullback_lookback candles before n at least one counter candle,
--      a low touching EMA9 + pullback_zone_atr ATR, and no close below
--      EMA50; candle n triggers (ENGULF/REJECTION*/FAILED_BREAK/
--      STRONG_CLOSE), is bullish and closes above EMA9.
--   TREND_CONTINUATION  EMA9 > EMA21 > EMA50, slope >= slope_min, trigger
--      ENGULF/STRONG_CLOSE/BREAKOUT, close > EMA9 and close[n-1] > EMA9.
--   BREAKOUT_CONFIRMATION  BREAKOUT pattern on candle n; late when the close
--      is more than entry.breakout_max_ext_atr beyond the broken level.
--   RANGE_REJECTION  low of n or n-1 at support / range low, trigger
--      REJECTION*/ENGULF/FAILED_BREAK, RSI (side frame) at n-1 <= 50,
--      close in the lower 60% of the range.
-- =====================================================================
local util = require ("util")
local price_action = require ("price_action")
local M = {}

local PB_TRIG = { ENGULF = true, REJECTION_CONF = true, REJECTION = true, FAILED_BREAK = true, STRONG_CLOSE = true }
local TC_TRIG = { ENGULF = true, STRONG_CLOSE = true, BREAKOUT = true }
local RR_TRIG = { REJECTION_CONF = true, REJECTION = true, ENGULF = true, FAILED_BREAK = true }

local function pick (pa, allowed)
    local best, pts = nil, -1
    for _, p in ipairs (pa.patterns) do
        local v = price_action.POINTS[p]
        if allowed[p] and v > pts then best, pts = p, v end
    end
    return best
end

function M.analyze_side (f, s, pa, prof, cfg)
    local en, n = cfg.entry, f.n
    local atr = f.atr[n - 1]
    local e9, e21, e50 = s * f.ema_f[n], s * f.ema_m[n], s * f.ema_s[n]
    local es5 = f.ema_s[n - 5]
    local slope = s * (f.ema_s[n] - es5) / (5 * f.atr[n])
    local c, c1 = s * f.C[n], s * f.C[n - 1]
    local g = pa.geom
    local ext21 = (c - e21) / atr
    local move3 = (c - s * f.O[n - 2]) / atr
    local out = {}

    for _, setup in ipairs (prof.setups) do
        local E = { present = false, ext = ext21, ext_ref = "EMA21", room = pa.room_atr, late = false }
        local max_ext = prof.max_ext_atr
        if setup == "PULLBACK_CONTINUATION" then
            local touched, counter, inside = false, false, true
            for i = n - en.pullback_lookback, n - 1 do
                local lo = (s == 1) and f.L[i] or -f.H[i]
                if lo <= s * f.ema_f[i] + en.pullback_zone_atr * atr then touched = true end
                if s * (f.C[i] - f.O[i]) < 0 then counter = true end
                if s * f.C[i] <= s * f.ema_s[i] then inside = false end
            end
            E.trigger = pick (pa, PB_TRIG)
            E.present = e21 > e50 and slope > 0 and touched and counter and inside
                and E.trigger ~= nil and g.bull and c > e9
            E.ext, E.ext_ref = (c - e9) / atr, "EMA9"
        elseif setup == "TREND_CONTINUATION" then
            E.trigger = pick (pa, TC_TRIG)
            E.present = e9 > e21 and e21 > e50 and slope >= cfg.regime.slope_min and E.trigger ~= nil
                and c > e9 and c1 > s * f.ema_f[n - 1]
        elseif setup == "BREAKOUT_CONFIRMATION" then
            E.trigger = util.contains (pa.patterns, "BREAKOUT") and "BREAKOUT" or nil
            E.present = E.trigger ~= nil
            if pa.breakout_level then E.ext, E.ext_ref = (c - pa.breakout_level) / atr, "BREAKOUT_LEVEL" end
            max_ext = en.breakout_max_ext_atr
        elseif setup == "RANGE_REJECTION" then
            local r1 = f.rsi[n - 1]
            r1 = (s == 1) and r1 or (r1 and 100 - r1)
            E.trigger = pick (pa, RR_TRIG)
            E.present = (pa.at_support or pa.at_range_low) and E.trigger ~= nil and r1 ~= nil and r1 <= 50
                and pa.range_pos <= 0.6
        end
        -- timing
        if setup == "RANGE_REJECTION" then
            if pa.range_pos > 0.6 then E.late, E.late_why = true, "RANGE_MIDDLE" end
        elseif E.ext > max_ext then E.late, E.late_why = true, "EXTENDED_FROM_" .. E.ext_ref end
        if not E.late and move3 > en.late_move_atr then E.late, E.late_why = true, "MOVE_ALREADY_MADE" end
        if not E.late and g.body > en.max_trigger_body_atr * atr then E.late, E.late_why = true, "TRIGGER_TOO_LARGE" end
        E.no_room = pa.room_atr < prof.min_room_atr
        E.quality = 0.5 * util.unit ((pa.room_atr - prof.min_room_atr) / 1.5)
            + 0.5 * (1 - util.unit (math.max (E.ext, 0) / math.max (max_ext, 0.1)))
        out[setup] = E
    end
    return out
end

return M
