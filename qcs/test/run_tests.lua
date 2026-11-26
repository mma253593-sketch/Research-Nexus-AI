-- =====================================================================
--  V2 offline test suite (mock QCS runtime). Deterministic.
--  Usage (repo root):  lua5.3 qcs/test/run_tests.lua
--  Synthetic data verifies LOGIC only. It is not evidence of trading edge.
-- =====================================================================
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")
local gen  = require ("datasets")

local MAIN  = "qcs/scripts/XAUUSD_Smart_Entry_Main.lua"
local PANEL = "qcs/scripts/XAUUSD_Smart_Entry_Panel.lua"
local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end
local SRC = { [MAIN] = read (MAIN), [PANEL] = read (PANEL) }

local failures, passes = 0, 0
local function check (ok, msg)
    if ok then passes = passes + 1; print ("  PASS  " .. msg)
    else failures = failures + 1; print ("  FAIL  " .. msg) end
end
local function section (s) print ("\n== " .. s) end

local REG = { WARM = 0, TREND = 1, RANGE = 2, HIVOL = 3, LOVOL = 4, TRANS = 5 }
local FIELDS = { "SIG_DIR", "SIG_SCORE", "SIG_TRIG", "SIG_MIN", "SIG_ROOM", "REGIME", "REGIME_RAW",
                 "BULL_SCORE", "BEAR_SCORE", "BULL_REASON", "BEAR_REASON", "BULL_TRIG", "BEAR_TRIG",
                 "WAIT_REASON", "WAIT_SIDE", "TREND_DIR", "COOLDOWN_USED", "PROF_ROOM", "PROF_LATE_EXT",
                 "PROF_LATE_BODY", "PROF_RSI_MID", "PROF_ACCEL", "PROF_TRADABLE" }
local DECISION = { "SIG_DIR", "SIG_SCORE", "SIG_TRIG", "REGIME", "BULL_SCORE", "BEAR_SCORE",
                   "BULL_REASON", "BEAR_REASON", "WAIT_REASON" }

-- run a script over bars; optional live-tick simulation on every bar
local function run (file, bars, opts)
    opts = opts or {}
    local E = mock.new (bars)
    E.load (SRC[file])
    local rec, tickdiff = {}, 0
    for T = 1, #bars do
        if opts.ticks and T > 1 then
            local real = bars[T]
            local atr = math.max (real.h - real.l, 0.5)
            for k = 1, opts.ticks do
                local f = { o = real.o }
                local amp = (k % 3 == 0) and 10 * atr or 2 * atr         -- includes extreme ticks
                f.c = real.o + (math.random () - 0.5) * amp
                f.h = math.max (f.o, f.c) + math.random () * amp * 0.5
                f.l = math.min (f.o, f.c) - math.random () * amp * 0.5
                bars[T] = f
                E.run_bar (T)
                local snap = {}
                for _, k2 in ipairs (DECISION) do snap[k2] = E.env[k2] end
                bars[T] = real
                E.run_bar (T)
                for _, k2 in ipairs (DECISION) do
                    if snap[k2] ~= E.env[k2] then tickdiff = tickdiff + 1; break end
                end
            end
        else
            E.run_bar (T)
        end
        local r = {}
        for _, k in ipairs (FIELDS) do r[k] = E.env[k] end
        rec[T] = r
    end
    return rec, E, tickdiff
end

local function signals (rec, from, to)
    local out = {}
    for T = from or 1, to or #rec do if rec[T].SIG_DIR ~= 0 then out[#out + 1] = T end end
    return out
end
local function share (rec, from, to, regime)
    local n, c = 0, 0
    for T = from, to do n = n + 1; if rec[T].REGIME == regime then c = c + 1 end end
    return c / n
end
local function count_dir (rec, from, to, d)
    local c = 0
    for T = from, to do if rec[T].SIG_DIR == d then c = c + 1 end end
    return c
end

-- --------------------------------------------------------------------
-- Independent re-check of every mandatory filter for every signal.
-- Values are read from the engine's series, the rules re-implemented here.
-- --------------------------------------------------------------------
local function verify_signals (rec, E, bars)
    local env, V = E.env, E.val
    local bad = {}
    local function fail (T, why) bad[#bad + 1] = ("bar %d: %s"):format (T, why) end
    local last = nil
    for T = 1, #rec do
        local r = rec[T]
        if r.SIG_DIR ~= 0 then
            local s = r.SIG_DIR
            local function px (b) return s * b end
            local o1, c1 = bars[T - 1].o, bars[T - 1].c
            local h1 = s == 1 and bars[T - 1].h or bars[T - 1].l
            local l1 = s == 1 and bars[T - 1].l or bars[T - 1].h
            local ef = px (V (env.ema_f, T - 1)); local em = px (V (env.ema_m, T - 1))
            local es = px (V (env.ema_s, T - 1)); local es6 = px (V (env.ema_s, T - 6))
            local rs1 = V (env.rsi_val, T - 1); if s == -1 then rs1 = 100 - rs1 end
            local h_1, h_2, h_3 = px (V (env.macd_hist, T - 1)), px (V (env.macd_hist, T - 2)), px (V (env.macd_hist, T - 3))
            local atr2 = V (env.atr_val, T - 2)
            local C = px (c1)
            -- threshold & regime
            if r.SIG_SCORE < r.SIG_MIN then fail (T, "score below adaptive minimum") end
            if r.SIG_MIN < 70 then fail (T, "adaptive minimum below configured 70") end
            if not (r.REGIME == REG.TREND or r.REGIME == REG.TRANS) then fail (T, "signal in non-tradable regime " .. r.REGIME) end
            -- stage 2
            if not (em > es and C > es and es > es6 and ef > em) then fail (T, "trend filter") end
            if rs1 <= r.PROF_RSI_MID or h_1 <= 0 then fail (T, "momentum conflict") end
            if h_1 < h_2 and h_2 < h_3 then fail (T, "weak momentum (2-bar fade)") end
            if r.PROF_ACCEL and h_1 <= h_2 then fail (T, "no acceleration in strict regime") end
            -- stage 4
            local body = math.abs (c1 - o1)
            if body > r.PROF_LATE_BODY * atr2 + 1e-9 then fail (T, "late body") end
            if (C - em) / atr2 > r.PROF_LATE_EXT + 1e-9 then fail (T, "too far from EMA21") end
            -- room, recomputed from the level series
            local room = 99
            local lv = s == 1 and { env.res1, env.res2, env.resM } or { env.sup1, env.sup2, env.supM }
            for _, ser in ipairs (lv) do
                local x = V (ser, T); if x then x = px (x); if x > C then room = math.min (room, (x - C) / atr2) end end
            end
            local rng = s == 1 and V (env.rng_hi, T - 2) or V (env.rng_lo, T - 2)
            if rng then rng = px (rng); if rng > C then room = math.min (room, (rng - C) / atr2) end end
            local step = env.round_step
            if step > 0 then
                local nxt = math.ceil (C / step) * step; if nxt <= C then nxt = nxt + step end
                room = math.min (room, (nxt - C) / atr2)
            end
            if room < r.PROF_ROOM - 1e-9 then fail (T, ("room %.2f < %.2f"):format (room, r.PROF_ROOM)) end
            -- cooldown
            if last and (T - last) <= r.COOLDOWN_USED then fail (T, "inside cooldown") end
            last = T
        end
    end
    return bad
end

local function report_bad (bad, label)
    check (#bad == 0, label .. (#bad > 0 and (" -> " .. bad[1]) or ""))
end

-- =====================================================================
section ("Syntax (luac5.3 -p)")
for _, f in ipairs ({ MAIN, PANEL }) do
    local ok = os.execute ("luac5.3 -p " .. f .. " 2>/dev/null")
    check (ok == true or ok == 0, "syntax " .. f)
end

-- =====================================================================
section ("A. Trending market")
do
    local bars, info = gen.trend (1200, 101, 0.15)
    local rec, E = run (MAIN, bars)
    local s = info.test_from
    check (share (rec, s, #bars, REG.TREND) >= 0.5, ("TREND share in trend segment = %.0f%% (>= 50%%)"):format (100 * share (rec, s, #bars, REG.TREND)))
    check (count_dir (rec, s, #bars, 1) >= 1, "at least one CALL in an up-trend: " .. count_dir (rec, s, #bars, 1))
    check (count_dir (rec, s, #bars, -1) == 0, "no PUT in a steady up-trend")
    report_bad (verify_signals (rec, E, bars), "all mandatory filters hold for every signal")
end

section ("B. Ranging market")
do
    local bars, info = gen.range (1400, 202)
    local rec, E = run (MAIN, bars)
    local s = info.test_from
    local rs = share (rec, s, #bars, REG.RANGE)
    check (rs >= 0.3, ("RANGE share in ranging segment = %.0f%% (>= 30%%)"):format (100 * rs))
    local in_range = 0
    for T = s, #bars do if rec[T].SIG_DIR ~= 0 and rec[T].REGIME == REG.RANGE then in_range = in_range + 1 end end
    check (in_range == 0, "no signal while REGIME = RANGE")
    report_bad (verify_signals (rec, E, bars), "all mandatory filters hold for every signal")
end

section ("C. High volatility")
do
    local bars, info = gen.vol_shift (1000, 303, 3.0)
    local rec, E = run (MAIN, bars)
    local hv = share (rec, info.shift + 1, info.shift + 60, REG.HIVOL)
    check (hv >= 0.6, ("HIGH_VOL share in first 60 hot bars = %.0f%% (>= 60%%)"):format (100 * hv))
    local n = 0
    for T = 1, #bars do if rec[T].REGIME == REG.HIVOL and rec[T].SIG_DIR ~= 0 then n = n + 1 end end
    check (n == 0, "no signal while REGIME = HIGH_VOL")
    report_bad (verify_signals (rec, E, bars), "all mandatory filters hold for every signal")
end

section ("D. Low volatility")
do
    local bars, info = gen.vol_shift (1000, 404, 0.3)
    local rec = run (MAIN, bars)
    local lv = share (rec, info.shift + 20, info.shift + 80, REG.LOVOL)
    check (lv >= 0.5, ("LOW_VOL share in bars 20-80 of quiet segment = %.0f%% (>= 50%%)"):format (100 * lv))
    local n = 0
    for T = 1, #bars do if rec[T].REGIME == REG.LOVOL and rec[T].SIG_DIR ~= 0 then n = n + 1 end end
    check (n == 0, "no signal while REGIME = LOW_VOL (allow_low_vol = false)")
end

section ("E. Sudden volatility spike")
do
    local bars, info = gen.trend (900, 505, 0.15)
    local k = 700
    local b = bars[k]
    bars[k] = { o = b.o, c = b.o + 9, h = b.o + 10, l = b.o - 0.5 }       -- ~10 ATR candle
    for t = k + 1, #bars do                                               -- shift the rest
        local d = 9
        bars[t] = { o = bars[t].o + d, h = bars[t].h + d, l = bars[t].l + d, c = bars[t].c + d }
    end
    local rec = run (MAIN, bars)
    check (rec[k + 1].REGIME == REG.HIVOL, "HIGH_VOL is entered on the bar right after the spike closes")
    local ok = true
    for T = k + 1, k + 3 do if rec[T].SIG_DIR ~= 0 then ok = false end end
    check (ok, "no signal on the 3 bars after the spike")
    check (rec[k].REGIME ~= REG.HIVOL or rec[k - 1].REGIME == REG.HIVOL, "spike bar itself is not used before it closes (no look-ahead)")
end

section ("F. False breakout detector")
do
    local bars = gen.trend (900, 606, 0.08)
    -- locate a confirmed support level and its ATR at bar K
    local K = 650
    local _, E0 = run (MAIN, { table.unpack (bars, 1, K) })
    local sup = E0.val (E0.env.sup1, K)
    local atr = E0.val (E0.env.atr_val, K - 1)
    check (sup ~= nil and atr ~= nil, "a confirmed support exists before the test candle")
    -- positive: sweep below support by 0.5 ATR, close back above with a long lower wick
    local p = { table.unpack (bars, 1, K) }
    local prev = p[K]
    if prev.c < prev.o then prev.c, prev.o = prev.o, prev.c end          -- previous candle bullish (no engulf)
    local o = sup + 0.6 * atr
    p[K + 1] = { o = o, l = sup - 0.5 * atr, c = o + 0.15 * atr, h = o + 0.25 * atr }
    p[K + 2] = { o = p[K + 1].c, h = p[K + 1].c + 0.2, l = p[K + 1].c - 0.2, c = p[K + 1].c + 0.1 }
    local rec = run (MAIN, p)
    check (rec[K + 2].BULL_TRIG == "FALSE-BRK", "sweep-and-reclaim candle is detected as FALSE-BRK (got " .. rec[K + 2].BULL_TRIG .. ")")
    -- negative: real breakdown (closes below), the NEXT candle rallies -> must not be FALSE-BRK
    local n = { table.unpack (bars, 1, K) }
    n[K] = prev
    n[K + 1] = { o = sup + 0.2 * atr, h = sup + 0.3 * atr, l = sup - 0.8 * atr, c = sup - 0.6 * atr }
    n[K + 2] = { o = n[K + 1].c, l = n[K + 1].c - 0.1, c = sup + 1.0 * atr, h = sup + 1.1 * atr }
    n[K + 3] = { o = n[K + 2].c, h = n[K + 2].c + 0.2, l = n[K + 2].c - 0.2, c = n[K + 2].c }
    local rn = run (MAIN, n)
    check (rn[K + 2].BULL_TRIG ~= "FALSE-BRK" and rn[K + 3].BULL_TRIG ~= "FALSE-BRK",
           "a close below support followed by a rally is NOT a false breakout")
end

section ("G. Trend reversal")
do
    local bars, info = gen.reversal (1500, 707)
    local rec, E = run (MAIN, bars)
    check (count_dir (rec, info.flip + 80, #bars, 1) == 0, "no CALL once the down-trend is established (flip+80 .. end)")
    check (count_dir (rec, info.flip + 1, #bars, -1) >= 1, "PUT signals appear after the reversal: " .. count_dir (rec, info.flip + 1, #bars, -1))
    check (count_dir (rec, 1, info.flip, -1) == 0, "no PUT during the up-trend")
    report_bad (verify_signals (rec, E, bars), "all mandatory filters hold for every signal")
end

-- Mixed random-regime datasets reused by several sections
local MIXED = {}
for _, seed in ipairs ({ 7, 42, 2026 }) do MIXED[#MIXED + 1] = gen.mixed (4000, seed) end
local MIXED_RUNS = {}
for i, bars in ipairs (MIXED) do
    local rec, E, tick = run (MAIN, bars, { ticks = 4 })
    MIXED_RUNS[i] = { rec = rec, E = E, tick = tick, bars = bars }
end

section ("H/I/J/K. Weak momentum, late entry, S/R obstruction, cooldown (mixed data, all signals)")
do
    local total, bad_all, seen = 0, {}, {}
    for i, m in ipairs (MIXED_RUNS) do
        total = total + #signals (m.rec)
        for _, b in ipairs (verify_signals (m.rec, m.E, m.bars)) do bad_all[#bad_all + 1] = "ds" .. i .. " " .. b end
        for T = 1, #m.rec do
            seen[m.rec[T].BULL_REASON] = true; seen[m.rec[T].BEAR_REASON] = true
        end
    end
    check (total > 0, "signals produced on mixed data: " .. total)
    report_bad (bad_all, "every signal passes independent re-check (weak-mom, late, room, cooldown, trend, momentum, regime, score)")
    for _, r in ipairs ({ "WEAK-MOM", "LATE", "NEAR-SR", "EXHAUST", "OVEREXT", "CONFLICT", "RANGING", "VOLATILE" }) do
        check (seen[r], "filter " .. r .. " is exercised (rejects at least one setup)")
    end
end

section ("I2. Late-entry construction")
do
    local bars = gen.trend (900, 808, 0.15)
    local k = 720
    local b = bars[k]
    -- 2.2 ATR body, 2.4 ATR range: below the spike limit (2.8) but late
    local atr = 0
    do local _, E0 = run (MAIN, { table.unpack (bars, 1, k) }); atr = E0.val (E0.env.atr_val, k - 1) end
    bars[k] = { o = b.o, c = b.o + 2.2 * atr, h = b.o + 2.3 * atr, l = b.o - 0.1 * atr }
    local rec = run (MAIN, { table.unpack (bars, 1, k + 1) })
    check (rec[k + 1].SIG_DIR == 0, "no signal after a 2.2 ATR candle (reason: " .. rec[k + 1].BULL_REASON .. ")")
    check (rec[k + 1].BULL_REASON ~= "", "the CALL side reports a blocking reason")
end

section ("L. Repainting / execution safety")
do
    local diffs = 0
    for _, m in ipairs (MIXED_RUNS) do diffs = diffs + m.tick end
    check (diffs == 0, "4 simulated ticks per bar (incl. 10-ATR extremes) never change decisions: " .. diffs .. " diffs")
    -- no look-ahead: decisions on a prefix equal decisions on the full history
    local bars = MIXED[1]
    local full = MIXED_RUNS[1].rec
    local same = true
    for _, N in ipairs ({ 1500, 2600, 3333 }) do
        local pre = run (MAIN, { table.unpack (bars, 1, N) })
        for T = 1, N do
            for _, k in ipairs (DECISION) do if pre[T][k] ~= full[T][k] then same = false end end
        end
    end
    check (same, "historical decisions are identical whether or not later bars exist (prefix test)")
end

section ("M. Main / Panel synchronisation")
do
    local same, cmp = true, 0
    for i, bars in ipairs (MIXED) do
        local p = run (PANEL, bars)
        for T = 1, #bars do
            for _, k in ipairs (FIELDS) do
                cmp = cmp + 1
                if p[T][k] ~= MIXED_RUNS[i].rec[T][k] then same = false end
            end
        end
    end
    check (same, "Main and Panel produce identical engine outputs (" .. cmp .. " values compared)")
end

section ("N. Adaptive regime switching")
do
    local rec = MIXED_RUNS[1].rec
    local raw_flips, flips, early = 0, 0, 0
    for T = 120, #rec do
        if rec[T].REGIME_RAW ~= rec[T - 1].REGIME_RAW then raw_flips = raw_flips + 1 end
        if rec[T].REGIME ~= rec[T - 1].REGIME and rec[T - 1].REGIME ~= REG.WARM then
            flips = flips + 1
            if rec[T].REGIME ~= REG.HIVOL then
                for j = 0, 2 do if rec[T - j].REGIME_RAW ~= rec[T].REGIME then early = early + 1; break end end
            end
        end
    end
    check (flips < raw_flips, ("hysteresis: confirmed flips %d < raw flips %d"):format (flips, raw_flips))
    check (early == 0, "every non-HIGH_VOL change was confirmed by 3 consecutive raw bars")
    local again = run (MAIN, MIXED[1])
    local det = true
    for T = 1, #rec do if again[T].REGIME ~= rec[T].REGIME or again[T].SIG_DIR ~= rec[T].SIG_DIR then det = false end end
    check (det, "regime classification and signals are deterministic across runs")
    print (("        confirmed regime flips: %.1f per 1000 bars (raw %.1f)"):format (1000 * flips / (#rec - 120), 1000 * raw_flips / (#rec - 120)))
end

section ("Warm-up, short and degenerate data")
do
    local rec = MIXED_RUNS[2].rec
    local first = signals (rec)[1] or math.huge
    local warm_ok = true
    for T = 1, 115 do if rec[T].REGIME ~= REG.WARM or rec[T].SIG_DIR ~= 0 then warm_ok = false end end
    check (warm_ok, "no regime and no signal during the first 115 bars (warm-up)")
    check (first > 116, "first signal after warm-up (bar " .. tostring (first) .. ")")
    local ok1, err1 = pcall (run, MAIN, gen.mixed (80, 9))
    check (ok1, "80-bar history runs without error" .. (ok1 and "" or (": " .. tostring (err1))))
    local flat = gen.flat (400)
    local ok2, r2 = pcall (run, MAIN, flat)
    local quiet = ok2
    if ok2 then for T = 1, #flat do if r2[T].SIG_DIR ~= 0 or r2[T].BULL_SCORE ~= r2[T].BULL_SCORE then quiet = false end end end
    check (quiet, "flat price (zero ranges, zero ATR) -> no error, no signal, no NaN")
    local ok3 = pcall (run, PANEL, gen.gap (600, 11))
    check (ok3, "price gap of 20 USD runs without error")
end

print (("\n%d passed, %d failed"):format (passes, failures))
print (failures == 0 and "ALL TESTS PASSED" or "TESTS FAILED")
os.exit (failures == 0 and 0 or 1)
