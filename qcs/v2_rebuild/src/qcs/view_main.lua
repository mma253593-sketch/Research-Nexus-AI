-- =====================================================================
--  MAIN CHART VIEW (overlay): CALL / PUT arrows on the ENTRY candle.
--  Enter at the open of the arrow candle, 1-minute expiry. The arrow is
--  decided from closed candles only and never changes during the candle.
--  The score is NOT a win probability.
-- =====================================================================
input_group {
    "Display",
    v2_show_setup = input { default = true, type = input.plot_visibility },
    v2_call_color = input { default = "#00E676", type = input.color },
    v2_put_color  = input { default = "#FF1744", type = input.color }
}
local up, dn = SIG_DIR == 1, SIG_DIR == -1
local AU, AD, BB, AB = shape_style.arrowup, shape_style.arrowdown, shape_location.belowbar, shape_location.abovebar
plot_shape (up, "CALL", AU, shape_size.large, v2_call_color, BB, 0, "CALL", v2_call_color)
plot_shape (dn, "PUT", AD, shape_size.large, v2_put_color, AB, 0, "PUT", v2_put_color)
if v2_show_setup then
    local C, S, cc, pc = shape_style.circle, shape_size.tiny, v2_call_color, v2_put_color
    plot_shape (up and SIG_SETUP == "PULLBACK_CONTINUATION", "CALL PULLBACK", C, S, cc, BB, -1, "PULLBACK", cc)
    plot_shape (up and SIG_SETUP == "TREND_CONTINUATION", "CALL TREND", C, S, cc, BB, -1, "TREND", cc)
    plot_shape (up and SIG_SETUP == "BREAKOUT_CONFIRMATION", "CALL BREAKOUT", C, S, cc, BB, -1, "BREAKOUT", cc)
    plot_shape (up and SIG_SETUP == "RANGE_REJECTION", "CALL RANGE", C, S, cc, BB, -1, "RANGE", cc)
    plot_shape (dn and SIG_SETUP == "PULLBACK_CONTINUATION", "PUT PULLBACK", C, S, pc, AB, -1, "PULLBACK", pc)
    plot_shape (dn and SIG_SETUP == "TREND_CONTINUATION", "PUT TREND", C, S, pc, AB, -1, "TREND", pc)
    plot_shape (dn and SIG_SETUP == "BREAKOUT_CONFIRMATION", "PUT BREAKOUT", C, S, pc, AB, -1, "BREAKOUT", pc)
    plot_shape (dn and SIG_SETUP == "RANGE_REJECTION", "PUT RANGE", C, S, pc, AB, -1, "RANGE", pc)
end
