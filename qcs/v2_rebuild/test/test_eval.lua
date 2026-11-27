-- Evaluation framework: metrics, CSV provenance/parsing, chronological
-- splits, backtest wiring (on SYNTHETIC data only — framework check).
local M = require ("metrics")
local csv = require ("csv")
local B = require ("backtest")
local C = require ("config")
local F = require ("fixtures")

local function tmpfile (name, text)
    local p = V2_ROOT .. "/eval/.tmp_" .. name
    local f = assert (io.open (p, "w")); f:write (text); f:close ()
    return p
end

return function (T)
    T.case ("Wilson interval matches reference values", function ()
        local lo, hi = M.wilson (50, 100)
        T.near (lo, 0.4038, 1e-4); T.near (hi, 0.5962, 1e-4)
        local l0, h0 = M.wilson (0, 10)
        T.near (l0, 0, 1e-12); T.near (h0, 0.2775, 1e-4)
        T.eq (select (1, M.wilson (0, 0)), 0)
    end)

    T.case ("summary: accuracy, expectancy after payout, ties, losing streak", function ()
        local tr = {}
        for _, o in ipairs ({ "win", "loss", "loss", "tie", "loss", "win", "win" }) do tr[#tr + 1] = { outcome = o } end
        local s = M.summarize (tr, { payout = 0.8 })
        T.eq (s.wins, 3); T.eq (s.losses, 3); T.eq (s.ties, 1)
        T.near (s.accuracy, 0.5)
        T.near (s.net, 3 * 0.8 - 4); T.near (s.expectancy, (3 * 0.8 - 4) / 7)
        T.eq (s.max_losing_streak, 4)
        local p = M.summarize (tr, { payout = 0.8, tie = "push" })
        T.near (p.net, 3 * 0.8 - 3); T.eq (p.max_losing_streak, 3)
        local g = M.summarize (tr)
        T.eq (g.expectancy, nil, "no payout -> no net expectancy")
        T.near (M.summarize (tr, { payout = 0.8 }).breakeven, 1 / 1.8)
    end)

    T.case ("chronological splits cover all bars once, in order", function ()
        local sp = M.splits (1000, { 0.6, 0.8, 1.0 }, { "dev", "val", "test" })
        T.eq (sp[1].first, 1); T.eq (sp[1].last, 600); T.eq (sp[2].first, 601); T.eq (sp[2].last, 800)
        T.eq (sp[3].first, 801); T.eq (sp[3].last, 1000)
    end)

    T.case ("sessions, score buckets, grouping and sample-size table", function ()
        T.eq (M.session (F.T0 + 3 * 3600), "Asia 00-07 UTC"); T.eq (M.session (F.T0 + 8 * 3600), "London 07-13 UTC")
        T.eq (M.session (F.T0 + 14 * 3600), "New York 13-21 UTC"); T.eq (M.session (F.T0 + 22 * 3600), "Late 21-24 UTC")
        T.eq (M.score_bucket (65), "60-69"); T.eq (M.score_bucket (90), "90-100")
        local tr = {}
        for i = 1, 60 do tr[i] = { outcome = (i % 3 == 0) and "loss" or "win", dir = (i % 2 == 0) and 1 or -1 } end
        local g = M.group (tr, function (t) return t.dir end)
        T.eq (#g, 2)
        local ss = M.by_sample_size (tr, {})
        T.eq (ss[1].k, 25); T.eq (ss[2].k, 50); T.eq (ss[#ss].k, 60); T.ok (ss[#ss].all)
    end)

    T.case ("CSV: header variants, time formats, timezone offset, provenance", function ()
        T.eq (csv.parse_time ("2025-01-01 00:01"), F.T0 + 60)
        T.eq (csv.parse_time ("2025.01.01 00:01:30"), F.T0 + 90)
        T.eq (csv.parse_time ("2025-01-01T00:02:00Z"), F.T0 + 120)
        T.eq (csv.parse_time (tostring (F.T0 * 1000)), F.T0)
        T.eq (csv.parse_time ("2025.01.01", "00:03"), F.T0 + 180)
        T.eq (csv.parse_time ("garbage"), nil)
        T.eq (csv.iso (F.T0 + 3661), "2025-01-01 01:01:01Z")
        T.eq (csv.iso (csv.parse_time ("2024-02-29 23:59")), "2024-02-29 23:59:00Z")
        local p = tmpfile ("a.csv", "Date,Time,Open,High,Low,Close,Volume\n2025.01.01,02:00,2650,2651,2649,2650.5,10\n"
            .. "2025.01.01,02:01,2650.5,2652,2650,2651,12\nbad,row,x,y,z,w,1\n")
        local bars, info = csv.load (p, { tz_offset_min = 120 })
        os.remove (p)
        T.eq (#bars, 2); T.eq (info.bad_rows, 1); T.eq (bars[1].t, F.T0, "UTC+2 file shifted to UTC")
        T.eq (#info.fnv1a, 8); T.eq (#info.order_errors, 0)
        local q = tmpfile ("b.csv", "time,open,high,low,close\n" .. (F.T0 + 60) .. ",1,1,1,1\n" .. F.T0 .. ",1,1,1,1\n")
        local _, info2 = csv.load (q)
        os.remove (q)
        T.eq (info2.order_errors[1], 2, "non-chronological rows reported, not sorted")
        T.eq (csv.fnv1a (""), "811c9dc5"); T.eq (csv.fnv1a ("a"), "e40c292c")
    end)

    T.case ("backtest: only past candles reach the engine; outcomes use the entry candle", function ()
        local bars = F.series (F.MIXED, 11)
        local cfg = assert (C.load ())
        local res = B.run_v2 (bars, cfg)
        T.eq (res.evaluated, #bars - 1)
        T.eq (res.decisions.CALL + res.decisions.PUT, #res.trades)
        for _, t in ipairs (res.trades) do
            local b = bars[t.bar]
            local d = (b.c - b.o) * t.dir
            T.eq (t.outcome, d > 0 and "win" or (d < 0 and "loss" or "tie"))
            T.eq (t.t, b.t)
        end
        local text = B.report (bars, { source = "SYNTHETIC test", tz_offset_min = 0 }, res, nil, { tie = "loss" }, "SYNTHETIC")
        T.ok (text:find ("SYNTHETIC DATA — NOT MARKET RESULTS", 1, true), "synthetic banner")
        T.ok (text:find ("net expectancy NOT computed", 1, true), "no payout assumed")
        T.ok (text:find ("development 0-60%", 1, true) and text:find ("test 80-100%", 1, true))
    end)

    T.case ("backtest: V1.2 runs unmodified through the QCS mock on the same candles", function ()
        local bars = F.series (F.UP, 5)
        local v1 = B.run_v1 (bars)
        for _, t in ipairs (v1.trades) do T.ok (t.dir == 1 or t.dir == -1); T.ok (t.bar >= 2) end
    end)
end
