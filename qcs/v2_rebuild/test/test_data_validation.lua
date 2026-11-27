-- Requirements 1-7 (+ invalid data never trades): data validation.
local F = require ("fixtures")
local DV = require ("data_validation")
local E = require ("main")
local C = require ("config")

return function (T)
    local cfg = assert (C.load ())
    local base = F.series (F.UP, 5)                 -- 320 contiguous closed candles

    local function prep (m1, extra) return DV.prepare (F.input (m1, extra), cfg) end

    T.case ("valid contiguous data passes", function ()
        local r = prep (F.copy (base))
        T.ok (r.ok, table.concat (r.errors, ","))
        T.eq (#r.m1, cfg.data.m1_window, "window bounded")
        T.eq (r.m1[#r.m1].t, base[#base].t, "newest candle kept")
        T.eq (r.m5_source, "aggregate")
    end)

    T.case ("invalid OHLC: high below low / body outside range / non-positive / NaN", function ()
        local cases = {
            { f = function (b) b.h, b.l = b.l - 1, b.h end, code = "M1_OHLC_INCONSISTENT" },
            { f = function (b) b.h = math.max (b.o, b.c) - 0.5 end, code = "M1_OHLC_INCONSISTENT" },
            { f = function (b) b.l = math.min (b.o, b.c) + 0.5 end, code = "M1_OHLC_INCONSISTENT" },
            { f = function (b) b.o, b.l = -1, -2 end, code = "M1_OHLC_NON_POSITIVE" },
            { f = function (b) b.c = 0 / 0 end, code = "M1_CANDLE_FIELD_INVALID" },
            { f = function (b) b.h = math.huge end, code = "M1_CANDLE_FIELD_INVALID" },
            { f = function (b) b.o = "2650" end, code = "M1_CANDLE_FIELD_INVALID" },
            { f = function (b) b.t = b.t + 7 end, code = "M1_TIMESTAMP_MISALIGNED" },
            { f = function (b) b.closed = "yes" end, code = "M1_CLOSED_FLAG_INVALID" },
        }
        for _, cs in ipairs (cases) do
            local m1 = F.copy (base)
            cs.f (m1[300])
            local r = prep (m1)
            T.no (r.ok, cs.code)
            T.has (r.errors, cs.code)
            T.eq (E.evaluate (F.input (m1), cfg).decision, "WAIT", "invalid OHLC must WAIT")
        end
    end)

    T.case ("missing candles: small gap tolerated with warning, ratio limit enforced", function ()
        local m1 = F.copy (base)
        table.remove (m1, 300)                       -- one missing minute
        local r = prep (m1)
        T.ok (r.ok, table.concat (r.errors, ","))
        T.has (r.warnings, "M1_MISSING_CANDLES")
        T.eq (r.stats.missing, 1)
        local strict = assert (C.load ({ data = { max_missing_ratio = 0 } }))
        local r2 = DV.prepare (F.input (m1), strict)
        T.has (r2.errors, "M1_TOO_MANY_MISSING")
    end)

    T.case ("large gap resets history -> insufficient history -> WAIT", function ()
        local m1 = F.copy (base)
        for _ = 1, 5 do table.remove (m1, 250) end   -- 5 missing > max_gap_candles (3)
        local r = prep (m1)
        T.has (r.warnings, "M1_HISTORY_RESET_AT_GAP")
        T.has (r.errors, "INSUFFICIENT_HISTORY")
        local res = E.evaluate (F.input (m1), cfg)
        T.eq (res.decision, "WAIT"); T.has (res.reasons, "INSUFFICIENT_HISTORY")
    end)

    T.case ("duplicate timestamps: identical dropped with warning, conflicting rejected", function ()
        local m1 = F.copy (base)
        table.insert (m1, 300, F.copy ({ m1[300] })[1])
        local r = prep (m1)
        T.ok (r.ok); T.has (r.warnings, "M1_DUPLICATE_DROPPED")
        local nod = assert (C.load ({ data = { dedupe_identical = false } }))
        T.has (DV.prepare (F.input (m1), nod).errors, "M1_DUPLICATE_CANDLE")
        local m2 = F.copy (base)
        local d = F.copy ({ m2[300] })[1]; d.c = d.c + 0.01; d.h = math.max (d.h, d.c)
        table.insert (m2, 301, d)
        T.has (prep (m2).errors, "M1_DUPLICATE_CONFLICT")
    end)

    T.case ("out-of-order candles rejected (never silently sorted)", function ()
        local m1 = F.copy (base)
        m1[300], m1[301] = m1[301], m1[300]
        local r = prep (m1)
        T.has (r.errors, "M1_OUT_OF_ORDER")
        T.eq (E.evaluate (F.input (m1), cfg).decision, "WAIT")
    end)

    T.case ("incomplete candles: forming candle dropped, incomplete-before-closed rejected", function ()
        local m1 = F.copy (base)
        local now = m1[#m1].t + 30                   -- newest candle is still forming
        local r = DV.prepare ({ m1 = m1, now = now }, cfg)
        T.has (r.warnings, "M1_INCOMPLETE_DROPPED")
        T.eq (r.m1[#r.m1].t, m1[#m1 - 1].t, "forming candle excluded")
        local m2 = F.copy (base); m2[#m2].closed = false
        local r2 = prep (m2)
        T.has (r2.warnings, "M1_INCOMPLETE_DROPPED")
        T.eq (r2.m1[#r2.m1].t, m2[#m2 - 1].t)
        local m3 = F.copy (base); m3[200].closed = false
        T.has (prep (m3).errors, "M1_INCOMPLETE_BEFORE_CLOSED")
    end)

    T.case ("future candles and premature closed flags are rejected (look-ahead guard)", function ()
        local m1 = F.copy (base)
        local now = m1[#m1].t                        -- the last candle opens exactly at `now`
        T.has (DV.prepare ({ m1 = m1, now = now - 60 }, cfg).errors, "M1_FUTURE_CANDLE")
        m1[#m1].closed = true
        T.has (DV.prepare ({ m1 = m1, now = now + 30 }, cfg).errors, "M1_CLOSED_FLAG_BEFORE_CLOSE")
    end)

    T.case ("stale data rejected", function ()
        local m1 = F.copy (base)
        local r = DV.prepare ({ m1 = m1, now = m1[#m1].t + 60 + 60 }, cfg)
        T.has (r.errors, "STALE_DATA")
    end)

    T.case ("insufficient history rejected", function ()
        local m1 = F.copy ({ table.unpack (base, 1, cfg.data.min_m1_bars - 1) })
        T.has (prep (m1).errors, "INSUFFICIENT_HISTORY")
        local ok = F.copy ({ table.unpack (base, 1, cfg.data.min_m1_bars) })
        T.lacks (prep (ok).errors, "INSUFFICIENT_HISTORY")
    end)

    T.case ("empty / malformed input -> WAIT, never an exception", function ()
        for _, input in ipairs ({ {}, { m1 = {} , now = F.T0 }, { m1 = "x", now = F.T0 }, { m1 = base, now = 1.5 },
                                  { m1 = base } }) do
            local r = E.evaluate (input, cfg)
            T.eq (r.decision, "WAIT"); T.has (r.reasons, "DATA_INVALID")
        end
        T.eq (E.evaluate (nil, cfg).decision, "WAIT")
    end)

    T.case ("M1/M5 aggregation is clock aligned, complete buckets only", function ()
        local m1 = F.copy (base)
        local now = F.now_after (m1)
        local agg = DV.aggregate_m5 (m1, now, cfg)
        for _, b in ipairs (agg) do
            T.eq (b.t % 300, 0, "bucket aligned")
            T.ok (b.t + 300 <= now, "bucket closed")
            T.ok (b.minutes >= cfg.data.m5_min_minutes)
        end
        -- recompute one bucket by hand
        local k = agg[#agg].t
        local hi, lo = -math.huge, math.huge
        local first, last
        for _, b in ipairs (m1) do
            if b.t >= k and b.t < k + 300 then
                hi, lo = math.max (hi, b.h), math.min (lo, b.l)
                first = first or b; last = b
            end
        end
        T.eq (agg[#agg].h, hi); T.eq (agg[#agg].l, lo); T.eq (agg[#agg].o, first.o); T.eq (agg[#agg].c, last.c)
        -- evaluation mid-bucket: the forming M5 bucket must be excluded
        local cut = {}
        for _, b in ipairs (m1) do if b.t + 60 <= k + 120 then cut[#cut + 1] = b end end
        local agg2 = DV.aggregate_m5 (cut, k + 120, cfg)
        T.ok (agg2[#agg2].t < k, "forming M5 bucket excluded")
    end)

    T.case ("provided M5: consistent accepted, mismatching / stale / missing rejected", function ()
        local m1 = F.copy (base)
        local now = F.now_after (m1)
        local m5 = DV.aggregate_m5 (m1, now, cfg)
        for _, b in ipairs (m5) do b.minutes = nil end
        local r = DV.prepare ({ m1 = m1, m5 = m5, now = now }, cfg)
        T.ok (r.ok, table.concat (r.errors, ",")); T.eq (r.m5_source, "provided")
        local bad = F.copy (m5); bad[#bad].c = bad[#bad].c + 5; bad[#bad].h = math.max (bad[#bad].h, bad[#bad].c)
        T.has (DV.prepare ({ m1 = m1, m5 = bad, now = now }, cfg).errors, "M5_M1_MISMATCH")
        local stale = F.copy (m5); stale[#stale] = nil
        T.has (DV.prepare ({ m1 = m1, m5 = stale, now = now }, cfg).errors, "M5_STALE_OR_MISALIGNED")
        local mis = F.copy (m5); mis[5].t = mis[5].t + 60
        T.has (DV.prepare ({ m1 = m1, m5 = mis, now = now }, cfg).errors, "M5_TIMESTAMP_MISALIGNED")
        local need = assert (C.load ({ data = { m5_source = "provided" } }))
        T.has (DV.prepare ({ m1 = m1, now = now }, need).errors, "M5_MISSING")
        local forming = F.copy (m5)
        forming[#forming + 1] = { t = forming[#forming].t + 300, o = 2700, h = 2701, l = 2699, c = 2700 }
        local r2 = DV.prepare ({ m1 = m1, m5 = forming, now = now }, cfg)
        T.has (r2.warnings, "M5_INCOMPLETE_DROPPED"); T.ok (r2.ok, table.concat (r2.errors, ","))
    end)
end
