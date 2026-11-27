-- =====================================================================
--  Reproducible chronological backtest: V2.0 vs V1.2 on identical candles.
--
--  lua5.3 qcs/v2_rebuild/eval/backtest.lua --csv FILE [--payout 0.82] [--tie loss|push]
--        [--tz-offset-min 0] [--out report.md] [--signals signals.jsonl] [--no-v1]
--  lua5.3 qcs/v2_rebuild/eval/backtest.lua --synthetic [--out ...]   (framework check only)
--
--  EXPIRY MODEL (1 minute, candle level): the engine is evaluated at the
--  OPEN of candle T using only candles that closed before it; the trade is
--  entered at open[T] and expires at close[T]. CALL wins if close > open,
--  PUT wins if close < open, equal = tie. Real fills happen seconds after
--  the open and the broker's quote differs from any third-party feed:
--  tick data and the broker feed would be needed for an exact match.
--  PAYOUT: no payout is assumed. Without --payout only gross directional
--  accuracy is reported; with it, net expectancy is added.
--  SPLITS: development 0-60%, validation 60-80%, out-of-sample test 80-100%
--  of the bars, in time order. No parameter is fitted on any split.
--  V1.2 is run unmodified (qcs/v1/scripts/..._V1_2_Main.lua) in the
--  offline QCS mock with the same entry/expiry rules.
-- =====================================================================
local root = V2_ROOT or (arg and arg[0] or ""):match ("^(.*)/eval/[^/]*$") or "."
package.path = root .. "/src/?.lua;" .. root .. "/config/?.lua;" .. root .. "/eval/?.lua;" .. root .. "/test/?.lua;"
    .. root .. "/../test/?.lua;" .. package.path

local engine = require ("main")
local metrics = require ("metrics")
local csv = require ("csv")
local diagnostics = require ("diagnostics")

local B = {}

function B.parse_args (argv)
    local a, i = {}, 1
    while i <= #argv do
        local k = argv[i]:gsub ("^%-%-", "")
        local v = argv[i + 1]
        if v == nil or v:match ("^%-%-") then a[k] = true; i = i + 1 else a[k] = v; i = i + 2 end
    end
    return a
end

--- runs V2.0 bar by bar. Only candles strictly before T are passed in.
function B.run_v2 (bars, cfg, sink)
    local run = engine.new_runner (cfg)
    local W = cfg.data.m1_window + cfg.data.max_gap_candles + 10
    local trades, decisions = {}, { CALL = 0, PUT = 0, WAIT = 0 }
    local evaluated, reasons = 0, {}
    for T = 2, #bars do
        local m1 = {}
        for j = math.max (1, T - W), T - 1 do
            local b = bars[j]
            m1[#m1 + 1] = { t = b.t, o = b.o, h = b.h, l = b.l, c = b.c }
        end
        local res = run:step ({ now = bars[T].t, m1 = m1 })
        evaluated = evaluated + 1
        decisions[res.decision] = decisions[res.decision] + 1
        local key = res.reasons[1] or "SIGNAL"
        reasons[key] = (reasons[key] or 0) + 1
        if res.decision ~= "WAIT" then
            local dir = res.decision == "CALL" and 1 or -1
            local d = (bars[T].c - bars[T].o) * dir
            local tr = { bar = T, t = bars[T].t, dir = dir, score = res.score, setup = res.setup,
                         regime = res.diagnostics.regime and res.diagnostics.regime.confirmed or "n/a",
                         outcome = d > 0 and "win" or (d < 0 and "loss" or "tie") }
            trades[#trades + 1] = tr
            if sink then sink (diagnostics.to_json ({ trade = tr, diagnostics = res.diagnostics })) end
        end
    end
    return { trades = trades, decisions = decisions, evaluated = evaluated, reasons = reasons }
end

--- runs the unmodified V1.2 QCS script in the offline mock
function B.run_v1 (bars)
    local mock = require ("mock_qcs")
    local f = assert (io.open (root .. "/../v1/scripts/XAUUSD_Smart_Entry_V1_2_Main.lua"))
    local src = f:read ("a"); f:close ()
    local E = mock.new (bars); E.load (src)
    local trades = {}
    for T = 1, #bars do
        E.run_bar (T)
        local dir = E.env.SIG_DIR
        if dir ~= 0 and T >= 2 then
            local d = (bars[T].c - bars[T].o) * dir
            trades[#trades + 1] = { bar = T, t = bars[T].t, dir = dir, score = E.env.SIG_SCORE, setup = "V1",
                                    regime = "n/a", outcome = d > 0 and "win" or (d < 0 and "loss" or "tie") }
        end
    end
    return { trades = trades }
end

local function pct (x) return x and string.format ("%.1f%%", 100 * x) or "n/a" end

function B.row (name, s, opts)
    local net = opts.payout and string.format ("%+.3f", s.expectancy or 0) or "n/a (no payout)"
    return ("| %s | %d | %d / %d / %d | %s | %s–%s | %s | %d |"):format (name, s.n, s.wins, s.losses, s.ties,
        pct (s.accuracy), pct (s.acc_lo), pct (s.acc_hi), net, s.max_losing_streak)
end
B.HDR = "| Group | Signals | W / L / Tie | Accuracy | 95% CI | Expectancy / trade | Max losing streak |\n|---|---|---|---|---|---|---|"

function B.report (bars, info, v2, v1, opts, label)
    local L = {}
    local function p (s) L[#L + 1] = s or "" end
    local function filt (list, f) local o = {} for _, x in ipairs (list) do if f (x) then o[#o + 1] = x end end return o end
    p ("# XAUUSD Smart Entry V2.0 — evaluation report"); p ()
    if label == "SYNTHETIC" then
        p ("> **SYNTHETIC DATA — NOT MARKET RESULTS.** Generated by test/fixtures.lua to check that the framework runs.")
        p ("> Nothing in this report says anything about real XAUUSD performance."); p ()
    end
    p ("## Data provenance"); p ()
    p ("* Source: " .. info.source)
    if info.path then p (("* File: `%s`, %d bytes, FNV-1a `%s`, %d rows, %d unparseable rows"):format (info.path, info.bytes, info.fnv1a, info.rows, info.bad_rows)) end
    p (("* Candles: %d, %s → %s (UTC, tz offset applied: %d min)"):format (#bars, csv.iso (bars[1].t), csv.iso (bars[#bars].t), info.tz_offset_min or 0))
    local gaps = 0
    for i = 2, #bars do if bars[i].t - bars[i - 1].t > 60 then gaps = gaps + 1 end end
    p (("* Gaps between consecutive candles: %d (weekends / sessions / missing data; the engine WAITs after large gaps)"):format (gaps))
    p (("* Payout: %s. Ties: %s. Expiry: entry open[T] → close[T] (1 minute)."):format (
        opts.payout and string.format ("%.2f (break-even accuracy %.1f%%)", opts.payout, 100 / (1 + opts.payout))
        or "not supplied → net expectancy NOT computed", opts.tie == "push" and "push (refund)" or "loss (conservative)"))
    p ("* No parameter was fitted on this data. Backtest results do not guarantee future performance."); p ()

    p ("## V2.0 decision counts"); p ()
    local ev = v2.evaluated
    p (("Evaluations %d: CALL %d, PUT %d, WAIT %d → %.2f signals per 1,000 candles"):format (ev, v2.decisions.CALL,
        v2.decisions.PUT, v2.decisions.WAIT, ev > 0 and 1000 * (v2.decisions.CALL + v2.decisions.PUT) / ev or 0)); p ()
    p ("| Primary WAIT / signal reason | Count |"); p ("|---|---|")
    local keys = {}
    for k in pairs (v2.reasons) do keys[#keys + 1] = k end
    table.sort (keys, function (a, b) if v2.reasons[a] ~= v2.reasons[b] then return v2.reasons[a] > v2.reasons[b] end return a < b end)
    for _, k in ipairs (keys) do p (("| %s | %d |"):format (k, v2.reasons[k])) end
    p ()
    local sets = { { "V2.0", v2.trades } }
    if v1 then sets[#sets + 1] = { "V1.2", v1.trades } end
    p ("## All signals"); p (); p (B.HDR)
    for _, s in ipairs (sets) do p (B.row (s[1], metrics.summarize (s[2], opts), opts)) end
    p ()
    p ("## Chronological splits (development / validation / out-of-sample test)"); p (); p (B.HDR)
    for _, sp in ipairs (metrics.splits (#bars, { 0.6, 0.8, 1.0 }, { "development 0-60%", "validation 60-80%", "test 80-100%" })) do
        for _, s in ipairs (sets) do
            p (B.row (sp.name .. " " .. s[1], metrics.summarize (filt (s[2], function (t) return t.bar >= sp.first and t.bar <= sp.last end), opts), opts))
        end
    end
    p ()
    p ("## CALL / PUT"); p (); p (B.HDR)
    for _, s in ipairs (sets) do
        for _, d in ipairs ({ 1, -1 }) do
            p (B.row ((d == 1 and "CALL " or "PUT ") .. s[1], metrics.summarize (filt (s[2], function (t) return t.dir == d end), opts), opts))
        end
    end
    p ()
    local function section (title, key, list)
        p ("## " .. title); p (); p (B.HDR)
        for _, g in ipairs (metrics.group (list, key)) do p (B.row (tostring (g.key), metrics.summarize (g.trades, opts), opts)) end
        p ()
    end
    section ("V2.0 by market regime (confirmed regime at the decision)", function (t) return t.regime end, v2.trades)
    section ("V2.0 by strategy profile (setup)", function (t) return t.setup or "n/a" end, v2.trades)
    section ("V2.0 by trading session (UTC)", function (t) return metrics.session (t.t) end, v2.trades)
    if v1 then section ("V1.2 by trading session (UTC)", function (t) return metrics.session (t.t) end, v1.trades) end
    section ("V2.0 score calibration (score bucket → observed accuracy; score is NOT a probability)",
        function (t) return metrics.score_bucket (t.score) end, v2.trades)
    p ("## V2.0 results by sample size (first k signals, cumulative)"); p (); p (B.HDR)
    for _, x in ipairs (metrics.by_sample_size (v2.trades, opts)) do p (B.row ((x.all and "all " or "first ") .. x.k, x.s, opts)) end
    p ()
    p ("Reading the table: if the 95% interval contains the break-even accuracy, the data do not show an edge.")
    return table.concat (L, "\n") .. "\n"
end

function B.main (argv)
    local a = B.parse_args (argv)
    local opts = { payout = a.payout and tonumber (a.payout) or nil, tie = a.tie == "push" and "push" or "loss" }
    if a.payout and not (opts.payout and opts.payout > 0 and opts.payout < 5) then error ("--payout must be a number in (0, 5)") end
    local bars, info, label
    if a.csv then
        bars, info = csv.load (a.csv, { tz_offset_min = tonumber (a["tz-offset-min"] or "0") })
        info.source = "user-supplied CSV (provenance must be documented by the supplier)"
        label = "CSV"
        if #info.order_errors > 0 then
            error ("CSV is not strictly chronological (rows " .. table.concat (info.order_errors, ",") .. "); refusing to sort silently")
        end
    elseif a.synthetic then
        local F = require ("fixtures")
        bars = F.series (F.MIXED, tonumber (a.seed or "11"))
        info = { source = "SYNTHETIC fixtures.MIXED (deterministic LCG) — not market data", tz_offset_min = 0 }
        label = "SYNTHETIC"
    else
        io.stderr:write ("usage: backtest.lua --csv FILE [--payout P] [--tie loss|push] [--out FILE] [--signals FILE] [--no-v1]\n")
        io.stderr:write ("       backtest.lua --synthetic [--out FILE]   (framework check only)\n")
        os.exit (2)
    end
    assert (#bars > 300, "need more than 300 candles")
    local cfg = assert (engine.config ())
    local sink, sf = nil, nil
    if a.signals then sf = assert (io.open (a.signals, "w")); sink = function (line) sf:write (line, "\n") end end
    local v2 = B.run_v2 (bars, cfg, sink)
    if sf then sf:close () end
    local v1 = (not a["no-v1"]) and B.run_v1 (bars) or nil
    local text = B.report (bars, info, v2, v1, opts, label)
    if a.out then local f = assert (io.open (a.out, "w")); f:write (text); f:close (); print ("written " .. a.out)
    else io.write (text) end
end

if arg and arg[0] and arg[0]:match ("backtest%.lua$") then B.main (arg) end
return B
