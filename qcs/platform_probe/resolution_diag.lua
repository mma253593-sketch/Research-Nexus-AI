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
    view     = input (1, "View 1=Type labels 2=Close 3=OpenTime 4=Numbers", input.integer, 1, 4),
    dsp      = input (2, "Numbers: bars per character", input.integer, 1, 20),
    group    = input (1, "Labels 1=Chart+resolution 2=security()", input.integer, 1, 2),
    spacing  = input (8, "Bars between labels", input.integer, 1, 100),
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
    d.cv, d.ov, d.ok3, d.ok4 = cv, ov, ok3, ok4
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
-- Type labels (View 1). Each label = "<item> <what get_value returned>":
--   NUM  a number            NAN  a number that is NaN
--   NIL  nil (or the field/series does not exist)
--   OTH  another Lua type    ERR  the call raised an error
-- Items are shown one at a time, `spacing` bars apart, on two
-- alternating rows, so the text of different items never overlaps.
-- group 1: RES (type of resolution), CH close, CH open_time,
--          CH open_time[1], CH close_time   (chart built-in series)
-- group 2: 1m/5m/15m close and open_time from security()
-- ------------------------------------------------------------------
local K_NUM, K_NAN, K_NIL, K_OTH, K_ERR = 1, 2, 3, 4, 5
local KTXT = { "NUM", "NAN", "NIL", "OTH", "ERR" }
local KCOL = { "#00E676", "#FFEA00", "#FF1744", "#FF9100", "#FF1744" }

local function kind(ok, v)
    if not ok then
        return K_ERR
    end
    if v == nil then
        return K_NIL
    end
    if type(v) == "number" then
        if v ~= v then
            return K_NAN
        end
        return K_NUM
    end
    return K_OTH
end

local function gv(f)
    local ok, v = try(f)
    return kind(ok, v)
end

local RTYPES = { "string", "function", "nil", "number", "table", "userdata", "boolean" }
local RTXT   = { "str", "fn", "nil", "num", "table", "udata", "bool" }
local res_k = 0
for i, n in ipairs(RTYPES) do
    if res_type == n then
        res_k = i
    end
end

local function sec_kind(d, which)
    if d.ttype == nil then
        if d.code == 2 then
            return K_ERR
        end
        return K_NIL
    end
    if which == "c" then
        if d.ok3 == nil then
            return K_NIL
        end
        return kind(d.ok3, d.cv)
    end
    if d.ok4 == nil then
        return K_NIL
    end
    return kind(d.ok4, d.ov)
end

local items
if group == 1 then
    items = {
        { "CH close",      gv(function () return get_value(close) end) },
        { "CH open_time",  gv(function () return get_value(open_time) end) },
        { "CH ot[1]",      gv(function () return get_value(open_time[1]) end) },
        { "CH close_time", gv(function () return get_value(close_time) end) },
    }
else
    items = {
        { "1m close",  sec_kind(s1, "c") },  { "1m ot",  sec_kind(s1, "t") },
        { "5m close",  sec_kind(s5, "c") },  { "5m ot",  sec_kind(s5, "t") },
        { "15m close", sec_kind(s15, "c") }, { "15m ot", sec_kind(s15, "t") },
    }
end

local cnt = make_series()
local cnt_prev = at1(cnt)
local bar_no = (cnt_prev or 0) + 1
cnt:set(bar_no)

local n_slots = #items
if group == 1 then
    n_slots = n_slots + 1          -- slot 0 = RES
end
local cycle = spacing * n_slots
local slot = -1
if bar_no % spacing == 0 then
    slot = (bar_no % cycle) / spacing
end
local function ypos(j)
    if j % 2 == 0 then
        return 1
    end
    return 3
end

local function at_slot(j, on)
    local s = make_series()
    if on and slot == j then
        s:set(ypos(j))
    else
        s:set(NaN)
    end
    return s
end

local function lab(series, text, color)
    plot_shape (series, text, shape_style.circle, shape_size.tiny, color,
                shape_location.absolute, 0, text, color)
end

if view == 1 then
    local FR_lo, FR_hi = S(0), S(4)
    plot (FR_lo, "frame 0", rgba(0,0,0,0), 1)
    plot (FR_hi, "frame 4", rgba(0,0,0,0), 1)
    local first = 0
    if group == 1 then
        for i = 1, #RTYPES do
            lab (at_slot(0, res_k == i), "RES " .. RTXT[i], "#29B6F6")
        end
        lab (at_slot(0, res_k == 0), "RES other", "#29B6F6")
        first = 1
    end
    for i, it in ipairs(items) do
        for k = 1, 5 do
            lab (at_slot(first + i - 1, it[2] == k), it[1] .. " " .. KTXT[k], KCOL[k])
        end
    end
end

-- ------------------------------------------------------------------
-- Numbers (View 4): writes real values on the chart, one character
-- per `dsp` bars, so they can be read without the Script Log.
-- Each item = name label, then its digits. The value is captured on
-- the first bar of the item's block and held (make_series) so all
-- digits come from the same bar. "NA" = nil / NaN / not a number.
--   RES  = resolution     STEP = open_time - open_time[1]
--   LEN  = close_time - open_time   OT = chart open_time
--   5mOT / 15mOT = open_time from security("5m" / "15m")
-- ------------------------------------------------------------------
local NUM_ITEMS = {
    { "RES",   num(resolution) },
    { "STEP",  e4 },
    { "LEN",   e3 },
    { "OT",    ch_ot },
    { "5mOT",  num(s5.ov) },
    { "15mOT", num(s15.ov) },
}
local W = 16                        -- slots per item (1 name + 15 chars)
local blk = W * dsp
local ncycle = blk * #NUM_ITEMS
local pos = (bar_no - 1) % ncycle
local cur_item = pos // blk + 1
local cur_slot = -1
if pos % dsp == 0 then
    cur_slot = (pos % blk) // dsp
end

local held = {}
for i, it in ipairs(NUM_ITEMS) do
    local h = make_series()
    local v
    if (pos % blk) == 0 and cur_item == i then
        v = it[2]
    else
        v = at1(h)
    end
    if v == nil then
        h:set(NaN)
    else
        h:set(v)
    end
    held[i] = v
end

local function fmt(v)
    if v == nil then
        return "NA"
    end
    if v == math.floor(v) and math.abs(v) < 1e15 then
        return string.format("%.0f", v)
    end
    return string.format("%.5f", v)
end

local txt = fmt(held[cur_item])
local ch = nil
if cur_slot >= 1 then
    if txt == "NA" then
        if cur_slot == 1 then
            ch = "NA"
        end
    elseif cur_slot <= #txt then
        ch = txt:sub(cur_slot, cur_slot)
    end
end

local function at_if(cond)
    local s = make_series()
    if cond then
        s:set(1)
    else
        s:set(NaN)
    end
    return s
end

local CHARS = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-", "NA" }
local CH_S = {}
for i, c in ipairs(CHARS) do
    CH_S[i] = at_if(ch == c)
end
local NAME_S = {}
for i = 1, #NUM_ITEMS do
    NAME_S[i] = at_if(cur_slot == 0 and cur_item == i)
end

if view == 4 then
    local FR_lo, FR_hi = S(0), S(2)
    plot (FR_lo, "frame 0", rgba(0,0,0,0), 1)
    plot (FR_hi, "frame 2", rgba(0,0,0,0), 1)
    for i, it in ipairs(NUM_ITEMS) do
        plot_shape (NAME_S[i], it[1], shape_style.square, shape_size.tiny, "#29B6F6",
                    shape_location.absolute, 0, it[1] .. "=", "#29B6F6")
    end
    for i, c in ipairs(CHARS) do
        plot_shape (CH_S[i], "char " .. c, shape_style.circle, shape_size.tiny, "#FFFFFF",
                    shape_location.absolute, 0, c, "#FFFFFF")
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
