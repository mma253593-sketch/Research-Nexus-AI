-- =====================================================================
--  M1 -> M5 / M15 AGGREGATION PROBE (TASK 03C)  —  NOT FOR TRADING
--  Stand-alone test. security() did not return M5/M15 prices on
--  IQ Option, so this script builds M5 / M15 bars from the chart's own
--  M1 bars (open/high/low/close/open_time, read with get_value, which
--  were confirmed to be numbers on the platform). The Owner compares
--  the result with the real M5 / M15 candles of IQ Option.
--
--  Run on an M1 chart. No synthetic data. No security() call.
--
--  How bars are grouped (works whatever the time unit is):
--   P      = smallest positive open_time step seen so far
--            (= one chart bar; 60 if seconds, 60000 if milliseconds)
--   bucket = floor(open_time / (k * P)),  k = 5 or 15
--   A new bucket starts a new HTF bar. The HTF bar that just CLOSED
--   is copied to "last closed" and never changes afterwards, because
--   it is built only from M1 bars that are already closed ([1]).
--
--  APIs (docs: quadcode-tech.github.io/quadcodescript-docs):
--   instrument, input, input_group, get_value, make_series, :set,
--   plot, plot_shape (shape_location.absolute / top / bottom),
--   conditional, date, open, high, low, close, open_time, rgba
--  Lua 5.3: pcall, type, math.floor, math.max, math.min, string.format
-- =====================================================================

instrument { name = "M1 Aggregate Probe", short_name = "AGG-PROBE", overlay = false }

input_group {
    "Probe",
    view = input (1, "View 1=Lines 2=Text M5 3=Text M15", input.integer, 1, 3),
    dsp  = input (2, "Bars per character", input.integer, 1, 20)
}

local NaN = 0 / 0
local HAS_PCALL = type(pcall) == "function"

local function try(f, a, b)
    if HAS_PCALL then
        return pcall(f, a, b)
    end
    return true, f(a, b)
end

local function num(v)
    if type(v) == "number" and v == v then
        return v
    end
    return nil
end

local function at1(s)
    local ok, v = try(function () return get_value(s[1]) end)
    if ok then
        return num(v)
    end
    return nil
end

local function put(s, v)
    if v == nil then
        s:set(NaN)
    else
        s:set(v)
    end
end

local function gv(x)
    local ok, v = try(get_value, x)
    if ok then
        return num(v)
    end
    return nil
end

-- ------------------------------------------------------------------
-- Chart M1 bar
-- ------------------------------------------------------------------
local o, h, l, c = gv(open), gv(high), gv(low), gv(close)
local ot = gv(open_time)
local ot1 = nil
do
    local ok, v = try(function () return get_value(open_time[1]) end)
    if ok then
        ot1 = num(v)
    end
end

-- bar counter
local cnt = make_series()
local bar_no = (at1(cnt) or 0) + 1
cnt:set(bar_no)

-- P = smallest positive step seen so far
local ps = make_series()
local P = at1(ps)
if ot ~= nil and ot1 ~= nil then
    local step = ot - ot1
    if step > 0 and (P == nil or step < P) then
        P = step
    end
end
put(ps, P)

-- ------------------------------------------------------------------
-- Aggregation for one higher timeframe of k chart bars
-- ------------------------------------------------------------------
local function aggregate(k)
    local sb, so, sh, sl, sc, sn = make_series(), make_series(), make_series(),
        make_series(), make_series(), make_series()
    local qb, qo, qh, ql, qc, qn = make_series(), make_series(), make_series(),
        make_series(), make_series(), make_series()

    local r = { k = k }
    local bucket = nil
    if ot ~= nil and P ~= nil and P > 0 then
        bucket = math.floor(ot / (k * P))
        r.phase = math.floor(ot / P) % k     -- 0 = first chart bar of HTF bar
    end
    local pb = at1(sb)
    -- last closed bar, carried from the previous chart bar
    local lb, lo, lh, ll, lc, ln = at1(qb), at1(qo), at1(qh), at1(ql), at1(qc), at1(qn)
    local ao, ah, al, ac, an

    r.new = bucket ~= nil and (pb == nil or bucket ~= pb)
    if bucket == nil or o == nil or h == nil or l == nil or c == nil then
        ao, ah, al, ac, an = nil, nil, nil, nil, nil
    elseif r.new then
        if pb ~= nil then
            -- the previous HTF bar just closed: freeze its values
            lb, lo, lh, ll, lc, ln = pb, at1(so), at1(sh), at1(sl), at1(sc), at1(sn)
            r.closed_now = true
        end
        ao, ah, al, ac, an = o, h, l, c, 1
    else
        local po, ph, pl, pn = at1(so), at1(sh), at1(sl), at1(sn)
        ao = po or o
        ah = (ph ~= nil) and math.max(ph, h) or h
        al = (pl ~= nil) and math.min(pl, l) or l
        ac = c
        an = (pn or 0) + 1
    end

    put(sb, bucket)
    put(so, ao)
    put(sh, ah)
    put(sl, al)
    put(sc, ac)
    put(sn, an)
    put(qb, lb)
    put(qo, lo)
    put(qh, lh)
    put(ql, ll)
    put(qc, lc)
    put(qn, ln)

    r.bucket, r.o, r.h, r.l, r.c, r.n = bucket, ao, ah, al, ac, an
    r.lb, r.lo, r.lh, r.ll, r.lc, r.ln = lb, lo, lh, ll, lc, ln
    if lb ~= nil and P ~= nil then
        r.lstart = lb * k * P                -- open_time of last closed bar
    end
    r.full = r.closed_now and ln == k
    r.gap = r.closed_now and ln ~= nil and ln ~= k
    return r
end

local A5 = aggregate(5)
local A15 = aggregate(15)

-- ------------------------------------------------------------------
-- View 1: lines (gap = value not available)
-- ------------------------------------------------------------------
local function S(v)
    local s = make_series()
    put(s, v)
    return s
end
local L_c   = S(c)
local L_5f  = S(A5.c)
local L_5c  = S(A5.lc)
local L_15f = S(A15.c)
local L_15c = S(A15.lc)

if view == 1 then
    plot (L_c,   "M1 close (chart)",     "#FFFFFF", 1)
    plot (L_5f,  "M5 forming close",     "#80DEEA", 1)
    plot (L_5c,  "M5 last CLOSED close", "#29B6F6", 2)
    plot (L_15f, "M15 forming close",    "#FFCC80", 1)
    plot (L_15c, "M15 last CLOSED close","#FFA726", 2)
end

-- Markers on the first M1 bar of each new HTF bar:
--   5OK / 15OK  = the bar that just closed had exactly 5 / 15 M1 bars
--   5GAP / 15GAP = it had a different count (missing bars / gap)
plot_shape (conditional(view == 1 and A5.full == true),  "M5 closed ok",   shape_style.triangleup, shape_size.tiny, "#29B6F6", shape_location.bottom, 0, "5OK", "#29B6F6")
plot_shape (conditional(view == 1 and A5.gap == true),   "M5 closed gap",  shape_style.xcross, shape_size.tiny, "#FF1744", shape_location.bottom, 0, "5GAP", "#FF1744")
plot_shape (conditional(view == 1 and A15.full == true), "M15 closed ok",  shape_style.triangleup, shape_size.small, "#FFA726", shape_location.top, 0, "15OK", "#FFA726")
plot_shape (conditional(view == 1 and A15.gap == true),  "M15 closed gap", shape_style.xcross, shape_size.small, "#FF1744", shape_location.top, 0, "15GAP", "#FF1744")

-- Chart must be M1: P = 60 (seconds) or 60000 (ms). On another chart
-- timeframe the "M5"/"M15" groups would be 5/15 bars of THAT timeframe.
local not_m1 = P ~= nil and P ~= 60 and P ~= 60000
plot_shape (conditional(not_m1), "Chart not M1", shape_style.xcross, shape_size.small, "#FF1744", shape_location.top, 0, "NOT 1M CHART", "#FF1744")

-- ------------------------------------------------------------------
-- Views 2 / 3: text line for the LAST CLOSED M5 / M15 bar, written one
-- character every `dsp` bars. All values are captured on the first bar
-- of the cycle and held, so one line describes one moment.
--   "M5 P=60 T=08:35 O=... H=... L=... C=... N=5 PH=0"
--   P  = chart bar step, T = open time (date(), OS timezone) of the
--   last closed HTF bar, N = M1 bars in it, PH = phase of current bar
-- ------------------------------------------------------------------
local CYC = 110
local period = CYC * dsp
local pos = (bar_no - 1) % period
local start = pos == 0

local function hold(v)
    local s = make_series()
    local out
    if start then
        out = v
    else
        out = at1(s)
    end
    put(s, out)
    return out
end

local function f(v, dec)
    if v == nil then
        return "NA"
    end
    if dec then
        return string.format("%.5f", v)
    end
    return string.format("%.0f", v)
end

local A = (view == 3) and A15 or A5
local hP, hT = hold(P), hold(A.lstart)
local hO, hH, hL, hC = hold(A.lo), hold(A.lh), hold(A.ll), hold(A.lc)
local hN, hPH = hold(A.ln), hold(A.phase)

local tt = "NA"
if hT ~= nil and type(date) == "function" then
    local ok, d = try(date, math.floor(hT))
    if ok and type(d) == "table" and num(d.hour) ~= nil and num(d.min) ~= nil then
        tt = string.format("%02d:%02d", d.hour, d.min)
    end
end

local line = ((view == 3) and "M15" or "M5") .. " P=" .. f(hP) .. " T=" .. tt
    .. " O=" .. f(hO, true) .. " H=" .. f(hH, true) .. " L=" .. f(hL, true)
    .. " C=" .. f(hC, true) .. " N=" .. f(hN) .. " PH=" .. f(hPH)

local ALPHA = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-", "=",
    ":", "A", "C", "H", "L", "M", "N", "O", "P", "T", "?" }
local IDX = {}
for i, ch in ipairs(ALPHA) do
    IDX[ch] = i
end

local cur = nil
if view >= 2 and pos % dsp == 0 then
    local slot = pos // dsp + 1
    if slot <= #line then
        local ch = line:sub(slot, slot)
        if ch ~= " " then
            cur = IDX[ch] or IDX["?"]
        end
    end
end

local CS = {}
for i = 1, #ALPHA do
    local s = make_series()
    if cur == i then
        s:set(1)
    else
        s:set(NaN)
    end
    CS[i] = s
end

if view >= 2 then
    local f0, f2 = make_series(), make_series()
    f0:set(0)
    f2:set(2)
    plot (f0, "frame 0", rgba(0,0,0,0), 1)
    plot (f2, "frame 2", rgba(0,0,0,0), 1)
    for i, ch in ipairs(ALPHA) do
        plot_shape (CS[i], "ch " .. ch, shape_style.circle, shape_size.tiny, "#FFFFFF",
                    shape_location.absolute, 0, ch, "#FFFFFF")
    end
end
