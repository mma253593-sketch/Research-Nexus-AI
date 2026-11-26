instrument { name = "XAUUSD Smart Entry V2", short_name = "XAU-SE2", overlay = true }
-- Generated from qcs/src (core.lua + view_main.lua). Edit the sources, then run qcs/build.sh.
input_group { "Trend (EMA)",
    ema_fast_len = input (9,  "EMA Fast", input.integer, 1, 200), ema_mid_len  = input (21, "EMA Mid",  input.integer, 1, 300),
    ema_slow_len = input (50, "EMA Slow", input.integer, 1, 500)
}
input_group { "Momentum (RSI / MACD)",
    rsi_len       = input (14, "RSI Period", input.integer, 2, 100), rsi_ext_high  = input (78, "RSI too high - block CALL", input.double, 55, 100, 1), rsi_ext_low   = input (22, "RSI too low - block PUT",   input.double, 0, 45, 1),
    macd_fast_len = input (12, "MACD Fast",   input.integer, 1, 100), macd_slow_len = input (26, "MACD Slow",   input.integer, 2, 200),
    macd_sig_len  = input (9,  "MACD Signal", input.integer, 1, 100)
}
input_group { "Volatility (Bollinger / ATR)",
    bb_len       = input (20,  "BB Period",                   input.integer, 2, 200), bb_mult      = input (2.0, "BB Deviation",                input.double, 0.5, 5, 0.1), atr_len      = input (14,  "ATR Period",                  input.integer, 1, 100),
    atr_base_len = input (100, "ATR Baseline Period",         input.integer, 10, 500),
    spike_mult   = input (2.8, "Spike: candle range > ATR x", input.double, 1, 10, 0.1)
}
input_group { "Market Regime (adaptive)",
    adx_len        = input (14,   "ADX Period",                        input.integer, 2, 100), er_len         = input (20,   "Efficiency Ratio Period",           input.integer, 3, 100), adx_trend_in   = input (25,   "Trend: ADX enter >=",               input.double, 10, 60, 1),
    adx_trend_out  = input (20,   "Trend: ADX stay >=",                input.double, 5, 60, 1), adx_range      = input (18,   "Range: ADX <",                      input.double, 5, 40, 1), er_trend       = input (0.25, "Trend: Efficiency Ratio >=",        input.double, 0.05, 1, 0.01),
    er_range       = input (0.15, "Range: Efficiency Ratio <",         input.double, 0.01, 1, 0.01), hv_in          = input (1.60, "High vol: ATR/baseline enter >=",   input.double, 1, 5, 0.05), hv_out         = input (1.35, "High vol: ATR/baseline stay >=",    input.double, 1, 5, 0.05),
    lv_in          = input (0.60, "Low vol: ATR/baseline enter <=",    input.double, 0.1, 1, 0.05), lv_out         = input (0.70, "Low vol: ATR/baseline stay <=",     input.double, 0.1, 1, 0.05), regime_confirm = input (3,    "Regime change confirm (bars)",      input.integer, 1, 20),
    allow_trans    = input (true,  "Trade TRANSITIONAL (stricter)",    input.boolean),
    allow_low_vol  = input (false, "Trade LOW VOLATILITY (stricter)",  input.boolean)
}
input_group { "Support / Resistance",
    pivot_len       = input (5,    "Minor pivot strength (bars)",      input.integer, 2, 20), major_pivot_len = input (15,   "Major pivot strength (bars)",      input.integer, 5, 50), range_len       = input (50,   "Range lookback (bars)",            input.integer, 10, 300),
    round_step      = input (10,   "Round-number step (0 = off)",      input.double, 0, 1000, 1),
    min_room_atr    = input (0.8,  "Min room to next level (ATR x)",   input.double, 0.3, 5, 0.1)
}
input_group { "Signal Filter",
    min_score     = input (70,   "Min confidence in TREND (60-95)",     input.integer, 60, 95), trans_extra   = input (8,    "Extra score required in TRANSITIONAL", input.integer, 0, 25), cooldown_bars = input (3,    "Cooldown in TREND (bars)",            input.integer, 0, 50),
    trans_cool    = input (5,    "Cooldown in TRANSITIONAL (bars)",     input.integer, 0, 50), late_body_atr = input (1.8,  "Late: candle body > ATR x",           input.double, 0.5, 10, 0.1), max_ext_atr   = input (2.2,  "Late: distance from EMA Mid > ATR x", input.double, 0.5, 10, 0.1),
    whip_len      = input (10,   "Whipsaw window (bars)",               input.integer, 3, 50), whip_max      = input (2,    "Whipsaw: EMA9/21 crosses >=",         input.integer, 1, 10), exhaust_run   = input (5,    "Exhaustion: same-colour candles >=",  input.integer, 3, 12),
    chase_atr     = input (0.35, "No chase: live move > ATR x",         input.double, 0.05, 5, 0.05)
}
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
adx_up  = change (high)
adx_dn  = -change (low)
adx_pdm = iff (adx_up > adx_dn and nz (adx_up) > 0, adx_up, 0)
adx_mdm = iff (adx_dn > adx_up and nz (adx_dn) > 0, adx_dn, 0)
adx_atr = rma (tr, adx_len)
adx_pdi = 100 * rma (adx_pdm / adx_atr, adx_len)
adx_mdi = 100 * rma (adx_mdm / adx_atr, adx_len)
adx_val = 100 * rma (abs (adx_pdi - adx_mdi) / (adx_pdi + adx_mdi), adx_len)
er_val = abs (change (close, er_len)) / sum (abs (change (close)), er_len)
piv_hp = highest (high, pivot_len)
piv_lp = lowest  (low,  pivot_len)
maj_hp = highest (high, major_pivot_len)
maj_lp = lowest  (low,  major_pivot_len)
rng_hi = highest (high, range_len)
rng_lo = lowest  (low,  range_len)
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
res1 = make_series (); res2 = make_series (); sup1 = make_series (); sup2 = make_series ()
resM = make_series (); resM_old = make_series (); supM = make_series (); supM_old = make_series ()
remember (res1, res2, pivot_hi (pivot_len, piv_hp))
remember (sup1, sup2, pivot_lo (pivot_len, piv_lp))
remember (resM, resM_old, pivot_hi (major_pivot_len, maj_hp))
remember (supM, supM_old, pivot_lo (major_pivot_len, maj_lp))
bar_count = make_series ()
bar_count:set (num (bar_count[1], 0) + 1)
sig_age   = make_series (); reg_state = make_series (); reg_cand  = make_series (); reg_cnt   = make_series ()
ema_cross = make_series ()
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
local crossed = 0
if EF1 and EM1 and EF2 and EM2 and ((EF1 - EM1) > 0) ~= ((EF2 - EM2) > 0) then crossed = 1 end
ema_cross:set (crossed)
local whip_count = 0
for i = 0, whip_len - 1 do whip_count = whip_count + num (ema_cross[i], 0) end
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
REG_WARMUP, REG_TREND, REG_RANGE, REG_HIGHVOL, REG_LOWVOL, REG_TRANS = 0, 1, 2, 3, 4, 5
SIG_DIR     = 0; SIG_SCORE   = 0; SIG_TRIG    = ""; SIG_MIN     = min_score
SIG_ROOM    = 0; BULL_SCORE  = 0; BEAR_SCORE  = 0; BULL_REASON = ""
BEAR_REASON = ""; BULL_TRIG   = ""; BEAR_TRIG   = ""; TREND_DIR   = 0
REGIME      = REG_WARMUP; REGIME_RAW  = REG_WARMUP; REGIME_NEW  = false; WAIT_REASON = ""
WAIT_SIDE   = 0; BUY_PRESS   = 50; SELL_PRESS  = 50; NO_CHASE    = false
COOLDOWN_USED = cooldown_bars; ATR_RATIO   = 0; ADX_NOW     = 0; ER_NOW      = 0
local prev_state = num (reg_state[1], REG_WARMUP)
local prev_cand  = num (reg_cand[1], REG_WARMUP)
local prev_cnt   = num (reg_cnt[1], 0)
local spike = false
local function classify (prev)
    local atrr = ATR1 / ATRB1
    local bwr  = BW1 / BWA1
    spike = (H1 - L1) > spike_mult * ATR2
    if spike or atrr >= hv_in or (prev == REG_HIGHVOL and atrr >= hv_out) then
        return REG_HIGHVOL
    end
    if (atrr <= lv_in and bwr <= 0.85) or (prev == REG_LOWVOL and atrr <= lv_out) then
        return REG_LOWVOL
    end
    local slope = (ES1 - ES6) / (5 * ATR1)
    local stack_up = EF1 > EM1 and EM1 > ES1
    local stack_dn = EF1 < EM1 and EM1 < ES1
    local aligned  = (EM1 > ES1 and slope > 0) or (EM1 < ES1 and slope < 0)
    if prev == REG_TREND then
        if ADX1 >= adx_trend_out and aligned then return REG_TREND end
    elseif ADX1 >= adx_trend_in and ER1 >= er_trend and (stack_up or stack_dn)
           and aligned and math.abs (slope) >= 0.02 then
        return REG_TREND
    end
    local tangled = math.abs (EF1 - ES1) < 0.5 * ATR1
    if ADX1 < adx_range and (ER1 < er_range or tangled) then
        return REG_RANGE
    end
    return REG_TRANS
end
if data_ok then
    local raw = classify (prev_state)
    local cnt = (raw == prev_cand) and (prev_cnt + 1) or 1
    local state = prev_state
    if prev_state == REG_WARMUP then
        state = raw
    elseif raw == REG_HIGHVOL then
        state = REG_HIGHVOL
    elseif raw ~= prev_state and cnt >= regime_confirm then
        state = raw
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
    local atr = ATR2
    local rng1  = math.max (v.h1 - v.l1, 0.0000001)
    local rng2  = math.max (v.h2 - v.l2, 0.0000001)
    local body1 = math.abs (v.c1 - v.o1)
    local body2 = math.abs (v.c2 - v.o2)
    local upw1  = v.h1 - math.max (v.c1, v.o1)
    local loww1 = math.min (v.c1, v.o1) - v.l1
    local loww2 = math.min (v.c2, v.o2) - v.l2
    local cpos1 = (v.c1 - v.l1) / rng1
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
    local pa, trig = 0, ""
    local function take (p, t) if p > pa then pa, trig = p, t end end
    local function at_support (low_px, ema_mid)
        return (low_px <= ema_mid + 0.15 * atr)
            or (near_sup ~= nil and low_px <= near_sup + 0.25 * atr)
    end
    if v.c1 > v.o1 and v.c2 < v.o2 and v.c1 >= v.o2 and v.o1 <= v.c2
       and body1 >= 1.2 * body2 and body2 >= 0.15 * atr and body1 >= 0.4 * atr and cpos1 >= 0.7 then
        take (20, "ENGULF")
    end
    if v.sweep_lvl ~= nil and v.l1 < v.sweep_lvl - 0.1 * atr and v.c1 > v.sweep_lvl
       and loww1 >= 0.5 * rng1 and cpos1 >= 0.6 then
        take (18, "FALSE-BRK")
    end
    if loww2 >= 0.5 * rng2 and rng2 >= 0.5 * atr and at_support (v.l2, v.em2)
       and v.c1 > v.o1 and v.c1 > math.max (v.o2, v.c2) and cpos1 >= 0.6 then
        take (17, "REJECT")
    end
    if loww1 >= 2 * body1 and loww1 >= 0.6 * rng1 and upw1 <= 0.25 * rng1
       and rng1 >= 0.6 * atr and at_support (v.l1, v.em1) then
        take (15, "PIN")
    end
    if v.brk_lvl ~= nil and v.c1 > v.brk_lvl + 0.15 * atr and v.c2 <= v.brk_lvl
       and v.c1 > v.o1 and body1 >= 0.55 * rng1 and cpos1 >= 0.75 and body1 <= 2.0 * atr then
        take (15, "BREAKOUT")
    end
    if v.c1 > v.o1 and body1 >= 0.6 * rng1 and cpos1 >= 0.75
       and body1 >= 0.4 * atr and body1 <= 1.5 * atr then
        take (10, "MOMENTUM")
    end
    r.trig = trig
    local sR = prof.regime_pts
    local stack = v.ef1 > v.em1 and v.em1 > v.es1
    local sT = (stack and 8 or 0)
        + 7 * clamp ((ADX1 - 15) / 20, 0, 1)
        + 5 * clamp ((v.pdi - v.mdi) / 10, 0, 1)
    local sM = 8 * clamp ((v.r1 - 50) / 15, 0, 1)
    if v.hi1 > 0 and v.hi1 > v.hi2 then sM = sM + 7 elseif v.hi1 > 0 then sM = sM + 3 end
    local sP = pa
    local ext = (v.c1 - v.em1) / atr
    local sE = 12 * clamp ((room - prof.room) / 2.0, 0, 1)
        + 8 * (1 - clamp ((ext - 1.0) / math.max (prof.late_ext - 1.0, 0.1), 0, 1))
    local sV = 10 * (1 - clamp (math.abs (math.log (ATR1 / ATRB1)) / math.log (1.6), 0, 1))
    local pen = 0
    if v.clv < 0.45 then pen = pen + 6 end
    if v.r1 < v.r2 then pen = pen + 5 end
    if upw1 >= 0.35 * rng1 then pen = pen + 6 end
    r.score = math.floor (clamp (sR + sT + sM + sP + sE + sV - pen, 0, 100) + 0.5)
    local trend_ok = v.em1 > v.es1 and v.c1 > v.es1 and v.es1 > v.es6 and v.ef1 > v.em1
    r.bias = trend_ok
    local climax = v.range_hi ~= nil and v.h1 >= v.range_hi and upw1 >= 0.4 * rng1
    local reason = ""
    if not prof.tradable then reason = prof.block
    elseif not trend_ok then reason = "NO-TREND"
    elseif v.swing_lo ~= nil and v.c1 < v.swing_lo then reason = "REVERSAL"
    elseif v.r1 <= prof.rsi_mid or v.hi1 <= 0 then reason = "CONFLICT"
    elseif (v.hi1 < v.hi2 and v.hi2 < v.hi3) or (prof.need_accel and v.hi1 <= v.hi2) then reason = "WEAK-MOM"
    elseif whip_count >= whip_max then reason = "WHIPSAW"
    elseif v.r1 > (prof.rsi_hi_side or prof.rsi_hi) then reason = "OVEREXT"
    elseif v.run >= exhaust_run or climax then reason = "EXHAUST"
    elseif pa < prof.pa_min or cpos1 < 0.5 then reason = "NO-PA"
    elseif body1 > prof.late_body * atr or ext > prof.late_ext then reason = "LATE"
    elseif room < prof.room then reason = "NEAR-SR"
    elseif r.score < prof.min then reason = "LOW-SCORE"
    end
    r.reason = reason
    return r
end
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
    prof_bear.rsi_hi_side = 100 - prof.rsi_lo
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
        local function setup (x)
            return x.bias and x.trig ~= "" and x.score >= prof.min and x.reason ~= "LOW-SCORE"
        end
        if setup (bull) then WAIT_REASON, WAIT_SIDE = bull.reason, 1
        elseif setup (bear) then WAIT_REASON, WAIT_SIDE = bear.reason, -1 end
    end
    if SIG_DIR ~= 0 then
        local o0, c0 = num (open), num (close)
        if o0 ~= nil and c0 ~= nil and SIG_DIR * (c0 - o0) > chase_atr * ATR1 then
            NO_CHASE = true
        end
    end
end
sig_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)
local REASON_CODE = { ["NEAR-SR"] = 1, RANGING = 2, VOLATILE = 3, LATE = 4, OVEREXT = 5,
                      CONFLICT = 6, ["NO-PA"] = 7, COOLDOWN = 9, ["NO-TREND"] = 10,
                      ["WEAK-MOM"] = 11, WHIPSAW = 12, EXHAUST = 13, REVERSAL = 14,
                      TRANSITION = 15, ["LOW-VOL"] = 16 }
wait_code = make_series ()
local wcode = (REASON_CODE[WAIT_REASON] or 0) * WAIT_SIDE
wait_code:set (wcode)
WAIT_NEW = wcode ~= 0 and wcode ~= num (wait_code[1], 0)
input_group { "Display - Lines",
    show_ema     = input { default = true, type = input.plot_visibility }, ema_f_color  = input { default = "#FFD54F", type = input.color }, ema_m_color  = input { default = "#29B6F6", type = input.color },
    ema_s_color  = input { default = "#AB47BC", type = input.color }, show_sr      = input { default = true, type = input.plot_visibility }, res_color    = input { default = rgba(255,82,82,0.85), type = input.color },
    sup_color    = input { default = rgba(0,230,118,0.85), type = input.color }, show_major   = input { default = true, type = input.plot_visibility }, major_color  = input { default = rgba(255,255,255,0.55), type = input.color },
    show_range   = input { default = false, type = input.plot_visibility }, range_color  = input { default = rgba(255,255,255,0.35), type = input.color }, show_bb      = input { default = false, type = input.plot_visibility },
    bb_color     = input { default = rgba(120,144,156,0.6), type = input.color }
}
input_group { "Display - Signals",
    call_color    = input { default = "#00E676", type = input.color }, put_color     = input { default = "#FF1744", type = input.color }, show_trigger  = input { default = true, type = input.plot_visibility },
    show_regime   = input { default = true, type = input.plot_visibility }, regime_color  = input { default = rgba(176,190,197,0.9), type = input.color }, show_cancel   = input { default = true, type = input.plot_visibility },
    show_cancel_m = input { default = false, type = input.plot_visibility }, cancel_color  = input { default = rgba(255,193,7,0.9), type = input.color },
    chase_color   = input { default = "#FF9100", type = input.color }
}
if show_ema then
    plot (ema_f, "EMA 9",  ema_f_color, 1)
    plot (ema_m, "EMA 21", ema_m_color, 2)
    plot (ema_s, "EMA 50", ema_s_color, 2)
end
if show_sr then
    plot (res1, "Resistance", res_color, 2)
    plot (sup1, "Support",    sup_color, 2)
end
if show_major then
    plot (resM, "Major Resistance", major_color, 1)
    plot (supM, "Major Support",    major_color, 1)
end
if show_range then
    plot (rng_hi, "Range High", range_color, 1)
    plot (rng_lo, "Range Low",  range_color, 1)
end
if show_bb then
    plot (bb_up, "BB Upper", bb_color, 1)
    plot (bb_lo, "BB Lower", bb_color, 1)
end
local call_on = SIG_DIR == 1
local put_on  = SIG_DIR == -1
plot_shape (call_on and SIG_SCORE >= 85, "CALL Strong", shape_style.arrowup, shape_size.huge, call_color, shape_location.belowbar, 0, "CALL 85+", call_color)
plot_shape (call_on and SIG_SCORE >= 70 and SIG_SCORE < 85, "CALL Good", shape_style.arrowup, shape_size.large, call_color, shape_location.belowbar, 0, "CALL 70+", call_color)
plot_shape (call_on and SIG_SCORE < 70, "CALL Weak", shape_style.arrowup, shape_size.normal, call_color, shape_location.belowbar, 0, "CALL 60+", call_color)
plot_shape (put_on and SIG_SCORE >= 85, "PUT Strong", shape_style.arrowdown, shape_size.huge, put_color, shape_location.abovebar, 0, "PUT 85+", put_color)
plot_shape (put_on and SIG_SCORE >= 70 and SIG_SCORE < 85, "PUT Good", shape_style.arrowdown, shape_size.large, put_color, shape_location.abovebar, 0, "PUT 70+", put_color)
plot_shape (put_on and SIG_SCORE < 70, "PUT Weak", shape_style.arrowdown, shape_size.normal, put_color, shape_location.abovebar, 0, "PUT 60+", put_color)
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
plot_shape (call_on and NO_CHASE, "CALL No Chase", shape_style.xcross, shape_size.small, chase_color, shape_location.abovebar, 0, "NO CHASE", chase_color)
plot_shape (put_on and NO_CHASE, "PUT No Chase", shape_style.xcross, shape_size.small, chase_color, shape_location.belowbar, 0, "NO CHASE", chase_color)
if show_regime then
    plot_shape (REGIME_NEW and REGIME == REG_TREND,   "Regime Trend",    shape_style.flag, shape_size.tiny, regime_color, shape_location.top, 0, "TREND",  regime_color)
    plot_shape (REGIME_NEW and REGIME == REG_RANGE,   "Regime Range",    shape_style.flag, shape_size.tiny, regime_color, shape_location.top, 0, "RANGE",  regime_color)
    plot_shape (REGIME_NEW and REGIME == REG_HIGHVOL, "Regime High Vol", shape_style.flag, shape_size.tiny, regime_color, shape_location.top, 0, "HI-VOL", regime_color)
    plot_shape (REGIME_NEW and REGIME == REG_LOWVOL,  "Regime Low Vol",  shape_style.flag, shape_size.tiny, regime_color, shape_location.top, 0, "LO-VOL", regime_color)
    plot_shape (REGIME_NEW and REGIME == REG_TRANS,   "Regime Transit",  shape_style.flag, shape_size.tiny, regime_color, shape_location.top, 0, "TRANS",  regime_color)
end
local cb = WAIT_NEW and WAIT_SIDE == 1
local cs = WAIT_NEW and WAIT_SIDE == -1
local regime_block = WAIT_REASON == "RANGING" or WAIT_REASON == "TRANSITION" or WAIT_REASON == "LOW-VOL"
local momentum_block = WAIT_REASON == "CONFLICT" or WAIT_REASON == "WEAK-MOM" or WAIT_REASON == "OVEREXT"
    or WAIT_REASON == "EXHAUST" or WAIT_REASON == "WHIPSAW" or WAIT_REASON == "REVERSAL"
if show_cancel then
    plot_shape (cb and WAIT_REASON == "NEAR-SR",  "WAIT CALL near S/R",   shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:SR",     cancel_color)
    plot_shape (cb and regime_block,              "WAIT CALL regime",     shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:REGIME", cancel_color)
    plot_shape (cb and WAIT_REASON == "VOLATILE", "WAIT CALL volatility", shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:VOL",    cancel_color)
    plot_shape (cb and WAIT_REASON == "LATE",     "WAIT CALL late",       shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:LATE",   cancel_color)
    plot_shape (cs and WAIT_REASON == "NEAR-SR",  "WAIT PUT near S/R",    shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:SR",     cancel_color)
    plot_shape (cs and regime_block,              "WAIT PUT regime",      shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:REGIME", cancel_color)
    plot_shape (cs and WAIT_REASON == "VOLATILE", "WAIT PUT volatility",  shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:VOL",    cancel_color)
    plot_shape (cs and WAIT_REASON == "LATE",     "WAIT PUT late",        shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:LATE",   cancel_color)
end
if show_cancel_m then
    plot_shape (cb and momentum_block, "WAIT CALL momentum", shape_style.xcross, shape_size.tiny, cancel_color, shape_location.belowbar, 0, "X:MOM", cancel_color)
    plot_shape (cs and momentum_block, "WAIT PUT momentum",  shape_style.xcross, shape_size.tiny, cancel_color, shape_location.abovebar, 0, "X:MOM", cancel_color)
end
