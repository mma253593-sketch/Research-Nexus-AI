-- =====================================================================
--  XAUUSD SMART ENTRY V2.0 — ADAPTIVE PRECISION ENGINE (shared core)
--  Quadcode Script (QCS, Lua 5.3 based) for the IQ Option script editor
--  Shared by the Main (chart) and Panel scripts. Rules: docs/ADAPTIVE_ENGINE_SPEC.md
--
--  NO-REPAINT CONTRACT
--  * Every decision uses CLOSED candles only (index [1] and older).
--  * The signal is printed on the NEW candle (index [0]) at its open and is
--    frozen: nothing on the live candle feeds the decision.
--  * Pivots are accepted only after `pivot_len` right-side candles closed.
--  * All state lives in make_series written from its own [1] value, so
--    re-running the live bar on every tick writes the same value again.
--  * NO_CHASE is the only live read; it is a warning, not a signal input.
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
    rsi_len       = input (14, "RSI Period", input.integer, 2, 100),
    rsi_ext_high  = input (78, "RSI too high - block CALL", input.double, 55, 100, 1),
    rsi_ext_low   = input (22, "RSI too low - block PUT",   input.double, 0, 45, 1),
    macd_fast_len = input (12, "MACD Fast",   input.integer, 1, 100),
    macd_slow_len = input (26, "MACD Slow",   input.integer, 2, 200),
    macd_sig_len  = input (9,  "MACD Signal", input.integer, 1, 100)
}

input_group {
    "Volatility (Bollinger / ATR)",
    bb_len       = input (20,  "BB Period",                   input.integer, 2, 200),
    bb_mult      = input (2.0, "BB Deviation",                input.double, 0.5, 5, 0.1),
    atr_len      = input (14,  "ATR Period",                  input.integer, 1, 100),
    atr_base_len = input (100, "ATR Baseline Period",         input.integer, 10, 500),
    spike_mult   = input (2.8, "Spike: candle range > ATR x", input.double, 1, 10, 0.1)
}

input_group {
    "Market Regime (adaptive)",
    adx_len        = input (14,   "ADX Period",                        input.integer, 2, 100),
    er_len         = input (20,   "Efficiency Ratio Period",           input.integer, 3, 100),
    adx_trend_in   = input (25,   "Trend: ADX enter >=",               input.double, 10, 60, 1),
    adx_trend_out  = input (20,   "Trend: ADX stay >=",                input.double, 5, 60, 1),
    adx_range      = input (18,   "Range: ADX <",                      input.double, 5, 40, 1),
    er_trend       = input (0.25, "Trend: Efficiency Ratio >=",        input.double, 0.05, 1, 0.01),
    er_range       = input (0.15, "Range: Efficiency Ratio <",         input.double, 0.01, 1, 0.01),
    hv_in          = input (1.60, "High vol: ATR/baseline enter >=",   input.double, 1, 5, 0.05),
    hv_out         = input (1.35, "High vol: ATR/baseline stay >=",    input.double, 1, 5, 0.05),
    lv_in          = input (0.60, "Low vol: ATR/baseline enter <=",    input.double, 0.1, 1, 0.05),
    lv_out         = input (0.70, "Low vol: ATR/baseline stay <=",     input.double, 0.1, 1, 0.05),
    regime_confirm = input (3,    "Regime change confirm (bars)",      input.integer, 1, 20),
    allow_trans    = input (true,  "Trade TRANSITIONAL (stricter)",    input.boolean),
    allow_low_vol  = input (false, "Trade LOW VOLATILITY (stricter)",  input.boolean)
}

input_group {
    "Support / Resistance",
    pivot_len       = input (5,    "Minor pivot strength (bars)",      input.integer, 2, 20),
    major_pivot_len = input (15,   "Major pivot strength (bars)",      input.integer, 5, 50),
    range_len       = input (50,   "Range lookback (bars)",            input.integer, 10, 300),
    round_step      = input (10,   "Round-number step (0 = off)",      input.double, 0, 1000, 1),
    min_room_atr    = input (0.8,  "Min room to next level (ATR x)",   input.double, 0.3, 5, 0.1)
}

input_group {
    "Signal Filter",
    min_score     = input (70,   "Min confidence in TREND (60-95)",     input.integer, 60, 95),
    trans_extra   = input (8,    "Extra score required in TRANSITIONAL", input.integer, 0, 25),
    cooldown_bars = input (3,    "Cooldown in TREND (bars)",            input.integer, 0, 50),
    trans_cool    = input (5,    "Cooldown in TRANSITIONAL (bars)",     input.integer, 0, 50),
    late_body_atr = input (1.8,  "Late: candle body > ATR x",           input.double, 0.5, 10, 0.1),
    max_ext_atr   = input (2.2,  "Late: distance from EMA Mid > ATR x", input.double, 0.5, 10, 0.1),
    whip_len      = input (10,   "Whipsaw window (bars)",               input.integer, 3, 50),
    whip_max      = input (2,    "Whipsaw: EMA9/21 crosses >=",         input.integer, 1, 10),
    exhaust_run   = input (5,    "Exhaustion: same-colour candles >=",  input.integer, 3, 12),
    chase_atr     = input (0.35, "No chase: live move > ATR x",         input.double, 0.05, 5, 0.05)
}

-- --------------------------- BASE SERIES ------------------------------
-- Every series function is called unconditionally on every bar.
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

clv     = (close - low) / max (high - low, 0.0000001)
clv_avg = sma (clv, 5)

-- ADX / DI: same formula as the official quadcodescript-library trend/adx_dms.lua
adx_up  = change (high)
adx_dn  = -change (low)
adx_pdm = iff (adx_up > adx_dn and nz (adx_up) > 0, adx_up, 0)
adx_mdm = iff (adx_dn > adx_up and nz (adx_dn) > 0, adx_dn, 0)
adx_atr = rma (tr, adx_len)
adx_pdi = 100 * rma (adx_pdm / adx_atr, adx_len)
adx_mdi = 100 * rma (adx_mdm / adx_atr, adx_len)
adx_val = 100 * rma (abs (adx_pdi - adx_mdi) / (adx_pdi + adx_mdi), adx_len)

-- Kaufman efficiency ratio: net move / path length (1 = straight line)
er_val = abs (change (close, er_len)) / sum (abs (change (close)), er_len)

-- Pivot windows (minor + major) and range extremes
piv_hp = highest (high, pivot_len)
piv_lp = lowest  (low,  pivot_len)
maj_hp = highest (high, major_pivot_len)
maj_lp = lowest  (low,  major_pivot_len)
rng_hi = highest (high, range_len)
rng_lo = lowest  (low,  range_len)

-- ------------------------------ HELPERS -------------------------------
local function num (s, d)
    local v = get_value (s)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then
        return d
    end
    return v
end

local function clamp (x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- ---------------------- PIVOT STATE (TICK-SAFE) -----------------------
-- Pivot high at bar [p+1]: strictly above the p bars on its left, and not
-- below any of the p closed bars on its right. Strict-left = one pivot per
-- plateau (no duplicate levels from equal highs).
local function pivot_hi (p, hp)
    local x, left, right = num (high[p + 1]), num (hp[p + 2]), num (hp[1])
    if x ~= nil and left ~= nil and right ~= nil and x > left and x >= right then return x end
    return nil
end
local function pivot_lo (p, lp)
    local x, left, right = num (low[p + 1]), num (lp[p + 2]), num (lp[1])
    if x ~= nil and left ~= nil and right ~= nil and x < left and x <= right then return x end
    return nil
end

-- Two-deep memory: newest level and the one before it.
local function remember (s1, s2, new)
    local p1, p2 = num (s1[1]), num (s2[1])
    if new ~= nil then
        s1:set (new)
        if p1 ~= nil then s2:set (p1) end
    else
        if p1 ~= nil then s1:set (p1) end
        if p2 ~= nil then s2:set (p2) end
    end
end

res1 = make_series ()
res2 = make_series ()
sup1 = make_series ()
sup2 = make_series ()
resM = make_series ()
resM_old = make_series ()
supM = make_series ()
supM_old = make_series ()
remember (res1, res2, pivot_hi (pivot_len, piv_hp))
remember (sup1, sup2, pivot_lo (pivot_len, piv_lp))
remember (resM, resM_old, pivot_hi (major_pivot_len, maj_hp))
remember (supM, supM_old, pivot_lo (major_pivot_len, maj_lp))

-- ------------------------------ STATE ---------------------------------
bar_count = make_series ()
bar_count:set (num (bar_count[1], 0) + 1)

sig_age   = make_series ()   -- bars since the last printed signal
reg_state = make_series ()   -- confirmed regime
reg_cand  = make_series ()   -- candidate regime
reg_cnt   = make_series ()   -- consecutive bars of the candidate
ema_cross = make_series ()   -- 1 if EMA fast crossed EMA mid on that closed bar

-- ------------------- SNAPSHOT OF THE CLOSED CANDLES -------------------
local O1, H1, L1, C1 = num (open[1]), num (high[1]), num (low[1]), num (close[1])
local O2, H2, L2, C2 = num (open[2]), num (high[2]), num (low[2]), num (close[2])

local EF1, EF2       = num (ema_f[1]), num (ema_f[2])
local EM1, EM2       = num (ema_m[1]), num (ema_m[2])
local ES1, ES6       = num (ema_s[1]), num (ema_s[6])
local R1, R2         = num (rsi_val[1]), num (rsi_val[2])
local HI1, HI2, HI3  = num (macd_hist[1]), num (macd_hist[2]), num (macd_hist[3])
local ATR1, ATR2     = num (atr_val[1]), num (atr_val[2])
local ATRB1          = num (atr_base[1])
local BW1, BWA1      = num (bb_width[1]), num (bb_width_avg[1])
local CLV1           = num (clv_avg[1], 0.5)
local ADX1           = num (adx_val[1])
local PDI1, MDI1     = num (adx_pdi[1]), num (adx_mdi[1])
local ER1            = num (er_val[1], 0)

local RES1, RES2 = num (res1), num (res2)
local SUP1, SUP2 = num (sup1), num (sup2)
local RESM, SUPM = num (resM), num (supM)
local RHI2, RLO2 = num (rng_hi[2]), num (rng_lo[2])

local warm_need = math.max (ema_slow_len, range_len, atr_base_len, bb_len * 3,
                            2 * major_pivot_len + 2, 3 * adx_len, er_len + 1) + 2 * pivot_len + 5
local data_ok = num (bar_count, 0) > warm_need
    and O1 and H1 and L1 and C1 and O2 and H2 and L2 and C2
    and EF1 and EF2 and EM1 and EM2 and ES1 and ES6 and R1 and R2
    and HI1 and HI2 and HI3 and ATR1 and ATR2 and ATRB1 and BW1 and BWA1
    and ADX1 and PDI1 and MDI1
    and ATR1 > 0 and ATR2 > 0 and ATRB1 > 0 and BWA1 > 0
data_ok = data_ok and true or false

-- EMA whipsaw bookkeeping (closed bars [1] vs [2])
local crossed = 0
if EF1 and EM1 and EF2 and EM2 and ((EF1 - EM1) > 0) ~= ((EF2 - EM2) > 0) then crossed = 1 end
ema_cross:set (crossed)
local whip_count = 0
for i = 0, whip_len - 1 do whip_count = whip_count + num (ema_cross[i], 0) end

-- Consecutive same-colour closed candles ending at [1]
local run_up, run_dn = 0, 0
for i = 1, exhaust_run + 1 do
    local o, c = num (open[i]), num (close[i])
    if o == nil or c == nil or c <= o then break end
    run_up = run_up + 1
end
for i = 1, exhaust_run + 1 do
    local o, c = num (open[i]), num (close[i])
    if o == nil or c == nil or c >= o then break end
    run_dn = run_dn + 1
end

-- ------------------------- OUTPUT VARIABLES ---------------------------
REG_WARMUP, REG_TREND, REG_RANGE, REG_HIGHVOL, REG_LOWVOL, REG_TRANS = 0, 1, 2, 3, 4, 5

SIG_DIR     = 0      --  1 = CALL, -1 = PUT, 0 = WAIT
SIG_SCORE   = 0      -- confidence of the printed signal
SIG_TRIG    = ""     -- price-action trigger of the signal
SIG_MIN     = min_score  -- effective (adaptive) minimum score on this bar
SIG_ROOM    = 0      -- room to the next obstacle (ATR units) of the signal
BULL_SCORE  = 0      -- CALL score 2.0 (0-100)
BEAR_SCORE  = 0      -- PUT  score 2.0 (0-100)
BULL_REASON = ""     -- first failed validation stage for CALL ("" = passed)
BEAR_REASON = ""
BULL_TRIG   = ""
BEAR_TRIG   = ""
TREND_DIR   = 0      --  1 up, -1 down, 0 none
REGIME      = REG_WARMUP
REGIME_RAW  = REG_WARMUP
REGIME_NEW  = false  -- first bar of a newly confirmed regime
WAIT_REASON = ""     -- why a would-be signal was cancelled
WAIT_SIDE   = 0
BUY_PRESS   = 50
SELL_PRESS  = 50
NO_CHASE    = false
COOLDOWN_USED = cooldown_bars
ATR_RATIO   = 0
ADX_NOW     = 0
ER_NOW      = 0

-- ---------------------------- REGIME ENGINE ---------------------------
local prev_state = num (reg_state[1], REG_WARMUP)
local prev_cand  = num (reg_cand[1], REG_WARMUP)
local prev_cnt   = num (reg_cnt[1], 0)
local spike = false

local function classify (prev)
    local atrr = ATR1 / ATRB1
    local bwr  = BW1 / BWA1
    spike = (H1 - L1) > spike_mult * ATR2
    -- A. HIGH VOLATILITY (highest priority, safety)
    if spike or atrr >= hv_in or (prev == REG_HIGHVOL and atrr >= hv_out) then
        return REG_HIGHVOL
    end
    -- B. LOW VOLATILITY
    if (atrr <= lv_in and bwr <= 0.85) or (prev == REG_LOWVOL and atrr <= lv_out) then
        return REG_LOWVOL
    end
    -- C. TRENDING
    local slope = (ES1 - ES6) / (5 * ATR1)                 -- EMA slow slope, ATR per bar
    local stack_up = EF1 > EM1 and EM1 > ES1
    local stack_dn = EF1 < EM1 and EM1 < ES1
    local aligned  = (EM1 > ES1 and slope > 0) or (EM1 < ES1 and slope < 0)
    if prev == REG_TREND then
        -- stay: ADX (double-smoothed) above the lower band and EMA structure intact.
        -- ER is an entry-only criterion: it dips on normal pullbacks and caused flapping.
        if ADX1 >= adx_trend_out and aligned then return REG_TREND end
    elseif ADX1 >= adx_trend_in and ER1 >= er_trend and (stack_up or stack_dn)
           and aligned and math.abs (slope) >= 0.02 then
        return REG_TREND
    end
    -- D. RANGING
    local tangled = math.abs (EF1 - ES1) < 0.5 * ATR1
    if ADX1 < adx_range and (ER1 < er_range or tangled) then
        return REG_RANGE
    end
    -- E. TRANSITIONAL (everything in between)
    return REG_TRANS
end

if data_ok then
    local raw = classify (prev_state)
    local cnt = (raw == prev_cand) and (prev_cnt + 1) or 1
    local state = prev_state
    if prev_state == REG_WARMUP then
        state = raw                                   -- first classified bar
    elseif raw == REG_HIGHVOL then
        state = REG_HIGHVOL                           -- safety: enter at once
    elseif raw ~= prev_state and cnt >= regime_confirm then
        state = raw                                   -- confirmed change
    end
    reg_state:set (state)
    reg_cand:set (raw)
    reg_cnt:set (cnt)
    REGIME, REGIME_RAW = state, raw
    REGIME_NEW = state ~= prev_state
    ATR_RATIO, ADX_NOW, ER_NOW = ATR1 / ATRB1, ADX1, ER1
else
    reg_state:set (prev_state)
    reg_cand:set (prev_cand)
    reg_cnt:set (prev_cnt)
end

-- -------------------------- ADAPTIVE PROFILE --------------------------
-- Bounded per-regime thresholds. Unsuitable regimes are not tradable.
local function make_profile (regime)
    local p = {
        tradable = false, block = "WARMUP", regime_pts = 0,
        min = min_score, room = min_room_atr, late_ext = max_ext_atr, late_body = late_body_atr,
        rsi_mid = 50, rsi_hi = rsi_ext_high, rsi_lo = rsi_ext_low,
        need_accel = false, pa_min = 10, cool = cooldown_bars
    }
    local strict = false
    if regime == REG_TREND then
        p.tradable, p.block, p.regime_pts = true, "", 15
    elseif regime == REG_TRANS then
        p.tradable, p.block, p.regime_pts = allow_trans, "TRANSITION", 6
        strict = true
    elseif regime == REG_LOWVOL then
        p.tradable, p.block, p.regime_pts = allow_low_vol, "LOW-VOL", 4
        strict = true
    elseif regime == REG_RANGE then
        p.block = "RANGING"
    elseif regime == REG_HIGHVOL then
        p.block = "VOLATILE"
    end
    if p.tradable then p.block = "" end
    if strict then
        p.min        = clamp (min_score + trans_extra, min_score, 95)
        p.room       = clamp (min_room_atr * 1.5, min_room_atr, 3.0)
        p.late_ext   = clamp (max_ext_atr * 0.75, 1.0, max_ext_atr)
        p.late_body  = clamp (late_body_atr * 0.85, 0.8, late_body_atr)
        p.rsi_mid    = 52
        p.rsi_hi     = math.min (rsi_ext_high, 72)
        p.rsi_lo     = math.max (rsi_ext_low, 28)
        p.need_accel = true
        p.pa_min     = 15
        p.cool       = math.max (cooldown_bars, trans_cool)
    end
    return p
end

-- ----------------------- SIDE-NEUTRAL EVALUATION ----------------------
-- PUT is evaluated by mirroring prices (x -> -x), RSI (r -> 100 - r),
-- MACD (h -> -h) and DI (+DI <-> -DI): CALL and PUT rules are identical.
local function make_view (s)
    local v = {}
    if s == 1 then
        v.o1, v.h1, v.l1, v.c1 = O1, H1, L1, C1
        v.o2, v.h2, v.l2, v.c2 = O2, H2, L2, C2
        v.pdi, v.mdi = PDI1, MDI1
        v.run = run_up
    else
        v.o1, v.h1, v.l1, v.c1 = -O1, -L1, -H1, -C1
        v.o2, v.h2, v.l2, v.c2 = -O2, -L2, -H2, -C2
        v.pdi, v.mdi = MDI1, PDI1
        v.run = run_dn
    end
    v.ef1, v.em1, v.em2, v.es1, v.es6 = s * EF1, s * EM1, s * EM2, s * ES1, s * ES6
    v.r1 = (s == 1) and R1 or (100 - R1)
    v.r2 = (s == 1) and R2 or (100 - R2)
    v.hi1, v.hi2, v.hi3 = s * HI1, s * HI2, s * HI3
    v.clv = (s == 1) and CLV1 or (1 - CLV1)

    local obst, supp = {}, {}
    local function add (t, x) if x ~= nil then t[#t + 1] = s * x end end
    if s == 1 then
        add (obst, RES1) add (obst, RES2) add (obst, RESM) add (obst, RHI2)
        add (supp, SUP1) add (supp, SUP2) add (supp, SUPM) add (supp, RLO2)
        v.brk_lvl   = RES1
        v.sweep_lvl = SUP1
        v.swing_lo  = SUP1
        v.range_hi  = RHI2
    else
        add (obst, SUP1) add (obst, SUP2) add (obst, SUPM) add (obst, RLO2)
        add (supp, RES1) add (supp, RES2) add (supp, RESM) add (supp, RHI2)
        v.brk_lvl   = SUP1 and -SUP1
        v.sweep_lvl = RES1 and -RES1
        v.swing_lo  = RES1 and -RES1
        v.range_hi  = RLO2 and -RLO2
    end
    v.obst, v.supp = obst, supp
    return v
end

local function evaluate (v, prof)
    local r = { score = 0, trig = "", reason = "", bias = false, room = 0 }
    local atr = ATR2                       -- ATR before the confirmation candle

    -- candle geometry
    local rng1  = math.max (v.h1 - v.l1, 0.0000001)
    local rng2  = math.max (v.h2 - v.l2, 0.0000001)
    local body1 = math.abs (v.c1 - v.o1)
    local body2 = math.abs (v.c2 - v.o2)
    local upw1  = v.h1 - math.max (v.c1, v.o1)
    local loww1 = math.min (v.c1, v.o1) - v.l1
    local loww2 = math.min (v.c2, v.o2) - v.l2
    local cpos1 = (v.c1 - v.l1) / rng1

    -- room to the nearest obstacle ahead (pivots, major pivot, range, round number)
    local room = 99
    for _, x in ipairs (v.obst) do
        if x > v.c1 then room = math.min (room, (x - v.c1) / atr) end
    end
    if round_step > 0 then
        local nxt = math.ceil (v.c1 / round_step) * round_step
        if nxt <= v.c1 then nxt = nxt + round_step end
        room = math.min (room, (nxt - v.c1) / atr)
    end
    local near_sup = nil
    for _, x in ipairs (v.supp) do
        if x < v.c1 and (near_sup == nil or x > near_sup) then near_sup = x end
    end
    r.room = room

    -- ---------- Stage 3: price-action triggers (quality-filtered) ----------
    local pa, trig = 0, ""
    local function take (p, t) if p > pa then pa, trig = p, t end end
    local function at_support (low_px, ema_mid)
        return (low_px <= ema_mid + 0.15 * atr)
            or (near_sup ~= nil and low_px <= near_sup + 0.25 * atr)
    end

    -- Engulfing (meaningful engulfed body, strong close)
    if v.c1 > v.o1 and v.c2 < v.o2 and v.c1 >= v.o2 and v.o1 <= v.c2
       and body1 >= 1.2 * body2 and body2 >= 0.15 * atr and body1 >= 0.4 * atr and cpos1 >= 0.7 then
        take (20, "ENGULF")
    end
    -- False breakout: a real sweep below support, closed back above it
    if v.sweep_lvl ~= nil and v.l1 < v.sweep_lvl - 0.1 * atr and v.c1 > v.sweep_lvl
       and loww1 >= 0.5 * rng1 and cpos1 >= 0.6 then
        take (18, "FALSE-BRK")
    end
    -- Rejection WITH follow-through: rejection candle [2], confirming candle [1]
    if loww2 >= 0.5 * rng2 and rng2 >= 0.5 * atr and at_support (v.l2, v.em2)
       and v.c1 > v.o1 and v.c1 > math.max (v.o2, v.c2) and cpos1 >= 0.6 then
        take (17, "REJECT")
    end
    -- Pin bar at a level (pin bars away from any level are ignored)
    if loww1 >= 2 * body1 and loww1 >= 0.6 * rng1 and upw1 <= 0.25 * rng1
       and rng1 >= 0.6 * atr and at_support (v.l1, v.em1) then
        take (15, "PIN")
    end
    -- Breakout of the last confirmed pivot with a strong, non-climactic close
    if v.brk_lvl ~= nil and v.c1 > v.brk_lvl + 0.15 * atr and v.c2 <= v.brk_lvl
       and v.c1 > v.o1 and body1 >= 0.55 * rng1 and cpos1 >= 0.75 and body1 <= 2.0 * atr then
        take (15, "BREAKOUT")
    end
    -- Momentum candle (not accepted in stricter regimes: pa_min = 15)
    if v.c1 > v.o1 and body1 >= 0.6 * rng1 and cpos1 >= 0.75
       and body1 >= 0.4 * atr and body1 <= 1.5 * atr then
        take (10, "MOMENTUM")
    end
    r.trig = trig

    -- ---------- Score 2.0 ----------
    -- R. regime suitability (0-15)
    local sR = prof.regime_pts
    -- T. trend structure (0-20): EMA stack 8 + ADX strength 7 + DI alignment 5
    local stack = v.ef1 > v.em1 and v.em1 > v.es1
    local sT = (stack and 8 or 0)
        + 7 * clamp ((ADX1 - 15) / 20, 0, 1)
        + 5 * clamp ((v.pdi - v.mdi) / 10, 0, 1)
    -- M. momentum (0-15): RSI distance above 50 (8) + MACD hist acceleration (7)
    local sM = 8 * clamp ((v.r1 - 50) / 15, 0, 1)
    if v.hi1 > 0 and v.hi1 > v.hi2 then sM = sM + 7 elseif v.hi1 > 0 then sM = sM + 3 end
    -- P. price action (0-20)
    local sP = pa
    -- E. entry quality (0-20): room beyond the minimum (12) + closeness to EMA mid (8)
    local ext = (v.c1 - v.em1) / atr
    local sE = 12 * clamp ((room - prof.room) / 2.0, 0, 1)
        + 8 * (1 - clamp ((ext - 1.0) / math.max (prof.late_ext - 1.0, 0.1), 0, 1))
    -- V. volatility quality (0-10): 10 at ATR = baseline, 0 at x1.6 or /1.6
    local sV = 10 * (1 - clamp (math.abs (math.log (ATR1 / ATRB1)) / math.log (1.6), 0, 1))
    -- Penalties for conflicting evidence
    local pen = 0
    if v.clv < 0.45 then pen = pen + 6 end                 -- recent closes in the lower part of candles
    if v.r1 < v.r2 then pen = pen + 5 end                  -- RSI turning against
    if upw1 >= 0.35 * rng1 then pen = pen + 6 end          -- selling wick on the trigger candle
    r.score = math.floor (clamp (sR + sT + sM + sP + sE + sV - pen, 0, 100) + 0.5)

    -- ---------- Validation stages (first failure = reason) ----------
    local trend_ok = v.em1 > v.es1 and v.c1 > v.es1 and v.es1 > v.es6 and v.ef1 > v.em1
    r.bias = trend_ok
    local climax = v.range_hi ~= nil and v.h1 >= v.range_hi and upw1 >= 0.4 * rng1

    local reason = ""
    -- Stage 1: market
    if not prof.tradable then reason = prof.block
    -- Stage 2: direction
    elseif not trend_ok then reason = "NO-TREND"
    elseif v.swing_lo ~= nil and v.c1 < v.swing_lo then reason = "REVERSAL"
    elseif v.r1 <= prof.rsi_mid or v.hi1 <= 0 then reason = "CONFLICT"
    elseif (v.hi1 < v.hi2 and v.hi2 < v.hi3) or (prof.need_accel and v.hi1 <= v.hi2) then reason = "WEAK-MOM"
    elseif whip_count >= whip_max then reason = "WHIPSAW"
    elseif v.r1 > (prof.rsi_hi_side or prof.rsi_hi) then reason = "OVEREXT"
    elseif v.run >= exhaust_run or climax then reason = "EXHAUST"
    -- Stage 3: price action
    elseif pa < prof.pa_min or cpos1 < 0.5 then reason = "NO-PA"
    -- Stage 4: entry
    elseif body1 > prof.late_body * atr or ext > prof.late_ext then reason = "LATE"
    elseif room < prof.room then reason = "NEAR-SR"
    -- Stage 5: score
    elseif r.score < prof.min then reason = "LOW-SCORE"
    end
    r.reason = reason
    return r
end

-- ------------------------------ DECISION ------------------------------
local prev_age = num (sig_age[1], 999)
local prof = make_profile (REGIME)
SIG_MIN, COOLDOWN_USED = prof.min, prof.cool
PROF_ROOM, PROF_LATE_EXT, PROF_LATE_BODY = prof.room, prof.late_ext, prof.late_body
PROF_RSI_MID, PROF_PA_MIN, PROF_ACCEL = prof.rsi_mid, prof.pa_min, prof.need_accel
PROF_TRADABLE = prof.tradable

if data_ok then
    local prof_bull = prof
    local prof_bear = {}
    for k, x in pairs (prof) do prof_bear[k] = x end
    prof_bull.rsi_hi_side = prof.rsi_hi
    prof_bear.rsi_hi_side = 100 - prof.rsi_lo          -- mirrored RSI limit for PUT

    local bull = evaluate (make_view (1), prof_bull)
    local bear = evaluate (make_view (-1), prof_bear)

    BULL_SCORE, BEAR_SCORE   = bull.score, bear.score
    BULL_REASON, BEAR_REASON = bull.reason, bear.reason
    BULL_TRIG, BEAR_TRIG     = bull.trig, bear.trig
    if REGIME == REG_TREND or REGIME == REG_TRANS then
        if bull.bias then TREND_DIR = 1 elseif bear.bias then TREND_DIR = -1 end
    end

    BUY_PRESS  = clamp (CLV1 * 100, 0, 100)
    SELL_PRESS = 100 - BUY_PRESS

    local best, side = nil, 0
    if bull.reason == "" then best, side = bull, 1
    elseif bear.reason == "" then best, side = bear, -1 end

    if best ~= nil and prev_age < prof.cool then
        WAIT_REASON, WAIT_SIDE = "COOLDOWN", side
        best = nil
    end

    if best ~= nil then
        SIG_DIR, SIG_SCORE, SIG_TRIG, SIG_ROOM = side, best.score, best.trig, best.room
    elseif WAIT_REASON == "" then
        -- report the cancel reason only for a complete would-be setup
        local function setup (x)
            return x.bias and x.trig ~= "" and x.score >= prof.min and x.reason ~= "LOW-SCORE"
        end
        if setup (bull) then WAIT_REASON, WAIT_SIDE = bull.reason, 1
        elseif setup (bear) then WAIT_REASON, WAIT_SIDE = bear.reason, -1 end
    end

    -- LIVE advisory on the entry candle (does not influence SIG_DIR)
    if SIG_DIR ~= 0 then
        local o0, c0 = num (open), num (close)
        if o0 ~= nil and c0 ~= nil and SIG_DIR * (c0 - o0) > chase_atr * ATR1 then
            NO_CHASE = true
        end
    end
end

sig_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)

-- Show a cancel reason only on the first bar of a streak (less clutter)
local REASON_CODE = { ["NEAR-SR"] = 1, RANGING = 2, VOLATILE = 3, LATE = 4, OVEREXT = 5,
                      CONFLICT = 6, ["NO-PA"] = 7, COOLDOWN = 9, ["NO-TREND"] = 10,
                      ["WEAK-MOM"] = 11, WHIPSAW = 12, EXHAUST = 13, REVERSAL = 14,
                      TRANSITION = 15, ["LOW-VOL"] = 16 }
wait_code = make_series ()
local wcode = (REASON_CODE[WAIT_REASON] or 0) * WAIT_SIDE
wait_code:set (wcode)
WAIT_NEW = wcode ~= 0 and wcode ~= num (wait_code[1], 0)
