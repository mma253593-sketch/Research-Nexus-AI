-- =====================================================================
--  MAIN CHART VIEW (overlay): CALL / PUT arrows on the ENTRY candle.
--  Enter at the open of the arrow candle, 1-minute expiry. The arrow is
--  decided from closed candles only and never changes during the candle.
--  Setup marker on the confirmation candle: PB pullback, TR trend
--  continuation, BO breakout, RG range rejection. The score is NOT a
--  win probability.
-- =====================================================================
input_group {
    "Display",
    v2_show_setup = input { default = true, type = input.plot_visibility },
    v2_call_color = input { default = "#00E676", type = input.color },
    v2_put_color  = input { default = "#FF1744", type = input.color }
}
local cc, pc, BB, AB = v2_call_color, v2_put_color, shape_location.belowbar, shape_location.abovebar
plot_shape (SIG_DIR == 1, "CALL", shape_style.arrowup, shape_size.large, cc, BB, 0, "CALL", cc)
plot_shape (SIG_DIR == -1, "PUT", shape_style.arrowdown, shape_size.large, pc, AB, 0, "PUT", pc)
if v2_show_setup then
    local C, S, K = shape_style.circle, shape_size.tiny, SIG_KIND
    plot_shape (K == 1, "CALL PB", C, S, cc, BB, -1, "PB", cc)
    plot_shape (K == 2, "CALL TR", C, S, cc, BB, -1, "TR", cc)
    plot_shape (K == 3, "CALL BO", C, S, cc, BB, -1, "BO", cc)
    plot_shape (K == 4, "CALL RG", C, S, cc, BB, -1, "RG", cc)
    plot_shape (K == -1, "PUT PB", C, S, pc, AB, -1, "PB", pc)
    plot_shape (K == -2, "PUT TR", C, S, pc, AB, -1, "TR", pc)
    plot_shape (K == -3, "PUT BO", C, S, pc, AB, -1, "BO", pc)
    plot_shape (K == -4, "PUT RG", C, S, pc, AB, -1, "RG", pc)
end
