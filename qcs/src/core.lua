-- =====================================================================
--  XAUUSD SMART ENTRY V3 — PRECISION FAST ENTRY (M1, 1-minute expiry)
--  Shared core for the Main and Panel scripts. Quadcode Script (Lua 5.3).
--  Rules: docs/FAST_ENTRY_CONFIG.md
--  * Decisions use CLOSED candles only ([1] and older): signals never repaint.
--  * State lives in make_series written from its own [1] value (tick-safe).
--  * NO_CHASE reads the live candle and is only a warning, never an input.
-- =====================================================================
input_group {
    "Trend (EMA)",
    ema_fast_len  = input (9,    "EMA Fast",   input.integer, 1, 200),
    ema_mid_len   = input (21,   "EMA Medium", input.integer, 1, 300),
    ema_slow_len  = input (50,   "EMA Slow",   input.integer, 1, 500),
    slope_min     = input (0.02, "EMA50 min slope (ATR per bar)", input.double, 0, 1, 0.005),
    strong_spread = input (1.0,  "Strong trend: EMA9-EMA50 > ATR x", input.double, 0, 10, 0.1)
}
input_group {
    "Momentum (RSI / MACD)",
    rsi_len       = input (14, "RSI Period", input.integer, 2, 100),
    rsi_ext_high  = input (78, "RSI CALL block", input.double, 55, 100, 1),
    rsi_ext_low   = input (22, "RSI PUT block",  input.double, 0, 45, 1),
    macd_fast_len = input (12, "MACD Fast",   input.integer, 1, 100),
    macd_slow_len = input (26, "MACD Slow",   input.integer, 2, 200),
    macd_sig_len  = input (9,  "MACD Signal", input.integer, 1, 100)
}
input_group {
    "Volatility",
    bb_len        = input (20,   "BB Period",    input.integer, 2, 200),
    bb_mult       = input (2.0,  "BB Deviation", input.double, 0.5, 5, 0.1),
    atr_len       = input (14,   "ATR Period",   input.integer, 1, 100),
    atr_base_len  = input (100,  "ATR Baseline", input.integer, 10, 500),
    squeeze_ratio = input (0.75, "Squeeze: BB width < avg x",   input.double, 0.1, 1.5, 0.05),
    flat_atr      = input (0.25, "Flat: EMA21 3-bar move < ATR x", input.double, 0, 2, 0.05),
    spike_mult    = input (2.8,  "Spike: range > ATR x",        input.double, 1, 10, 0.1),
    hot_ratio     = input (1.9,  "Hot: ATR > baseline x",       input.double, 1, 5, 0.1),
    hot_exit      = input (1.5,  "Hot stays while ATR > baseline x", input.double, 1, 5, 0.1),
    cold_ratio    = input (0.5,  "Cold: ATR < baseline x",      input.double, 0.1, 1, 0.05),
    er_len        = input (20,   "Sideways: efficiency ratio period", input.integer, 5, 100),
    er_side       = input (0.15, "Sideways: efficiency ratio <", input.double, 0, 1, 0.01),
    side_confirm  = input (2,    "Sideways change confirm (bars)", input.integer, 1, 10)
}
input_group {
    "Support / Resistance",
    pivot_len    = input (5,   "Pivot (bars each side)", input.integer, 2, 20),
    range_len    = input (50,  "Range lookback",         input.integer, 10, 300),
    min_room_atr = input (0.8, "Min SR distance (ATR x)", input.double, 0, 5, 0.1)
}
input_group {
    "Signal Filter",
    min_score     = input (70,   "Min confidence", input.integer, 60, 95),
    cooldown_bars = input (2,    "Cooldown (bars)", input.integer, 0, 50),
    late_body_atr = input (2.0,  "Late body > ATR x", input.double, 0.5, 10, 0.1),
    max_ext_atr   = input (2.2,  "Late distance > ATR x", input.double, 0.5, 10, 0.1),
    chase_atr     = input (0.35, "No chase: live move > ATR x", input.double, 0.05, 5, 0.05),
    exhaust_run   = input (5,    "Exhaustion: same-colour candles", input.integer, 3, 12)
}
input_group {
    "Entry Types",
    use_momentum = input (true, "Momentum Entry", input.boolean),
    use_pullback = input (true, "Pullback Entry", input.boolean),
    pb_zone      = input (0.3,  "Pullback zone: EMA9 + ATR x", input.double, 0, 2, 0.05),
    pb_bars      = input (3,    "Pullback lookback (bars)", input.integer, 1, 6)
}

-- ----------------------------- SERIES ---------------------------------
ema_f = ema (close, ema_fast_len)
ema_m = ema (close, ema_mid_len)
ema_s = ema (close, ema_slow_len)
rsi_val = rsi (close, rsi_len)
macd_fast_ma = ema (close, macd_fast_len)
macd_slow_ma = ema (close, macd_slow_len)
macd_line = macd_fast_ma - macd_slow_ma
macd_sig = ema (macd_line, macd_sig_len)
macd_hist = macd_line - macd_sig
bb_mid = sma (close, bb_len)
bb_dev = stdev (close, bb_len) * bb_mult
bb_width = (2 * bb_dev) / bb_mid
bb_width_avg = sma (bb_width, bb_len * 3)
atr_val = rma (tr, atr_len)
atr_base = sma (atr_val, atr_base_len)
er_val = abs (change (close, er_len)) / sum (abs (change (close)), er_len)
clv = (close - low) / max (high - low, 0.0000001)
clv_avg = sma (clv, 5)
piv_hp = highest (high, pivot_len)
piv_lp = lowest (low, pivot_len)
rng_hi = highest (high, range_len)
rng_lo = lowest (low, range_len)

local function num (s, d)
    local v = get_value (s)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return d end
    return v
end
local function clamp (x, a, b) if x < a then return a elseif x > b then return b end return x end

-- Confirmed pivots: strictly beyond the p bars on the left, not exceeded by the p
-- closed bars on the right (one pivot per plateau). Two-deep tick-safe memory.
local function pivot (ser, w, sgn)
    local x, l, r = num (ser[pivot_len + 1]), num (w[pivot_len + 2]), num (w[1])
    if x and l and r and sgn * x > sgn * l and sgn * x >= sgn * r then return x end
end
local function remember (s1, s2, new)
    local p1, p2 = num (s1[1]), num (s2[1])
    if new ~= nil then s1:set (new); if p1 then s2:set (p1) end
    else if p1 then s1:set (p1) end; if p2 then s2:set (p2) end end
end
res1 = make_series ()
res2 = make_series ()
sup1 = make_series ()
sup2 = make_series ()
remember (res1, res2, pivot (high, piv_hp, 1))
remember (sup1, sup2, pivot (low, piv_lp, -1))

bar_count = make_series ()
bar_count:set (num (bar_count[1], 0) + 1)
sig_age = make_series ()
side_state = make_series ()
hv_state = make_series ()
side_run = make_series ()

-- ------------------------ CLOSED-CANDLE SNAPSHOT ----------------------
local O1, H1, L1, C1 = num (open[1]), num (high[1]), num (low[1]), num (close[1])
local O2, H2, L2, C2 = num (open[2]), num (high[2]), num (low[2]), num (close[2])
local EF1, EF2, EM1, EM2 = num (ema_f[1]), num (ema_f[2]), num (ema_m[1]), num (ema_m[2])
local EM4, ES1, ES6 = num (ema_m[4]), num (ema_s[1]), num (ema_s[6])
local R1, R2 = num (rsi_val[1]), num (rsi_val[2])
local HI1, HI2, HI3 = num (macd_hist[1]), num (macd_hist[2]), num (macd_hist[3])
local ATR1, ATR2, ATRB1 = num (atr_val[1]), num (atr_val[2]), num (atr_base[1])
local BW1, BWA1, CLV1 = num (bb_width[1]), num (bb_width_avg[1]), num (clv_avg[1], 0.5)
local ER1 = num (er_val[1], 0)
local RES1, RES2, SUP1, SUP2 = num (res1), num (res2), num (sup1), num (sup2)
local RHI2, RLO2 = num (rng_hi[2]), num (rng_lo[2])
local warm = math.max (ema_slow_len, range_len, atr_base_len, bb_len * 3) + 2 * pivot_len + 5
local data_ok = (num (bar_count, 0) > warm and O1 and H1 and L1 and C1 and O2 and H2 and L2 and C2
    and EF1 and EF2 and EM1 and EM2 and EM4 and ES1 and ES6 and R1 and R2 and HI1 and HI2 and HI3
    and ATR1 and ATR2 and ATRB1 and BW1 and BWA1 and ATR1 > 0 and ATR2 > 0 and ATRB1 > 0 and BWA1 > 0)
    and true or false

-- ------------------------------ OUTPUTS -------------------------------
SIG_DIR, SIG_SCORE, SIG_SETUP, SIG_TRIG = 0, 0, "", ""   -- signal of this bar
SIG_STATE = 0          -- 2 CALL, -2 PUT, 1 CALL READY, -1 PUT READY, 3 EXPIRED, 4 BLOCKED, 0 WAIT
BLOCK, BLOCK_SIDE, BLOCK_NEW = "", 0, false
BULL_SCORE, BEAR_SCORE, RAW_SCORE = 0, 0, 0
SC_TREND, SC_MOM, SC_PA, SC_LOC, SC_VOL, SC_STRUCT, SC_PEN = 0, 0, 0, 0, 0, 0, 0
TREND_STATE = 0        -- 2/1 strong/weak up, -1/-2 weak/strong down, 0 sideways, 5 transition
MARKET = 0             -- 1 trend, 2 sideways, 3 high vol, 4 low vol, 5 exhaustion, 6 reversal, 0 transition
MOM_STATE = 0          -- 2 accel up, 1 bullish, -1 bearish, -2 accel down, 0 neutral
MOM_WEAK = false
ATR_RATIO, ROOM_ATR, LOC_ATR, COOL_LEFT = 0, 0, 0, 0
NO_CHASE = false

-- --------------------------- MARKET STATE -----------------------------
local prev_side, prev_run = num (side_state[1], 0), num (side_run[1], 0)
local sideways = prev_side == 1
local high_vol, low_vol = false, false
if data_ok then
    -- V1 rule (flat EMA21 + squeeze/tangle) OR choppy path with a flat EMA50
    local raw = (math.abs (EM1 - EM4) < flat_atr * ATR2
        and (BW1 < BWA1 * squeeze_ratio or math.abs (EF1 - ES1) < 0.3 * ATR2))
        or (ER1 < er_side and math.abs (ES1 - ES6) / (5 * ATR2) < 2 * slope_min)
    local run = ((raw and 1 or 0) ~= prev_side) and (prev_run + 1) or 0
    if run >= side_confirm then prev_side, run = (raw and 1 or 0), 0 end
    sideways = prev_side == 1
    side_state:set (prev_side); side_run:set (run)
    -- enter at hot_ratio (or a spike candle); stay while ATR is still above hot_exit
    high_vol = (H1 - L1) > spike_mult * ATR2 or ATR1 > hot_ratio * ATRB1
        or (num (hv_state[1], 0) == 1 and ATR1 > math.min (hot_exit, hot_ratio) * ATRB1)
    hv_state:set (high_vol and 1 or 0)
    low_vol = ATR1 < cold_ratio * ATRB1
    ATR_RATIO = ATR1 / ATRB1
else
    side_state:set (prev_side); side_run:set (prev_run); hv_state:set (num (hv_state[1], 0))
end

-- ---------------------- SIDE-NEUTRAL EVALUATION -----------------------
-- s = 1 CALL, s = -1 PUT. PUT mirrors prices (x -> -x), RSI (100 - r), MACD (-h).
local function evaluate (s)
    local function px (x) return x and s * x end
    local o1, c1, o2, c2 = s * O1, s * C1, s * O2, s * C2
    local h1, l1 = (s == 1) and H1 or -L1, (s == 1) and L1 or -H1
    local h2, l2 = (s == 1) and H2 or -L2, (s == 1) and L2 or -H2
    local ef1, em1, em2, es1, es6 = s * EF1, s * EM1, s * EM2, s * ES1, s * ES6
    local r1, r2 = (s == 1) and R1 or 100 - R1, (s == 1) and R2 or 100 - R2
    local hi1, hi2, hi3 = s * HI1, s * HI2, s * HI3
    local rext = (s == 1) and rsi_ext_high or 100 - rsi_ext_low
    local swing_lo = px ((s == 1) and SUP1 or RES1)
    local swing_lo2 = px ((s == 1) and SUP2 or RES2)
    local swing_hi = px ((s == 1) and RES1 or SUP1)
    local range_hi = px ((s == 1) and RHI2 or RLO2)
    local atr = ATR2
    local r = { side = s, score = 0, raw = 0, setup = "", trig = "", reason = "", bias = false, ready = false }

    -- trend
    local slope = (es1 - es6) / (5 * atr)
    local up = ef1 > em1 and em1 > es1 and c1 > es1 and slope > slope_min
    local strong = up and (ef1 - es1) / atr >= strong_spread and slope >= 2 * slope_min
    r.up, r.strong = up, strong

    -- candle geometry
    local rng1, rng2 = math.max (h1 - l1, 1e-7), math.max (h2 - l2, 1e-7)
    local body1, body2 = math.abs (c1 - o1), math.abs (c2 - o2)
    local upw1, loww1 = h1 - math.max (c1, o1), math.min (c1, o1) - l1
    local loww2, cpos1 = math.min (c2, o2) - l2, (c1 - l1) / rng1

    -- room to the nearest obstacle ahead
    local room = 99
    for _, x in ipairs ({ px ((s == 1) and RES1 or SUP1), px ((s == 1) and RES2 or SUP2), range_hi }) do
        if x and x > c1 then room = math.min (room, (x - c1) / atr) end
    end
    local function at_level (lp, e)
        return lp <= e + 0.15 * atr or (swing_lo ~= nil and lp <= swing_lo + 0.25 * atr)
    end

    -- pullback inside the trend: touch of the EMA9 zone in the last pb_bars,
    -- after a counter-trend candle, never closing beyond EMA50
    local touched, counter, inside, depth_lo, depth_hi = false, false, true, 1e18, -1e18
    for i = 1, pb_bars do
        local o, c = s * num (open[i], 0), s * num (close[i], 0)
        local lo = (s == 1) and num (low[i], 0) or -num (high[i], 0)
        local hi = (s == 1) and num (high[i], 0) or -num (low[i], 0)
        local e9, e50 = s * num (ema_f[i], 0), s * num (ema_s[i], 0)
        if lo <= e9 + pb_zone * atr then touched = true end
        if c < o then counter = true end
        if c <= e50 then inside = false end
        depth_lo = math.min (depth_lo, lo)
        depth_hi = math.max (depth_hi, hi)
    end
    local depth = (depth_hi - depth_lo) / atr

    -- price-action triggers (minimum size enforced, ATR before the candle)
    local pa, trig = 0, ""
    local function take (p, t) if p > pa then pa, trig = p, t end end
    if c1 > o1 and c2 < o2 and c1 >= o2 and o1 <= c2 and body1 >= 1.2 * body2
       and body2 >= 0.15 * atr and body1 >= 0.4 * atr and cpos1 >= 0.7 then take (20, "ENGULF") end
    if swing_lo and l1 < swing_lo - 0.1 * atr and c1 > swing_lo and loww1 >= 0.5 * rng1 and cpos1 >= 0.6 then
        take (18, "FALSE-BRK") end
    if loww2 >= 0.5 * rng2 and rng2 >= 0.5 * atr and at_level (l2, em2) and c1 > o1
       and c1 > math.max (o2, c2) and cpos1 >= 0.6 then take (17, "REJECT") end
    if loww1 >= 2 * body1 and loww1 >= 0.6 * rng1 and upw1 <= 0.25 * rng1 and rng1 >= 0.6 * atr
       and (at_level (l1, em1) or l1 <= ef1 + pb_zone * atr) then take (15, "PIN") end
    if swing_hi and c1 > swing_hi + 0.15 * atr and c2 <= swing_hi and c1 > o1 and body1 >= 0.55 * rng1
       and cpos1 >= 0.75 and body1 <= 2.0 * atr then take (15, "BREAKOUT") end
    if touched and counter and c1 > o1 and c1 > ef1 and body1 >= 0.3 * atr and cpos1 >= 0.6 then
        take (12, "RESUME") end
    if c1 > o1 and body1 >= 0.6 * rng1 and cpos1 >= 0.75 and body1 >= 0.4 * atr and body1 <= 1.5 * atr then
        take (10, "MOMENTUM") end

    -- momentum states
    local accel = hi1 > 0 and hi1 > hi2 and r1 > r2
    local weak = hi1 < hi2 and hi2 < hi3
    local exhaust, run = r1 > rext, 0
    for i = 1, exhaust_run + 1 do
        local o, c = num (open[i]), num (close[i])
        if o == nil or c == nil or s * (c - o) <= 0 then break end
        run = run + 1
    end
    if run >= exhaust_run or (range_hi and h1 >= range_hi and upw1 >= 0.4 * rng1) then exhaust = true end
    r.accel, r.weak, r.exhaust = accel, weak, exhaust
    r.reversal = em1 > es1 and swing_lo ~= nil and c1 < swing_lo

    -- one evaluation per setup type; returns score parts and first failed rule
    local clv_side = (s == 1) and CLV1 or 1 - CLV1
    local function setup (kind)
        local pb = kind == "PULLBACK"
        local okset = pb and (trig == "REJECT" or trig == "PIN" or trig == "ENGULF" or trig == "RESUME")
            or (not pb and (trig == "ENGULF" or trig == "BREAKOUT" or trig == "MOMENTUM" or trig == "FALSE-BRK"))
        local ref = pb and ef1 or em1                       -- late distance reference EMA
        local ext = (c1 - ref) / atr
        local t = 10 * ((ef1 > em1 and em1 > es1) and 1 or (em1 > es1 and 0.5 or 0))
            + 8 * clamp (slope / (3 * math.max (slope_min, 1e-4)), 0, 1) + (strong and 7 or (up and 3 or 0))
        local m = pb and 8 * clamp ((r1 - 45) / 20, 0, 1) or 8 * clamp ((r1 - 50) / 15, 0, 1)
        if accel then m = m + 12 elseif hi1 > 0 then m = m + 6 elseif pb and hi1 > hi2 then m = m + 8 end
        local p = okset and pa or 0
        local loc = 10 * clamp ((room - min_room_atr) / 2, 0, 1)
            + 10 * (1 - clamp ((ext - 0.5) / math.max (max_ext_atr - 0.5, 0.1), 0, 1))
        local v = 10 * (1 - clamp (math.abs (math.log (ATR1 / ATRB1)) / math.log (1.9), 0, 1))
        local st = ((swing_lo and swing_lo2 and swing_lo > swing_lo2) and 3 or 0) + ((swing_hi and c1 > swing_hi) and 2 or 0)
        local pen = (clv_side < 0.45 and 5 or 0) + (upw1 >= 0.35 * rng1 and 6 or 0) + ((not pb and r1 < r2) and 5 or 0)
        local raw = t + m + p + loc + v + st
        local x = { kind = kind, raw = math.floor (raw + 0.5), score = math.floor (clamp (raw - pen, 0, 100) + 0.5),
                    t = t, m = m, p = p, loc = loc, v = v, st = st, pen = pen, ext = ext, trig = okset and trig or "" }
        local why = ""
        if not data_ok then why = "WARMUP"
        elseif high_vol then why = "VOLATILITY"
        elseif low_vol then why = "LOW-VOL"
        elseif sideways then why = "SIDEWAYS"
        elseif not (pb and use_pullback or (not pb and use_momentum)) then why = "OFF"
        elseif pb and not (em1 > es1 and ef1 > es1 and c1 > ef1 and slope > slope_min) then why = "NO-TREND"
        elseif not pb and not up then why = "NO-TREND"
        elseif r.reversal then why = "REVERSAL"
        elseif pb and not (touched and counter and inside and depth >= 0.4) then why = "NO-PULLBACK"
        elseif pb and not (hi1 > hi2 and r1 > r2 and r1 > 45) then why = "CONFLICT"
        elseif not pb and not (hi1 > 0 and r1 > 50) then why = "CONFLICT"
        elseif not pb and weak then why = "WEAK-MOM"
        elseif exhaust then why = "EXHAUST"
        elseif not okset or cpos1 < 0.6 then why = "NO-PA"
        elseif body1 > late_body_atr * atr or ext > max_ext_atr then why = "LATE"
        elseif room < min_room_atr then why = (s == 1) and "RESISTANCE" or "SUPPORT"
        elseif x.score < min_score then why = "LOW-CONFIDENCE"
        end
        x.reason = why
        return x
    end
    local a, b = setup ("MOMENTUM"), setup ("PULLBACK")
    local best
    if a.reason == "" and b.reason == "" then best = (a.score >= b.score) and a or b
    elseif a.reason == "" then best = a
    elseif b.reason == "" then best = b
    elseif b.trig ~= "" and (a.trig == "" or b.score > a.score) then best = b   -- for display only
    else best = a end
    r.best, r.room, r.bias = best, room, up or (em1 > es1 and slope > slope_min)
    r.ready = data_ok and not high_vol and not low_vol and not sideways and r.bias and not exhaust
        and touched and trig == "" and hi1 > hi2 and room >= min_room_atr
    return r
end

-- ------------------------------ DECISION ------------------------------
local prev_age = num (sig_age[1], 999)
COOL_LEFT = math.max (cooldown_bars - prev_age, 0)
if data_ok then
    local bull, bear = evaluate (1), evaluate (-1)
    BULL_SCORE, BEAR_SCORE = bull.best.score, bear.best.score
    if sideways then TREND_STATE = 0
    elseif bull.up then TREND_STATE = bull.strong and 2 or 1
    elseif bear.up then TREND_STATE = bear.strong and -2 or -1
    else TREND_STATE = 5 end
    if high_vol then MARKET = 3 elseif low_vol then MARKET = 4 elseif sideways then MARKET = 2
    elseif (bull.bias and bull.exhaust) or (bear.bias and bear.exhaust) then MARKET = 5
    elseif bull.reversal or bear.reversal then MARKET = 6
    elseif bull.up or bear.up then MARKET = 1 end
    if bull.accel then MOM_STATE = 2 elseif bear.accel then MOM_STATE = -2
    elseif HI1 > 0 and R1 > 50 then MOM_STATE = 1 elseif HI1 < 0 and R1 < 50 then MOM_STATE = -1 end
    MOM_WEAK = (HI1 > 0 and bull.weak) or (HI1 < 0 and bear.weak)

    local pick = nil
    if bull.best.reason == "" then pick = bull elseif bear.best.reason == "" then pick = bear end
    local shown = pick or ((bull.best.score >= bear.best.score) and bull or bear)
    local b = shown.best
    RAW_SCORE, SC_TREND, SC_MOM, SC_PA, SC_LOC, SC_VOL, SC_STRUCT, SC_PEN = b.raw, b.t, b.m, b.p, b.loc, b.v, b.st, b.pen
    ROOM_ATR, LOC_ATR = shown.room, b.ext
    if pick and prev_age < cooldown_bars then
        BLOCK, BLOCK_SIDE, pick = "COOLDOWN", pick.side, nil
    end
    if pick then
        SIG_DIR, SIG_SCORE, SIG_SETUP, SIG_TRIG = pick.side, pick.best.score, pick.best.kind, pick.best.trig
        SIG_STATE = 2 * pick.side
    else
        -- report a block only for a complete would-be setup (trend + valid trigger)
        for _, x in ipairs ({ bull, bear }) do
            local y = x.best
            if BLOCK == "" and x.bias and y.trig ~= "" and y.reason ~= "" and y.reason ~= "OFF"
               and (y.score >= min_score or (y.reason == "LOW-CONFIDENCE" and y.score >= min_score - 10)) then
                BLOCK, BLOCK_SIDE = y.reason, x.side
            end
        end
        if BLOCK ~= "" then SIG_STATE = 4
        elseif prev_age == 0 then SIG_STATE = 3
        elseif bull.ready then SIG_STATE = 1
        elseif bear.ready then SIG_STATE = -1 end
    end
    if SIG_DIR ~= 0 then
        local o0, c0 = num (open), num (close)
        NO_CHASE = o0 ~= nil and c0 ~= nil and SIG_DIR * (c0 - o0) > chase_atr * ATR1
    end
end
sig_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)

-- show a block marker only on the first bar of a streak
local CODES = { SIDEWAYS = 1, LATE = 2, RESISTANCE = 3, SUPPORT = 3, ["LOW-CONFIDENCE"] = 4, VOLATILITY = 5,
                ["LOW-VOL"] = 5, EXHAUST = 6, REVERSAL = 7, CONFLICT = 8, ["WEAK-MOM"] = 8, COOLDOWN = 9,
                ["NO-PA"] = 10, ["NO-PULLBACK"] = 10, ["NO-TREND"] = 10 }
block_code = make_series ()
BLOCK_CODE = (CODES[BLOCK] or 0) * BLOCK_SIDE
block_code:set (BLOCK_CODE)
BLOCK_NEW = BLOCK_CODE ~= 0 and BLOCK_CODE ~= num (block_code[1], 0)
