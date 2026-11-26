-- =====================================================================
--  Offline evaluation harness: V1 vs V2 vs V3 on identical candles.
--  Developer tool (runs outside IQ Option, through the mock QCS runtime).
--
--  lua5.3 qcs/eval/evaluate.lua --csv xauusd_m1.csv [--payout 0.80] [--out report.md]
--  lua5.3 qcs/eval/evaluate.lua --synthetic randomwalk|mixed [--payout 0.80] [--out ...]
--
--  CSV: chronological M1 candles; header with open,high,low,close and optionally
--  time (unix seconds/ms or "YYYY-MM-DD HH:MM[:SS]", UTC) for the session split.
--
--  1-MINUTE EXPIRY MODEL (conservative, candle-level):
--    entry  = OPEN of the arrow (entry) candle
--    expiry = CLOSE of that same candle (one M1 candle later)
--    CALL wins if close > open, PUT wins if close < open, TIE = LOSS
--    win +payout, loss -1 stake. Real fills happen seconds after the open;
--    exact matching needs tick data (not available) -> see report notes.
--  Definitions:
--    false signal rate      = losing signals / signals
--    missed opportunity rate = share of "opportunity" candles without a signal,
--      opportunity = candle whose body >= 0.5 ATR in the direction of the
--      EMA21/EMA50 trend known at its open (closed data only)
--  No parameter is fitted on any split.
-- =====================================================================
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")
local gen  = require ("datasets")

local SCRIPTS = {
    { "V1.0", "qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua" },
    { "V2.0", "qcs/archive/v2/scripts/XAUUSD_Smart_Entry_Main.lua" },
    { "V3.0", "qcs/scripts/XAUUSD_Smart_Entry_Main.lua" },
}
local args = {}
do local i = 1; while i <= #arg do args[arg[i]:gsub ("^%-%-", "")] = arg[i + 1] or true; i = i + 2 end end
local payout = tonumber (args.payout or "0.80")
local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end

-- ------------------------------ data ---------------------------------
local function parse_time (s)
    if not s or s == "" then return nil end
    local n = tonumber (s)
    if n then if n > 1e12 then n = n / 1000 end; return math.floor (n % 86400 / 3600) end
    local h = s:match ("%d%d%d%d%-%d%d%-%d%d[ T](%d%d):%d%d")
    return h and tonumber (h) or nil
end
local function load_csv (path)
    local bars, idx = {}, nil
    for line in io.lines (path) do
        local cols = {}
        for c in (line .. ","):gmatch ("([^,]*),") do cols[#cols + 1] = c:gsub ("^%s+", ""):gsub ("%s+$", "") end
        if not idx then
            local low = {}
            for i, c in ipairs (cols) do low[c:lower ()] = i end
            if low.open and low.close then
                idx = { o = low.open, h = low.high, l = low.low, c = low.close,
                        t = low.time or low.date or low.datetime or low.timestamp }
                goto next
            end
            idx = { t = 1, o = 2, h = 3, l = 4, c = 5 }
        end
        do
            local o, h, l, c = tonumber (cols[idx.o]), tonumber (cols[idx.h]), tonumber (cols[idx.l]), tonumber (cols[idx.c])
            if o and h and l and c then bars[#bars + 1] = { o = o, h = h, l = l, c = c, hour = parse_time (cols[idx.t]) } end
        end
        ::next::
    end
    return bars
end

local bars, source
if args.csv then
    bars, source = load_csv (args.csv), "CSV " .. args.csv
elseif args.synthetic == "randomwalk" then
    math.randomseed (99)
    bars, source = {}, "SYNTHETIC driftless random walk (leakage check, seed 99)"
    local p = 2650
    for t = 1, 12000 do
        local c = p + (math.random () - 0.5) * 1.6
        bars[t] = { o = p, c = c, h = math.max (p, c) + math.random () * 0.5, l = math.min (p, c) - math.random () * 0.5 }
        p = c
    end
else
    bars, source = {}, "SYNTHETIC mixed regimes (seeds 7, 42, 2026 concatenated)"
    for _, seed in ipairs ({ 7, 42, 2026 }) do
        local part = gen.mixed (4000, seed)
        local shift = #bars > 0 and (bars[#bars].c - part[1].o) or 0
        for _, b in ipairs (part) do bars[#bars + 1] = { o = b.o + shift, h = b.h + shift, l = b.l + shift, c = b.c + shift } end
    end
end
assert (#bars > 300, "need more than 300 candles")

-- --------------------------- run scripts -----------------------------
local RESULT = {}
for _, s in ipairs (SCRIPTS) do
    local E = mock.new (bars); E.load (read (s[2]))
    local trades = {}
    for T = 1, #bars do
        E.run_bar (T)
        local e = E.env
        if e.SIG_DIR ~= 0 then
            local b = bars[T]
            local d = (b.c - b.o) * e.SIG_DIR
            trades[#trades + 1] = { bar = T, dir = e.SIG_DIR, score = e.SIG_SCORE, win = d > 0,
                                    setup = e.SIG_SETUP ~= "" and e.SIG_SETUP or "n/a", hour = b.hour }
        end
    end
    RESULT[s[1]] = { trades = trades, E = E }
end

-- market condition of every bar (V3 classification) for the by-market split
local MARKET = {}
do
    local E = mock.new (bars); E.load (read (SCRIPTS[3][2]))
    for T = 1, #bars do E.run_bar (T); MARKET[T] = E.env.MARKET end
end
local MNAME = { [0] = "transition/warm-up", "trend", "sideways", "high vol", "low vol", "exhaustion", "reversal risk" }

-- opportunities: trend known at the open (closed data) and a 0.5-ATR candle in that direction
local OPP = {}
do
    local E = mock.new (bars); E.load (read (SCRIPTS[3][2]))
    for T = 1, #bars do
        E.run_bar (T)
        local em, es, atr = E.val (E.env.ema_m, T - 1), E.val (E.env.ema_s, T - 1), E.val (E.env.atr_val, T - 1)
        if em and es and atr and T > 150 then
            local d = (em > es) and 1 or -1
            if (bars[T].c - bars[T].o) * d >= 0.5 * atr then OPP[T] = true end
        end
    end
end

local function session (h)
    if not h then return "n/a (no time column)" end
    if h < 7 then return "Asia 00-07 UTC" elseif h < 13 then return "London 07-13 UTC"
    elseif h < 21 then return "New York 13-21 UTC" else return "Late 21-24 UTC" end
end
local function wilson (w, n)
    if n == 0 then return 0, 0 end
    local z, p = 1.96, w / n
    local d = 1 + z * z / n
    local c, m = (p + z * z / (2 * n)) / d, z * math.sqrt (p * (1 - p) / n + z * z / (4 * n * n)) / d
    return c - m, c + m
end
local function stats (list)
    local n, w, eq, peak, dd, st, mst = #list, 0, 0, 0, 0, 0, 0
    for _, t in ipairs (list) do
        if t.win then w = w + 1; eq = eq + payout; st = 0 else eq = eq - 1; st = st + 1; mst = math.max (mst, st) end
        peak = math.max (peak, eq); dd = math.max (dd, peak - eq)
    end
    local wr = n > 0 and w / n or 0
    local lo, hi = wilson (w, n)
    return n, wr, lo, hi, eq, dd, mst
end
local function filter (l, f) local o = {} for _, x in ipairs (l) do if f (x) then o[#o + 1] = x end end return o end

-- ------------------------------ report -------------------------------
local L = {}
local function p (s) L[#L + 1] = s or "" end
local HDR = "| Version | Signals | Win rate | 95% CI | Loss / false-signal rate | Net (stakes) | Per trade | Max DD | Max consec. losses |"
local SEP = "|---|---|---|---|---|---|---|---|---|"
local function row (name, list)
    local n, wr, lo, hi, eq, dd, mst = stats (list)
    return ("| %s | %d | %.1f%% | %.1f–%.1f%% | %.1f%% | %+.1f | %+.3f | %.1f | %d |"):format (
        name, n, 100 * wr, 100 * lo, 100 * hi, n > 0 and 100 * (1 - wr) or 0, eq, n > 0 and eq / n or 0, dd, mst)
end

p ("# Evaluation output (1-minute expiry)")
p ()
p ("* Data: " .. source .. ", " .. #bars .. " M1 candles")
p (("* Payout %.0f%% → break-even win rate %.1f%%. Entry = open of the arrow candle, expiry = its close, tie = loss."):format (100 * payout, 100 / (1 + payout)))
p ()
p ("## All signals"); p (); p (HDR); p (SEP)
for _, s in ipairs (SCRIPTS) do p (row (s[1], RESULT[s[1]].trades)) end
p ()
p ("## CALL / PUT"); p (); p ("| Side |" .. HDR:sub (2)); p ("|---" .. SEP)
for _, s in ipairs (SCRIPTS) do for _, d in ipairs ({ 1, -1 }) do
    p ("| " .. (d == 1 and "CALL" or "PUT") .. " " .. row (s[1], filter (RESULT[s[1]].trades, function (t) return t.dir == d end)))
end end
p ()
p ("## V3 by setup type"); p (); p ("| Setup |" .. HDR:sub (2)); p ("|---" .. SEP)
for _, k in ipairs ({ "MOMENTUM", "PULLBACK" }) do
    p ("| " .. k .. " " .. row ("V3.0", filter (RESULT["V3.0"].trades, function (t) return t.setup == k end)))
end
p ()
p ("## By market condition (V3 classification at the entry bar)"); p (); p ("| Market |" .. HDR:sub (2)); p ("|---" .. SEP)
for k = 0, 6 do for _, s in ipairs (SCRIPTS) do
    local sub = filter (RESULT[s[1]].trades, function (t) return MARKET[t.bar] == k end)
    if #sub > 0 then p ("| " .. MNAME[k] .. " " .. row (s[1], sub)) end
end end
p ()
p ("## By session"); p (); p ("| Session |" .. HDR:sub (2)); p ("|---" .. SEP)
local sess = {}
for _, t in ipairs (RESULT["V3.0"].trades) do sess[session (t.hour)] = true end
for name in pairs (sess) do for _, s in ipairs (SCRIPTS) do
    local sub = filter (RESULT[s[1]].trades, function (t) return session (t.hour) == name end)
    if #sub > 0 then p ("| " .. name .. " " .. row (s[1], sub)) end
end end
p ()
p ("## Missed opportunities"); p ()
local nopp = 0 for _ in pairs (OPP) do nopp = nopp + 1 end
p ("| Version | Opportunity candles | Caught (signal on that candle, same side) | Missed opportunity rate |")
p ("|---|---|---|---|")
for _, s in ipairs (SCRIPTS) do
    local caught = 0
    for _, t in ipairs (RESULT[s[1]].trades) do if OPP[t.bar] and t.win then caught = caught + 1 end end
    p (("| %s | %d | %d | %.1f%% |"):format (s[1], nopp, caught, nopp > 0 and 100 * (1 - caught / nopp) or 0))
end
p ()
p ("## Chronological splits and walk-forward (no fitting)"); p (); p ("| Split |" .. HDR:sub (2)); p ("|---" .. SEP)
local n = #bars
for _, sp in ipairs ({ { "train 0-60%", 0, 0.6 }, { "validation 60-80%", 0.6, 0.8 }, { "test 80-100%", 0.8, 1 },
                       { "fold 1", 0, 0.2 }, { "fold 2", 0.2, 0.4 }, { "fold 3", 0.4, 0.6 }, { "fold 4", 0.6, 0.8 }, { "fold 5", 0.8, 1 } }) do
    for _, s in ipairs (SCRIPTS) do
        p ("| " .. sp[1] .. " " .. row (s[1], filter (RESULT[s[1]].trades, function (t) return t.bar > sp[2] * n and t.bar <= sp[3] * n end)))
    end
end

local text = table.concat (L, "\n") .. "\n"
if args.out then local f = assert (io.open (args.out, "w")); f:write (text); f:close (); print ("written " .. args.out)
else io.write (text) end
