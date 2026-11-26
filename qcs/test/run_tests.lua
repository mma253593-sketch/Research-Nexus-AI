-- Offline checks for the built scripts using the mock runtime.
-- Usage (from repo root):  lua5.3 qcs/test/run_tests.lua
package.path = "qcs/test/?.lua;" .. package.path
local mock = require ("mock_qcs")

local function read (p) local f = assert (io.open (p)); local s = f:read ("a"); f:close (); return s end

-- -------- synthetic XAUUSD-like candles (trend / range / spike regimes) --------
local function gen (n, seed)
    math.randomseed (seed)
    local bars, p, drift, vol = {}, 2650, 0, 0.8
    for t = 1, n do
        if t % 150 == 1 then
            local r = math.random ()
            drift = (r < 0.35) and 0.18 or (r < 0.7) and -0.18 or 0
            vol = 0.5 + math.random () * 0.7
        end
        local o = p
        local move = drift + (math.random () - 0.5) * 2 * vol
        if math.random () < 0.01 then move = move * 6 end           -- news spike
        local c = o + move
        local h = math.max (o, c) + math.random () * vol * 0.7
        local l = math.min (o, c) - math.random () * vol * 0.7
        bars[t] = { o = o, h = h, l = l, c = c }
        p = c
    end
    return bars
end

local function copy (b) return { o = b.o, h = b.h, l = b.l, c = b.c } end

local failures = 0
local function check (ok, msg) if ok then print ("  PASS  " .. msg) else failures = failures + 1; print ("  FAIL  " .. msg) end end

local function run (file, bars, ticks)
    local E = mock.new (bars)
    E.load (read (file))
    local res = { dir = {}, score = {}, trig = {}, reason = {}, tickdiff = 0 }
    for T = 1, #bars do
        if ticks and T > 1 then
            -- simulate the forming candle: several intrabar ticks before the close
            local real = bars[T]
            for k = 1, 3 do
                local f = copy (real)
                f.c = real.o + (math.random () - 0.5) * 4
                f.h = math.max (f.o, f.c) + math.random ()
                f.l = math.min (f.o, f.c) - math.random ()
                bars[T] = f
                E.run_bar (T)
                local d, s = E.env.SIG_DIR, E.env.SIG_SCORE
                bars[T] = real
                E.run_bar (T)
                if d ~= E.env.SIG_DIR or s ~= E.env.SIG_SCORE then res.tickdiff = res.tickdiff + 1 end
            end
        else
            E.run_bar (T)
        end
        res.dir[T], res.score[T] = E.env.SIG_DIR, E.env.SIG_SCORE
        res.trig[T], res.reason[T] = E.env.SIG_TRIG, E.env.WAIT_REASON
    end
    res.E = E
    return res
end

for _, seed in ipairs ({ 7, 42, 2026 }) do
    print (("== dataset seed %d (4000 bars)"):format (seed))
    local bars = gen (4000, seed)

    local main = run ("qcs/scripts/XAUUSD_Smart_Entry_Main.lua", bars, true)
    local panel = run ("qcs/scripts/XAUUSD_Smart_Entry_Panel.lua", bars, false)

    local calls, puts, grades, trig, reasons = 0, 0, { strong = 0, good = 0, weak = 0 }, {}, {}
    local low_score, too_close, last = 0, 0, -1000
    local same = true
    for T = 1, #bars do
        local d = main.dir[T]
        if d ~= panel.dir[T] then same = false end
        if d ~= 0 then
            if d == 1 then calls = calls + 1 else puts = puts + 1 end
            local s = main.score[T]
            if s < 70 then low_score = low_score + 1 end
            if s >= 85 then grades.strong = grades.strong + 1 elseif s >= 70 then grades.good = grades.good + 1 else grades.weak = grades.weak + 1 end
            trig[main.trig[T]] = (trig[main.trig[T]] or 0) + 1
            if T - last <= 3 then too_close = too_close + 1 end
            last = T
        elseif main.reason[T] ~= "" then
            reasons[main.reason[T]] = (reasons[main.reason[T]] or 0) + 1
        end
    end

    check (calls > 0 and puts > 0, ("signals produced: CALL=%d PUT=%d"):format (calls, puts))
    check (low_score == 0, "no signal below the min score (70)")
    check (too_close == 0, "no repeated signal inside the 3-bar cooldown")
    check (main.tickdiff == 0, "no repaint: intrabar ticks never change the signal (" .. main.tickdiff .. " diffs)")
    check (same, "Main and Panel scripts give identical decisions")
    local plotted = 0
    for name, t in pairs (main.E.shapes) do for _ in pairs (t) do plotted = plotted + 1 end end
    check (plotted > 0, "shapes plotted on the chart: " .. plotted)

    local function fmt (t) local o = {} for k, v in pairs (t) do o[#o + 1] = k .. "=" .. v end table.sort (o) return table.concat (o, " ") end
    print ("  grades : " .. fmt (grades))
    print ("  trigger: " .. fmt (trig))
    print ("  cancel : " .. fmt (reasons))
end

print (failures == 0 and "ALL TESTS PASSED" or (failures .. " TEST(S) FAILED"))
os.exit (failures == 0 and 0 or 1)
