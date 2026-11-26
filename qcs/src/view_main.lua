
-- =====================================================================
--  MAIN CHART VIEW: EMA, S/R, arrows, setup type, READY, blocks, NO CHASE
-- =====================================================================
input_group {
    "Display",
    show_ema   = input { default = true, type = input.plot_visibility },
    show_sr    = input { default = true, type = input.plot_visibility },
    show_setup = input { default = true, type = input.plot_visibility },
    show_ready = input { default = true, type = input.plot_visibility },
    show_block = input { default = true, type = input.plot_visibility },
    call_color = input { default = "#00E676", type = input.color },
    put_color  = input { default = "#FF1744", type = input.color },
    note_color = input { default = rgba(255,193,7,0.9), type = input.color }
}

if show_ema then
    plot (ema_f, "EMA 9", "#FFD54F", 1)
    plot (ema_m, "EMA 21", "#29B6F6", 2)
    plot (ema_s, "EMA 50", "#AB47BC", 2)
end
if show_sr then
    plot (res1, "Resistance", rgba(255,82,82,0.85), 2)
    plot (sup1, "Support", rgba(0,230,118,0.85), 2)
end

-- Arrow on the ENTRY candle (enter at its open, 1-minute expiry)
local up, dn = SIG_DIR == 1, SIG_DIR == -1
local AU, AD, BB, AB = shape_style.arrowup, shape_style.arrowdown, shape_location.belowbar, shape_location.abovebar
plot_shape (up and SIG_SCORE >= 85, "CALL Strong", AU, shape_size.huge, call_color, BB, 0, "CALL 85+", call_color)
plot_shape (up and SIG_SCORE >= 75 and SIG_SCORE < 85, "CALL Good", AU, shape_size.large, call_color, BB, 0, "CALL 75+", call_color)
plot_shape (up and SIG_SCORE < 75, "CALL Moderate", AU, shape_size.normal, call_color, BB, 0, "CALL 70+", call_color)
plot_shape (dn and SIG_SCORE >= 85, "PUT Strong", AD, shape_size.huge, put_color, AB, 0, "PUT 85+", put_color)
plot_shape (dn and SIG_SCORE >= 75 and SIG_SCORE < 85, "PUT Good", AD, shape_size.large, put_color, AB, 0, "PUT 75+", put_color)
plot_shape (dn and SIG_SCORE < 75, "PUT Moderate", AD, shape_size.normal, put_color, AB, 0, "PUT 70+", put_color)

-- Setup type on the CONFIRMATION candle (one bar back)
if show_setup then
    local C = shape_style.circle
    plot_shape (up and SIG_SETUP == "MOMENTUM", "CALL Momentum", C, shape_size.tiny, call_color, BB, -1, "MOMENTUM", call_color)
    plot_shape (up and SIG_SETUP == "PULLBACK", "CALL Pullback", C, shape_size.tiny, call_color, BB, -1, "PULLBACK", call_color)
    plot_shape (dn and SIG_SETUP == "MOMENTUM", "PUT Momentum", C, shape_size.tiny, put_color, AB, -1, "MOMENTUM", put_color)
    plot_shape (dn and SIG_SETUP == "PULLBACK", "PUT Pullback", C, shape_size.tiny, put_color, AB, -1, "PULLBACK", put_color)
end

-- READY = a pullback is forming (information only, NOT an entry)
if show_ready then
    plot_shape (SIG_STATE == 1, "CALL Ready", shape_style.diamond, shape_size.tiny, call_color, BB, 0, "READY", call_color)
    plot_shape (SIG_STATE == -1, "PUT Ready", shape_style.diamond, shape_size.tiny, put_color, AB, 0, "READY", put_color)
end

-- Live warning only (does not change the signal)
plot_shape (SIG_DIR ~= 0 and NO_CHASE, "No Chase", shape_style.xcross, shape_size.small, "#FF9100", shape_location.top, 0, "NO CHASE", "#FF9100")

-- Blocked setups (first bar of a streak)
if show_block then
    local X, T = shape_style.xcross, shape_size.tiny
    local cb, cs = BLOCK_NEW and BLOCK_SIDE == 1, BLOCK_NEW and BLOCK_SIDE == -1
    local sr = BLOCK == "RESISTANCE" or BLOCK == "SUPPORT"
    local vol = BLOCK == "VOLATILITY" or BLOCK == "LOW-VOL"
    plot_shape (cb and BLOCK == "LATE", "CALL blocked: late", X, T, note_color, BB, 0, "X:LATE", note_color)
    plot_shape (cb and sr, "CALL blocked: S/R", X, T, note_color, BB, 0, "X:SR", note_color)
    plot_shape (cb and BLOCK == "SIDEWAYS", "CALL blocked: sideways", X, T, note_color, BB, 0, "X:SIDE", note_color)
    plot_shape (cb and vol, "CALL blocked: volatility", X, T, note_color, BB, 0, "X:VOL", note_color)
    plot_shape (cs and BLOCK == "LATE", "PUT blocked: late", X, T, note_color, AB, 0, "X:LATE", note_color)
    plot_shape (cs and sr, "PUT blocked: S/R", X, T, note_color, AB, 0, "X:SR", note_color)
    plot_shape (cs and BLOCK == "SIDEWAYS", "PUT blocked: sideways", X, T, note_color, AB, 0, "X:SIDE", note_color)
    plot_shape (cs and vol, "PUT blocked: volatility", X, T, note_color, AB, 0, "X:VOL", note_color)
end
