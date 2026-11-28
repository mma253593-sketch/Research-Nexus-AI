-- =====================================================================
--  MOCK TEST for m1_aggregate_probe_v2.lua  —  Lua stub, NOT QCS.
--  This proves only that the Lua logic does what it is meant to do on
--  made-up M1 bars. It says NOTHING about IQ Option behaviour.
--  Run:  lua5.3 mock_test_m1_aggregate_probe_v2.lua
-- =====================================================================
local DIR = (arg and arg[0] and arg[0]:match("^(.*)/")) or "."
local SRC = io.open(DIR .. "/m1_aggregate_probe_v2.lua"):read("a")
local SRC03C = io.open(DIR .. "/m1_aggregate_probe.lua"):read("a")

local NaN = 0 / 0
local T0 = 1764288000            -- 2025-11-28 00:00:00 UTC, multiple of 900

-- ------------------------------------------------------------------
-- Data: M1 bars. opts.skip = { [minute_index]=true } removes bars,
-- opts.step = bar step in seconds, opts.unit = 1 or 1000 (ms)
-- ------------------------------------------------------------------
local function make_bars(n, opts)
    opts = opts or {}
    local bars, step, unit = {}, opts.step or 60, opts.unit or 1
    local start = opts.start or T0
    for i = 0, n - 1 do
        if not (opts.skip and opts.skip[i]) then
            local base = 3600 + math.sin(i / 3) * 5 + i * 0.1
            local O = base
            local C = base + math.cos(i) * 0.7
            bars[#bars + 1] = { t = (start + i * step) * unit, o = O, h = math.max(O, C) + 0.3,
                                l = math.min(O, C) - 0.2, c = C }
        end
    end
    return bars
end

-- ------------------------------------------------------------------
-- Stub runtime: script re-runs every bar; make_series by call order;
-- s[1] = value of the previous bar; last bar can get several ticks.
-- ------------------------------------------------------------------
local function run(src, bars, over, ticks)
    over = over or {}
    local reg, bar, k = {}, 0, 0
    local R = { plots = {}, shapes = {}, prints = {}, err = nil, candles = {} }
    local cur                                   -- values seen this eval
    local function rec(tbl, b, name, v)
        tbl[name] = tbl[name] or {}
        tbl[name][b] = v
    end
    local function series_of(get)
        return setmetatable({}, { __index = function (_, i)
            if type(i) == "number" then return { v = get(bar - i) } end
        end })
    end
    local function eval(b, vals)
        bar, k = b, 0
        local env = setmetatable({}, { __index = _G })
        env.instrument = function () end
        env.input_group = function (t)
            for key, v in pairs(t) do
                if type(key) == "string" then
                    if over[key] ~= nil then env[key] = over[key] else env[key] = v end
                end
            end
        end
        env.input = setmetatable({ integer = 1 }, { __call = function (_, d) return d end })
        env.get_value = function (s, d)
            if type(s) == "table" then
                if s.v == nil then return d end
                return s.v
            end
            return s
        end
        env.make_series = function ()
            k = k + 1
            reg[k] = reg[k] or {}
            local hist = reg[k]
            local s = setmetatable({ hist = hist }, { __index = function (_, i)
                if type(i) == "number" then return { v = hist[bar - i] } end
            end })
            s.set = function (self, v) self.v = v; hist[bar] = v end
            return s
        end
        env.plot = function (s, name) rec(R.plots, b, name, s.v) end
        env.plot_candle = function (t) rec(R.candles, b, t.name, { t.open.v, t.high.v, t.low.v, t.close.v }) end
        env.plot_shape = function (s, name, st, sz, col, loc, off, txt)
            local on = (type(s) == "table") and (s.v == true or (type(s.v) == "number" and s.v == s.v))
            if on then rec(R.shapes, b, name, txt) else rec(R.shapes, b, name, nil) end
        end
        env.conditional = function (x) return { v = x and true or false } end
        env.shape_style, env.shape_size, env.shape_location = {}, {}, {}
        env.rgba = function () return "rgba" end
        env.print = function (...) R.prints[#R.prints + 1] = { b, table.concat({ ... }, " ") } end
        env.error = function (m) error({ probe = m }) end
        env.date = function (ts)
            local d = os.date("!*t", ts)
            return { year = d.year, month = d.month, day = d.day, hour = d.hour, min = d.min, sec = d.sec }
        end
        local function field(f)
            return setmetatable({ v = vals[f] }, { __index = function (_, i)
                if type(i) == "number" then
                    local x = bars[b - i]
                    return { v = x and x[f] or nil }
                end
            end })
        end
        env.open, env.high, env.low, env.close = field("o"), field("h"), field("l"), field("c")
        env.open_time = field("t")
        local fn = assert(load(src, "probe", "t", env))
        local ok, e = pcall(fn)
        if not ok then
            if type(e) == "table" and e.probe then R.err = { b, e.probe } return false end
            error(e)
        end
        return true
    end
    for b = 1, #bars do
        local x = bars[b]
        if ticks and not ticks.live_each and b == #bars then
            for _, tk in ipairs(ticks) do
                if not eval(b, { t = x.t, o = tk.o, h = tk.h, l = tk.l, c = tk.c }) then return R end
            end
        elseif ticks and ticks.live_each then
            -- every bar is seen live: partial tick first, then (maybe) final
            local part = { t = x.t, o = x.o, h = math.max(x.o, x.o + 0.05), l = math.min(x.o, x.o - 0.05), c = x.o + 0.01 }
            if not eval(b, part) then return R end
            if not ticks.miss_final then
                if not eval(b, x) then return R end
            end
        else
            if not eval(b, x) then return R end
        end
    end
    return R
end

-- ------------------------------------------------------------------
-- Expected values computed directly from the bars
-- ------------------------------------------------------------------
local function bucket_of(bars, k, startsec, unit)
    unit = unit or 1
    local P = 60 * unit
    local b = math.floor(startsec * unit / (k * P))
    local o, h, l, c, n
    for _, x in ipairs(bars) do
        if math.floor(x.t / (k * P)) == b then
            if n == nil then o, h, l, c, n = x.o, x.h, x.l, x.c, 1
            else h, l, c, n = math.max(h, x.h), math.min(l, x.l), x.c, n + 1 end
        end
    end
    return { o = o, h = h, l = l, c = c, n = n }
end

local function f5(v) return string.format("%.5f", v) end
local function ohlc(x) return "O" .. f5(x.o) .. " H" .. f5(x.h) .. " L" .. f5(x.l) .. " C" .. f5(x.c) end

local pass, fail = 0, 0
local function check(name, cond, info)
    if cond then pass = pass + 1; print("PASS  " .. name)
    else fail = fail + 1; print("FAIL  " .. name .. (info and ("  :: " .. tostring(info)) or "")) end
end
local function has(s, sub) return s ~= nil and s:find(sub, 1, true) ~= nil end
local function first_print(R, prefix)
    for _, p in ipairs(R.prints) do if p[2]:sub(1, #prefix) == prefix then return p[2], p[1] end end
end

-- 1. Normal bucket (M5 01:15, M15 01:15), previous bucket
do
    local bars = make_bars(240)
    local R = run(SRC, bars, { sel_hour = 1, sel_min = 17 })
    local s5 = first_print(R, "M5 ")
    local e5, p5 = bucket_of(bars, 5, T0 + 75 * 60), bucket_of(bars, 5, T0 + 70 * 60)
    check("T1 M5 selected OK + OHLC", has(s5, "B28 01:15-01:19 OK N5/5 " .. ohlc(e5)), s5)
    check("T1 M5 previous OK + OHLC", has(s5, "PRV28 01:10-01:14 OK N5/5 " .. ohlc(p5)), s5)
    check("T1 shows query time", has(s5, "SEL01:17"), s5)
    local s15 = first_print(R, "M15 ")
    local e15, p15 = bucket_of(bars, 15, T0 + 75 * 60), bucket_of(bars, 15, T0 + 60 * 60)
    check("T1 M15 selected OK + OHLC", has(s15, "B28 01:15-01:29 OK N15/15 " .. ohlc(e15)), s15)
    check("T1 M15 previous OK + OHLC", has(s15, "PRV28 01:00-01:14 OK N15/15 " .. ohlc(p15)), s15)
end

-- 2. GAP bucket: one M1 missing inside M5 01:15 (minute 77)
do
    local bars = make_bars(240, { skip = { [77] = true } })
    local R = run(SRC, bars, { sel_hour = 1, sel_min = 15 })
    local s5 = first_print(R, "M5 ")
    local e5 = bucket_of(bars, 5, T0 + 75 * 60)
    check("T2 M5 GAP status, N4/5", has(s5, "B28 01:15-01:19 GAP N4/5 " .. ohlc(e5)), s5)
    local s15 = first_print(R, "M15 ")
    check("T2 M15 GAP status, N14/15", has(s15, "GAP N14/15"), s15)
    -- usable line must be empty while that bucket is the last closed one
    local barAt80
    for i, x in ipairs(bars) do if x.t == T0 + 80 * 60 then barAt80 = i end end
    local R1 = run(SRC, bars, { view = 1 })
    local v = R1.plots["M5 last CLOSED close (OK)"][barAt80]
    check("T2 GAP value rejected from usable line", v ~= v, v)
    check("T2 5GAP marker on first bar after the bucket", R1.shapes["M5 closed GAP"][barAt80] == "5GAP")
end

-- 3. Missing whole M5 bucket 01:10 (minutes 70..74)
do
    local skip = {}
    for m = 70, 74 do skip[m] = true end
    local bars = make_bars(240, { skip = skip })
    local R = run(SRC, bars, { sel_hour = 1, sel_min = 15 })
    local s5 = first_print(R, "M5 ")
    check("T3 previous bucket NODATA when it has no bars", has(s5, "PRV28 01:10-01:14 NODATA N0/5"), s5)
    local R2 = run(SRC, bars, { sel_hour = 1, sel_min = 10, view = 1 })
    local s = first_print(R2, "M5 ")
    check("T3 selecting an empty bucket gives no record (no event)", s == nil, s)
    -- no fake bar: no closure marker at the empty bucket
    local any = false
    for i, x in ipairs(bars) do
        local mm = (x.t - T0) // 60
        if mm == 75 and R2.shapes["M5 closed OK"][i] then any = R2.shapes["M5 closed OK"][i] end
    end
    check("T3 bucket 01:05 closes OK on the 01:15 bar (no 01:10 bar made up)", any == "5OK", any)
end

-- 4. Forming bucket: select the bucket that contains the last bar
do
    local bars = make_bars(243)                 -- last bar = 04:02 -> M5 04:00 forming
    local R = run(SRC, bars, { sel_hour = 4, sel_min = 0, view = 2, idle = 1, dsp = 1 })
    -- rebuild the text the printer started on the last line start
    local R2 = run(SRC, bars, { sel_hour = 4, sel_min = 0, view = 1 })
    local u = R2.plots["M5 last CLOSED close (OK)"][#bars]
    local e = bucket_of(bars, 5, T0 + 235 * 60)
    check("T4 last CLOSED is the previous bucket, not the forming one", math.abs(u - e.c) < 1e-9, u)
    local s5 = first_print(R, "M5 ")
    check("T4 no selected record printed while FORMING", s5 == nil, s5)
end

-- 5. Text reconstruction (View 2) and FORMING status in the text
do
    local bars = make_bars(243)
    local R = run(SRC, bars, { sel_hour = 4, sel_min = 0, view = 2, idle = 200, dsp = 1, rows = 1, rec = 1 })
    -- collect characters of the line that starts at bar 1
    local chars = {}
    for b = 1, #bars do
        for name, per in pairs(R.shapes) do
            if name:sub(1, 3) == "M5 " and per[b] then chars[#chars + 1] = per[b] end
        end
    end
    local txt = table.concat(chars)
    check("T5 text row prints NODATA before the bucket exists", txt:sub(1, 20) == ("M5SEL04:00B----:--NODATAN0/5"):sub(1, 20), txt:sub(1, 40))
    -- the forming status is printed by a status line that starts on the forming bucket
    local bars2 = make_bars(243)
    local R3 = run(SRC, bars2, { sel_hour = 4, sel_min = 0, view = 2, idle = 1, dsp = 1, rows = 1, rec = 1 })
    local seq = {}
    for b = 241, #bars2 do
        for name, per in pairs(R3.shapes) do
            if name:sub(1, 3) == "M5 " and per[b] then seq[#seq + 1] = b .. per[b] end
        end
    end
    check("T5 text printer runs on the last bars", #seq > 0, table.concat(seq, ","))
end

-- 6. Selection by day: two days of data, same time each day
do
    local bars = make_bars(2 * 1440 + 100)
    local Rlatest = run(SRC, bars, { sel_hour = 1, sel_min = 15, sel_day = 0 })
    local p = {}
    for _, x in ipairs(Rlatest.prints) do if x[2]:sub(1, 3) == "M5 " then p[#p + 1] = x[2] end end
    check("T6 day=0 follows each match (3 days -> 3 records)", #p == 3, #p)
    check("T6 day=0 last record is day 30", has(p[#p], "B30 01:15"), p[#p])
    local Rd = run(SRC, bars, { sel_hour = 1, sel_min = 15, sel_day = 29 })
    local q = first_print(Rd, "M5 ")
    local e = bucket_of(bars, 5, T0 + 1440 * 60 + 75 * 60)
    check("T6 day=29 picks that day only", has(q, "B29 01:15-01:19 OK N5/5 " .. ohlc(e)), q)
    local n = 0
    for _, x in ipairs(Rd.prints) do if x[2]:sub(1, 3) == "M5 " then n = n + 1 end end
    check("T6 day=29 prints once", n == 1, n)
end

-- 7. Live ticks: final tick of each bar missed -> 03C differs, v2 does not
do
    local bars = make_bars(60)
    local Rlive = run(SRC, bars, { view = 1 }, { live_each = true, miss_final = true })
    local any_diff = false
    for _, v in pairs(Rlive.shapes["03C vs closed DIFF"] or {}) do if v then any_diff = true end end
    check("T7 DIFF marker when live ticks missed the bar's final value", any_diff)
    local Rhist = run(SRC, bars, { view = 1 })
    local same = true
    for b = 1, #bars do
        local a, c2 = Rlive.plots["M5 last CLOSED close (OK)"][b], Rhist.plots["M5 last CLOSED close (OK)"][b]
        if not ((a ~= a and c2 ~= c2) or a == c2) then same = false end
    end
    check("T7 v2 last CLOSED identical live vs reload (built from closed bars)", same)
    local hd = false
    for _, v in pairs(Rhist.shapes["03C vs closed DIFF"] or {}) do if v then hd = true end end
    check("T7 no DIFF when every bar is final (history)", not hd)
end

-- 8. Same algorithm as 03C on history: 03C last CLOSED == v2 for OK buckets
do
    local bars = make_bars(300, { skip = { [77] = true, [130] = true } })
    local Rv2 = run(SRC, bars, { view = 1 })
    local R03 = run(SRC03C, bars, { view = 1 })
    local ok, cmp = true, 0
    for b = 1, #bars do
        local v = Rv2.plots["M5 last CLOSED close (OK)"][b]
        local w = R03.plots["M5 last CLOSED close"][b]
        if v == v and v ~= nil then
            cmp = cmp + 1
            if w == nil or math.abs(v - w) > 1e-9 then ok = false end
        end
        local v15 = Rv2.plots["M15 last CLOSED close (OK)"][b]
        local w15 = R03.plots["M15 last CLOSED close"][b]
        if v15 == v15 and v15 ~= nil and (w15 == nil or math.abs(v15 - w15) > 1e-9) then ok = false end
    end
    check("T8 v2 == 03C on every OK bar (" .. cmp .. " bars compared)", ok and cmp > 200)
end

-- 9. No lookahead: record printed at the event bar is the same with data cut there
do
    local bars = make_bars(240)
    local R = run(SRC, bars, { sel_hour = 1, sel_min = 15 })
    local s, at = first_print(R, "M5 ")
    local cut = {}
    for i = 1, at do cut[i] = bars[i] end
    local Rc = run(SRC, cut, { sel_hour = 1, sel_min = 15 })
    check("T9 same record when later bars do not exist", first_print(Rc, "M5 ") == s)
    check("T9 record appears on the first bar of the next bucket", (bars[at].t - T0) // 60 == 80, at)
end

-- 10. Chart not M1 (M5 chart: step 300 s)
do
    local bars = make_bars(100, { step = 300 })
    local R = run(SRC, bars, { view = 1 })
    local m = false
    for _, v in pairs(R.shapes["Chart not M1"] or {}) do if v then m = true end end
    check("T10 NOT 1M CHART marker on a 5m chart", m)
    local any = false
    for _, v in pairs(R.plots["M5 last CLOSED close (OK)"]) do if v == v then any = true end end
    check("T10 no usable values on a 5m chart", not any)
end

-- 11. Millisecond timestamps
do
    local bars = make_bars(240, { unit = 1000 })
    local R = run(SRC, bars, { sel_hour = 1, sel_min = 15 })
    local s5 = first_print(R, "M5 ")
    local e5 = bucket_of(bars, 5, T0 + 75 * 60, 1000)
    check("T11 ms timestamps give the same record", has(s5, "B28 01:15-01:19 OK N5/5 " .. ohlc(e5)), s5)
end

-- 12. Snapshot view (error message)
do
    local bars = make_bars(240)
    local R = run(SRC, bars, { view = 4, sel_hour = 1, sel_min = 15 })
    local e15 = bucket_of(bars, 15, T0 + 75 * 60)
    check("T12 snapshot stops on the bar where M15 closed", R.err ~= nil and (bars[R.err[1]].t - T0) // 60 == 90, R.err and R.err[1])
    check("T12 snapshot text has both rows", R.err and has(R.err[2], "M5 SEL01:15") and has(R.err[2], ohlc(e15)), R.err and R.err[2])
end

-- 13. First bucket after chart start is incomplete -> GAP
do
    local bars = make_bars(60, { start = T0 + 2 * 60 })   -- starts at 00:02
    local R = run(SRC, bars, { sel_hour = 0, sel_min = 0 })
    local s5 = first_print(R, "M5 ")
    check("T13 first partial bucket of the chart is GAP (N3/5)", has(s5, "B28 00:00-00:04 GAP N3/5"), s5)
end

-- 14. Time going backwards inside data -> bucket rejected
do
    local bars = make_bars(40)
    bars[13], bars[14] = bars[14], bars[13]                -- 00:12 / 00:13 swapped
    local R = run(SRC, bars, { sel_hour = 0, sel_min = 10 })
    local s5 = first_print(R, "M5 ")
    check("T14 out-of-order M1 times -> GAP", has(s5, "B28 00:10-00:14 GAP"), s5)
end

-- 15. View 2 text row rebuilds exactly the printed record (both rows)
do
    local bars = make_bars(600)
    for _, dsp in ipairs({ 1, 2 }) do
        local R = run(SRC, bars, { sel_hour = 1, sel_min = 15, view = 2, dsp = dsp, idle = 500 })
        for _, tf in ipairs({ "M5 ", "M15 " }) do
            local line, at = first_print(R, tf)
            local got = {}
            for b = at, #bars do
                for name, per in pairs(R.shapes) do
                    if name:sub(1, #tf) == tf and per[b] then got[#got + 1] = per[b] end
                end
            end
            local want = line:gsub(" ", "")
            check("T15 text row = record (" .. tf .. "dsp " .. dsp .. ")", table.concat(got):sub(1, #want) == want,
                  #want .. " vs " .. #table.concat(got) .. " at " .. at)
        end
    end
end

print(string.format("\nMOCK RESULT: %d passed, %d failed (Lua stub, not IQ Option)", pass, fail))
os.exit(fail == 0 and 0 or 1)
