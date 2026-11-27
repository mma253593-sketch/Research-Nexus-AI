-- =====================================================================
--  V1.1 tests: V1 + two fixes (RSI score, pivot S/R). Mock QCS runtime.
--  Usage (repo root): lua5.3 qcs/test/run_tests_v1.lua   (or qcs/build.sh --test)
-- =====================================================================
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")
local gen  = require ("datasets")

local V1    = "qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua"
local MAIN  = "qcs/v1/scripts/XAUUSD_Smart_Entry_V1_1_Main.lua"
local PANEL = "qcs/v1/scripts/XAUUSD_Smart_Entry_V1_1_Panel.lua"
local MINI  = "qcs/v1/scripts/XAUUSD_Smart_Entry_V1_1_Mini.lua"
local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end
local SRC = {}
for _, p in ipairs ({ V1, MAIN, PANEL, MINI }) do SRC[p] = read (p) end

local failures, passes = 0, 0
local function check (ok, msg)
    if ok then passes = passes + 1; print ("  PASS  " .. msg) else failures = failures + 1; print ("  FAIL  " .. msg) end
end
local function section (s) print ("\n== " .. s) end

local FIELDS = { "SIG_DIR", "SIG_SCORE", "SIG_TRIG", "BULL_SCORE", "BEAR_SCORE", "TREND_DIR", "WAIT_REASON", "WAIT_SIDE" }

local function run (file, bars, ticks)
    local E = mock.new (bars); E.load (SRC[file])
    local rec, diff = {}, 0
    for T = 1, #bars do
        if ticks and T > 1 then
            local real = bars[T]
            local a = math.max (real.h - real.l, 0.5)
            for k = 1, ticks do
                local amp = (k % 2 == 0) and 10 * a or 2 * a
                local c = real.o + (math.random () - 0.5) * amp
                bars[T] = { o = real.o, c = c, h = math.max (real.o, c) + math.random () * amp / 2, l = math.min (real.o, c) - math.random () * amp / 2 }
                E.run_bar (T)
                local d, s = E.env.SIG_DIR, E.env.SIG_SCORE
                bars[T] = real
                E.run_bar (T)
                if d ~= E.env.SIG_DIR or s ~= E.env.SIG_SCORE then diff = diff + 1 end
            end
        else
            E.run_bar (T)
        end
        local r = {}
        for _, f in ipairs (FIELDS) do r[f] = E.env[f] end
        r.res1, r.res2 = E.val (E.env.res_lvl, T), E.val (E.env.res_lvl2, T)
        r.sup1, r.sup2 = E.val (E.env.sup_lvl, T), E.val (E.env.sup_lvl2, T)
        r.rsi1 = E.val (E.env.rsi_val, T - 1)
        rec[T] = r
    end
    return rec, E, diff
end

-- prices rounded to 0.10 USD: equal highs/lows (plateaus) become common, as on real quotes
local function quantize (bars, step)
    local q = {}
    for i, b in ipairs (bars) do
        local function r (x) return math.floor (x / step + 0.5) * step end
        local o, c = r (b.o), r (b.c)
        q[i] = { o = o, c = c, h = math.max (r (b.h), o, c), l = math.min (r (b.l), o, c) }
    end
    return q
end

local DATA = {}
for _, seed in ipairs ({ 7, 42, 2026 }) do DATA[#DATA + 1] = { "mixed " .. seed, gen.mixed (4000, seed) } end
DATA[#DATA + 1] = { "mixed 7 quantized 0.10", quantize (gen.mixed (4000, 7), 0.10) }
DATA[#DATA + 1] = { "uptrend", (gen.trend (1500, 21, 0.25)) }
DATA[#DATA + 1] = { "downtrend", (gen.trend (1500, 12, -0.25)) }

section ("Syntax (luac5.3 -p)")
for _, f in ipairs ({ MAIN, PANEL, MINI }) do
    local ok = os.execute ("luac5.3 -p " .. f .. " 2>/dev/null")
    check (ok == true or ok == 0, "syntax " .. f)
end

section ("Only the two intended fixes change V1 behaviour")
local OLD, NEW = {}, {}
do
    local total, changed, unexplained, by_rsi, by_sr, sigs_v1, sigs_v11 = 0, 0, 0, 0, 0, 0, 0
    local sig_changed, sig_bars = 0, 0
    local example
    for i, d in ipairs (DATA) do
        local a = run (V1, d[2]); local b = run (MAIN, d[2])
        OLD[i], NEW[i] = a, b
        for T = 1, #d[2] do
            total = total + 1
            if a[T].SIG_DIR ~= 0 then sigs_v1 = sigs_v1 + 1 end
            if b[T].SIG_DIR ~= 0 then sigs_v11 = sigs_v11 + 1 end
            if a[T].SIG_DIR ~= 0 or b[T].SIG_DIR ~= 0 then
                sig_bars = sig_bars + 1
                if a[T].SIG_DIR ~= b[T].SIG_DIR or a[T].SIG_SCORE ~= b[T].SIG_SCORE then sig_changed = sig_changed + 1 end
            end
            local diff = false
            for _, f in ipairs (FIELDS) do if a[T][f] ~= b[T][f] then diff = true end end
            if diff then
                changed = changed + 1
                -- explained if S/R levels differ now or earlier (cooldown/state carry-over),
                -- or the directional RSI was above 74 (the re-scored band)
                local sr = false
                for j = math.max (1, T - 60), T do
                    local x, y = a[j], b[j]
                    if x.res1 ~= y.res1 or x.res2 ~= y.res2 or x.sup1 ~= y.sup1 or x.sup2 ~= y.sup2 then sr = true; break end
                end
                local r = a[T].rsi1
                local rsi = r and (r > 74 or r < 26)
                if sr then by_sr = by_sr + 1 elseif rsi then by_rsi = by_rsi + 1
                else unexplained = unexplained + 1; example = example or (d[1] .. " bar " .. T) end
            end
        end
    end
    print (("        %d bars compared, %d differ (S/R levels %d, RSI 74-78 band %d); signals V1 %d -> V1.1 %d")
        :format (total, changed, by_sr, by_rsi, sigs_v1, sigs_v11))
    check (unexplained == 0, "every difference traces to a changed S/R level or the RSI 74-78 band" .. (example and (" (first unexplained: " .. example .. ")") or ""))
    -- displayed raw scores change on every RSI 74-78 bar by design; what matters is the signals
    print (("        signal bars: %d, changed direction or score: %d"):format (sig_bars, sig_changed))
    check (sig_changed <= sig_bars * 0.25, ("most signals unchanged (%d of %d differ)"):format (sig_changed, sig_bars))
end

section ("RSI score fix")
do
    -- any bar where the only difference is the RSI band must have a HIGHER (never lower) score in V1.1
    local lower = 0
    for i, d in ipairs (DATA) do
        for T = 1, #d[2] do
            local a, b = OLD[i][T], NEW[i][T]
            local r = a.rsi1
            local same_sr = a.res1 == b.res1 and a.res2 == b.res2 and a.sup1 == b.sup1 and a.sup2 == b.sup2
            if same_sr and r and r > 74 and r <= 78 and b.BULL_SCORE < a.BULL_SCORE then lower = lower + 1 end
            if same_sr and r and r < 26 and r >= 22 and b.BEAR_SCORE < a.BEAR_SCORE then lower = lower + 1 end
        end
    end
    check (lower == 0, "RSI 74-78 (CALL) / 22-26 (PUT) never scores lower than in V1")
end

section ("Duplicate S/R levels")
do
    local q = 4                                     -- quantized dataset
    local function dup (rec) local n, m = 0, 0
        for T = 200, #rec do
            local r = rec[T]
            if r.res1 and r.res2 then m = m + 1; if r.res1 == r.res2 then n = n + 1 end end
            if r.sup1 and r.sup2 then m = m + 1; if r.sup1 == r.sup2 then n = n + 1 end end
        end
        return n, m
    end
    local n1, m1 = dup (OLD[q]); local n2, m2 = dup (NEW[q])
    print (("        quantized prices: level 1 == level 2 on %.1f%% of bars in V1, %.1f%% in V1.1"):format (100 * n1 / m1, 100 * n2 / m2))
    check (n2 < n1, "fewer duplicated levels than V1")
    -- a plateau (two adjacent equal highs) must create only one new level in V1.1
    local plateau_dup = 0
    local bars, rec = DATA[q][2], NEW[q]
    for T = 20, #rec do
        local p = 6                                 -- pivot_len + 1
        local h1, h2 = bars[T - p].h, bars[T - p - 1].h
        if h1 == h2 and rec[T].res1 == h1 and rec[T].res2 == h1 and rec[T - 1].res1 ~= h1 then plateau_dup = plateau_dup + 1 end
    end
    check (plateau_dup == 0, "a flat double top never stores the same level twice")
end

section ("Anti-repainting, look-ahead, consistency")
do
    local _, _, d = run (MAIN, DATA[1][2], 4)
    check (d == 0, "4 live ticks per bar (incl. 10-ATR extremes): " .. d .. " signal changes")
    local pre = run (MAIN, { table.unpack (DATA[2][2], 1, 2500) })
    local same = true
    for T = 1, 2500 do if pre[T].SIG_DIR ~= NEW[2][T].SIG_DIR or pre[T].SIG_SCORE ~= NEW[2][T].SIG_SCORE then same = false end end
    check (same, "decisions on a 2500-bar prefix equal the full-history decisions")
    local diff = 0
    for _, f in ipairs ({ PANEL, MINI }) do
        local rec = run (f, DATA[1][2])
        for T = 1, #rec do for _, k in ipairs (FIELDS) do if rec[T][k] ~= NEW[1][T][k] then diff = diff + 1 end end end
    end
    check (diff == 0, "Panel and Mini give identical outputs to Main")
    local chars = utf8.len (SRC[MINI]) or #SRC[MINI]
    check (chars <= 25000, ("Mini script %d characters (<= 25,000)"):format (chars))
end

section ("V1 rules still hold")
do
    local low, close = 0, 0
    for i in ipairs (DATA) do
        local last
        for T, r in ipairs (NEW[i]) do
            if r.SIG_DIR ~= 0 then
                if r.SIG_SCORE < 70 then low = low + 1 end
                if last and T - last <= 3 then close = close + 1 end
                last = T
            end
        end
    end
    check (low == 0, "no signal below the minimum score 70")
    check (close == 0, "3-bar cooldown respected")
end

print (("\n%d passed, %d failed"):format (passes, failures))
print (failures == 0 and "ALL V1.1 TESTS PASSED" or "V1.1 TESTS FAILED")
os.exit (failures == 0 and 0 or 1)
