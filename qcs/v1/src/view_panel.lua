
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
