-- =====================================================================
--  QCS SECURITY READ DIAGNOSTIC  (TASK 03B)  —  NOT FOR TRADING
--  Stand-alone. Finds out what security(current_ticker_id, "1m"/"5m"/
--  "15m") really returns on IQ Option, field by field, and writes the
--  raw result on the chart as text (works on mobile, no Script Log).
--
--  Nothing is assumed: the result type, each field, is_series(), and
--  get_value(series) / get_value(series[1]) are all checked with
--  type(). Missing / unreadable values print as NIL / NAN / ERR.
--  No synthetic data. No M5/M15 built from M1. `resolution` not used.
--
--  APIs (docs: quadcode-tech.github.io/quadcodescript-docs):
--    security, current_ticker_id, get_value, is_series, make_series,
--    :set, plot, plot_shape (shape_location.absolute), input,
--    input_group, instrument, rgba, close, print
--  Lua 5.3: type, pcall, tostring, string.format, math.floor
--
--  Text codes on the chart:
--    type  : TBL table  UD userdata  NIL  NUM number  STR string
--            FN function  BOOL boolean  OTH other  ERR error
--    value : NUM  NAN (number NaN)  NIL  OTH (not a number)  ERR
--    is_series: Y / N / ERR / NA (no field)
-- =====================================================================

instrument { name = "Security Read Diagnostic", short_name = "SEC-READ", overlay = false }

input_group {
    "Diagnostic",
    tf_sel   = input (2, "TF 1=1m 2=5m 3=15m", input.integer, 1, 3),
    mode     = input (1, "Show 1=Types A 2=Types B 3=Prices 4=Times 5=Lines", input.integer, 1, 5),
    dsp      = input (2, "Bars per character", input.integer, 1, 20),
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

-- ------------------------------------------------------------------
-- Codes
-- ------------------------------------------------------------------
local TYPE_TXT = { "TBL", "UD", "NIL", "NUM", "STR", "FN", "BOOL", "OTH", "ERR" }
local TYPE_OF  = { table = 1, userdata = 2, ["nil"] = 3, number = 4,
                   string = 5, ["function"] = 6, boolean = 7 }
local function tcode(ok, v)
    if not ok then
        return 9
    end
    return TYPE_OF[type(v)] or 8
end

local KIND_TXT = { "NUM", "NAN", "NIL", "OTH", "ERR" }
local function kcode(ok, v)
    if not ok then
        return 5
    end
    if v == nil then
        return 3
    end
    if type(v) == "number" then
        if v ~= v then
            return 2
        end
        return 1
    end
    return 4
end

local ISS_TXT = { "Y", "N", "ERR", "NA" }      -- NA = no field to test

-- ------------------------------------------------------------------
-- Read one timeframe. Every step is guarded and recorded.
-- ------------------------------------------------------------------
local FIELDS = { "close", "open", "high", "low", "volume", "open_time", "close_time" }
local SHORT  = { close = "C", open = "O", high = "H", low = "L", volume = "V",
                 open_time = "OT", close_time = "CT" }

local function read_tf(res)
    local d = { res = res, f = {} }
    local ok, t
    if type(security) ~= "function" then
        ok, t = false, "security is " .. type(security)
    elseif current_ticker_id == nil then
        ok, t = false, "current_ticker_id is nil"
    else
        ok, t = try(security, current_ticker_id, res)
    end
    d.rt = tcode(ok, t)
    d.err = (not ok) and tostring(t) or ""
    for _, name in ipairs(FIELDS) do
        local r = { }
        if ok and t ~= nil then
            local okf, s = try(function () return t[name] end)
            r.ft = tcode(okf, s)
            if okf and s ~= nil then
                if type(is_series) == "function" then
                    local oki, b = try(is_series, s)
                    if not oki then
                        r.is = 3
                    elseif b then
                        r.is = 1
                    else
                        r.is = 2
                    end
                else
                    r.is = 3
                end
                local ok0, v0 = try(get_value, s)
                local ok1, v1 = try(function () return get_value(s[1]) end)
                r.k0, r.v0 = kcode(ok0, v0), (ok0 and num(v0) or nil)
                r.k1, r.v1 = kcode(ok1, v1), (ok1 and num(v1) or nil)
                r.raw0 = ok0 and tostring(v0) or ("ERR " .. tostring(v0))
                r.raw1 = ok1 and tostring(v1) or ("ERR " .. tostring(v1))
            elseif okf then
                r.is, r.k0, r.k1 = 4, 3, 3      -- field is nil
            else
                r.is, r.k0, r.k1 = 4, 5, 5      -- field access raised
            end
        else
            r.ft, r.is, r.k0, r.k1 = (ok and 3 or 9), 4, (ok and 3 or 5), (ok and 3 or 5)
        end
        d.f[name] = r
    end
    return d
end

local TFS = { read_tf("1m"), read_tf("5m"), read_tf("15m") }
local TF_NAME = { "1M", "5M", "15M" }

-- ------------------------------------------------------------------
-- Bar counter + change tracking (make_series, chart timeline)
-- ------------------------------------------------------------------
local cnt = make_series()
local bar_no = (at1(cnt) or 0) + 1
cnt:set(bar_no)

-- per TF: previous close[0] / open_time[0], bars where close[0] is NUM
local CHG = {}
for i, d in ipairs(TFS) do
    local hc = make_series()
    local ho = make_series()
    local hn = make_series()
    local pc, po = at1(hc), at1(ho)
    local c0 = d.f.close.v0
    local o0 = d.f.open_time.v0
    hc:set(c0 == nil and NaN or c0)
    ho:set(o0 == nil and NaN or o0)
    local nbars = (at1(hn) or 0) + ((c0 ~= nil) and 1 or 0)
    hn:set(nbars)
    local cc, oc = 3, 3                     -- 1 Y changed, 2 N same, 3 NA
    if c0 ~= nil and pc ~= nil then
        cc = (c0 ~= pc) and 1 or 2
    end
    if o0 ~= nil and po ~= nil then
        oc = (o0 ~= po) and 1 or 2
    end
    CHG[i] = { cc = cc, oc = oc, nbars = nbars }
end
local YN = { "Y", "N", "NA" }

-- ------------------------------------------------------------------
-- Build the text line for the selected TF and mode. Every variable
-- part goes through hold(), which keeps the value of the first bar of
-- the cycle, so all characters of one line come from the same bar.
-- ------------------------------------------------------------------
local CYC = 100                              -- characters per line
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
    s:set(out == nil and NaN or out)
    return out
end

local function fmtnum(k, v)
    if k ~= 1 or v == nil then
        return KIND_TXT[k] or "NA"
    end
    if v == math.floor(v) and v < 1e15 and v > -1e15 then
        return string.format("%.0f", v)
    end
    return string.format("%.5f", v)
end

local d = TFS[tf_sel]
local ch = CHG[tf_sel]
local parts = { TF_NAME[tf_sel] }
local function add(x)
    parts[#parts + 1] = x
end
local function code_txt(tbl, v)
    return tbl[hold(v)] or "NA"
end
local function types_of(name)
    local r = d.f[name]
    add(SHORT[name] .. ":" .. code_txt(TYPE_TXT, r.ft) .. "/" .. code_txt(ISS_TXT, r.is)
        .. "/" .. code_txt(KIND_TXT, r.k0) .. "/" .. code_txt(KIND_TXT, r.k1))
end
local function value_of(label, r, which)
    local k, v
    if which == 0 then
        k, v = r.k0, r.v0
    else
        k, v = r.k1, r.v1
    end
    add(label .. "=" .. fmtnum(hold(k) or 3, hold(v)))
end

if mode == 1 then
    add("R=" .. code_txt(TYPE_TXT, d.rt))
    types_of("close")
    types_of("open")
    types_of("high")
    types_of("low")
elseif mode == 2 then
    types_of("volume")
    types_of("open_time")
    types_of("close_time")
    add("OK=" .. string.format("%.0f", hold(ch.nbars) or 0) .. "/" .. string.format("%.0f", hold(bar_no) or 0))
elseif mode == 3 then
    value_of("C0", d.f.close, 0)
    value_of("C1", d.f.close, 1)
    value_of("H0", d.f.high, 0)
    value_of("L0", d.f.low, 0)
elseif mode == 4 then
    value_of("OT0", d.f.open_time, 0)
    value_of("OT1", d.f.open_time, 1)
    value_of("CT0", d.f.close_time, 0)
    add("CC=" .. code_txt(YN, ch.cc))
    add("OTC=" .. code_txt(YN, ch.oc))
end
local line = table.concat(parts, " ")

-- ------------------------------------------------------------------
-- Character renderer: one plot_shape per character of the alphabet,
-- drawn at row y = 1 on the bar of that character. Space = no shape.
-- ------------------------------------------------------------------
local ALPHA = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-", "=",
    "/", ":", "A", "B", "C", "D", "E", "F", "H", "I", "K", "L", "M", "N",
    "O", "R", "S", "T", "U", "V", "Y", "?" }
local IDX = {}
for i, c in ipairs(ALPHA) do
    IDX[c] = i
end

local cur = nil
if mode <= 4 and pos % dsp == 0 then
    local slot = pos // dsp + 1
    if slot <= #line then
        local c = line:sub(slot, slot)
        if c ~= " " then
            cur = IDX[c] or IDX["?"]
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

if mode <= 4 then
    local f0, f2 = make_series(), make_series()
    f0:set(0)
    f2:set(2)
    plot (f0, "frame 0", rgba(0,0,0,0), 1)
    plot (f2, "frame 2", rgba(0,0,0,0), 1)
    for i, c in ipairs(ALPHA) do
        plot_shape (CS[i], "ch " .. c, shape_style.circle, shape_size.tiny, "#FFFFFF",
                    shape_location.absolute, 0, c, "#FFFFFF")
    end
end

-- ------------------------------------------------------------------
-- Mode 5: raw price lines of the selected TF (gap = not a number)
-- ------------------------------------------------------------------
local function S(v)
    local s = make_series()
    s:set(v == nil and NaN or v)
    return s
end
local L_ch = S(num(get_value(close)))
local L_c0 = S(d.f.close.v0)
local L_c1 = S(d.f.close.v1)
local L_h0 = S(d.f.high.v0)
local L_l0 = S(d.f.low.v0)
if mode == 5 then
    plot (L_ch, "Chart close", "#FFFFFF", 1)
    plot (L_c0, TF_NAME[tf_sel] .. " close[0]", "#29B6F6", 2)
    plot (L_c1, TF_NAME[tf_sel] .. " close[1]", "#0277BD", 1)
    plot (L_h0, TF_NAME[tf_sel] .. " high[0]",  "#00E676", 1)
    plot (L_l0, TF_NAME[tf_sel] .. " low[0]",   "#FF1744", 1)
end

-- ------------------------------------------------------------------
-- Script log (desktop): full raw result of all three TFs
-- ------------------------------------------------------------------
if do_print == 1 then
    for i, t in ipairs(TFS) do
        local s = "SEC-READ " .. t.res .. " result=" .. TYPE_TXT[t.rt] .. " " .. t.err
        for _, name in ipairs(FIELDS) do
            local r = t.f[name]
            s = s .. " | " .. name .. " type=" .. TYPE_TXT[r.ft] .. " is_series=" .. ISS_TXT[r.is]
                .. " [0]=" .. tostring(r.raw0) .. " [1]=" .. tostring(r.raw1)
        end
        s = s .. " | close_changed=" .. YN[CHG[i].cc] .. " ot_changed=" .. YN[CHG[i].oc]
            .. " close_num_bars=" .. CHG[i].nbars .. "/" .. bar_no
        print(s)
    end
end
