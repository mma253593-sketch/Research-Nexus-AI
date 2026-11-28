-- =====================================================================
--  M1 -> M5 / M15 AGGREGATION PROBE v2 (TASK 03D)  —  DIAGNOSTIC ONLY
--  NOT FOR TRADING. No signals, no CALL/PUT, not part of V2.
--
--  Builds M5 / M15 bars from the chart's own M1 bars (open, high, low,
--  close, open_time). No security(). No synthetic data.
--
--  Bucket rule (same as TASK 03C, m1_aggregate_probe.lua):
--   P      = smallest positive open_time step seen so far
--   bucket = floor(open_time / (k * P)),  k = 5 or 15
--
--  New in v2:
--   * "Last CLOSED" is built only from M1 bars that are CLOSED: each bar
--     adds the PREVIOUS bar ([1]) to the bucket, and a bucket is closed
--     only when a bar of a later bucket exists. The 03C path (forming
--     bar incl. the live M1 bar) is kept for the FORMING value and as a
--     cross-check: a DIFF marker appears if the two closed values differ.
--   * Status per bucket: OK / GAP / NODATA / FORMING / BADP
--       OK      = closed, exactly k M1 bars, times strictly increasing,
--                 chart step P is 60 s (or 60000 ms)
--       GAP     = closed but N ~= k or times out of order -> REJECTED
--       NODATA  = no M1 bar of that bucket on the chart
--       FORMING = bucket not closed yet -> not usable
--       BADP    = chart is not M1 (P ~= 60 / 60000) -> not usable
--     Only OK values are "usable". Lines and candles show usable values
--     only; GAP values appear only as text marked GAP.
--   * Bucket selection by day / hour / minute (chart time = date(), OS
--     timezone) and the previous bucket next to it.
--   * Text rows: M5 and M15 at the same time, larger text, no dots.
--
--  APIs used (QCS docs): instrument, input, input_group, get_value,
--   make_series, :set, plot, plot_shape, plot_candle, conditional, date,
--   rgba, print, error, open/high/low/close/open_time.
--  Lua 5.3: pcall, type, math.floor/max/min/abs, string.format, //
-- =====================================================================

instrument { name = "M1 Aggregate Probe v2", short_name = "AGG-PROBE-V2", overlay = false }

input_group {
    "Probe v2",
    view     = input (2, "View 1=Lines 2=Text 3=Candles 4=Snapshot", input.integer, 1, 4),
    sel_on   = input (1, "Select 0=latest closed 1=by time", input.integer, 0, 1),
    sel_day  = input (0, "Select day of month (0=latest match)", input.integer, 0, 31),
    sel_hour = input (7, "Select hour (chart time)", input.integer, 0, 23),
    sel_min  = input (15, "Select minute", input.integer, 0, 59),
    rec      = input (0, "Text 0=SEL+PRV 1=SEL 2=PRV", input.integer, 0, 2),
    rows     = input (3, "Rows 1=M5 2=M15 3=both", input.integer, 1, 3),
    place    = input (1, "Text place 1=top/bottom 2=absolute", input.integer, 1, 2),
    tsize    = input (4, "Text size 1=tiny .. 5=huge", input.integer, 1, 5),
    dot      = input (0, "Show shape under text 0=no 1=yes", input.integer, 0, 1),
    dsp      = input (2, "Bars per character", input.integer, 1, 20),
    idle     = input (20, "Bars between status lines", input.integer, 1, 500),
    logp     = input (1, "print() selected records 0=no 1=yes", input.integer, 0, 1)
}

local NaN = 0 / 0
local HAS_PCALL = type(pcall) == "function"
local OK, GAP, NODATA, FORMING, BADP = 1, 2, 3, 4, 5
local STN = { "OK", "GAP", "NODATA", "FORMING", "BADP" }

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

local function gv1(x)
    local ok, v = try(function () return get_value(x[1]) end)
    if ok then
        return num(v)
    end
    return nil
end

-- ------------------------------------------------------------------
-- Chart M1 bar: current (may be live) and previous (closed)
-- ------------------------------------------------------------------
local o, h, l, c = gv(open), gv(high), gv(low), gv(close)
local ot = gv(open_time)
local o1, h1, l1, c1 = gv1(open), gv1(high), gv1(low), gv1(close)
local ot1 = gv1(open_time)

local cnt = make_series()
local bar_no = (at1(cnt) or 0) + 1
cnt:set(bar_no)

-- P = smallest positive step seen so far (03C rule)
local ps = make_series()
local P = at1(ps)
if ot ~= nil and ot1 ~= nil then
    local step = ot - ot1
    if step > 0 and (P == nil or step < P) then
        P = step
    end
end
put(ps, P)
local PV = P == 60 or P == 60000          -- M1 chart confirmed

local function sec(t)                       -- timestamp for date()
    if t == nil then
        return nil
    end
    if P == 60000 then
        return math.floor(t / 1000)
    end
    return math.floor(t)
end

local function dt(t)
    if t == nil or type(date) ~= "function" then
        return nil
    end
    local ok, d = try(date, sec(t))
    if ok and type(d) == "table" and num(d.hour) ~= nil and num(d.min) ~= nil then
        return d
    end
    return nil
end

-- ------------------------------------------------------------------
-- A) 03C aggregation, unchanged (forming bar incl. live M1 bar)
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
    end
    local pb = at1(sb)
    local lb, lo, lh, ll, lc, ln = at1(qb), at1(qo), at1(qh), at1(ql), at1(qc), at1(qn)
    local ao, ah, al, ac, an

    r.new = bucket ~= nil and (pb == nil or bucket ~= pb)
    if bucket == nil or o == nil or h == nil or l == nil or c == nil then
        ao, ah, al, ac, an = nil, nil, nil, nil, nil
    elseif r.new then
        if pb ~= nil then
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

    put(sb, bucket); put(so, ao); put(sh, ah); put(sl, al); put(sc, ac); put(sn, an)
    put(qb, lb); put(qo, lo); put(qh, lh); put(ql, ll); put(qc, lc); put(qn, ln)

    r.bucket, r.o, r.h, r.l, r.c, r.n = bucket, ao, ah, al, ac, an
    r.lb, r.lo, r.lh, r.ll, r.lc, r.ln = lb, lo, lh, ll, lc, ln
    return r
end

-- ------------------------------------------------------------------
-- B) Closed-bars-only aggregation (same bucket rule)
--    record = { b, o, h, l, c, n, bad }
-- ------------------------------------------------------------------
local FIELDS = { "b", "o", "h", "l", "c", "n", "bad" }

local function rec_series()
    local t = {}
    for i = 1, #FIELDS do
        t[i] = make_series()
    end
    return t
end

local function rec_read(S)
    local r = {}
    for i, f in ipairs(FIELDS) do
        r[f] = at1(S[i])
    end
    if r.b == nil then
        return nil
    end
    return r
end

local function rec_write(S, r)
    for i, f in ipairs(FIELDS) do
        put(S[i], r and r[f] or nil)
    end
end

local function copy(r)
    if r == nil then
        return nil
    end
    local t = {}
    for _, f in ipairs(FIELDS) do
        t[f] = r[f]
    end
    return t
end

local function closed_agg(k)
    local SA, SZ, SY = rec_series(), rec_series(), rec_series()
    local sat = make_series()                 -- open_time of last bar in A
    local A, Z, Y = rec_read(SA), rec_read(SZ), rec_read(SY)
    local lt = at1(sat)
    local r = { k = k }

    if PV and ot ~= nil then
        r.b0 = math.floor(ot / (k * P))
    end
    if PV and ot1 ~= nil and o1 ~= nil and h1 ~= nil and l1 ~= nil and c1 ~= nil then
        local b1 = math.floor(ot1 / (k * P))
        if A ~= nil and A.b == b1 then
            A = { b = b1, o = A.o, h = math.max(A.h, h1), l = math.min(A.l, l1),
                  c = c1, n = A.n + 1, bad = A.bad }
            if lt ~= nil and ot1 <= lt then
                A.bad = 1                      -- time not increasing
            end
        else
            local back = A ~= nil and b1 < A.b
            A = { b = b1, o = o1, h = h1, l = l1, c = c1, n = 1, bad = back and 1 or 0 }
        end
        lt = ot1
        if r.b0 ~= nil and r.b0 ~= b1 then
            -- a bar of a later bucket exists: bucket b1 is complete
            Y, Z = Z, copy(A)
            if r.b0 < b1 then
                Z.bad = 1
            end
            r.closed_now = true
        end
    end

    rec_write(SA, A); rec_write(SZ, Z); rec_write(SY, Y); put(sat, lt)
    r.A, r.Z, r.Y = A, Z, Y
    return r
end

local function status_of(x, k)
    if x == nil or x.b == nil then
        return NODATA
    end
    if not PV then
        return BADP
    end
    if x.bad == 1 or x.n ~= k then
        return GAP
    end
    return OK
end

-- consumer rule: values only when OK, otherwise nothing
local function usable(x, k)
    if status_of(x, k) == OK then
        return x
    end
    return nil
end

local function same(a, b)
    if a == nil or b == nil then
        return a == b
    end
    return math.abs(a - b) <= 1e-9 * math.max(1, math.abs(a))
end

-- ------------------------------------------------------------------
-- C) Selection of one bucket (by time, or latest closed) + previous
-- ------------------------------------------------------------------
local function pick(k, LG, CA)
    local st = make_series()
    local SS, SP = rec_series(), rec_series()
    local tgt = at1(st)
    local S, Pv = rec_read(SS), rec_read(SP)
    local r = { k = k, event = false }

    if sel_on == 1 then
        if CA.b0 ~= nil then
            local d = dt(CA.b0 * k * P)
            if d ~= nil and d.hour == sel_hour and d.min == sel_min - sel_min % k
                and (sel_day == 0 or (num(d.day) ~= nil and d.day == sel_day)) then
                if tgt ~= CA.b0 then
                    tgt, S, Pv = CA.b0, nil, nil
                end
            end
        end
        if CA.closed_now and tgt ~= nil and CA.Z ~= nil then
            if CA.Z.b == tgt then
                S, r.event = copy(CA.Z), true
            elseif CA.Z.b == tgt - 1 then
                Pv = copy(CA.Z)
            end
        end
    else
        S, Pv = CA.Z, nil
        tgt = S and S.b or nil
        if S ~= nil and CA.Y ~= nil and CA.Y.b == S.b - 1 then
            Pv = CA.Y
        end
    end

    put(st, tgt); rec_write(SS, S); rec_write(SP, Pv)

    -- selected bucket
    r.tgt = tgt
    if tgt == nil then
        r.s_st = NODATA
    elseif S ~= nil and S.b == tgt then
        r.s_st, r.S = status_of(S, k), S
    elseif CA.b0 ~= nil and tgt == CA.b0 and LG.bucket == tgt then
        r.s_st = FORMING
        r.S = { b = tgt, o = LG.o, h = LG.h, l = LG.l, c = LG.c, n = LG.n }
    else
        r.s_st = NODATA
    end
    if not PV and r.s_st ~= NODATA then
        r.s_st = BADP
    end
    -- previous bucket (tgt - 1)
    if tgt ~= nil and Pv ~= nil and Pv.b == tgt - 1 then
        r.p_st, r.Pv = status_of(Pv, k), Pv
    else
        r.p_st = NODATA
    end
    return r
end

local L5, L15 = aggregate(5), aggregate(15)
local C5, C15 = closed_agg(5), closed_agg(15)
local S5, S15 = pick(5, L5, C5), pick(15, L15, C15)

-- 03C closed value vs closed-bars-only value (same bar, same bucket)
local function diff(LG, CA)
    -- CA.Y ~= nil: skip the chart's first bucket, where 03C cannot use
    -- bar 1 (P is unknown on bar 1) and so always counts one bar less
    if not (PV and LG.closed_now and CA.closed_now and CA.Z ~= nil and CA.Y ~= nil
            and LG.lb == CA.Z.b) then
        return false
    end
    local z = CA.Z
    return not (same(LG.lo, z.o) and same(LG.lh, z.h) and same(LG.ll, z.l)
        and same(LG.lc, z.c) and LG.ln == z.n)
end
local D5, D15 = diff(L5, C5), diff(L15, C15)

-- ------------------------------------------------------------------
-- Text of one record line
--  "M5 SEL07:17 B28 07:15-07:19 OK N5/5 O3699.95728 H... L... C...
--   PRV28 07:10-07:14 OK N5/5 O... H... L... C..."
-- ------------------------------------------------------------------
local function f5(v)
    if v == nil then
        return "NA"
    end
    return string.format("%.5f", v)
end

local function hm(t)
    local d = dt(t)
    if d == nil then
        return "--:--"
    end
    return string.format("%02d:%02d", d.hour, d.min)
end

local function dd(t)
    local d = dt(t)
    if d == nil or num(d.day) == nil then
        return "--"
    end
    return string.format("%02d", d.day)
end

local function part(tag, st, x, b, k)
    local s = tag
    if b ~= nil and P ~= nil then
        local t0 = b * k * P
        s = s .. dd(t0) .. " " .. hm(t0) .. "-" .. hm(t0 + (k - 1) * P)
    else
        s = s .. "-- --:--"
    end
    s = s .. " " .. STN[st] .. " N" .. ((x and x.n) and string.format("%d", x.n) or "0")
        .. "/" .. k
    if x ~= nil and st ~= NODATA then
        s = s .. " O" .. f5(x.o) .. " H" .. f5(x.h) .. " L" .. f5(x.l) .. " C" .. f5(x.c)
    end
    return s
end

local function line_of(R)
    local k = R.k
    local s = "M" .. k
    if sel_on == 1 then
        s = s .. " SEL" .. string.format("%02d:%02d", sel_hour, sel_min)
            .. (sel_day > 0 and ("D" .. sel_day) or "")
    else
        s = s .. " LIVE"
    end
    if rec ~= 2 then
        s = s .. " " .. part("B", R.s_st, R.S, R.tgt, k)
    end
    if rec ~= 1 then
        s = s .. " " .. part("PRV", R.p_st, R.Pv, R.tgt and (R.tgt - 1) or nil, k)
    end
    return s
end

local line5, line15 = line_of(S5), line_of(S15)

if logp == 1 then
    if S5.event then print(line5) end
    if S15.event then print(line15) end
end

-- ------------------------------------------------------------------
-- Text printer: a line starts right after the selected bucket closes,
-- or every `idle` bars after the previous line ended. The line text is
-- frozen on its first bar, so one line describes one moment.
-- ------------------------------------------------------------------
local ALPHA = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-", ":", "/",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "K", "L", "M", "N", "O", "P", "R",
    "S", "T", "V", "?" }
local IDX = {}
for i, ch in ipairs(ALPHA) do
    IDX[ch] = i
end
-- QCS re-runs the whole script on every bar, so a Lua table does not
-- survive. The numbers behind a line are held in series instead, and the
-- line is rebuilt from them on every bar of that line.
local function flat(R)
    local S, Pv = R.S or {}, R.Pv or {}
    return { R.s_st, R.tgt, S.o, S.h, S.l, S.c, S.n,
             R.p_st, Pv.o, Pv.h, Pv.l, Pv.c, Pv.n, R.event and 1 or 0 }
end

local function unflat(v, k)
    local R = { k = k, s_st = v[1] or NODATA, tgt = v[2], p_st = v[8] or NODATA }
    if v[3] ~= nil or v[7] ~= nil then
        R.S = { o = v[3], h = v[4], l = v[5], c = v[6], n = v[7] }
    end
    if v[9] ~= nil or v[13] ~= nil then
        R.Pv = { o = v[9], h = v[10], l = v[11], c = v[12], n = v[13] }
    end
    return R
end

local function char_at(R, line)
    local srs, slen = make_series(), make_series()
    local rs, len = at1(srs), at1(slen)
    local HV = {}
    for i = 1, 14 do
        HV[i] = make_series()
    end
    local start = R.event or rs == nil or len == nil
        or (bar_no - rs) >= len * dsp + idle
    local text
    if start then
        rs, len, text = bar_no, #line, line
        local v = flat(R)
        for i = 1, 14 do
            put(HV[i], v[i])
        end
    else
        local v = {}
        for i = 1, 14 do
            v[i] = at1(HV[i])
            put(HV[i], v[i])
        end
        text = line_of(unflat(v, R.k))
    end
    put(srs, rs); put(slen, len)

    local pos = bar_no - rs
    if pos % dsp ~= 0 then
        return nil
    end
    local slot = pos // dsp + 1
    if slot > #text then
        return nil
    end
    local ch = text:sub(slot, slot)
    if ch == " " then
        return nil
    end
    return IDX[ch] or IDX["?"]
end

local cur5, cur15 = char_at(S5, line5), char_at(S15, line15)

-- ------------------------------------------------------------------
-- View 1: lines (usable values only) + status markers
-- ------------------------------------------------------------------
local function S(v)
    local s = make_series()
    put(s, v)
    return s
end
local u5, u15 = usable(C5.Z, 5), usable(C15.Z, 15)
local L_c   = S(c)
local L_5f  = S(L5.c)
local L_5c  = S(u5 and u5.c or nil)
local L_15f = S(L15.c)
local L_15c = S(u15 and u15.c or nil)

if view == 1 then
    plot (L_c,   "M1 close (chart)",            "#FFFFFF", 1)
    plot (L_5f,  "M5 FORMING close",            "#80DEEA", 1)
    plot (L_5c,  "M5 last CLOSED close (OK)",   "#29B6F6", 2)
    plot (L_15f, "M15 FORMING close",           "#FFCC80", 1)
    plot (L_15c, "M15 last CLOSED close (OK)",  "#FFA726", 2)
end

local function closed_st(CA, k)
    if CA.closed_now then
        return status_of(CA.Z, k)
    end
    return nil
end
local cs5, cs15 = closed_st(C5, 5), closed_st(C15, 15)
local v1 = view == 1
plot_shape (conditional(v1 and cs5 == OK),   "M5 closed OK",   shape_style.triangleup, shape_size.tiny,  "#29B6F6", shape_location.bottom, 0, "5OK",   "#29B6F6")
plot_shape (conditional(v1 and cs5 == GAP),  "M5 closed GAP",  shape_style.xcross,     shape_size.small, "#FF1744", shape_location.bottom, 0, "5GAP",  "#FF1744")
plot_shape (conditional(v1 and cs15 == OK),  "M15 closed OK",  shape_style.triangleup, shape_size.small, "#FFA726", shape_location.top,    0, "15OK",  "#FFA726")
plot_shape (conditional(v1 and cs15 == GAP), "M15 closed GAP", shape_style.xcross,     shape_size.normal,"#FF1744", shape_location.top,    0, "15GAP", "#FF1744")
plot_shape (conditional(v1 and (D5 or D15)), "03C vs closed DIFF", shape_style.diamond, shape_size.small, "#E040FB", shape_location.top, 0, "DIFF", "#E040FB")
plot_shape (conditional(v1 and S5.event),    "Selected M5 closed",  shape_style.square, shape_size.small, "#00E676", shape_location.bottom, 0, "SEL5", "#00E676")
plot_shape (conditional(v1 and S15.event),   "Selected M15 closed", shape_style.square, shape_size.small, "#00E676", shape_location.top,    0, "SEL15", "#00E676")

local not_m1 = P ~= nil and not PV
plot_shape (conditional(not_m1), "Chart not M1", shape_style.xcross, shape_size.small, "#FF1744", shape_location.top, 0, "NOT 1M CHART", "#FF1744")

-- ------------------------------------------------------------------
-- View 2: text rows. M5 = bottom row, M15 = top row (place 1), or
-- absolute rows y=1 (M5) and y=2 (M15) (place 2, as in 03C).
-- ------------------------------------------------------------------
local SIZES = { shape_size.tiny, shape_size.small, shape_size.normal,
    shape_size.large, shape_size.huge }
local TSZ = SIZES[tsize] or shape_size.large
local DOTC = (dot == 1) and "#9E9E9E" or rgba(0, 0, 0, 0)

local function char_series(cur, y)
    local t = {}
    for i = 1, #ALPHA do
        local s = make_series()
        if cur == i then
            s:set(y)
        else
            s:set(NaN)
        end
        t[i] = s
    end
    return t
end
local CS5  = char_series(cur5, 1)
local CS15 = char_series(cur15, 2)

if view == 2 then
    if place == 2 then
        local f0, f3 = make_series(), make_series()
        f0:set(0)
        f3:set(3)
        plot (f0, "frame 0", rgba(0,0,0,0), 1)
        plot (f3, "frame 3", rgba(0,0,0,0), 1)
    end
    for i, ch in ipairs(ALPHA) do
        if rows ~= 2 then
            if place == 2 then
                plot_shape (CS5[i], "M5 " .. ch, shape_style.circle, TSZ, DOTC,
                            shape_location.absolute, 0, ch, "#4FC3F7")
            else
                plot_shape (conditional(cur5 == i), "M5 " .. ch, shape_style.circle, TSZ, DOTC,
                            shape_location.bottom, 0, ch, "#4FC3F7")
            end
        end
        if rows ~= 1 then
            if place == 2 then
                plot_shape (CS15[i], "M15 " .. ch, shape_style.circle, TSZ, DOTC,
                            shape_location.absolute, 0, ch, "#FFB74D")
            else
                plot_shape (conditional(cur15 == i), "M15 " .. ch, shape_style.circle, TSZ, DOTC,
                            shape_location.top, 0, ch, "#FFB74D")
            end
        end
    end
end

-- ------------------------------------------------------------------
-- View 3: candles of the last CLOSED usable bar (rows 2 = M15, else M5)
-- ------------------------------------------------------------------
local U = (rows == 2) and u15 or u5
local K_o, K_h, K_l, K_c = S(U and U.o or nil), S(U and U.h or nil),
    S(U and U.l or nil), S(U and U.c or nil)
if view == 3 then
    plot_candle {
        open = K_o, high = K_h, low = K_l, close = K_c,
        name = (rows == 2) and "M15 last CLOSED (OK)" or "M5 last CLOSED (OK)",
        color = "#B0BEC5"
    }
end

-- ------------------------------------------------------------------
-- View 4: snapshot. Stops the script with error() and the record text
-- on the bar where the selected bucket(s) closed. Use only to read the
-- numbers; nothing is drawn after that bar.
-- ------------------------------------------------------------------
if view == 4 and sel_on == 1 then
    local want5, want15 = rows ~= 2, rows ~= 1
    local ready5 = (not want5) or (S5.S ~= nil and S5.s_st ~= FORMING)
    local ready15 = (not want15) or (S15.S ~= nil and S15.s_st ~= FORMING)
    local now = (want5 and S5.event) or (want15 and S15.event)
    if now and ready5 and ready15 then
        local msg = ""
        if want5 then msg = line5 end
        if want15 then msg = msg .. (want5 and " || " or "") .. line15 end
        error(msg)
    end
end
