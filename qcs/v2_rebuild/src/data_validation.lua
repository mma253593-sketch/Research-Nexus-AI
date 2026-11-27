-- =====================================================================
--  MODULE 1 — data_validation
--
--  prepare(input, cfg) -> result
--    input = { now = <unix seconds of the evaluation instant>,
--              m1  = { {t=, o=, h=, l=, c=, closed=?}, ... }  chronological,
--              m5  = optional, same shape with 300 s candles }
--    t = candle OPEN time (unix seconds, multiple of the period).
--    A candle is COMPLETE when closed == true, or closed == nil and
--    t + period <= now. closed == false or t + period > now -> incomplete.
--
--    result = { ok, errors = {codes}, warnings = {codes},
--               m1 = closed contiguous window (bounded by data.m1_window),
--               m5 = closed M5 candles, m5_source, stats = {...} }
--
--  Policy: any error -> ok = false and the engine returns WAIT. Nothing
--  is interpolated, sorted or repaired silently; only identical duplicate
--  candles may be dropped (configurable) and that is reported.
-- =====================================================================
local util = require ("util")

local M = {}

local function add (list, code) if not util.contains (list, code) then list[#list + 1] = code end end

--- structural check of one candle -> nil or an error code
function M.check_candle (b, period)
    if type (b) ~= "table" then return "CANDLE_NOT_TABLE" end
    local fin = util.finite
    if not (fin (b.t) and fin (b.o) and fin (b.h) and fin (b.l) and fin (b.c)) then return "CANDLE_FIELD_INVALID" end
    if math.floor (b.t) ~= b.t or b.t % period ~= 0 then return "TIMESTAMP_MISALIGNED" end
    if b.o <= 0 or b.h <= 0 or b.l <= 0 or b.c <= 0 then return "OHLC_NON_POSITIVE" end
    if b.h < b.l or b.h < math.max (b.o, b.c) or b.l > math.min (b.o, b.c) then return "OHLC_INCONSISTENT" end
    if b.closed ~= nil and type (b.closed) ~= "boolean" then return "CLOSED_FLAG_INVALID" end
    return nil
end

local function same (a, b) return a.o == b.o and a.h == b.h and a.l == b.l and a.c == b.c end

--- validates a candle list -> closed candles (chronological) + counters.
--- prefix distinguishes M1_/M5_ codes.
function M.closed_candles (list, period, now, cfg, prefix, errs, warns)
    local out, stats = {}, { input = 0, incomplete = 0, duplicates = 0 }
    if type (list) ~= "table" then add (errs, prefix .. "DATA_MISSING"); return out, stats end
    stats.input = #list
    local prev, seen_incomplete = nil, false
    for i = 1, #list do
        local b = list[i]
        local e = M.check_candle (b, period)
        if e then add (errs, prefix .. e)
        else
            local complete = (b.closed == true) or (b.closed == nil and b.t + period <= now)
            if b.t > now then add (errs, prefix .. "FUTURE_CANDLE")            -- look-ahead guard
            elseif b.closed == true and b.t + period > now then add (errs, prefix .. "CLOSED_FLAG_BEFORE_CLOSE")
            elseif prev and b.t < prev.t then add (errs, prefix .. "OUT_OF_ORDER")
            elseif prev and b.t == prev.t then
                stats.duplicates = stats.duplicates + 1
                if not same (b, prev) or (b.closed ~= prev.closed) then add (errs, prefix .. "DUPLICATE_CONFLICT")
                elseif not cfg.data.dedupe_identical then add (errs, prefix .. "DUPLICATE_CANDLE")
                else add (warns, prefix .. "DUPLICATE_DROPPED") end
            elseif not complete then
                stats.incomplete = stats.incomplete + 1
                add (warns, prefix .. "INCOMPLETE_DROPPED")
                prev, seen_incomplete = b, true
            else
                if seen_incomplete then add (errs, prefix .. "INCOMPLETE_BEFORE_CLOSED") end
                out[#out + 1] = { t = b.t, o = b.o, h = b.h, l = b.l, c = b.c }
                prev = b
            end
        end
    end
    return out, stats
end

--- aggregate closed M1 candles into clock-aligned M5 buckets
function M.aggregate_m5 (m1, now, cfg)
    local P, need = cfg.data.m5_period, cfg.data.m5_min_minutes
    local out, cur = {}, nil
    local function flush ()
        if cur and cur.n >= need and cur.t + P <= now then
            out[#out + 1] = { t = cur.t, o = cur.o, h = cur.h, l = cur.l, c = cur.c, minutes = cur.n }
        end
    end
    for _, b in ipairs (m1) do
        local k = b.t - b.t % P
        if cur == nil or cur.t ~= k then
            flush ()
            cur = { t = k, o = b.o, h = b.h, l = b.l, c = b.c, n = 1 }
        else
            cur.h, cur.l, cur.c, cur.n = math.max (cur.h, b.h), math.min (cur.l, b.l), b.c, cur.n + 1
        end
    end
    flush ()
    return out
end

function M.prepare (input, cfg)
    local d = cfg.data
    local errs, warns = {}, {}
    local res = { ok = false, errors = errs, warnings = warns, m1 = {}, m5 = {}, m5_source = "none", stats = {} }
    if type (input) ~= "table" then add (errs, "INPUT_INVALID"); return res end
    local now = input.now
    if not util.finite (now) or math.floor (now) ~= now then add (errs, "NOW_INVALID"); return res end

    local closed, st = M.closed_candles (input.m1, d.m1_period, now, cfg, "M1_", errs, warns)
    res.stats.m1 = st
    if #errs > 0 then return res end
    if #closed == 0 then add (errs, "M1_NO_CLOSED_CANDLES"); return res end

    -- contiguous segment ending at the newest closed candle
    local P, start, resets = d.m1_period, 1, 0
    for i = #closed, 2, -1 do
        local missing = (closed[i].t - closed[i - 1].t) / P - 1
        if missing > d.max_gap_candles then start = i; resets = 1; break end
    end
    if resets > 0 then add (warns, "M1_HISTORY_RESET_AT_GAP") end
    local first = math.max (start, #closed - d.m1_window + 1)
    local win = util.slice (closed, first, #closed)
    local span = (win[#win].t - win[1].t) / P + 1
    local missing = span - #win
    res.stats.window, res.stats.missing = #win, missing
    if missing > 0 then add (warns, "M1_MISSING_CANDLES") end
    if missing / span > d.max_missing_ratio then add (errs, "M1_TOO_MANY_MISSING") end
    if #win < d.min_m1_bars then add (errs, "INSUFFICIENT_HISTORY") end
    local age = now - (win[#win].t + P)
    res.stats.staleness_sec = age
    if age >= d.max_staleness_sec then add (errs, "STALE_DATA") end
    res.m1 = win

    -- M5 context: provided or aggregated from clock-aligned M1 buckets
    local P5 = d.m5_period
    local agg = M.aggregate_m5 (win, now, cfg)
    local use_provided = input.m5 ~= nil and d.m5_source ~= "aggregate"
    if d.m5_source == "provided" and input.m5 == nil then add (errs, "M5_MISSING") end
    local m5 = agg
    res.m5_source = "aggregate"
    if use_provided then
        local p5, st5 = M.closed_candles (input.m5, P5, now, cfg, "M5_", errs, warns)
        res.stats.m5 = st5
        m5, res.m5_source = p5, "provided"
        -- cross-check the newest bucket that M1 fully covers
        local by = {}
        for _, b in ipairs (p5) do by[b.t] = b end
        for i = #agg, 1, -1 do
            local a = agg[i]
            if a.minutes == P5 / P then
                local b = by[a.t]
                if b then
                    local tol = d.m5_tolerance_rel * a.c
                    if math.abs (a.o - b.o) > tol or math.abs (a.h - b.h) > tol or math.abs (a.l - b.l) > tol
                       or math.abs (a.c - b.c) > tol then add (errs, "M5_M1_MISMATCH") end
                end
                break
            end
        end
    end
    -- bound the M5 history and check alignment with `now`
    if #m5 > 200 then m5 = util.slice (m5, #m5 - 199, #m5) end
    res.m5 = m5
    local expected = now - now % P5 - P5
    if #m5 == 0 or m5[#m5].t ~= expected then add (errs, "M5_STALE_OR_MISALIGNED") end
    for i = 2, #m5 do
        if m5[i].t - m5[i - 1].t ~= P5 then add (warns, "M5_GAP"); break end
    end
    if #m5 < d.min_m5_bars then add (errs, "M5_INSUFFICIENT") end
    table.sort (errs); table.sort (warns)
    res.ok = #errs == 0
    return res
end

return M
