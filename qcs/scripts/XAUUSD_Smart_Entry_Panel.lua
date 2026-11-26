instrument { name = "XAUUSD Smart Entry Panel", short_name = "XAU-SE Score", overlay = false }
-- Generated from qcs/src (core.lua + view_panel.lua). Edit the sources, then run qcs/build.sh.
-- =====================================================================
--  XAUUSD SMART ENTRY  —  CORE ANALYSIS ENGINE (shared by Main + Panel)
--  Quadcode Script (QCS, Lua 5.3 based) for the IQ Option script editor
--
--  ANTI-REPAINT DESIGN
--  * Every decision is taken from the LAST CLOSED candle (index [1]).
--  * The signal is therefore printed on the NEW candle (index [0]) at its
--    open and can never change while that candle is forming.
--  * Pivots (support / resistance) are only accepted after `pivot_len`
--    further candles have closed (no future data).
--  * Only the optional "NO CHASE" warning reads the live candle; it is a
--    live advisory, not a signal.
-- =====================================================================

-- ------------------------------ INPUTS -------------------------------
input_group {
    "Trend (EMA)",
    ema_fast_len = input (9,  "EMA Fast", input.integer, 1, 200),
    ema_mid_len  = input (21, "EMA Mid",  input.integer, 1, 300),
    ema_slow_len = input (50, "EMA Slow", input.integer, 1, 500)
}

input_group {
    "Momentum (RSI / MACD)",
    rsi_len        = input (14, "RSI Period", input.integer, 2, 100),
    rsi_ext_high   = input (78, "RSI too high - block CALL", input.double, 55, 100, 1),
    rsi_ext_low    = input (22, "RSI too low - block PUT",   input.double, 0, 45, 1),
    macd_fast_len  = input (12, "MACD Fast",   input.integer, 1, 100),
    macd_slow_len  = input (26, "MACD Slow",   input.integer, 2, 200),
    macd_sig_len   = input (9,  "MACD Signal", input.integer, 1, 100)
}

input_group {
    "Volatility (Bollinger / ATR)",
    bb_len        = input (20,   "BB Period",                    input.integer, 2, 200),
    bb_mult       = input (2.0,  "BB Deviation",                 input.double, 0.5, 5, 0.1),
    atr_len       = input (14,   "ATR Period",                   input.integer, 1, 100),
    atr_base_len  = input (100,  "ATR Baseline Period",          input.integer, 10, 500),
    squeeze_ratio = input (0.75, "Squeeze: BB width < avg x",    input.double, 0.1, 1.5, 0.05),
    flat_atr      = input (0.25, "Flat: EMA Mid slope < ATR x",  input.double, 0, 2, 0.05),
    spike_mult    = input (2.8,  "Spike: candle range > ATR x",  input.double, 1, 10, 0.1),
    hot_ratio     = input (1.9,  "Hot: ATR > baseline x",        input.double, 1, 5, 0.1)
}

input_group {
    "Support / Resistance",
    pivot_len    = input (5,   "Pivot strength (bars each side)", input.integer, 2, 20),
    range_len    = input (50,  "Range lookback (bars)",           input.integer, 10, 300),
    min_room_atr = input (0.8, "Min room to next level (ATR x)",  input.double, 0, 5, 0.1)
}

input_group {
    "Signal Filter",
    min_score     = input (70,   "Min confidence to signal (60-100)", input.integer, 60, 100),
    cooldown_bars = input (3,    "Cooldown after a signal (bars)",    input.integer, 0, 50),
    late_body_atr = input (1.8,  "Late: candle body > ATR x",         input.double, 0.5, 10, 0.1),
    max_ext_atr   = input (2.2,  "Late: distance from EMA Mid > ATR x", input.double, 0.5, 10, 0.1),
    chase_atr     = input (0.35, "No chase: live move > ATR x",       input.double, 0.05, 5, 0.05)
}

-- --------------------------- BASE SERIES ------------------------------
-- All series functions are called unconditionally on every bar.
ema_f = ema (close, ema_fast_len)
ema_m = ema (close, ema_mid_len)
ema_s = ema (close, ema_slow_len)

rsi_val = rsi (close, rsi_len)

macd_fast_ma = ema (close, macd_fast_len)
macd_slow_ma = ema (close, macd_slow_len)
macd_line    = macd_fast_ma - macd_slow_ma
macd_sig     = ema (macd_line, macd_sig_len)
macd_hist    = macd_line - macd_sig

bb_mid       = sma (close, bb_len)
bb_dev       = stdev (close, bb_len) * bb_mult
bb_up        = bb_mid + bb_dev
bb_lo        = bb_mid - bb_dev
bb_width     = (bb_up - bb_lo) / bb_mid
bb_width_avg = sma (bb_width, bb_len * 3)

atr_val  = rma (tr, atr_len)
atr_base = sma (atr_val, atr_base_len)

-- Close-location value of each candle (0 = closed at low, 1 = at high)
clv       = (close - low) / max (high - low, 0.0000001)
clv_avg   = sma (clv, 5)

-- Highest / lowest windows used for pivots and range extremes
piv_win_hi = highest (high, 2 * pivot_len + 1)
piv_win_lo = lowest  (low,  2 * pivot_len + 1)
rng_hi     = highest (high, range_len)
rng_lo     = lowest  (low,  range_len)

-- ------------------------------ HELPERS -------------------------------
-- Read the current value of a series as a plain Lua number (nil if n/a).
local function num (s, d)
    local v = get_value (s)
    if v == nil or v ~= v then
        return d
    end
    return v
end

local function clamp (x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- ------------------------- PIVOT S/R (CONFIRMED) ----------------------
-- A pivot high at bar (t-1-pivot_len) is confirmed when it is the highest
-- point of the window that ends at the last CLOSED candle.
local ph_val = num (high[pivot_len + 1])
local ph_ref = num (piv_win_hi[1])
local pl_val = num (low[pivot_len + 1])
local pl_ref = num (piv_win_lo[1])

local is_ph = (ph_val ~= nil and ph_ref ~= nil and ph_val >= ph_ref)
local is_pl = (pl_val ~= nil and pl_ref ~= nil and pl_val <= pl_ref)

res_lvl  = value_when (is_ph, high[pivot_len + 1], 0)
res_lvl2 = value_when (is_ph, high[pivot_len + 1], 1)
sup_lvl  = value_when (is_pl, low[pivot_len + 1], 0)
sup_lvl2 = value_when (is_pl, low[pivot_len + 1], 1)

-- ------------------------------ STATE ---------------------------------
bar_count = make_series ()
bar_count:set (num (bar_count[1], 0) + 1)

sig_age = make_series ()          -- bars since the last printed signal

-- ------------------- SNAPSHOT OF THE CLOSED CANDLES -------------------
local O1, H1, L1, C1 = num (open[1]), num (high[1]), num (low[1]), num (close[1])
local O2, H2, L2, C2 = num (open[2]), num (high[2]), num (low[2]), num (close[2])

local EF1, EM1, ES1 = num (ema_f[1]), num (ema_m[1]), num (ema_s[1])
local EM4, ES4      = num (ema_m[4]), num (ema_s[4])
local R1, R2        = num (rsi_val[1]), num (rsi_val[2])
local HI1, HI2      = num (macd_hist[1]), num (macd_hist[2])
local ML1           = num (macd_line[1])
local ATR1, ATR2    = num (atr_val[1]), num (atr_val[2])
local ATRB1         = num (atr_base[1])
local BW1, BWA1     = num (bb_width[1]), num (bb_width_avg[1])
local CLV1          = num (clv_avg[1], 0.5)

local RES1, RES2 = num (res_lvl), num (res_lvl2)
local SUP1, SUP2 = num (sup_lvl), num (sup_lvl2)
local RHI2, RLO2 = num (rng_hi[2]), num (rng_lo[2])

local warm_need = math.max (ema_slow_len, range_len, atr_base_len, bb_len * 3) + 2 * pivot_len + 5
local data_ok = num (bar_count, 0) > warm_need
    and O1 and H1 and L1 and C1 and O2 and H2 and L2 and C2
    and EF1 and EM1 and ES1 and EM4 and ES4 and R1 and R2
    and HI1 and HI2 and ML1 and ATR1 and ATR2 and ATRB1 and BW1 and BWA1
    and ATR1 > 0 and ATR2 > 0 and ATRB1 > 0

-- ------------------------- OUTPUT VARIABLES ---------------------------
-- Plain numbers / strings for the current bar, read by the views.
SIG_DIR     = 0      --  1 = CALL, -1 = PUT, 0 = WAIT
SIG_SCORE   = 0      -- confidence of the printed signal
SIG_TRIG    = ""     -- price-action trigger of the signal
BULL_SCORE  = 0      -- raw CALL alignment score (0-100)
BEAR_SCORE  = 0      -- raw PUT  alignment score (0-100)
TREND_DIR   = 0      --  1 up, -1 down, 0 none / sideways
WAIT_REASON = ""     -- why a would-be signal was cancelled
WAIT_SIDE   = 0      -- side of the cancelled signal (1 CALL, -1 PUT)
BUY_PRESS   = 50     -- buy pressure %  (closed candles)
SELL_PRESS  = 50     -- sell pressure % (closed candles)
NO_CHASE    = false  -- live: price already ran away on the entry candle

-- ----------------------- SIDE-NEUTRAL EVALUATION ----------------------
-- The bearish case is evaluated by mirroring prices (x -> -x) and RSI
-- (r -> 100 - r), so CALL and PUT rules are exactly symmetric.
local function make_view (s)
    local v = {}
    if s == 1 then
        v.o1, v.h1, v.l1, v.c1 = O1, H1, L1, C1
        v.o2, v.h2, v.l2, v.c2 = O2, H2, L2, C2
        v.ext = rsi_ext_high
    else
        v.o1, v.h1, v.l1, v.c1 = -O1, -L1, -H1, -C1
        v.o2, v.h2, v.l2, v.c2 = -O2, -L2, -H2, -C2
        v.ext = 100 - rsi_ext_low
    end
    v.ef1, v.em1, v.es1 = s * EF1, s * EM1, s * ES1
    v.em4, v.es4        = s * EM4, s * ES4
    v.r1 = (s == 1) and R1 or (100 - R1)
    v.r2 = (s == 1) and R2 or (100 - R2)
    v.hi1, v.hi2, v.ml1 = s * HI1, s * HI2, s * ML1

    -- obstacles in the trade direction / supports behind the trade
    local obst, supp = {}, {}
    local function add (t, x) if x ~= nil then t[#t + 1] = x end end
    if s == 1 then
        add (obst, RES1) add (obst, RES2) add (obst, RHI2)
        add (supp, SUP1) add (supp, SUP2) add (supp, RLO2)
        v.brk_lvl  = RES1
        v.sweep_lvl = SUP1
    else
        add (obst, SUP1 and -SUP1) add (obst, SUP2 and -SUP2) add (obst, RLO2 and -RLO2)
        add (supp, RES1 and -RES1) add (supp, RES2 and -RES2) add (supp, RHI2 and -RHI2)
        v.brk_lvl  = SUP1 and -SUP1
        v.sweep_lvl = RES1 and -RES1
    end
    v.obst, v.supp = obst, supp
    return v
end

local sideways, abnormal, squeeze = false, false, false

local function evaluate (v)
    local r = { score = 0, trig = "", reason = "", bias = false }
    local atr = ATR1

    -- ---------- candle geometry (closed candle) ----------
    local rng1  = math.max (v.h1 - v.l1, 0.0000001)
    local body1 = math.abs (v.c1 - v.o1)
    local body2 = math.abs (v.c2 - v.o2)
    local upw1  = v.h1 - math.max (v.c1, v.o1)
    local loww1 = math.min (v.c1, v.o1) - v.l1
    local close_pos = (v.c1 - v.l1) / rng1

    -- nearest obstacle ahead and nearest support behind
    local room = 99
    for _, x in ipairs (v.obst) do
        if x > v.c1 then room = math.min (room, (x - v.c1) / atr) end
    end
    local near_sup = nil
    for _, x in ipairs (v.supp) do
        if x < v.c1 and (near_sup == nil or x > near_sup) then near_sup = x end
    end

    -- ---------- 1. TREND  (max 25) ----------
    local trend_ok = v.em1 > v.es1 and v.c1 > v.es1 and v.es1 > v.es4
    local stack    = v.ef1 > v.em1 and v.em1 > v.es1
    local ts = 0
    if stack then ts = ts + 12 elseif v.ef1 > v.em1 then ts = ts + 5 end
    if v.c1 > v.em1 then ts = ts + 4 end
    if v.es1 > v.es4 then ts = ts + 5 end
    if (v.ef1 - v.es1) >= 0.5 * atr then ts = ts + 4 end

    -- ---------- 2. RSI  (max 15) ----------
    local rs = 0
    if v.r1 > 52 and v.r1 <= 70 and v.r1 >= v.r2 then rs = 15
    elseif v.r1 > 50 and v.r1 <= 74 then rs = 10
    elseif v.r1 >= 45 and v.r1 > v.r2 then rs = 4 end

    -- ---------- 3. MACD  (max 15) ----------
    local ms = 0
    if v.hi1 > 0 then ms = ms + 6 end
    if v.hi1 > v.hi2 then ms = ms + 5 end
    if v.ml1 > 0 then ms = ms + 4 end

    -- ---------- 4. PRICE ACTION  (max 20) ----------
    local pa, trig = 0, ""
    local function take (p, t) if p > pa then pa, trig = p, t end end

    -- Engulfing
    if v.c1 > v.o1 and v.c2 < v.o2 and v.c1 >= v.o2 and v.o1 <= v.c2
       and body1 > body2 and body1 >= 0.3 * atr then
        take (20, "ENGULF")
    end
    -- False breakout: swept the support behind, closed back above it
    if v.sweep_lvl ~= nil and v.l1 < v.sweep_lvl and v.c1 > v.sweep_lvl
       and loww1 >= 0.4 * rng1 and close_pos >= 0.5 then
        take (18, "FALSE-BRK")
    end
    -- Pin bar
    if loww1 >= 2 * body1 and loww1 >= 0.6 * rng1 and upw1 <= 0.25 * rng1
       and rng1 >= 0.5 * atr then
        take (16, "PIN")
    end
    -- Rejection of dynamic (EMA Mid) or static support
    local touched = (v.l1 <= v.em1 + 0.15 * atr)
        or (near_sup ~= nil and v.l1 <= near_sup + 0.25 * atr)
    if v.c1 > v.o1 and loww1 >= 0.4 * rng1 and touched and v.c1 > v.em1 then
        take (15, "REJECT")
    end
    -- Breakout of the last confirmed pivot level
    if v.brk_lvl ~= nil and v.c1 > v.brk_lvl + 0.1 * atr and v.c2 <= v.brk_lvl
       and v.c1 > v.o1 and body1 >= 0.5 * rng1 then
        take (14, "BREAKOUT")
    end
    -- Plain momentum candle
    if v.c1 > v.o1 and body1 >= 0.5 * rng1 and close_pos >= 0.7 then
        take (8, "MOMENTUM")
    end

    -- ---------- 5. ROOM TO NEXT LEVEL  (max 15) ----------
    local rm = 0
    if room >= 2.0 then rm = 15
    elseif room >= 1.5 then rm = 12
    elseif room >= 1.0 then rm = 8
    elseif room >= min_room_atr then rm = 4 end

    -- ---------- 6. VOLATILITY QUALITY  (max 10) ----------
    local vs = 0
    local atr_ratio = ATR1 / ATRB1
    if not squeeze and not abnormal and atr_ratio >= 0.6 and atr_ratio <= 1.6 then
        vs = 10
    elseif not abnormal then
        vs = 5
    end

    r.score = clamp (ts + rs + ms + pa + rm + vs, 0, 100)
    r.trig  = trig
    r.bias  = trend_ok

    -- ---------- HARD FILTERS (first failure = reason) ----------
    local late = body1 > late_body_atr * atr or (v.c1 - v.em1) > max_ext_atr * atr
    if abnormal then
        r.reason = "VOLATILE"
    elseif sideways then
        r.reason = "SIDEWAYS"
    elseif not trend_ok or not (v.ef1 > v.em1) then
        r.reason = "NO-TREND"
    elseif v.r1 <= 50 or v.hi1 <= 0 then
        r.reason = "CONFLICT"
    elseif v.r1 > v.ext then
        r.reason = "OVEREXT"
    elseif pa < 8 or close_pos < 0.5 then
        r.reason = "NO-PA"
    elseif late then
        r.reason = "LATE"
    elseif room < min_room_atr then
        r.reason = "NEAR-SR"
    elseif r.score < min_score then
        r.reason = "LOW-SCORE"
    end
    return r
end

-- ------------------------------ DECISION ------------------------------
local prev_age = num (sig_age[1], 999)

if data_ok then
    -- market regime (closed candle)
    squeeze  = BW1 < BWA1 * squeeze_ratio
    local flat     = math.abs (EM1 - EM4) < flat_atr * ATR1
    local tangled  = math.abs (EF1 - ES1) < 0.3 * ATR1
    sideways = flat and (squeeze or tangled)
    abnormal = (H1 - L1) > spike_mult * ATR2 or ATR1 > hot_ratio * ATRB1

    local bull = evaluate (make_view (1))
    local bear = evaluate (make_view (-1))

    BULL_SCORE = bull.score
    BEAR_SCORE = bear.score
    if bull.bias and not sideways then TREND_DIR = 1
    elseif bear.bias and not sideways then TREND_DIR = -1 end

    BUY_PRESS  = clamp (CLV1 * 100, 0, 100)
    SELL_PRESS = 100 - BUY_PRESS

    local cooled = prev_age >= cooldown_bars

    local best, side = nil, 0
    if bull.reason == "" then best, side = bull, 1
    elseif bear.reason == "" then best, side = bear, -1 end

    if best ~= nil and not cooled then
        WAIT_REASON, WAIT_SIDE = "COOLDOWN", side
        best = nil
    end

    if best ~= nil then
        SIG_DIR   = side
        SIG_SCORE = best.score
        SIG_TRIG  = best.trig
    else
        -- report the cancel reason only for a complete "would-be" setup:
        -- trend bias + price-action trigger + score above the threshold
        local function setup (x) return x.bias and x.trig ~= "" and x.score >= min_score end
        local cand, cside = nil, 0
        if setup (bull) then cand, cside = bull, 1
        elseif setup (bear) then cand, cside = bear, -1 end
        if cand ~= nil and WAIT_REASON == "" then
            WAIT_REASON, WAIT_SIDE = cand.reason, cside
        end
    end

    -- LIVE advisory on the entry candle: do not chase a runaway open
    if SIG_DIR ~= 0 then
        local o0, c0 = num (open), num (close)
        if o0 ~= nil and c0 ~= nil and SIG_DIR * (c0 - o0) > chase_atr * ATR1 then
            NO_CHASE = true
        end
    end
end

sig_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)

-- Show a cancel reason only on the first bar of a streak (less clutter)
local REASON_CODE = { ["NEAR-SR"] = 1, SIDEWAYS = 2, VOLATILE = 3, LATE = 4, OVEREXT = 5,
                      CONFLICT = 6, ["NO-PA"] = 7, ["LOW-SCORE"] = 8, COOLDOWN = 9, ["NO-TREND"] = 10 }
wait_code = make_series ()
local wcode = (REASON_CODE[WAIT_REASON] or 0) * WAIT_SIDE
wait_code:set (wcode)
WAIT_NEW = wcode ~= 0 and wcode ~= num (wait_code[1], 0)

-- =====================================================================
--  PANEL VIEW (separate window): confidence score, buy/sell pressure,
--  current status, trend strip and cancel reasons.
--  Keep the SAME input values as the Main script so both agree.
-- =====================================================================
input_group {
    "Panel Colors",
    p_call_color  = input { default = "#00E676", type = input.color },
    p_put_color   = input { default = "#FF1744", type = input.color },
    p_wait_color  = input { default = rgba(158,158,158,0.55), type = input.color },
    p_bull_color  = input { default = rgba(0,230,118,0.9), type = input.color },
    p_bear_color  = input { default = rgba(255,23,68,0.9), type = input.color },
    p_buyp_color  = input { default = rgba(105,240,174,0.45), type = input.color },
    p_sellp_color = input { default = rgba(255,138,128,0.45), type = input.color },
    p_level_color = input { default = rgba(255,255,255,0.25), type = input.color },
    p_note_color  = input { default = rgba(255,193,7,0.95), type = input.color },
    show_pressure = input { default = true, type = input.plot_visibility }
}

-- Plain numbers -> series so they can be plotted
score_s = make_series ()
bull_s  = make_series ()
bear_s  = make_series ()
buyp_s  = make_series ()
sellp_s = make_series ()
state_s = make_series ()
trend_s = make_series ()

local shown = SIG_DIR ~= 0 and SIG_SCORE or math.max (BULL_SCORE, BEAR_SCORE)
score_s:set (shown)
bull_s:set (BULL_SCORE)
bear_s:set (BEAR_SCORE)
buyp_s:set (BUY_PRESS)
sellp_s:set (SELL_PRESS)
state_s:set (SIG_DIR)
trend_s:set (TREND_DIR)

local col = p_wait_color
if SIG_DIR == 1 then col = p_call_color elseif SIG_DIR == -1 then col = p_put_color end

-- Score column: green = CALL, red = PUT, grey = WAIT (raw best score)
rect {
    first  = 0,
    second = score_s,
    color  = col,
    width  = 0.7
}

plot (bull_s, "CALL Score (raw)", p_bull_color, 1)
plot (bear_s, "PUT Score (raw)",  p_bear_color, 1)

if show_pressure then
    plot (buyp_s,  "Buy Pressure %",  p_buyp_color, 1)
    plot (sellp_s, "Sell Pressure %", p_sellp_color, 1)
end

-- Values readable in the legend / data window
plot (state_s, "Status (+1 CALL / -1 PUT / 0 WAIT)", rgba(0,0,0,0), 1)
plot (trend_s, "Trend (+1 Up / -1 Down / 0 None)",   rgba(0,0,0,0), 1)

hline (85, "Strong 85", p_level_color, 1)
hline (70, "Good 70",   p_level_color, 1)
hline (60, "Weak 60",   p_level_color, 1)
hline { value = 105, color = rgba(255,255,255,0), show_label = false }
hline { value = 0,   color = rgba(255,255,255,0), show_label = false }

-- Status labels at the top
plot_shape (SIG_DIR == 1,  "CALL", shape_style.arrowup,   shape_size.small, p_call_color, shape_location.top, 0, "CALL", p_call_color)
plot_shape (SIG_DIR == -1, "PUT",  shape_style.arrowdown, shape_size.small, p_put_color,  shape_location.top, 0, "PUT",  p_put_color)

-- Trend strip at the bottom
plot_shape (TREND_DIR == 1,  "Trend Up",   shape_style.square, shape_size.tiny, p_call_color, shape_location.bottom, 0, "", p_call_color)
plot_shape (TREND_DIR == -1, "Trend Down", shape_style.square, shape_size.tiny, p_put_color,  shape_location.bottom, 0, "", p_put_color)
plot_shape (TREND_DIR == 0,  "No Trend",   shape_style.square, shape_size.tiny, p_wait_color, shape_location.bottom, 0, "", p_wait_color)

-- Why a would-be signal was cancelled (top, small text)
local w = WAIT_NEW
plot_shape (w and WAIT_REASON == "NEAR-SR",   "Cancel: near S/R",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "SR",   p_note_color)
plot_shape (w and WAIT_REASON == "SIDEWAYS",  "Cancel: sideways",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "SIDE", p_note_color)
plot_shape (w and WAIT_REASON == "VOLATILE",  "Cancel: volatility",   shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "VOL",  p_note_color)
plot_shape (w and WAIT_REASON == "LATE",      "Cancel: late",         shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "LATE", p_note_color)
plot_shape (w and WAIT_REASON == "OVEREXT",   "Cancel: RSI extreme",  shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "RSI",  p_note_color)
plot_shape (w and WAIT_REASON == "CONFLICT",  "Cancel: conflict",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "CONF", p_note_color)
plot_shape (w and WAIT_REASON == "NO-PA",     "Cancel: no trigger",   shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "PA",   p_note_color)
plot_shape (w and WAIT_REASON == "LOW-SCORE", "Cancel: low score",    shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "LOW",  p_note_color)
plot_shape (w and WAIT_REASON == "COOLDOWN",  "Cancel: cooldown",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "CD",   p_note_color)
