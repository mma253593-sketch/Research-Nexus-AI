-- =====================================================================
--  QCS RESOLUTION + SECURITY DIAGNOSTIC  (TASK 03)  —  NOT FOR TRADING
--  Small stand-alone script. It does not reuse security_probe_main.lua.
--  Goal: log exactly what the IQ Option runtime gives the script for
--  `resolution` and for security(current_ticker_id, "1m"/"5m"/"15m").
--
--  Docs: Functions/Timeframes/resolution says "a String, for example
--  "1m"" but its Syntax Format is `resolution("10m")`. Both readings are
--  checked; nothing is assumed. Every value printed is the raw value
--  received. Missing values print as UNKNOWN with the real reason.
--
--  Evidence for the chart timeframe (each reported on its own):
--   E1  resolution == "1m"         direct value compare (documented string)
--   E2  resolution("1m")           ONLY if resolution is callable; this is
--                                  the docs' Syntax Format; raw result shown
--   E3  close_time - open_time      chart bar length (documented series)
--   E4  open_time - open_time[1]     step between chart bars
--  BAR TF: 1m/5m/15m measured from E4 (+E3 agreement); separate marker.
--  Verdict: M1 CONFIRMED only if E1 is true or E2 returns exactly true.
--           NOT M1 only if resolution equals another documented string.
--           Otherwise UNKNOWN + reason. E3 never confirms on its own.
-- =====================================================================

instrument { name = "Resolution Diagnostic", short_name = "RES-DIAG", overlay = false }

input_group {
    "Diagnostic",
    view     = input (1, "View 1=Status rows 2=Close 3=OpenTime", input.integer, 1, 3),
    repeat_n = input (30, "Status: repeat labels every N bars", input.integer, 1, 1000),
    do_print = input (1, "Print log 1=on 0=off", input.integer, 0, 1)
}

local NaN = 0 / 0
local HAS_PCALL = type(pcall) == "function"

local function try(f, a, b)
    if HAS_PCALL then
        return pcall(f, a, b)
    end
    return true, f(a, b)
end

-- raw text of any value, never raises
local function show(v)
    if v == nil then
        return "nil"
    end
    local ok, s = try(tostring, v)
    if ok and type(s) == "string" then
        if type(v) == "string" then
            return '"' .. s .. '" len=' .. #s
        end
        return s
    end
    return "<tostring failed>"
end

local function num(v)
    if type(v) == "number" and v == v then
        return v
    end
    return nil
end

local function S(v)
    local s = make_series()
    if v == nil then
        s:set(NaN)
    else
        s:set(v)
    end
    return s
end

-- value of series s one chart bar back (nil if missing)
local function at1(s)
    local ok, v = try(function () return get_value(s[1]) end)
    if ok then
        return num(v)
    end
    return nil
end

local DOC_RES = { ["1s"]=1, ["5s"]=1, ["10s"]=1, ["15s"]=1, ["30s"]=1,
    ["1m"]=1, ["2m"]=1, ["5m"]=1, ["10m"]=1, ["15m"]=1, ["30m"]=1,
    ["1H"]=1, ["2H"]=1, ["4H"]=1, ["8H"]=1, ["12H"]=1,
    ["1D"]=1, ["1W"]=1, ["1M"]=1, ["1Y"]=1 }

-- ------------------------------------------------------------------
-- 1. resolution: raw value, type, direct compare, documented call form
-- ------------------------------------------------------------------
local res_raw  = show(resolution)
local res_type = type(resolution)

local e1 = (resolution == "1m")                -- plain Lua compare

local e2_txt = "not attempted (resolution not callable)"
local e2_val = nil
local callable = res_type == "function"
if not callable and (res_type == "table" or res_type == "userdata") then
    local ok, mt = try(getmetatable, resolution)
    callable = ok and type(mt) == "table" and mt.__call ~= nil
end
if callable then
    local ok, r = try(resolution, "1m")
    if ok then
        e2_val = r
        e2_txt = "returned " .. show(r) .. " (type " .. type(r) .. ")"
    else
        e2_txt = "ERROR " .. show(r)
    end
end

-- E3: chart bar length from documented built-in series
local ch_ot = num(get_value(open_time))
local ch_ct = num(get_value(close_time))
local ch_c  = num(get_value(close))
local e3 = nil
if ch_ot ~= nil and ch_ct ~= nil then
    e3 = ch_ct - ch_ot
end

-- E4: open_time step between this chart bar and the previous one
local ch_ot1 = nil
do
    local ok, v = try(function () return get_value(open_time[1]) end)
    if ok then
        ch_ot1 = num(v)
    end
end
local e4 = nil
if ch_ot ~= nil and ch_ot1 ~= nil then
    e4 = ch_ot - ch_ot1
end

-- BAR timeframe: measured from the chart's own timestamps (real data,
-- no resolution variable). Exact matches only, seconds or milliseconds.
-- Needs E4 (step) to match AND E3 (length) to agree (= step or step-1)
-- when E3 is available. A gap (market closed) makes E4 larger -> UNKNOWN.
local BAR_TF = { [60]="1m", [300]="5m", [900]="15m",
    [60000]="1m", [300000]="5m", [900000]="15m" }
local bar_tf, bar_why = "UNKNOWN", ""
if e4 == nil then
    bar_why = "no open_time[1] on this bar"
elseif BAR_TF[e4] == nil then
    bar_why = "step " .. show(e4) .. " is not 1m/5m/15m (gap or other TF)"
elseif e3 ~= nil and e3 ~= e4 and e3 ~= e4 - 1 then
    bar_why = "step " .. show(e4) .. " but length " .. show(e3) .. " disagree"
else
    bar_tf = BAR_TF[e4]
    bar_why = "step " .. show(e4) .. " length " .. show(e3)
end

local verdict, reason
if e1 then
    verdict, reason = "M1 CONFIRMED", "E1 resolution == \"1m\""
elseif e2_val == true then
    verdict, reason = "M1 CONFIRMED", "E2 resolution(\"1m\") returned true"
elseif res_type == "string" and DOC_RES[resolution] then
    verdict, reason = "NOT M1", "resolution is documented value " .. res_raw
else
    verdict = "UNKNOWN"
    reason = "type=" .. res_type .. " value=" .. res_raw .. "; E2 " .. e2_txt
end

-- read-only look at the `timeframe` name used in the docs' examples
-- (timeframe.is_intraday() etc.). Fields are only read, never called.
local tf_txt = "timeframe type=" .. type(timeframe)
if type(timeframe) == "table" then
    local ok1, a = try(function () return timeframe.resolution end)
    local ok2, b = try(function () return timeframe.is_intrahour end)
    tf_txt = tf_txt .. " .resolution=" .. (ok1 and show(a) or "<err>")
        .. " .is_intrahour type=" .. (ok2 and type(b) or "<err>")
end
local glob_txt = "is_intrahour type=" .. type(is_intrahour)
    .. " is_intraday type=" .. type(is_intraday)

-- ------------------------------------------------------------------
-- 2. security() for 1m / 5m / 15m — raw results, no substitutes
-- ------------------------------------------------------------------
local function probe(res)
    local d = { res = res, ok = false, c = nil, ot = nil }
    if type(security) ~= "function" then
        d.why, d.code = "UNKNOWN: security type=" .. type(security), 3
        return d
    end
    if current_ticker_id == nil then
        d.why, d.code = "UNKNOWN: current_ticker_id is nil", 3
        return d
    end
    local ok, t = try(security, current_ticker_id, res)
    if not ok then
        d.why, d.code = "UNKNOWN: security error " .. show(t), 2
        return d
    end
    if t == nil then
        d.why, d.code = "UNKNOWN: security returned nil", 3
        return d
    end
    d.ttype = type(t)
    local okc, cs = try(function () return t.close end)
    local oko, os_ = try(function () return t.open_time end)
    if not okc or cs == nil then
        d.why, d.code = "UNKNOWN: no .close field", 4
        return d
    end
    if not oko or os_ == nil then
        d.why, d.code = "UNKNOWN: no .open_time field", 4
        return d
    end
    local ok3, cv = try(get_value, cs)
    local ok4, ov = try(get_value, os_)
    d.c_raw  = ok3 and show(cv) or ("get_value error " .. show(cv))
    d.ot_raw = ok4 and show(ov) or ("get_value error " .. show(ov))
    d.c  = ok3 and num(cv) or nil
    d.ot = ok4 and num(ov) or nil
    if d.c == nil or d.ot == nil then
        d.why, d.code = "UNKNOWN: close/open_time not a number on this bar", 5
        return d
    end
    d.ok = true
    d.why, d.code = "OK", 1
    return d
end

local s1  = probe("1m")
local s5  = probe("5m")
local s15 = probe("15m")

-- ------------------------------------------------------------------
-- 3. Plots (View 2 = close, View 3 = timestamps; NaN gap when unreadable)
-- ------------------------------------------------------------------
local B_e4 = S(e4)
local C_ch = S(ch_c)
local C_1  = S(s1.c)
local C_5  = S(s5.c)
local C_15 = S(s15.c)
local O_ch = S(ch_ot)
local O_1  = S(s1.ot)
local O_5  = S(s5.ot)
local O_15 = S(s15.ot)
local B_e3 = S(e3)

if view == 2 then
    plot (C_ch, "Chart close",    "#FFFFFF", 1)
    plot (C_1,  "SEC 1m close",   "#BDBDBD", 1)
    plot (C_5,  "SEC 5m close",   "#29B6F6", 2)
    plot (C_15, "SEC 15m close",  "#FFA726", 2)
elseif view == 3 then
    plot (O_ch, "Chart open_time",   "#FFFFFF", 1)
    plot (O_1,  "SEC 1m open_time",  "#BDBDBD", 1)
    plot (O_5,  "SEC 5m open_time",  "#29B6F6", 1)
    plot (O_15, "SEC 15m open_time", "#FFA726", 1)
    plot (B_e3, "E3 chart close_time-open_time", "#00E676", 1)
    plot (B_e4, "E4 chart open_time step", "#76FF03", 1)
end

-- ------------------------------------------------------------------
-- Status rows (View 1). One row per item, so labels never overlap:
--   row 6 RES (resolution)   row 5 BAR (bar timestamps)
--   row 3 SEC 1m   row 2 SEC 5m   row 1 SEC 15m
-- A label is drawn only when the state changes from the previous bar,
-- or every `repeat_n` bars, so the latest state is visible near the
-- right edge without covering every candle.
-- RES codes: 1 "1m"  2 other documented string  3 other string
--            4 callable, res("1m")==true  5 callable, other result
--            6 callable, call error  7 nil  8 other type
-- SEC codes: 1 OK  2 ERR (call raised)  3 NIL (no security / no
--            ticker / returned nil)  4 NOFLD (no close or open_time)
--            5 NAN (value not a number on this bar)
-- BAR codes: 1 1m  2 5m  3 15m  0 unknown
-- ------------------------------------------------------------------
local res_code = 8
if res_type == "string" then
    if e1 then
        res_code = 1
    elseif DOC_RES[resolution] then
        res_code = 2
    else
        res_code = 3
    end
elseif callable then
    if e2_val == true then
        res_code = 4
    elseif e2_txt:sub(1, 5) == "ERROR" then
        res_code = 6
    else
        res_code = 5
    end
elseif resolution == nil then
    res_code = 7
end
local bar_code = ({ ["1m"] = 1, ["5m"] = 2, ["15m"] = 3 })[bar_tf] or 0

local function snap(v)
    local s = S(v)
    return at1(s)
end
local cnt = make_series()
local cnt_prev = at1(cnt)
local bar_no = (cnt_prev or 0) + 1
cnt:set(bar_no)
local periodic = bar_no % repeat_n == 0

local function show_row(code, prev_code)
    return periodic or prev_code == nil or prev_code ~= code
end
local p_res  = snap(res_code)
local p_bar  = snap(bar_code)
local p_s1   = snap(s1.code)
local p_s5   = snap(s5.code)
local p_s15  = snap(s15.code)
local on_res = show_row(res_code, p_res)
local on_bar = show_row(bar_code, p_bar)
local on_s1  = show_row(s1.code, p_s1)
local on_s5  = show_row(s5.code, p_s5)
local on_s15 = show_row(s15.code, p_s15)

-- series at a fixed row height, NaN (not drawn) otherwise
local function row(on, ok, y)
    local s = make_series()
    if on and ok then
        s:set(y)
    else
        s:set(NaN)
    end
    return s
end

local RED, YEL, GRN = "#FF1744", "#FFEA00", "#00E676"
local function lab(series, name, color, text)
    plot_shape (series, name, shape_style.circle, shape_size.tiny, color,
                shape_location.absolute, 0, text, color)
end

local R = {
    row(on_res, res_code == 1, 6), row(on_res, res_code == 2, 6),
    row(on_res, res_code == 3, 6), row(on_res, res_code == 4, 6),
    row(on_res, res_code == 5, 6), row(on_res, res_code == 6, 6),
    row(on_res, res_code == 7, 6), row(on_res, res_code == 8, 6),
    row(on_bar, bar_code == 1, 5), row(on_bar, bar_code == 2, 5),
    row(on_bar, bar_code == 3, 5), row(on_bar, bar_code == 0, 5)
}
local SEC = {}
for i, d in ipairs({ { s1, on_s1, 3 }, { s5, on_s5, 2 }, { s15, on_s15, 1 } }) do
    SEC[i] = {}
    for c = 1, 5 do
        SEC[i][c] = row(d[2], d[1].code == c, d[3])
    end
end
local FR_lo, FR_hi = S(0), S(7)

if view == 1 then
    plot (FR_lo, "frame 0", rgba(0,0,0,0), 1)
    plot (FR_hi, "frame 7", rgba(0,0,0,0), 1)
    lab (R[1],  "RES 1m",        GRN, "RES=1m")
    lab (R[2],  "RES other doc", RED, "RES=doc not 1m")
    lab (R[3],  "RES other str", YEL, "RES=str?")
    lab (R[4],  "RES fn true",   GRN, "RES fn(1m)=true")
    lab (R[5],  "RES fn other",  YEL, "RES fn(1m)=not true")
    lab (R[6],  "RES fn error",  RED, "RES fn ERR")
    lab (R[7],  "RES nil",       YEL, "RES=nil")
    lab (R[8],  "RES other type",YEL, "RES type?")
    lab (R[9],  "BAR 1m",  GRN, "BAR 1m")
    lab (R[10], "BAR 5m",  GRN, "BAR 5m")
    lab (R[11], "BAR 15m", GRN, "BAR 15m")
    lab (R[12], "BAR ?",   YEL, "BAR ?")
    local names = { "1m", "5m", "15m" }
    local texts = { "OK", "ERR", "NIL", "NOFLD", "NAN" }
    local cols  = { GRN, RED, RED, RED, YEL }
    for i = 1, 3 do
        for c = 1, 5 do
            lab (SEC[i][c], "SEC " .. names[i] .. " " .. texts[c], cols[c],
                 names[i] .. " " .. texts[c])
        end
    end
end

-- ------------------------------------------------------------------
-- 4. Script log (every run = every bar, and possibly every tick)
-- ------------------------------------------------------------------
local function line(d)
    return "SEC " .. d.res .. ": " .. d.why
        .. " table=" .. tostring(d.ttype)
        .. " close=" .. tostring(d.c_raw)
        .. " open_time=" .. tostring(d.ot_raw) .. " code=" .. tostring(d.code)
end

if do_print == 1 then
    print("RES-DIAG bar open_time=" .. show(ch_ot) .. " close=" .. show(ch_c))
    print("RES-DIAG resolution value=" .. res_raw .. " type=" .. res_type)
    print("RES-DIAG E1 resolution==\"1m\" -> " .. tostring(e1))
    print("RES-DIAG E2 resolution(\"1m\") -> " .. e2_txt)
    print("RES-DIAG E3 close_time-open_time -> " .. show(e3))
    print("RES-DIAG E4 open_time-open_time[1] -> " .. show(e4))
    print("RES-DIAG VERDICT (resolution) " .. verdict .. " (" .. reason .. ")")
    print("RES-DIAG BAR TF (timestamps) " .. bar_tf .. " (" .. bar_why .. ")")
    print("RES-DIAG " .. tf_txt .. " | " .. glob_txt)
    print("RES-DIAG current_ticker_id=" .. show(current_ticker_id)
        .. " security type=" .. type(security) .. " pcall=" .. tostring(HAS_PCALL))
    print("RES-DIAG " .. line(s1))
    print("RES-DIAG " .. line(s5))
    print("RES-DIAG " .. line(s15))
end
