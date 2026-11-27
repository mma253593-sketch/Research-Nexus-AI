-- =====================================================================
--  XAUUSD Smart Entry V2.0 — default configuration (data only).
--  Every value is validated by src/config.lua (type, bounds and
--  cross-field rules). Distances are in ATR units unless stated.
--  Defaults are conventional / stability-driven; NONE were fitted to win
--  rate (no verified real XAUUSD data was available — see README).
-- =====================================================================
return {
    version    = "2.0.0",
    instrument = "XAUUSD",

    data = {
        m1_period          = 60,     -- seconds per M1 candle
        m5_period          = 300,    -- seconds per M5 candle
        m1_window          = 240,    -- closed M1 candles analysed per evaluation
        min_m1_bars        = 200,    -- minimum contiguous closed M1 history
        min_m5_bars        = 30,     -- minimum closed M5 candles for context
        m5_min_minutes     = 4,      -- an aggregated M5 bucket needs >= this many M1 candles
        max_staleness_sec  = 60,     -- now - close time of the last closed M1 must be < this
        max_gap_candles    = 3,      -- a gap of more missing M1 candles resets history
        max_missing_ratio  = 0.02,   -- missing M1 candles / window allowed
        dedupe_identical   = true,   -- identical duplicates are dropped (with a warning)
        m5_tolerance_rel   = 0.0005, -- provided M5 vs M1-aggregate OHLC tolerance (relative)
        m5_source          = "auto", -- "auto" | "provided" | "aggregate"
    },

    indicators = {
        ema_fast = 9, ema_mid = 21, ema_slow = 50,
        atr_len = 14, atr_base_len = 100,
        rsi_len = 14, er_len = 20,
        macd_fast = 12, macd_slow = 26, macd_signal = 9,
        m5_ema_fast = 8, m5_ema_slow = 21,
        pivot_len = 3,      -- swing pivot: strictly beyond `p` bars left, >= `p` closed bars right
        max_levels = 6,     -- most recent swing levels kept per side
    },

    regime = {
        hv_atr_ratio     = 1.8,   -- ATR / baseline ATR >= this -> HIGH_VOL
        lv_atr_ratio     = 0.5,   -- ATR / baseline ATR <= this -> LOW_VOL
        er_trend         = 0.30,  -- efficiency ratio >= this (plus slope + stack) -> TRENDING
        er_range         = 0.18,  -- efficiency ratio <= this (plus flat slope) -> RANGING
        slope_min        = 0.03,  -- |EMA50 slope| in ATR per bar
        whipsaw_lookback = 20,
        whipsaw_crosses  = 4,     -- EMA9/EMA21 crosses in lookback >= this -> UNSTABLE
        confirm_bars     = 2,     -- raw regime must repeat this many bars (HIGH_VOL immediate)
    },

    volatility = {
        abnormal_range_atr = 3.0,  -- last candle range > x ATR(before it) -> reject
        expansion_ratio    = 1.6,  -- ATR now / ATR k bars ago > x -> reject
        expansion_lookback = 5,
        flat_range_atr     = 0.05, -- candle range < x ATR counts as "flat"
        flat_lookback      = 10,
        max_flat_candles   = 3,    -- more flat candles than this -> low information
        min_atr_price      = 0.05, -- absolute ATR floor (USD); below -> no information
        noise_er           = 0.12,
        noise_wick_share   = 0.62, -- mean wick share of last 10 candles (with low ER) -> noise
    },

    momentum = {
        exhaust_rsi_high = 76,
        exhaust_rsi_low  = 24,
        exhaust_run      = 5,     -- consecutive same-direction candles
        climax_body_atr  = 2.5,
        div_min_rsi      = 3.0,   -- RSI gap required for a divergence
        div_max_age      = 15,    -- newest swing of the divergence within this many bars
        hist_strong_atr  = 0.15,  -- |MACD hist| / ATR at which strength saturates
    },

    price_action = {
        engulf_min_body_atr = 0.35,
        pin_wick_ratio      = 0.6,
        breakout_buffer_atr = 0.10,
        level_touch_atr     = 0.25,
        strong_close        = 0.70, -- close location in candle (0 low .. 1 high)
        range_lookback      = 30,
    },

    entry = {
        late_move_atr        = 2.5,  -- net move of the last 3 closed candles > x -> late
        max_trigger_body_atr = 1.8,
        breakout_max_ext_atr = 1.0,  -- close beyond the broken level > x -> late
        pullback_lookback    = 4,
        pullback_zone_atr    = 0.3,
        room_cap_atr         = 5.0,  -- room reported when no obstacle is known
    },

    profiles = {
        TRENDING = {
            setups       = { "PULLBACK_CONTINUATION", "TREND_CONTINUATION", "BREAKOUT_CONFIRMATION" },
            min_score    = 65,
            min_room_atr = 0.8,
            max_ext_atr  = 2.0,
        },
        RANGING = {
            setups       = { "RANGE_REJECTION", "BREAKOUT_CONFIRMATION" },
            min_score    = 70,
            min_room_atr = 1.0,
            max_ext_atr  = 1.5,
        },
    },

    scoring = {
        global_min_score     = 60,  -- floor: no profile may go below
        min_margin           = 15,  -- winning side must beat the other side by this
        m5_conflict_penalty  = 12,
        m5_block_strength    = 0.6, -- opposite M5 with strength >= this blocks continuation
        divergence_penalty   = 8,
        decel_penalty        = 5,
        wick_penalty         = 6,
    },

    runner = {
        cooldown_bars = 2,          -- suppress new signals for this many bars after one
    },
}
