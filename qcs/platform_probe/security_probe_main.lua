-- =====================================================================
--  QCS SECURITY() PLATFORM PROBE  (TASK 03)  —  NOT A TRADING INDICATOR
--  Purpose: show what security(current_ticker_id, "5m" / "15m") really
--  returns on IQ Option, bar by bar, so the Owner can record it.
--
--  * Run on an M1 chart (XAUUSD). One pane below the chart.
--  * Every value comes from the platform. No mock or synthetic data.
--  * If a call or series is missing, the probe shows a status code
--    (ERROR / UNSUPPORTED / NOT READY) and plots a gap (NaN). It never
--    substitutes a made-up value.
--
--  APIs used (all from https://quadcode-tech.github.io/quadcodescript-docs):
--    instrument, input, input_group, security, current_ticker_id,
--    resolution, get_value, make_series, :set, plot, plot_shape,
--    conditional, ema, rsi, open_time, close_time, close, print
--  Lua 5.3 standard: type, pcall, tostring, math.abs
--
--  Status codes plotted in View 3:
--     1 = OK          value read this bar
--     0 = NOT READY   call worked but value is nil / NaN on this bar
--    -1 = ERROR       call raised an error or returned nil
--    -2 = UNSUPPORTED function or field does not exist
-- =====================================================================

instrument { name = "Security Probe M1/M5/M15", short_name = "SEC-PROBE", overlay = false }

input_group {
    "Probe",
    view     = input (1, "View 1=Price 2=Timing 3=Status 4=RSI 5=RawTime", input.integer, 1, 5),
    ema_len  = input (21, "EMA length on HTF series", input.integer, 1, 500),
    rsi_len  = input (14, "RSI length on HTF series", input.integer, 2, 100),
    do_print = input (0, "Print log 1=on 0=off", input.integer, 0, 1)
}

local OK, NOTREADY, ERR, UNSUP = 1, 0, -1, -2
local NaN = 0 / 0
local EPS = 1e-9

-- ------------------------------------------------------------------
-- Safe helpers. pcall is standard Lua 5.3; if the platform removed it,
-- calls are made directly (an error then stops the script, which the
-- Owner records as ERROR for that API).
-- ------------------------------------------------------------------
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

-- value of series s at index i (0 = current chart bar, 1 = one back)
local function at(s, i)
    if s == nil then
        return nil
    end
    local ok, v
    if i == 0 then
        ok, v = try(get_value, s)
    else
        ok, v = try(function () return get_value(s[i]) end)
    end
    if ok then
        return num(v)
    end
    return nil
end

local function field(t, name)
    if t == nil then
        return nil
    end
    local ok, s = try(function () return t[name] end)
    if ok then
        return s
    end
    return nil
end

local function same(a, b)
    return a ~= nil and b ~= nil and math.abs(a - b) <= EPS
end

local function flag(b)
    if b == nil then
        return NaN
    end
    if b then
        return 1
    end
    return 0
end

-- 1 if equal, 0 if different, NaN if either is missing
local function eqf(a, b)
    if a == nil or b == nil then
        return NaN
    end
    if same(a, b) then
        return 1
    end
    return 0
end

local function sub(a, b)
    if a ~= nil and b ~= nil then
        return a - b
    end
    return nil
end

local function mod(a, m)
    if a ~= nil then
        return a % m
    end
    return nil
end

-- make a plottable series holding v (NaN when v is nil)
local function S(v)
    local s = make_series()
    if v == nil then
        s:set(NaN)
    else
        s:set(v)
    end
    return s
end

-- ------------------------------------------------------------------
-- Read one timeframe through security()
-- ------------------------------------------------------------------
local function read_tf(res)
    local d = { st = OK, msg = "", res = res }
    if type(security) ~= "function" then
        d.st, d.msg = UNSUP, "security() not defined"
        return d
    end
    if current_ticker_id == nil then
        d.st, d.msg = ERR, "current_ticker_id is nil"
        return d
    end
    local ok, t = try(security, current_ticker_id, res)
    if not ok then
        d.st, d.msg = ERR, "security(" .. res .. ") error: " .. tostring(t)
        return d
    end
    if t == nil then
        d.st, d.msg = ERR, "security(" .. res .. ") returned nil"
        return d
    end
    d.c  = field(t, "close")
    d.ot = field(t, "open_time")
    d.ct = field(t, "close_time")
    if d.c == nil or d.ot == nil or d.ct == nil then
        d.st, d.msg = UNSUP, "field close/open_time/close_time missing"
    end
    d.c0, d.c1   = at(d.c, 0),  at(d.c, 1)
    d.ot0, d.ot1 = at(d.ot, 0), at(d.ot, 1)
    d.ct0, d.ct1 = at(d.ct, 0), at(d.ct, 1)
    if d.st == OK and (d.c0 == nil or d.c1 == nil or d.ot0 == nil or d.ct0 == nil) then
        d.st, d.msg = NOTREADY, "value nil/NaN on this bar"
    end
    return d
end

-- indicator function (ema / rsi) applied to an external series
local function ind(fn, s, len)
    if type(fn) ~= "function" then
        return nil, UNSUP
    end
    if s == nil then
        return nil, NOTREADY
    end
    local ok, r = try(fn, s, len)
    if not ok or r == nil then
        return nil, ERR
    end
    local v = at(r, 0)
    if v == nil then
        return nil, NOTREADY
    end
    return v, OK
end

-- ------------------------------------------------------------------
-- Chart (M1) data — built-in series of the chart itself
-- ------------------------------------------------------------------
local ch_close = num(get_value(close))
local ch_ot    = num(get_value(open_time))
local ch_ct    = num(get_value(close_time))

-- Chart timeframe check. Docs (Functions/Timeframes/resolution) call
-- `resolution` a String variable with values "1s".."1Y", but the same
-- page shows `resolution("10m")`. The type is NOT assumed: it is read
-- with type() only, never called. A verdict is given only for a string
-- from the documented list; anything else is UNKNOWN (never "NOT M1").
--   RES_M1 = 1 M1 CONFIRMED, RES_NOT = 2 NOT M1, RES_UNK = 0 UNKNOWN
local RES_UNK, RES_M1, RES_NOT = 0, 1, 2
local RES_DOC = { ["1s"]=1, ["5s"]=1, ["10s"]=1, ["15s"]=1, ["30s"]=1,
    ["1m"]=1, ["2m"]=1, ["5m"]=1, ["10m"]=1, ["15m"]=1, ["30m"]=1,
    ["1H"]=1, ["2H"]=1, ["4H"]=1, ["8H"]=1, ["12H"]=1,
    ["1D"]=1, ["1W"]=1, ["1M"]=1, ["1Y"]=1 }
local res_type = type(resolution)
local res_txt = "?"
do
    local ok, v = try(tostring, resolution)
    if ok and type(v) == "string" then
        res_txt = v
    end
end
local res_state = RES_UNK
if res_type == "string" then
    if resolution == "1m" then
        res_state = RES_M1
    elseif RES_DOC[resolution] then
        res_state = RES_NOT
    end
end
local res_name = "UNKNOWN"
if res_state == RES_M1 then
    res_name = "M1 CONFIRMED"
elseif res_state == RES_NOT then
    res_name = "NOT M1"
end
local not_m1  = res_state == RES_NOT
local res_unk = res_state == RES_UNK

-- ------------------------------------------------------------------
-- security() reads (always called, same order every run)
-- ------------------------------------------------------------------
local m1  = read_tf("1m")
local m5  = read_tf("5m")
local m15 = read_tf("15m")

local ema5,  ema5_st  = ind(ema, m5.c,  ema_len)
local ema15, ema15_st = ind(ema, m15.c, ema_len)
local rsi5,  rsi5_st  = ind(rsi, m5.c,  rsi_len)
local rsi15, rsi15_st = ind(rsi, m15.c, rsi_len)

-- ------------------------------------------------------------------
-- Diagnostics (seconds if timestamps are UNIX seconds; see README)
-- ------------------------------------------------------------------
-- phase: how far the chart bar is inside the HTF bar reported at [0]
local m5_phase  = sub(ch_ot, m5.ot0)
local m15_phase = sub(ch_ot, m15.ot0)
-- dur: HTF close_time - open_time at [0]
local m5_dur  = sub(m5.ct0, m5.ot0)
local m15_dur = sub(m15.ct0, m15.ot0)
-- step: open_time[0] - open_time[1]  (0 => [1] is previous CHART bar,
-- 300 / 900 => [1] is previous HTF bar)
local m5_step  = sub(m5.ot0, m5.ot1)
local m15_step = sub(m15.ot0, m15.ot1)
-- alignment to the real clock grid (0 = aligned)
local m5_mod  = mod(m5.ot0, 300)
local m15_mod = mod(m15.ot0, 900)

-- EQ: HTF close[0] equals chart close on this bar
local eq5  = eqf(m5.c0, ch_close)
local eq15 = eqf(m15.c0, ch_close)
-- LOOK: HTF bar at [0] opens AFTER this chart bar (future data)
local la5_b  = m5.ot0 ~= nil and ch_ot ~= nil and m5.ot0 > ch_ot
local la15_b = m15.ot0 ~= nil and ch_ot ~= nil and m15.ot0 > ch_ot
-- M1 sanity: security("1m") close equals chart close
local eq1 = eqf(m1.c0, ch_close)

-- Snapshots on the chart timeline (make_series: one value per chart bar)
local s_ot5   = S(m5.ot0)
local s_ot15  = S(m15.ot0)
local s_c1_5  = S(m5.c1)
local s_c1_15 = S(m15.c1)

local p_ot5   = at(s_ot5, 1)
local p_ot15  = at(s_ot15, 1)
local p_c1_5  = at(s_c1_5, 1)
local p_c1_15 = at(s_c1_15, 1)

-- NEW: HTF open_time[0] differs from the previous chart bar
local new5_b  = m5.ot0 ~= nil and p_ot5 ~= nil and not same(m5.ot0, p_ot5)
local new15_b = m15.ot0 ~= nil and p_ot15 ~= nil and not same(m15.ot0, p_ot15)
-- C1CHG: close[1] changed although the HTF bar did NOT roll over
local chg5_b  = (not new5_b) and m5.c1 ~= nil and p_c1_5 ~= nil and not same(m5.c1, p_c1_5)
local chg15_b = (not new15_b) and m15.c1 ~= nil and p_c1_15 ~= nil and not same(m15.c1, p_c1_15)

-- ------------------------------------------------------------------
-- Plot series (created every run, plotted by view)
-- ------------------------------------------------------------------
-- View 1: prices
local P_ch    = S(ch_close)
local P_m1    = S(m1.c0)
local P_m5c0  = S(m5.c0)
local P_m5c1  = S(m5.c1)
local P_m15c0 = S(m15.c0)
local P_m15c1 = S(m15.c1)
local P_e5    = S(ema5)
local P_e15   = S(ema15)
-- View 2: timing
local T_ph5  = S(m5_phase)
local T_du5  = S(m5_dur)
local T_st5  = S(m5_step)
local T_md5  = S(m5_mod)
local T_ph15 = S(m15_phase)
local T_du15 = S(m15_dur)
local T_st15 = S(m15_step)
local T_md15 = S(m15_mod)
-- View 3: status codes and flags
local Z_m1    = S(m1.st)
local Z_m5    = S(m5.st)
local Z_m15   = S(m15.st)
local Z_e5    = S(ema5_st)
local Z_e15   = S(ema15_st)
local Z_r5    = S(rsi5_st)
local Z_r15   = S(rsi15_st)
local F_eq1   = S(eq1)
local F_eq5   = S(eq5)
local F_eq15  = S(eq15)
local F_la5   = S(flag(la5_b))
local F_la15  = S(flag(la15_b))
local F_new5  = S(flag(new5_b))
local F_new15 = S(flag(new15_b))
local F_chg5  = S(flag(chg5_b))
local F_chg15 = S(flag(chg15_b))
-- View 4: RSI
local R_5  = S(rsi5)
local R_15 = S(rsi15)
-- View 5: raw timestamps
local W_ch    = S(ch_ot)
local W_chct  = S(ch_ct)
local W_ot5   = S(m5.ot0)
local W_ot5b  = S(m5.ot1)
local W_ct5   = S(m5.ct0)
local W_ot15  = S(m15.ot0)
local W_ot15b = S(m15.ot1)
local W_ct15  = S(m15.ct0)

if view == 1 then
    plot (P_ch,    "Chart M1 Close",  "#FFFFFF", 1)
    plot (P_m1,    "SEC 1m Close[0]", "#9E9E9E", 1)
    plot (P_m5c0,  "M5 Close[0]",     "#29B6F6", 2)
    plot (P_m5c1,  "M5 Close[1]",     "#0277BD", 1)
    plot (P_m15c0, "M15 Close[0]",    "#FFA726", 2)
    plot (P_m15c1, "M15 Close[1]",    "#E65100", 1)
    plot (P_e5,    "EMA on M5",       "#66BB6A", 1)
    plot (P_e15,   "EMA on M15",      "#AB47BC", 1)
elseif view == 2 then
    plot (T_ph5,  "M5 phase (M1 ot - M5 ot0)",   "#29B6F6", 2)
    plot (T_du5,  "M5 dur (ct0 - ot0)",          "#0277BD", 1)
    plot (T_st5,  "M5 step (ot0 - ot1)",         "#80DEEA", 1)
    plot (T_md5,  "M5 ot0 mod 300",              "#FFFFFF", 1)
    plot (T_ph15, "M15 phase (M1 ot - M15 ot0)", "#FFA726", 2)
    plot (T_du15, "M15 dur (ct0 - ot0)",         "#E65100", 1)
    plot (T_st15, "M15 step (ot0 - ot1)",        "#FFCC80", 1)
    plot (T_md15, "M15 ot0 mod 900",             "#BDBDBD", 1)
elseif view == 3 then
    plot (Z_m1,    "ST sec 1m",       "#9E9E9E", 1)
    plot (Z_m5,    "ST sec 5m",       "#29B6F6", 2)
    plot (Z_m15,   "ST sec 15m",      "#FFA726", 2)
    plot (Z_e5,    "ST EMA M5",       "#66BB6A", 1)
    plot (Z_e15,   "ST EMA M15",      "#AB47BC", 1)
    plot (Z_r5,    "ST RSI M5",       "#26A69A", 1)
    plot (Z_r15,   "ST RSI M15",      "#EC407A", 1)
    plot (F_eq1,   "F 1m C0=Chart",   "#BDBDBD", 1)
    plot (F_eq5,   "F M5 C0=Chart",   "#4FC3F7", 1)
    plot (F_eq15,  "F M15 C0=Chart",  "#FFB74D", 1)
    plot (F_la5,   "F M5 lookahead",  "#FF1744", 1)
    plot (F_la15,  "F M15 lookahead", "#D50000", 1)
    plot (F_new5,  "F M5 new bar",    "#00E676", 1)
    plot (F_new15, "F M15 new bar",   "#76FF03", 1)
    plot (F_chg5,  "F M5 C1 changed", "#FFEA00", 1)
    plot (F_chg15, "F M15 C1 changed","#FFD600", 1)
elseif view == 4 then
    plot (R_5,  "RSI on M5",  "#26A69A", 2)
    plot (R_15, "RSI on M15", "#EC407A", 2)
else
    plot (W_ch,    "Chart open_time",  "#FFFFFF", 1)
    plot (W_chct,  "Chart close_time", "#9E9E9E", 1)
    plot (W_ot5,   "M5 open_time[0]",  "#29B6F6", 1)
    plot (W_ot5b,  "M5 open_time[1]",  "#0277BD", 1)
    plot (W_ct5,   "M5 close_time[0]", "#80DEEA", 1)
    plot (W_ot15,  "M15 open_time[0]", "#FFA726", 1)
    plot (W_ot15b, "M15 open_time[1]", "#E65100", 1)
    plot (W_ct15,  "M15 close_time[0]","#FFCC80", 1)
end

-- ------------------------------------------------------------------
-- Markers (all views). Text is the evidence label for screenshots.
-- ------------------------------------------------------------------
local RED, YEL, GRN, BLU, ORG = "#FF1744", "#FFEA00", "#00E676", "#29B6F6", "#FFA726"

plot_shape (conditional(not_m1), "Chart not M1", shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "NOT M1", RED)
plot_shape (conditional(res_unk), "Timeframe unknown", shape_style.xcross, shape_size.tiny, YEL, shape_location.top, 0, "TF UNKNOWN", YEL)
plot_shape (conditional(m5.st == ERR),    "M5 ERROR",  shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "M5 ERR", RED)
plot_shape (conditional(m5.st == UNSUP),  "M5 UNSUP",  shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "M5 UNSUP", RED)
plot_shape (conditional(m15.st == ERR),   "M15 ERROR", shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "M15 ERR", RED)
plot_shape (conditional(m15.st == UNSUP), "M15 UNSUP", shape_style.xcross, shape_size.small, RED, shape_location.top, 0, "M15 UNSUP", RED)
plot_shape (conditional(ema5_st == UNSUP or ema5_st == ERR), "EMA M5 fail", shape_style.xcross, shape_size.tiny, YEL, shape_location.top, 0, "EMA5 X", YEL)
plot_shape (conditional(la5_b),  "M5 lookahead",  shape_style.diamond, shape_size.small, RED, shape_location.top, 0, "LA5", RED)
plot_shape (conditional(la15_b), "M15 lookahead", shape_style.diamond, shape_size.small, RED, shape_location.top, 0, "LA15", RED)
plot_shape (conditional(chg5_b),  "M5 C1 changed",  shape_style.circle, shape_size.tiny, YEL, shape_location.top, 0, "C1CHG5", YEL)
plot_shape (conditional(chg15_b), "M15 C1 changed", shape_style.circle, shape_size.tiny, YEL, shape_location.top, 0, "C1CHG15", YEL)
plot_shape (conditional(new5_b),  "M5 new bar",  shape_style.triangleup, shape_size.tiny, BLU, shape_location.bottom, 0, "N5", BLU)
plot_shape (conditional(new15_b), "M15 new bar", shape_style.triangleup, shape_size.small, ORG, shape_location.bottom, 0, "N15", ORG)

-- ------------------------------------------------------------------
-- Optional script log (runs on every bar AND every tick when on)
-- ------------------------------------------------------------------
local function t(v)
    if v == nil then
        return "nil"
    end
    return tostring(v)
end

-- Timeframe detection is logged when the log is on, and always when the
-- verdict is not "M1 CONFIRMED" (so the type/value reach the Owner).
if do_print == 1 or res_state ~= RES_M1 then
    print("PROBE TF=" .. res_name .. " type(resolution)=" .. res_type
        .. " tostring(resolution)=" .. res_txt)
end

if do_print == 1 then
    print("PROBE res=" .. res_txt .. " (" .. res_type .. ", " .. res_name .. ")"
        .. " ot=" .. t(ch_ot) .. " C=" .. t(ch_close)
        .. " | 1m st=" .. t(m1.st) .. " c0=" .. t(m1.c0)
        .. " | 5m st=" .. t(m5.st) .. " c0=" .. t(m5.c0) .. " c1=" .. t(m5.c1)
        .. " ot0=" .. t(m5.ot0) .. " ot1=" .. t(m5.ot1) .. " ct0=" .. t(m5.ct0)
        .. " ema=" .. t(ema5) .. "/" .. t(ema5_st)
        .. " | 15m st=" .. t(m15.st) .. " c0=" .. t(m15.c0) .. " c1=" .. t(m15.c1)
        .. " ot0=" .. t(m15.ot0) .. " ot1=" .. t(m15.ot1) .. " ct0=" .. t(m15.ct0)
        .. " ema=" .. t(ema15) .. "/" .. t(ema15_st)
        .. " | " .. m5.msg .. " " .. m15.msg)
end
