
-- =====================================================================
--  PANEL VIEW (separate window): Score 2.0, pressure, status, regime
--  strip and cancel reasons. Keep the SAME inputs as the Main script.
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
    p_min_color   = input { default = rgba(255,193,7,0.6), type = input.color },
    p_note_color  = input { default = rgba(255,193,7,0.95), type = input.color },
    p_trend_color = input { default = "#00B0FF", type = input.color },
    p_range_color = input { default = "#9E9E9E", type = input.color },
    p_hv_color    = input { default = "#FF6D00", type = input.color },
    p_lv_color    = input { default = "#5C6BC0", type = input.color },
    p_trans_color = input { default = "#FFEE58", type = input.color },
    show_pressure = input { default = true, type = input.plot_visibility }
}

-- Plain numbers -> series so they can be plotted
score_s  = make_series ()
bull_s   = make_series ()
bear_s   = make_series ()
buyp_s   = make_series ()
sellp_s  = make_series ()
minsc_s  = make_series ()
state_s  = make_series ()
trend_s  = make_series ()
regime_s = make_series ()
adx_s    = make_series ()

local shown = SIG_DIR ~= 0 and SIG_SCORE or math.max (BULL_SCORE, BEAR_SCORE)
score_s:set (shown)
bull_s:set (BULL_SCORE)
bear_s:set (BEAR_SCORE)
buyp_s:set (BUY_PRESS)
sellp_s:set (SELL_PRESS)
minsc_s:set (SIG_MIN)
state_s:set (SIG_DIR)
trend_s:set (TREND_DIR)
regime_s:set (REGIME)
adx_s:set (ADX_NOW)

local col = p_wait_color
if SIG_DIR == 1 then col = p_call_color elseif SIG_DIR == -1 then col = p_put_color end

-- Score column: green = CALL, red = PUT, grey = WAIT (best raw score)
rect {
    first  = 0,
    second = score_s,
    color  = col,
    width  = 0.7
}

plot (bull_s, "CALL Score", p_bull_color, 1)
plot (bear_s, "PUT Score",  p_bear_color, 1)
plot (minsc_s, "Required Score (adaptive)", p_min_color, 1)

if show_pressure then
    plot (buyp_s,  "Buy Pressure %",  p_buyp_color, 1)
    plot (sellp_s, "Sell Pressure %", p_sellp_color, 1)
end

-- Values readable in the legend / data window
plot (state_s,  "Status (+1 CALL / -1 PUT / 0 WAIT)",                  rgba(0,0,0,0), 1)
plot (trend_s,  "Trend (+1 Up / -1 Down / 0 None)",                    rgba(0,0,0,0), 1)
plot (regime_s, "Regime (1 Trend 2 Range 3 HiVol 4 LoVol 5 Trans)",    rgba(0,0,0,0), 1)
plot (adx_s,    "ADX",                                                 rgba(0,0,0,0), 1)

hline (85, "Strong 85", p_level_color, 1)
hline (70, "Good 70",   p_level_color, 1)
hline (60, "Weak 60",   p_level_color, 1)
hline { value = 105, color = rgba(255,255,255,0), show_label = false }
hline { value = 0,   color = rgba(255,255,255,0), show_label = false }

-- Status labels at the top
plot_shape (SIG_DIR == 1,  "CALL", shape_style.arrowup,   shape_size.small, p_call_color, shape_location.top, 0, "CALL", p_call_color)
plot_shape (SIG_DIR == -1, "PUT",  shape_style.arrowdown, shape_size.small, p_put_color,  shape_location.top, 0, "PUT",  p_put_color)

-- Regime strip at the bottom (one square per bar, colour = confirmed regime)
plot_shape (REGIME == REG_TREND,   "Regime: Trend",        shape_style.square, shape_size.tiny, p_trend_color, shape_location.bottom, 0, "", p_trend_color)
plot_shape (REGIME == REG_RANGE,   "Regime: Range",        shape_style.square, shape_size.tiny, p_range_color, shape_location.bottom, 0, "", p_range_color)
plot_shape (REGIME == REG_HIGHVOL, "Regime: High Vol",     shape_style.square, shape_size.tiny, p_hv_color,    shape_location.bottom, 0, "", p_hv_color)
plot_shape (REGIME == REG_LOWVOL,  "Regime: Low Vol",      shape_style.square, shape_size.tiny, p_lv_color,    shape_location.bottom, 0, "", p_lv_color)
plot_shape (REGIME == REG_TRANS,   "Regime: Transitional", shape_style.square, shape_size.tiny, p_trans_color, shape_location.bottom, 0, "", p_trans_color)

-- Why a would-be signal was cancelled (top, small text; first bar of a streak)
local w = WAIT_NEW
plot_shape (w and WAIT_REASON == "NEAR-SR",    "Cancel: near S/R",       shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "SR",    p_note_color)
plot_shape (w and WAIT_REASON == "RANGING",    "Cancel: ranging",        shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "RANGE", p_note_color)
plot_shape (w and WAIT_REASON == "TRANSITION", "Cancel: transitional",   shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "TRANS", p_note_color)
plot_shape (w and WAIT_REASON == "LOW-VOL",    "Cancel: low volatility", shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "LOVOL", p_note_color)
plot_shape (w and WAIT_REASON == "VOLATILE",   "Cancel: high volatility",shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "VOL",   p_note_color)
plot_shape (w and WAIT_REASON == "LATE",       "Cancel: late",           shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "LATE",  p_note_color)
plot_shape (w and WAIT_REASON == "OVEREXT",    "Cancel: RSI extreme",    shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "RSI",   p_note_color)
plot_shape (w and WAIT_REASON == "CONFLICT",   "Cancel: conflict",       shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "CONF",  p_note_color)
plot_shape (w and WAIT_REASON == "WEAK-MOM",   "Cancel: weak momentum",  shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "WEAK",  p_note_color)
plot_shape (w and WAIT_REASON == "WHIPSAW",    "Cancel: EMA whipsaw",    shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "WHIP",  p_note_color)
plot_shape (w and WAIT_REASON == "EXHAUST",    "Cancel: exhaustion",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "EXH",   p_note_color)
plot_shape (w and WAIT_REASON == "REVERSAL",   "Cancel: structure break",shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "REV",   p_note_color)
plot_shape (w and WAIT_REASON == "NO-PA",      "Cancel: no trigger",     shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "PA",    p_note_color)
plot_shape (w and WAIT_REASON == "COOLDOWN",   "Cancel: cooldown",       shape_style.xcross, shape_size.tiny, p_note_color, shape_location.top, 0, "CD",    p_note_color)
