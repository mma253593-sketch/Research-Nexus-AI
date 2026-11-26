-- =====================================================================
--  Offline V1 vs V2 evaluation harness (developer tool, runs outside IQ Option)
--
--  lua5.3 qcs/eval/evaluate.lua --csv data.csv [--payout 0.80] [--out report.md]
--  lua5.3 qcs/eval/evaluate.lua --synthetic randomwalk|mixed [--payout 0.80]
--
--  CSV: chronological M1 candles with a header containing open,high,low,close
--  (any extra columns such as time are ignored), or 5 columns time,o,h,l,c.
--
--  Outcome model (Digital Option, conservative):
--    entry  = OPEN of the entry candle (the bar that shows the arrow)
--    expiry = CLOSE of the candle e-1 bars later (e = 1,2,3,5 candles)
--    CALL wins if close > entry, PUT wins if close < entry, a tie is a LOSS
--    win: +payout stake, loss: -1 stake.  No other costs modelled.
--  The scripts are run bar by bar through the mock runtime, so a signal can
--  only use data up to the previous closed candle (no look-ahead).
--  Parameters are fixed a priori: nothing is fitted on any split.
-- =====================================================================
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")
local gen  = require ("datasets")

local V1 = "qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua"
local V2 = "qcs/scripts/XAUUSD_Smart_Entry_Main.lua"
local EXPIRIES = { 1, 2, 3, 5 }
local REGNAME = { [0] = "WARMUP", "TREND", "RANGE", "HIGH_VOL", "LOW_VOL", "TRANS" }

-- ------------------------------ args ---------------------------------
local args = {}
do local i = 1; while i <= #arg do local k = arg[i]:gsub ("^%-%-", ""); args[k] = arg[i + 1] or true; i = i + 2 end end
local payout = tonumber (args.payout or "0.80")

local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end

local function load_csv (path)
    local bars, idx = {}, nil
    for line in io.lines (path) do
        local cols = {}
        for c in (line .. ","):gmatch ("([^,]*),") do cols[#cols + 1] = c:gsub ("^%s+", ""):gsub ("%s+$", "") end
        if idx == nil then
            local low = {}
            for i, c in ipairs (cols) do low[c:lower ()] = i end
            if low.open and low.high and low.low and low.close then
                idx = { low.open, low.high, low.low, low.close }
                goto continue
            end
            idx = { 2, 3, 4, 5 }
        end
        do
            local o, h, l, c = tonumber (cols[idx[1]]), tonumber (cols[idx[2]]), tonumber (cols[idx[3]]), tonumber (cols[idx[4]])
            if o and h and l and c then bars[#bars + 1] = { o = o, h = h, l = l, c = c } end
        end
        ::continue::
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
local function run (file)
    local E = mock.new (bars)
    E.load (read (file))
    local out = {}
    for T = 1, #bars do
        E.run_bar (T)
        out[T] = { dir = E.env.SIG_DIR, score = E.env.SIG_SCORE, regime = E.env.REGIME }
    end
    return out
end
local r1, r2 = run (V1), run (V2)

-- ----------------------------- trades --------------------------------
local function trades (rec)
    local t = {}
    for T = 1, #rec do
        local d = rec[T].dir
        if d ~= 0 then
            local tr = { bar = T, dir = d, score = rec[T].score, regime = r2[T].regime, res = {} }
            for _, e in ipairs (EXPIRIES) do
                local x = bars[T + e - 1]
                if x then
                    local diff = (x.c - bars[T].o) * d
                    tr.res[e] = diff > 0 and 1 or 0
                end
            end
            t[#t + 1] = tr
        end
    end
    return t
end

local function wilson (w, n)
    if n == 0 then return 0, 0 end
    local z, p = 1.96, w / n
    local d = 1 + z * z / n
    local c = (p + z * z / (2 * n)) / d
    local m = z * math.sqrt (p * (1 - p) / n + z * z / (4 * n * n)) / d
    return c - m, c + m
end

local function stats (list, e)
    local n, w, eq, peak, dd, streak, maxstreak = 0, 0, 0, 0, 0, 0, 0
    for _, tr in ipairs (list) do
        local r = tr.res[e]
        if r ~= nil then
            n = n + 1
            if r == 1 then w = w + 1; eq = eq + payout; streak = 0
            else eq = eq - 1; streak = streak + 1; maxstreak = math.max (maxstreak, streak) end
            peak = math.max (peak, eq); dd = math.max (dd, peak - eq)
        end
    end
    local wr = n > 0 and w / n or 0
    local lo, hi = wilson (w, n)
    return { n = n, wr = wr, lr = n > 0 and 1 - wr or 0, exp = n > 0 and (wr * payout - (1 - wr)) or 0,
             dd = dd, streak = maxstreak, lo = lo, hi = hi, pnl = eq }
end

local function filter (list, f) local o = {} for _, x in ipairs (list) do if f (x) then o[#o + 1] = x end end return o end

-- ------------------------------ report -------------------------------
local L = {}
local function p (s) L[#L + 1] = s or "" end
local t1, t2 = trades (r1), trades (r2)
local breakeven = 1 / (1 + payout)

p ("# Evaluation output")
p ()
p ("* Data: " .. source .. ", " .. #bars .. " candles")
p (("* Payout assumption: %.0f%% (break-even win rate %.1f%%). Tie = loss."):format (payout * 100, breakeven * 100))
p ("* Entry at the open of the arrow candle; expiry measured in candles.")
p ()

local function row (name, list, e)
    local s = stats (list, e)
    return ("| %s | %d | %.1f%% | %.1f–%.1f%% | %+.3f | %.1f | %d |"):format (name, s.n, 100 * s.wr, 100 * s.lo, 100 * s.hi, s.exp, s.dd, s.streak)
end
local HDR = "| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |"
local SEP = "|---|---|---|---|---|---|---|"

p ("## Signals")
p ()
p ("| Version | Total | CALL | PUT | Signals per 1000 bars |")
p ("|---|---|---|---|---|")
for _, v in ipairs ({ { "V1.0", t1 }, { "V2.0", t2 } }) do
    local c = #filter (v[2], function (x) return x.dir == 1 end)
    p (("| %s | %d | %d | %d | %.1f |"):format (v[1], #v[2], c, #v[2] - c, 1000 * #v[2] / #bars))
end
p ()

p ("## By expiry")
for _, e in ipairs (EXPIRIES) do
    p (); p (("### Expiry %d candle(s)"):format (e)); p (); p (HDR); p (SEP)
    p (row ("V1.0", t1, e)); p (row ("V2.0", t2, e))
end
p ()

p ("## By market regime (V2 regime at the entry bar), expiry 1")
p (); p ("| Regime | " .. HDR:sub (3)); p ("|---" .. SEP)
for k = 0, 5 do
    for _, v in ipairs ({ { "V1.0", t1 }, { "V2.0", t2 } }) do
        local sub = filter (v[2], function (x) return x.regime == k end)
        if #sub > 0 then p ("| " .. REGNAME[k] .. " " .. row (v[1], sub, 1)) end
    end
end
p ()

p ("## By confidence band, expiry 1")
p (); p ("| Band | " .. HDR:sub (3)); p ("|---" .. SEP)
for _, b in ipairs ({ { "60-69", 60, 69 }, { "70-84", 70, 84 }, { "85-100", 85, 100 } }) do
    for _, v in ipairs ({ { "V1.0", t1 }, { "V2.0", t2 } }) do
        local sub = filter (v[2], function (x) return x.score >= b[2] and x.score <= b[3] end)
        if #sub > 0 then p ("| " .. b[1] .. " " .. row (v[1], sub, 1)) end
    end
end
p ()

p ("## Chronological splits (no fitting on any split), expiry 1")
p (); p ("| Split | " .. HDR:sub (3)); p ("|---" .. SEP)
local n = #bars
for _, s in ipairs ({ { "train 0-60%", 0, 0.6 }, { "validation 60-80%", 0.6, 0.8 }, { "test 80-100%", 0.8, 1.0 } }) do
    for _, v in ipairs ({ { "V1.0", t1 }, { "V2.0", t2 } }) do
        local sub = filter (v[2], function (x) return x.bar > s[2] * n and x.bar <= s[3] * n end)
        p ("| " .. s[1] .. " " .. row (v[1], sub, 1))
    end
end
p ()

p ("## Walk-forward (5 sequential folds), expiry 1")
p (); p ("| Fold | " .. HDR:sub (3)); p ("|---" .. SEP)
for k = 1, 5 do
    for _, v in ipairs ({ { "V1.0", t1 }, { "V2.0", t2 } }) do
        local sub = filter (v[2], function (x) return x.bar > (k - 1) * n / 5 and x.bar <= k * n / 5 end)
        p ("| " .. k .. " " .. row (v[1], sub, 1))
    end
end

local text = table.concat (L, "\n") .. "\n"
if args.out then local f = assert (io.open (args.out, "w")); f:write (text); f:close (); print ("written " .. args.out)
else io.write (text) end
