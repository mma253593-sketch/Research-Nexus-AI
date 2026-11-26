-- =====================================================================
--  V3 Precision Fast Entry — offline test suite (mock QCS runtime).
--  Usage (repo root):  lua5.3 qcs/test/run_tests.lua      (or qcs/build.sh --test)
--  Synthetic data verifies LOGIC only; it is not evidence of market edge.
-- =====================================================================
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")
local gen  = require ("datasets")

local MAIN, PANEL = "qcs/scripts/XAUUSD_Smart_Entry_Main.lua", "qcs/scripts/XAUUSD_Smart_Entry_Panel.lua"
local COMPACT, MINI = "qcs/scripts/XAUUSD_Smart_Entry_Compact.lua", "qcs/scripts/XAUUSD_Smart_Entry_Mini.lua"
local V1 = "qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua"
local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end
local SRC = {}
for _, p in ipairs ({ MAIN, PANEL, COMPACT, MINI, V1 }) do SRC[p] = read (p) end

local failures, passes = 0, 0
local function check (ok, msg)
    if ok then passes = passes + 1; print ("  PASS  " .. msg) else failures = failures + 1; print ("  FAIL  " .. msg) end
end
local function section (s) print ("\n== " .. s) end

local FIELDS = { "SIG_DIR", "SIG_SCORE", "SIG_SETUP", "SIG_TRIG", "SIG_STATE", "BLOCK", "BLOCK_SIDE", "BULL_SCORE",
                 "BEAR_SCORE", "RAW_SCORE", "TREND_STATE", "MARKET", "MOM_STATE", "COOL_LEFT", "LOC_ATR", "ROOM_ATR" }
local DECISION = { "SIG_DIR", "SIG_SCORE", "SIG_SETUP", "SIG_STATE", "BLOCK", "MARKET", "TREND_STATE",
                   "BULL_SCORE", "BEAR_SCORE" }

local function run (file, bars, ticks)
    local E = mock.new (bars)
    E.load (SRC[file])
    local rec, tickdiff = {}, 0
    for T = 1, #bars do
        if ticks and T > 1 then
            local real = bars[T]
            local a = math.max (real.h - real.l, 0.5)
            for k = 1, ticks do
                local amp = (k % 2 == 0) and 10 * a or 2 * a
                local c = real.o + (math.random () - 0.5) * amp
                bars[T] = { o = real.o, c = c, h = math.max (real.o, c) + math.random () * amp / 2,
                            l = math.min (real.o, c) - math.random () * amp / 2 }
                E.run_bar (T)
                local snap = {}
                for _, f in ipairs (DECISION) do snap[f] = E.env[f] end
                bars[T] = real
                E.run_bar (T)
                for _, f in ipairs (DECISION) do if snap[f] ~= E.env[f] then tickdiff = tickdiff + 1; break end end
            end
        else
            E.run_bar (T)
        end
        local r = {}
        for _, f in ipairs (FIELDS) do r[f] = E.env[f] end
        r.NO_CHASE = E.env.NO_CHASE
        rec[T] = r
    end
    return rec, E, tickdiff
end

local function count (rec, from, to, f) local n = 0 for T = from, to do if f (rec[T], T) then n = n + 1 end end return n end
local function sig (d) return function (r) return r.SIG_DIR == d end end

-- ---------------------------------------------------------------------
-- Independent re-check of the mandatory rules for every printed signal
-- ---------------------------------------------------------------------
local MOM_TRIG = { ENGULF = 1, BREAKOUT = 1, MOMENTUM = 1, ["FALSE-BRK"] = 1 }
local PB_TRIG  = { REJECT = 1, PIN = 1, ENGULF = 1, RESUME = 1 }
local function verify (rec, E, bars)
    local env, V, bad, last = E.env, E.val, {}, nil
    local function fail (T, why) bad[#bad + 1] = ("bar %d: %s"):format (T, why) end
    for T = 1, #rec do
        local r = rec[T]
        if r.SIG_DIR ~= 0 then
            local s, pb = r.SIG_DIR, r.SIG_SETUP == "PULLBACK"
            local function P (x) return s * x end
            local b1, b2 = bars[T - 1], bars[T - 2]
            local atr1, atr2, base = V (env.atr_val, T - 1), V (env.atr_val, T - 2), V (env.atr_base, T - 1)
            local ef, em, es, es6 = P (V (env.ema_f, T - 1)), P (V (env.ema_m, T - 1)), P (V (env.ema_s, T - 1)), P (V (env.ema_s, T - 6))
            local r1, r2 = V (env.rsi_val, T - 1), V (env.rsi_val, T - 2)
            if s == -1 then r1, r2 = 100 - r1, 100 - r2 end
            local h1, h2, h3 = P (V (env.macd_hist, T - 1)), P (V (env.macd_hist, T - 2)), P (V (env.macd_hist, T - 3))
            local c1, o1 = P (b1.c), P (b1.o)
            local slope = (es - es6) / (5 * atr2)
            if r.SIG_SCORE < 70 then fail (T, "score < 70") end
            if r.MARKET == 2 or r.MARKET == 3 or r.MARKET == 4 then fail (T, "non-tradable market " .. r.MARKET) end
            if (b1.h - b1.l) > 2.8 * atr2 or atr1 > 1.9 * base or atr1 < 0.5 * base then fail (T, "volatility") end
            if pb then
                if not (em > es and ef > es and c1 > ef and slope > 0.02) then fail (T, "pullback trend") end
                if not (h1 > h2 and r1 > r2 and r1 > 45) then fail (T, "pullback momentum") end
                if not PB_TRIG[r.SIG_TRIG] then fail (T, "pullback trigger " .. r.SIG_TRIG) end
                local touched, counter, inside = false, false, true
                for i = 1, 3 do
                    local b = bars[T - i]
                    local lo = (s == 1) and b.l or -b.h
                    if lo <= P (V (env.ema_f, T - i)) + 0.3 * atr2 then touched = true end
                    if P (b.c) < P (b.o) then counter = true end
                    if P (b.c) <= P (V (env.ema_s, T - i)) then inside = false end
                end
                if not (touched and counter and inside) then fail (T, "not a pullback inside the trend") end
            else
                if not (ef > em and em > es and c1 > es and slope > 0.02) then fail (T, "momentum trend") end
                if not (h1 > 0 and r1 > 50) then fail (T, "momentum conflict") end
                if h1 < h2 and h2 < h3 then fail (T, "weak momentum") end
                if not MOM_TRIG[r.SIG_TRIG] then fail (T, "momentum trigger " .. r.SIG_TRIG) end
            end
            if r1 > 78 then fail (T, "RSI exhaustion") end    -- mirrored: PUT block 22 -> 78
            local run = 0
            for i = 1, 6 do local b = bars[T - i]; if P (b.c - b.o) <= 0 then break end; run = run + 1 end
            if run >= 5 then fail (T, "exhaustion run") end
            if math.abs (b1.c - b1.o) > 2.0 * atr2 + 1e-9 then fail (T, "late body") end
            local ref = pb and ef or em
            if (c1 - ref) / atr2 > 2.2 + 1e-9 then fail (T, "late distance") end
            local room = 99
            for _, ser in ipairs (s == 1 and { env.res1, env.res2 } or { env.sup1, env.sup2 }) do
                local x = V (ser, T); if x and P (x) > c1 then room = math.min (room, (P (x) - c1) / atr2) end
            end
            local rx = (s == 1) and V (env.rng_hi, T - 2) or V (env.rng_lo, T - 2)
            if rx and P (rx) > c1 then room = math.min (room, (P (rx) - c1) / atr2) end
            if room < 0.8 - 1e-9 then fail (T, ("room %.2f"):format (room)) end
            if last and T - last <= 2 then fail (T, "inside cooldown") end
            last = T
        end
    end
    return bad
end
local function report (bad, label) check (#bad == 0, label .. (#bad > 0 and (" -> " .. bad[1]) or "")) end

-- =====================================================================
section ("Syntax (luac5.3 -p)")
for _, f in ipairs ({ MAIN, PANEL, COMPACT, MINI }) do
    local ok = os.execute ("luac5.3 -p " .. f .. " 2>/dev/null")
    check (ok == true or ok == 0, "syntax " .. f)
end

section ("1. Strong uptrend")
do
    local bars, info = gen.trend (1500, 21, 0.25)
    local rec, E = run (MAIN, bars)
    local s = info.test_from
    check (count (rec, s, #bars, sig (1)) >= 1, "CALL signals: " .. count (rec, s, #bars, sig (1)))
    check (count (rec, s, #bars, sig (-1)) == 0, "no PUT in a strong uptrend")
    local up = count (rec, s, #bars, function (r) return r.TREND_STATE == 1 or r.TREND_STATE == 2 end) / (#bars - s + 1)
    check (up >= 0.6, ("uptrend state on %.0f%% of bars (>= 60%%)"):format (100 * up))
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

section ("2. Strong downtrend (the X:LATE / no-PUT problem)")
do
    local bars, info = gen.trend (1500, 12, -0.25)
    local rec, E = run (MAIN, bars)
    local v1 = run (V1, bars)
    local s = info.test_from
    local p3, p1 = count (rec, s, #bars, sig (-1)), count (v1, s, #bars, sig (-1))
    check (p3 >= 1, ("PUT signals V3 = %d (V1 = %d on the same data)"):format (p3, p1))
    check (count (rec, s, #bars, sig (1)) == 0, "no CALL in a strong downtrend")
    check (count (rec, s, #bars, function (r) return r.SIG_SETUP == "PULLBACK" end) >= 1, "pullback entries fire in the strong trend")
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

section ("3. Sideways (mean-reverting)")
do
    local bars, info = gen.range (1400, 202)
    local rec, E = run (MAIN, bars)
    local s = info.test_from
    local side = count (rec, s, #bars, function (r) return r.MARKET == 2 end) / (#bars - s + 1)
    check (side >= 0.5, ("sideways state on %.0f%% of the ranging segment (>= 50%%)"):format (100 * side))
    check (count (rec, 1, #bars, function (r) return r.MARKET == 2 and r.SIG_DIR ~= 0 end) == 0, "no signal while sideways")
    local rate_side = count (rec, s, #bars, function (r) return r.SIG_DIR ~= 0 end) / (#bars - s + 1)
    local pb, pinfo = gen.pullback (1500, 31, 1)
    local rp = run (MAIN, pb)
    local rate_trend = count (rp, pinfo.test_from, #pb, function (r) return r.SIG_DIR ~= 0 end) / (#pb - pinfo.test_from + 1)
    check (rate_side < rate_trend / 2, ("signal rate sideways %.1f vs trend %.1f per 1000 bars"):format (1000 * rate_side, 1000 * rate_trend))
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

section ("4. High volatility")
do
    local bars, info = gen.vol_shift (1000, 303, 3.0)
    local rec, E = run (MAIN, bars)
    local hv = count (rec, info.shift + 1, info.shift + 60, function (r) return r.MARKET == 3 end) / 60
    check (hv >= 0.6, ("high-vol state on %.0f%% of the first 60 hot bars"):format (100 * hv))
    check (count (rec, 1, #bars, function (r) return r.MARKET == 3 and r.SIG_DIR ~= 0 end) == 0, "no signal in high volatility")
    local spike = gen.trend (900, 505, 0.15)
    local k, b = 700, spike[700]
    spike[k] = { o = b.o, c = b.o + 9, h = b.o + 10, l = b.o - 0.5 }
    for t = k + 1, #spike do local x = spike[t]; spike[t] = { o = x.o + 9, h = x.h + 9, l = x.l + 9, c = x.c + 9 } end
    local rs = run (MAIN, spike)
    check (rs[k + 1].MARKET == 3 and rs[k + 1].SIG_DIR == 0, "sudden 10-ATR candle -> high-vol block on the next bar")
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

section ("5. Sudden reversal")
do
    local bars, info = gen.reversal (1500, 707)
    local rec, E = run (MAIN, bars)
    check (count (rec, info.flip + 80, #bars, sig (1)) == 0, "no CALL once the down-trend is established (flip+80..)")
    check (count (rec, info.flip + 1, #bars, sig (-1)) >= 1, "PUT after the reversal: " .. count (rec, info.flip + 1, #bars, sig (-1)))
    check (count (rec, 301, info.flip, sig (-1)) == 0, "no PUT during the up-leg")
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

section ("6. Pullback continuation")
for _, d in ipairs ({ 1, -1 }) do
    local bars, info = gen.pullback (1500, 31 + (d == 1 and 0 or 1), d)
    local rec, E = run (MAIN, bars)
    local s = info.test_from
    local pbn = count (rec, s, #bars, function (r) return r.SIG_SETUP == "PULLBACK" end)
    check (pbn >= 1, ("%s trend: pullback entries = %d"):format (d == 1 and "up" or "down", pbn))
    check (count (rec, s, #bars, sig (-d)) == 0, "no counter-trend signals")
    report (verify (rec, E, bars), "every signal passes the independent re-check")
end

-- Mixed data reused below (with live-tick simulation)
local MIXED, RUNS = {}, {}
for i, seed in ipairs ({ 7, 42, 2026 }) do
    MIXED[i] = gen.mixed (4000, seed)
    local rec, E, tick = run (MAIN, MIXED[i], 4)
    RUNS[i] = { rec = rec, E = E, tick = tick }
end

section ("Functional: entries, filters, states (mixed data)")
do
    local mom, pb, bad, seen, n = 0, 0, {}, {}, 0
    local expired_ok, ready_ok, dup = true, true, 0
    for i, m in ipairs (RUNS) do
        for _, b in ipairs (verify (m.rec, m.E, MIXED[i])) do bad[#bad + 1] = "ds" .. i .. " " .. b end
        for T = 2, #m.rec do
            local r, p = m.rec[T], m.rec[T - 1]
            if r.SIG_SETUP == "MOMENTUM" then mom = mom + 1 elseif r.SIG_SETUP == "PULLBACK" then pb = pb + 1 end
            if r.SIG_DIR ~= 0 then n = n + 1 end
            if r.BLOCK ~= "" then seen[r.BLOCK] = true end
            if p.SIG_DIR ~= 0 and r.SIG_DIR == 0 and r.SIG_STATE ~= 3 and r.SIG_STATE ~= 4 then expired_ok = false end
            if r.SIG_STATE == 3 and p.SIG_DIR == 0 then expired_ok = false end
            if (r.SIG_STATE == 1 or r.SIG_STATE == -1) and r.SIG_DIR ~= 0 then ready_ok = false end
            if r.SIG_DIR ~= 0 and p.SIG_DIR ~= 0 then dup = dup + 1 end
        end
    end
    check (mom >= 1, "Momentum Entry fires: " .. mom)
    check (pb >= 1, "Pullback Entry fires: " .. pb)
    report (bad, ("all %d signals pass the independent re-check (trend, momentum, PA, late, room, volatility, cooldown, score)"):format (n))
    for _, k in ipairs ({ "SIDEWAYS", "LATE", "SUPPORT", "RESISTANCE", "EXHAUST", "CONFLICT", "COOLDOWN", "LOW-CONFIDENCE" }) do
        check (seen[k], "block reason " .. k .. " is produced")
    end
    check (expired_ok, "EXPIRED appears exactly on the bar after a signal (unless a block is shown)")
    check (ready_ok, "READY is never shown together with a signal")
    check (dup == 0, "no duplicate signals on consecutive bars")
end

section ("Functional: touching EMA9 alone is not a signal")
do
    local bars = gen.trend (800, 909, 0.15)
    local k = 700
    local _, E0 = run (MAIN, { table.unpack (bars, 1, k) })
    local e9, atr = E0.val (E0.env.ema_f, k), E0.val (E0.env.atr_val, k)
    local p = { table.unpack (bars, 1, k) }
    p[k + 1] = { o = e9 + 0.3 * atr, c = e9 + 0.3 * atr, h = e9 + 0.4 * atr, l = e9 + 0.2 * atr }   -- tiny doji at EMA9
    p[k + 2] = { o = p[k + 1].c, c = p[k + 1].c, h = p[k + 1].c + 0.1, l = p[k + 1].c - 0.1 }
    local rec = run (MAIN, p)
    check (rec[k + 2].SIG_DIR == 0, "a small doji touching EMA9 gives no signal (state " .. rec[k + 2].SIG_STATE .. ")")
end

section ("Functional: NO CHASE is a live warning only")
do
    local m = RUNS[1]
    local T
    for t = 200, #m.rec do if m.rec[t].SIG_DIR ~= 0 then T = t break end end
    local bars = { table.unpack (MIXED[1], 1, T) }
    local E = mock.new (bars); E.load (SRC[MAIN])
    for t = 1, T do E.run_bar (t) end
    local d, sc = E.env.SIG_DIR, E.env.SIG_SCORE
    local atr = E.val (E.env.atr_val, T - 1)
    local o = bars[T].o
    bars[T] = { o = o, c = o + d * 1.0 * atr, h = math.max (o, o + d * atr), l = math.min (o, o + d * atr) }
    E.run_bar (T)
    check (E.env.NO_CHASE == true and E.env.SIG_DIR == d and E.env.SIG_SCORE == sc, "run-away entry candle -> NO CHASE, signal unchanged")
    bars[T] = { o = o, c = o - d * 0.2 * atr, h = o + 0.1, l = o - 0.1 }
    E.run_bar (T)
    check (E.env.NO_CHASE == false and E.env.SIG_DIR == d, "entry candle moving against -> no warning, signal unchanged")
end

section ("Functional: late entry construction")
do
    local bars = gen.trend (900, 808, 0.15)
    local k = 720
    local _, E0 = run (MAIN, { table.unpack (bars, 1, k) })
    local atr = E0.val (E0.env.atr_val, k - 1)
    local b = bars[k]
    bars[k] = { o = b.o, c = b.o + 2.3 * atr, h = b.o + 2.4 * atr, l = b.o - 0.05 * atr }
    local rec = run (MAIN, { table.unpack (bars, 1, k + 1) })
    check (rec[k + 1].SIG_DIR == 0, "no signal after a 2.3-ATR candle (block: " .. (rec[k + 1].BLOCK ~= "" and rec[k + 1].BLOCK or "none shown") .. ")")
end

section ("Anti-repainting and look-ahead")
do
    local diffs = 0
    for _, m in ipairs (RUNS) do diffs = diffs + m.tick end
    check (diffs == 0, "4 live ticks per bar (incl. 10-ATR extremes) on 12,000 bars: " .. diffs .. " decision changes")
    local same = true
    for _, N in ipairs ({ 1500, 2600, 3333 }) do
        local pre = run (MAIN, { table.unpack (MIXED[1], 1, N) })
        for T = 1, N do for _, f in ipairs (DECISION) do if pre[T][f] ~= RUNS[1].rec[T][f] then same = false end end end
    end
    check (same, "decisions on a history prefix equal the full-history decisions (signals never move)")
end

section ("Main / Panel / Compact / Mini consistency")
do
    local diff, n = 0, 0
    for _, file in ipairs ({ PANEL, COMPACT, MINI }) do
        for i = 1, 2 do
            local rec = run (file, MIXED[i])
            for T = 1, #rec do for _, f in ipairs (FIELDS) do
                n = n + 1; if rec[T][f] ~= RUNS[i].rec[T][f] then diff = diff + 1 end
            end end
        end
    end
    check (diff == 0, ("identical engine outputs (%d values, %d differences)"):format (n, diff))
    local chars = utf8.len (SRC[MINI]) or #SRC[MINI]
    check (chars <= 24790, ("Mini script %d characters (<= 24,790)"):format (chars))
end

section ("Warm-up, short and degenerate data")
do
    local rec = RUNS[2].rec
    local warm = true
    for T = 1, 115 do if rec[T].SIG_DIR ~= 0 or rec[T].MARKET ~= 0 then warm = false end end
    check (warm, "no market state and no signal during the first 115 bars")
    check (pcall (run, MAIN, gen.mixed (80, 9)), "80-bar history runs without error")
    local ok, r = pcall (run, MAIN, gen.flat (400))
    local quiet = ok
    if ok then for T = 1, 400 do if r[T].SIG_DIR ~= 0 or r[T].BULL_SCORE ~= r[T].BULL_SCORE then quiet = false end end end
    check (quiet, "flat price -> no error, no signal, no NaN")
    check (pcall (run, PANEL, gen.gap (600, 11)), "20 USD price gap runs without error")
end

print (("\n%d passed, %d failed"):format (passes, failures))
print (failures == 0 and "ALL TESTS PASSED" or "TESTS FAILED")
os.exit (failures == 0 and 0 or 1)
