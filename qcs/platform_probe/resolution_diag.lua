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
--  Verdict: M1 CONFIRMED only if E1 is true or E2 returns exactly true.
--           NOT M1 only if resolution equals another documented string.
--           Otherwise UNKNOWN + reason. E3 never confirms on its own.
-- =====================================================================

instrument { name = "Resolution Diagnostic", short_name = "RES-DIAG", overlay = false }

input_group {
    "Diagnostic",
    view     = input (1, "View 1=Status 2=Close 3=OpenTime", input.integer, 1, 3),
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
        d.why = "UNKNOWN: security type=" .. type(security)
        return d
    end
    if current_ticker_id == nil then
        d.why = "UNKNOWN: current_ticker_id is nil"
        return d
    end
    local ok, t = try(security, current_ticker_id, res)
    if not ok then
        d.why = "UNKNOWN: security error " .. show(t)
        return d
    end
    if t == nil then
        d.why = "UNKNOWN: security returned nil"
        return d
    end
    d.ttype = type(t)
    local okc, cs = try(function () return t.close end)
    local oko, os_ = try(function () return t.open_time end)
    if not okc or cs == nil then
        d.why = "UNKNOWN: no .close field"
        return d
    end
    if not oko or os_ == nil then
        d.why = "UNKNOWN: no .open_time field"
        return d
    end
    local ok3, cv = try(get_value, cs)
    local ok4, ov = try(get_value, os_)
    d.c_raw  = ok3 and show(cv) or ("get_value error " .. show(cv))
    d.ot_raw = ok4 and show(ov) or ("get_value error " .. show(ov))
    d.c  = ok3 and num(cv) or nil
    d.ot = ok4 and num(ov) or nil
    if d.c == nil or d.ot == nil then
        d.why = "UNKNOWN: close/open_time not a number on this bar"
        return d
    end
    d.ok = true
    d.why = "OK"
    return d
end

local s1  = probe("1m")
local s5  = probe("5m")
local s15 = probe("15m")

-- ------------------------------------------------------------------
-- 3. Plots (status: 1 = OK, 0 = UNKNOWN; NaN gap when unreadable)
-- ------------------------------------------------------------------
local function okv(d)
    if d.ok then
        return 1
    end
    return 0
end
local function b01(b)
    if b then
        return 1
    end
    return 0
end

local P_v  = S(b01(verdict == "M1 CONFIRMED"))
local P_e1 = S(b01(e1))
local P_e2 = S(b01(e2_val == true))
local P_s1 = S(okv(s1))
local P_s5 = S(okv(s5))
local P_s15 = S(okv(s15))
local C_ch = S(ch_c)
local C_1  = S(s1.c)
local C_5  = S(s5.c)
local C_15 = S(s15.c)
local O_ch = S(ch_ot)
local O_1  = S(s1.ot)
local O_5  = S(s5.ot)
local O_15 = S(s15.ot)
local B_e3 = S(e3)

if view == 1 then
    plot (P_v,   "M1 CONFIRMED (1/0)", "#00E676", 2)
    plot (P_e1,  "E1 res==1m",         "#FFFFFF", 1)
    plot (P_e2,  "E2 res(1m)==true",   "#9E9E9E", 1)
    plot (P_s1,  "SEC 1m OK",          "#BDBDBD", 1)
    plot (P_s5,  "SEC 5m OK",          "#29B6F6", 1)
    plot (P_s15, "SEC 15m OK",         "#FFA726", 1)
elseif view == 2 then
    plot (C_ch, "Chart close",    "#FFFFFF", 1)
    plot (C_1,  "SEC 1m close",   "#BDBDBD", 1)
    plot (C_5,  "SEC 5m close",   "#29B6F6", 2)
    plot (C_15, "SEC 15m close",  "#FFA726", 2)
else
    plot (O_ch, "Chart open_time",   "#FFFFFF", 1)
    plot (O_1,  "SEC 1m open_time",  "#BDBDBD", 1)
    plot (O_5,  "SEC 5m open_time",  "#29B6F6", 1)
    plot (O_15, "SEC 15m open_time", "#FFA726", 1)
    plot (B_e3, "E3 chart close_time-open_time", "#00E676", 1)
end

local RED, YEL, GRN = "#FF1744", "#FFEA00", "#00E676"
plot_shape (conditional(verdict == "M1 CONFIRMED"), "M1 CONFIRMED", shape_style.circle, shape_size.tiny, GRN, shape_location.top, 0, "M1 OK", GRN)
plot_shape (conditional(verdict == "NOT M1"),  "NOT M1",  shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "NOT M1", RED)
plot_shape (conditional(verdict == "UNKNOWN"), "TF UNKNOWN", shape_style.xcross, shape_size.tiny, YEL, shape_location.top, 0, "TF ?", YEL)
plot_shape (conditional(not s5.ok),  "5m unreadable",  shape_style.xcross, shape_size.tiny, RED, shape_location.bottom, 0, "5m ?", RED)
plot_shape (conditional(not s15.ok), "15m unreadable", shape_style.xcross, shape_size.tiny, RED, shape_location.bottom, 0, "15m ?", RED)

-- ------------------------------------------------------------------
-- 4. Script log (every run = every bar, and possibly every tick)
-- ------------------------------------------------------------------
local function line(d)
    return "SEC " .. d.res .. ": " .. d.why
        .. " table=" .. tostring(d.ttype)
        .. " close=" .. tostring(d.c_raw)
        .. " open_time=" .. tostring(d.ot_raw)
end

if do_print == 1 then
    print("RES-DIAG bar open_time=" .. show(ch_ot) .. " close=" .. show(ch_c))
    print("RES-DIAG resolution value=" .. res_raw .. " type=" .. res_type)
    print("RES-DIAG E1 resolution==\"1m\" -> " .. tostring(e1))
    print("RES-DIAG E2 resolution(\"1m\") -> " .. e2_txt)
    print("RES-DIAG E3 close_time-open_time -> " .. show(e3))
    print("RES-DIAG VERDICT " .. verdict .. " (" .. reason .. ")")
    print("RES-DIAG " .. tf_txt .. " | " .. glob_txt)
    print("RES-DIAG current_ticker_id=" .. show(current_ticker_id)
        .. " security type=" .. type(security) .. " pcall=" .. tostring(HAS_PCALL))
    print("RES-DIAG " .. line(s1))
    print("RES-DIAG " .. line(s5))
    print("RES-DIAG " .. line(s15))
end
