
-- =====================================================================
--  MAIN CHART VIEW  (overlay): EMA, S/R, arrows, triggers, cancel codes
-- =====================================================================
input_group {
    "Display - Lines",
    show_ema     = input { default = true, type = input.plot_visibility },
    ema_f_color  = input { default = "#FFD54F", type = input.color },
    ema_m_color  = input { default = "#29B6F6", type = input.color },
    ema_s_color  = input { default = "#AB47BC", type = input.color },
    show_sr      = input { default = true, type = input.plot_visibility },
    res_color    = input { default = rgba(255,82,82,0.85), type = input.color },
    sup_color    = input { default = rgba(0,230,118,0.85), type = input.color },
    show_range   = input { default = false, type = input.plot_visibility },
    range_color  = input { default = rgba(255,255,255,0.35), type = input.color },
    show_bb      = input { default = false, type = input.plot_visibility },
    bb_color     = input { default = rgba(120,144,156,0.6), type = input.color }
}

input_group {
    "Display - Signals",
    call_color    = input { default = "#00E676", type = input.color },
    put_color     = input { default = "#FF1744", type = input.color },
    show_trigger  = input { default = true, type = input.plot_visibility },
    show_cancel   = input { default = true, type = input.plot_visibility },
    show_cancel_m = input { default = false, type = input.plot_visibility },
    cancel_color  = input { default = rgba(255,193,7,0.9), type = input.color },
    chase_color   = input { default = "#FF9100", type = input.color }
}

-- ------------------------------ LINES ---------------------------------
if show_ema then
    plot (ema_f, "EMA 9",  ema_f_color, 1)
    plot (ema_m, "EMA 21", ema_m_color, 2)
    plot (ema_s, "EMA 50", ema_s_color, 2)
end

if show_sr then
    plot (res_lvl, "Resistance", res_color, 2)
    plot (sup_lvl, "Support",    sup_color, 2)
end

if show_range then
    plot (rng_hi, "Range High", range_color, 1)
    plot (rng_lo, "Range Low",  range_color, 1)
end

if show_bb then
    plot (bb_up, "BB Upper", bb_color, 1)
    plot (bb_lo, "BB Lower", bb_color, 1)
end

-- ----------------------------- SIGNALS --------------------------------
-- Arrow = ENTRY candle (enter at its open). Dot = CONFIRMATION candle.
local call_on = SIG_DIR == 1
local put_on  = SIG_DIR == -1

plot_shape (call_on and SIG_SCORE >= 85, "CALL Strong", shape_style.arrowup,
            shape_size.huge, call_color, shape_location.belowbar, 0, "CALL 85+", call_color)
plot_shape (call_on and SIG_SCORE >= 70 and SIG_SCORE < 85, "CALL Good", shape_style.arrowup,
            shape_size.large, call_color, shape_location.belowbar, 0, "CALL 70+", call_color)
plot_shape (call_on and SIG_SCORE < 70, "CALL Weak", shape_style.arrowup,
            shape_size.normal, call_color, shape_location.belowbar, 0, "CALL 60+", call_color)

plot_shape (put_on and SIG_SCORE >= 85, "PUT Strong", shape_style.arrowdown,
            shape_size.huge, put_color, shape_location.abovebar, 0, "PUT 85+", put_color)
plot_shape (put_on and SIG_SCORE >= 70 and SIG_SCORE < 85, "PUT Good", shape_style.arrowdown,
            shape_size.large, put_color, shape_location.abovebar, 0, "PUT 70+", put_color)
plot_shape (put_on and SIG_SCORE < 70, "PUT Weak", shape_style.arrowdown,
            shape_size.normal, put_color, shape_location.abovebar, 0, "PUT 60+", put_color)

-- Confirmation candle marker + trigger name (drawn one bar back)
if show_trigger then
    plot_shape (call_on and SIG_TRIG == "ENGULF",    "CALL Engulfing", shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "ENGULF",    call_color)
    plot_shape (call_on and SIG_TRIG == "FALSE-BRK", "CALL False BO",  shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "FALSE-BRK", call_color)
    plot_shape (call_on and SIG_TRIG == "PIN",       "CALL Pin Bar",   shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "PIN",       call_color)
    plot_shape (call_on and SIG_TRIG == "REJECT",    "CALL Rejection", shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "REJECT",    call_color)
    plot_shape (call_on and SIG_TRIG == "BREAKOUT",  "CALL Breakout",  shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "BREAKOUT",  call_color)
    plot_shape (call_on and SIG_TRIG == "MOMENTUM",  "CALL Momentum",  shape_style.circle, shape_size.tiny, call_color, shape_location.belowbar, -1, "MOMENTUM",  call_color)

    plot_shape (put_on and SIG_TRIG == "ENGULF",    "PUT Engulfing", shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "ENGULF",    put_color)
    plot_shape (put_on and SIG_TRIG == "FALSE-BRK", "PUT False BO",  shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "FALSE-BRK", put_color)
    plot_shape (put_on and SIG_TRIG == "PIN",       "PUT Pin Bar",   shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "PIN",       put_color)
    plot_shape (put_on and SIG_TRIG == "REJECT",    "PUT Rejection", shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "REJECT",    put_color)
    plot_shape (put_on and SIG_TRIG == "BREAKOUT",  "PUT Breakout",  shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "BREAKOUT",  put_color)
    plot_shape (put_on and SIG_TRIG == "MOMENTUM",  "PUT Momentum",  shape_style.circle, shape_size.tiny, put_color, shape_location.abovebar, -1, "MOMENTUM",  put_color)
end

-- Live advisory on the entry candle: price already ran -> do not chase
plot_shape (call_on and NO_CHASE, "CALL No Chase", shape_style.xcross, shape_size.small,
            chase_color, shape_location.abovebar, 0, "NO CHASE", chase_color)
plot_shape (put_on and NO_CHASE, "PUT No Chase", shape_style.xcross, shape_size.small,
            chase_color, shape_location.belowbar, 0, "NO CHASE", chase_color)

-- --------------------------- CANCELLED (WAIT) -------------------------
-- Shown when a complete setup existed (trend + price-action trigger +
-- score >= threshold) but a hard filter forced WAIT. Code = the reason.
-- Only the first bar of a streak is marked.
local cb = WAIT_NEW and WAIT_SIDE == 1
local cs = WAIT_NEW and WAIT_SIDE == -1

if show_cancel_m then
    plot_shape (cb and WAIT_REASON == "OVEREXT",  "WAIT CALL overextended",shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:RSI",   cancel_color)
    plot_shape (cb and WAIT_REASON == "CONFLICT", "WAIT CALL conflict",    shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:CONF",  cancel_color)
    plot_shape (cs and WAIT_REASON == "OVEREXT",  "WAIT PUT overextended", shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:RSI",   cancel_color)
    plot_shape (cs and WAIT_REASON == "CONFLICT", "WAIT PUT conflict",     shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:CONF",  cancel_color)
end

if show_cancel then
    plot_shape (cb and WAIT_REASON == "NEAR-SR",  "WAIT CALL near S/R",    shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:SR",    cancel_color)
    plot_shape (cb and WAIT_REASON == "SIDEWAYS", "WAIT CALL sideways",    shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:SIDE",  cancel_color)
    plot_shape (cb and WAIT_REASON == "VOLATILE", "WAIT CALL volatility",  shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:VOL",   cancel_color)
    plot_shape (cb and WAIT_REASON == "LATE",     "WAIT CALL late",        shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:LATE",  cancel_color)

    plot_shape (cs and WAIT_REASON == "NEAR-SR",  "WAIT PUT near S/R",     shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:SR",    cancel_color)
    plot_shape (cs and WAIT_REASON == "SIDEWAYS", "WAIT PUT sideways",     shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:SIDE",  cancel_color)
    plot_shape (cs and WAIT_REASON == "VOLATILE", "WAIT PUT volatility",   shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:VOL",   cancel_color)
    plot_shape (cs and WAIT_REASON == "LATE",     "WAIT PUT late",         shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:LATE",  cancel_color)
end
