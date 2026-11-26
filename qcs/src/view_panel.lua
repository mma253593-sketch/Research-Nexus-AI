
-- =====================================================================
--  PANEL VIEW: scores, status, market, setup, block reason, legend values.
--  QCS has no dynamic text API: values are shown in the legend (numeric
--  codes) and as fixed-text markers. Keep the SAME inputs as Main.
-- =====================================================================
input_group {
    "Panel",
    p_call = input { default = "#00E676", type = input.color },
    p_put  = input { default = "#FF1744", type = input.color },
    p_wait = input { default = rgba(158,158,158,0.55), type = input.color },
    p_note = input { default = rgba(255,193,7,0.95), type = input.color }
}

local col = p_wait
if SIG_DIR == 1 then col = p_call elseif SIG_DIR == -1 then col = p_put end
score_s = make_series ()
score_s:set (SIG_DIR ~= 0 and SIG_SCORE or math.max (BULL_SCORE, BEAR_SCORE))
rect { first = 0, second = score_s, color = col, width = 0.7 }

bull_s = make_series ()
bull_s:set (BULL_SCORE)
bear_s = make_series ()
bear_s:set (BEAR_SCORE)
min_s = make_series ()
min_s:set (min_score)
plot (bull_s, "CALL Score", rgba(0,230,118,0.9), 1)
plot (bear_s, "PUT Score", rgba(255,23,68,0.9), 1)
plot (min_s, "Min Confidence", rgba(255,193,7,0.6), 1)
hline (85, "Strong", rgba(255,255,255,0.25), 1)
hline (75, "Good", rgba(255,255,255,0.25), 1)
hline { value = 105, color = rgba(255,255,255,0), show_label = false }
hline { value = 0, color = rgba(255,255,255,0), show_label = false }

-- Legend values (transparent lines): read them in the data window
local Z = rgba(0,0,0,0)
st_s = make_series ()
st_s:set (SIG_STATE)
tr_s = make_series ()
tr_s:set (TREND_STATE)
mk_s = make_series ()
mk_s:set (MARKET)
su_s = make_series ()
su_s:set ((SIG_SETUP == "MOMENTUM") and 1 or ((SIG_SETUP == "PULLBACK") and 2 or 0))
mo_s = make_series ()
mo_s:set (MOM_STATE)
pa_s = make_series ()
pa_s:set (SC_PA)
lo_s = make_series ()
lo_s:set (LOC_ATR)
at_s = make_series ()
at_s:set (ATR_RATIO)
ro_s = make_series ()
ro_s:set (math.min (ROOM_ATR, 10))
bk_s = make_series ()
bk_s:set (BLOCK_CODE)
cd_s = make_series ()
cd_s:set (COOL_LEFT)
rw_s = make_series ()
rw_s:set (RAW_SCORE)
plot (st_s, "Status 2 CALL -2 PUT 1/-1 READY 3 EXPIRED 4 BLOCKED 0 WAIT", Z, 1)
plot (tr_s, "Trend 2/1 up -1/-2 down 0 sideways 5 transition", Z, 1)
plot (mk_s, "Market 1 trend 2 side 3 hivol 4 lovol 5 exhaust 6 reversal", Z, 1)
plot (su_s, "Setup 1 MOMENTUM 2 PULLBACK", Z, 1)
plot (mo_s, "Momentum 2 accel up 1 bull -1 bear -2 accel down", Z, 1)
plot (pa_s, "Price Action points", Z, 1)
plot (lo_s, "Entry distance (ATR)", Z, 1)
plot (at_s, "ATR / baseline", Z, 1)
plot (ro_s, "Room to S/R (ATR)", Z, 1)
plot (bk_s, "Block code (+CALL/-PUT)", Z, 1)
plot (cd_s, "Cooldown bars left", Z, 1)
plot (rw_s, "Raw score", Z, 1)

-- Status labels (top)
local TOP, X, T = shape_location.top, shape_style.xcross, shape_size.tiny
plot_shape (SIG_STATE == 2, "CALL", shape_style.arrowup, shape_size.small, p_call, TOP, 0, "CALL", p_call)
plot_shape (SIG_STATE == -2, "PUT", shape_style.arrowdown, shape_size.small, p_put, TOP, 0, "PUT", p_put)
plot_shape (SIG_STATE == 1, "CALL READY", shape_style.diamond, T, p_call, TOP, 0, "CALL READY", p_call)
plot_shape (SIG_STATE == -1, "PUT READY", shape_style.diamond, T, p_put, TOP, 0, "PUT READY", p_put)
plot_shape (SIG_STATE == 3, "EXPIRED", shape_style.circle, T, p_wait, TOP, 0, "EXPIRED", p_wait)

-- Block reasons (first bar of a streak)
local b = BLOCK_NEW
plot_shape (b and BLOCK == "SIDEWAYS", "BLOCK: SIDEWAYS", X, T, p_note, TOP, 0, "BLOCK: SIDEWAYS", p_note)
plot_shape (b and BLOCK == "LATE", "BLOCK: LATE", X, T, p_note, TOP, 0, "BLOCK: LATE", p_note)
plot_shape (b and BLOCK == "SUPPORT", "BLOCK: SUPPORT", X, T, p_note, TOP, 0, "BLOCK: SUPPORT", p_note)
plot_shape (b and BLOCK == "RESISTANCE", "BLOCK: RESISTANCE", X, T, p_note, TOP, 0, "BLOCK: RESISTANCE", p_note)
plot_shape (b and BLOCK == "LOW-CONFIDENCE", "BLOCK: LOW CONFIDENCE", X, T, p_note, TOP, 0, "BLOCK: LOW CONFIDENCE", p_note)
plot_shape (b and (BLOCK == "VOLATILITY" or BLOCK == "LOW-VOL"), "BLOCK: VOLATILITY", X, T, p_note, TOP, 0, "BLOCK: VOLATILITY", p_note)
plot_shape (b and BLOCK == "EXHAUST", "BLOCK: EXHAUSTION", X, T, p_note, TOP, 0, "BLOCK: EXHAUSTION", p_note)
plot_shape (b and BLOCK == "REVERSAL", "BLOCK: REVERSAL", X, T, p_note, TOP, 0, "BLOCK: REVERSAL", p_note)
plot_shape (b and (BLOCK == "CONFLICT" or BLOCK == "WEAK-MOM"), "BLOCK: MOMENTUM", X, T, p_note, TOP, 0, "BLOCK: MOMENTUM", p_note)
plot_shape (b and BLOCK == "COOLDOWN", "BLOCK: COOLDOWN", X, T, p_note, TOP, 0, "BLOCK: COOLDOWN", p_note)
plot_shape (SIG_DIR ~= 0 and NO_CHASE, "NO CHASE (live warning)", X, T, "#FF9100", TOP, 0, "NO CHASE", "#FF9100")

-- Market strip (bottom)
local BOT, SQ = shape_location.bottom, shape_style.square
plot_shape (MARKET == 1, "Market: Trend", SQ, T, "#00B0FF", BOT, 0, "", "#00B0FF")
plot_shape (MARKET == 2, "Market: Sideways", SQ, T, "#9E9E9E", BOT, 0, "", "#9E9E9E")
plot_shape (MARKET == 3, "Market: High Vol", SQ, T, "#FF6D00", BOT, 0, "", "#FF6D00")
plot_shape (MARKET == 4, "Market: Low Vol", SQ, T, "#5C6BC0", BOT, 0, "", "#5C6BC0")
plot_shape (MARKET == 5, "Market: Exhaustion", SQ, T, "#E040FB", BOT, 0, "", "#E040FB")
plot_shape (MARKET == 6, "Market: Reversal Risk", SQ, T, "#FFEE58", BOT, 0, "", "#FFEE58")
