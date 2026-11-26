instrument { name = "XAUUSD Smart Entry V2 Lite", short_name = "XAU-SE2L", overlay = true }
-- V2.0 Lite: same signal engine as V2 Main (default settings), short display. Closed candles only.
min_score     = input (70, "Min score", input.integer, 60, 95)
cooldown_bars = input (3, "Cooldown (bars)", input.integer, 0, 50)
allow_trans   = input (true, "Trade transitional market", input.boolean)
input_group { "Colors", call_color = input { default = "#00E676", type = input.color },
                        put_color  = input { default = "#FF1744", type = input.color } }
local RSI_HI, RSI_LO, SPIKE, ADX_IN, ADX_OUT, ADX_RNG, ER_TR, ER_RG = 78, 22, 2.8, 25, 20, 18, 0.25, 0.15
local HV_IN, HV_OUT, LV_IN, LV_OUT, CONFIRM, PIV, MPIV, ROUND, ROOM = 1.6, 1.35, 0.6, 0.7, 3, 5, 15, 10, 0.8
local EXTRA, TCOOL, LBODY, LEXT, WLEN, WMAX, XRUN, CHASE = 8, 5, 1.8, 2.2, 10, 2, 5, 0.35

ema_f = ema (close, 9)
ema_m = ema (close, 21)
ema_s = ema (close, 50)
rsi_val = rsi (close, 14)
macd_fast_ma = ema (close, 12)
macd_slow_ma = ema (close, 26)
macd_line = macd_fast_ma - macd_slow_ma
macd_sig = ema (macd_line, 9)
macd_hist = macd_line - macd_sig
bb_mid = sma (close, 20)
bb_dev = stdev (close, 20) * 2.0
bb_width = ((bb_mid + bb_dev) - (bb_mid - bb_dev)) / bb_mid
bb_width_avg = sma (bb_width, 60)
atr_val = rma (tr, 14)
atr_base = sma (atr_val, 100)
clv_avg = sma ((close - low) / max (high - low, 0.0000001), 5)
adx_up = change (high)
adx_dn = -change (low)
adx_pdm = iff (adx_up > adx_dn and nz (adx_up) > 0, adx_up, 0)
adx_mdm = iff (adx_dn > adx_up and nz (adx_dn) > 0, adx_dn, 0)
adx_atr = rma (tr, 14)
adx_pdi = 100 * rma (adx_pdm / adx_atr, 14)
adx_mdi = 100 * rma (adx_mdm / adx_atr, 14)
adx_val = 100 * rma (abs (adx_pdi - adx_mdi) / (adx_pdi + adx_mdi), 14)
er_val = abs (change (close, 20)) / sum (abs (change (close)), 20)
piv_hp = highest (high, PIV)
piv_lp = lowest (low, PIV)
maj_hp = highest (high, MPIV)
maj_lp = lowest (low, MPIV)
rng_hi = highest (high, 50)
rng_lo = lowest (low, 50)

local function num (s, d)
    local v = get_value (s)
    if v == nil or v ~= v or v == math.huge or v == -math.huge then return d end
    return v
end
local function clamp (x, a, b) if x < a then return a elseif x > b then return b end return x end
local function piv (p, ser, w, sgn)
    local x, l, r = num (ser[p + 1]), num (w[p + 2]), num (w[1])
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
resM = make_series ()
resM_old = make_series ()
supM = make_series ()
supM_old = make_series ()
remember (res1, res2, piv (PIV, high, piv_hp, 1))
remember (sup1, sup2, piv (PIV, low, piv_lp, -1))
remember (resM, resM_old, piv (MPIV, high, maj_hp, 1))
remember (supM, supM_old, piv (MPIV, low, maj_lp, -1))
bar_count = make_series ()
bar_count:set (num (bar_count[1], 0) + 1)
sig_age = make_series ()
reg_state = make_series ()
reg_cand = make_series ()
reg_cnt = make_series ()
ema_cross = make_series ()

local O1, H1, L1, C1 = num (open[1]), num (high[1]), num (low[1]), num (close[1])
local O2, H2, L2, C2 = num (open[2]), num (high[2]), num (low[2]), num (close[2])
local EF1, EF2, EM1, EM2 = num (ema_f[1]), num (ema_f[2]), num (ema_m[1]), num (ema_m[2])
local ES1, ES6, R1, R2 = num (ema_s[1]), num (ema_s[6]), num (rsi_val[1]), num (rsi_val[2])
local HI1, HI2, HI3 = num (macd_hist[1]), num (macd_hist[2]), num (macd_hist[3])
local ATR1, ATR2, ATRB1 = num (atr_val[1]), num (atr_val[2]), num (atr_base[1])
local BW1, BWA1, CLV1 = num (bb_width[1]), num (bb_width_avg[1]), num (clv_avg[1], 0.5)
local ADX1, PDI1, MDI1, ER1 = num (adx_val[1]), num (adx_pdi[1]), num (adx_mdi[1]), num (er_val[1], 0)
local RES1, RES2, SUP1, SUP2 = num (res1), num (res2), num (sup1), num (sup2)
local RESM, SUPM, RHI2, RLO2 = num (resM), num (supM), num (rng_hi[2]), num (rng_lo[2])
local data_ok = (num (bar_count, 0) > 115 and O1 and H1 and L1 and C1 and O2 and H2 and L2 and C2
    and EF1 and EF2 and EM1 and EM2 and ES1 and ES6 and R1 and R2 and HI1 and HI2 and HI3
    and ATR1 and ATR2 and ATRB1 and BW1 and BWA1 and ADX1 and PDI1 and MDI1
    and ATR1 > 0 and ATR2 > 0 and ATRB1 > 0 and BWA1 > 0) and true or false

local crossed = 0
if EF1 and EM1 and EF2 and EM2 and ((EF1 - EM1) > 0) ~= ((EF2 - EM2) > 0) then crossed = 1 end
ema_cross:set (crossed)
local whip = 0
for i = 0, WLEN - 1 do whip = whip + num (ema_cross[i], 0) end
local function run (dir)
    local n = 0
    for i = 1, XRUN + 1 do
        local o, c = num (open[i]), num (close[i])
        if o == nil or c == nil or dir * (c - o) <= 0 then break end
        n = n + 1
    end
    return n
end
local run_up, run_dn = run (1), run (-1)

SIG_DIR, SIG_SCORE, NO_CHASE, REGIME = 0, 0, false, 0
local prev_state, prev_cand, prev_cnt = num (reg_state[1], 0), num (reg_cand[1], 0), num (reg_cnt[1], 0)
local function classify (prev)
    local atrr, bwr = ATR1 / ATRB1, BW1 / BWA1
    if (H1 - L1) > SPIKE * ATR2 or atrr >= HV_IN or (prev == 3 and atrr >= HV_OUT) then return 3 end
    if (atrr <= LV_IN and bwr <= 0.85) or (prev == 4 and atrr <= LV_OUT) then return 4 end
    local slope = (ES1 - ES6) / (5 * ATR1)
    local stacked = (EF1 > EM1 and EM1 > ES1) or (EF1 < EM1 and EM1 < ES1)
    local aligned = (EM1 > ES1 and slope > 0) or (EM1 < ES1 and slope < 0)
    if prev == 1 then
        if ADX1 >= ADX_OUT and aligned then return 1 end
    elseif ADX1 >= ADX_IN and ER1 >= ER_TR and stacked and aligned and math.abs (slope) >= 0.02 then
        return 1
    end
    if ADX1 < ADX_RNG and (ER1 < ER_RG or math.abs (EF1 - ES1) < 0.5 * ATR1) then return 2 end
    return 5
end
if data_ok then
    local raw = classify (prev_state)
    local cnt = (raw == prev_cand) and (prev_cnt + 1) or 1
    local state = prev_state
    if prev_state == 0 or raw == 3 or (raw ~= prev_state and cnt >= CONFIRM) then state = raw end
    reg_state:set (state); reg_cand:set (raw); reg_cnt:set (cnt)
    REGIME = state
else
    reg_state:set (prev_state); reg_cand:set (prev_cand); reg_cnt:set (prev_cnt)
end

-- regime: 1 trend (normal), 5 transitional (stricter), 2 range / 3 high vol / 4 low vol = WAIT
local strict = REGIME == 5
local P = { ok = REGIME == 1 or (strict and allow_trans), pts = REGIME == 1 and 15 or 6,
            min = min_score, room = ROOM, lext = LEXT, lbody = LBODY, rmid = 50, rhi = RSI_HI,
            rlo = RSI_LO, accel = false, pamin = 10, cool = cooldown_bars }
if strict then
    P.min, P.room = clamp (min_score + EXTRA, min_score, 95), clamp (ROOM * 1.5, ROOM, 3.0)
    P.lext, P.lbody = clamp (LEXT * 0.75, 1.0, LEXT), clamp (LBODY * 0.85, 0.8, LBODY)
    P.rmid, P.rhi, P.rlo, P.accel, P.pamin = 52, math.min (RSI_HI, 72), math.max (RSI_LO, 28), true, 15
    P.cool = math.max (cooldown_bars, TCOOL)
end

-- side-neutral check: s = 1 CALL, s = -1 PUT (prices mirrored)
local function evaluate (s)
    local o1, h1, l1, c1, o2, h2, l2, c2
    if s == 1 then o1, h1, l1, c1, o2, h2, l2, c2 = O1, H1, L1, C1, O2, H2, L2, C2
    else o1, h1, l1, c1, o2, h2, l2, c2 = -O1, -L1, -H1, -C1, -O2, -L2, -H2, -C2 end
    local ef1, em1, em2, es1, es6 = s * EF1, s * EM1, s * EM2, s * ES1, s * ES6
    local r1 = s == 1 and R1 or 100 - R1
    local r2 = s == 1 and R2 or 100 - R2
    local hi1, hi2, hi3 = s * HI1, s * HI2, s * HI3
    local pdi, mdi = PDI1, MDI1
    if s == -1 then pdi, mdi = MDI1, PDI1 end
    local clv = s == 1 and CLV1 or 1 - CLV1
    local obst, supp = {}, {}
    local function add (t, x) if x ~= nil then t[#t + 1] = s * x end end
    local brk, sweep, rhi
    if s == 1 then
        add (obst, RES1) add (obst, RES2) add (obst, RESM) add (obst, RHI2)
        add (supp, SUP1) add (supp, SUP2) add (supp, SUPM) add (supp, RLO2)
        brk, sweep, rhi = RES1, SUP1, RHI2
    else
        add (obst, SUP1) add (obst, SUP2) add (obst, SUPM) add (obst, RLO2)
        add (supp, RES1) add (supp, RES2) add (supp, RESM) add (supp, RHI2)
        brk, sweep, rhi = SUP1 and -SUP1, RES1 and -RES1, RLO2 and -RLO2
    end
    local atr = ATR2
    local rng1, rng2 = math.max (h1 - l1, 0.0000001), math.max (h2 - l2, 0.0000001)
    local body1, body2 = math.abs (c1 - o1), math.abs (c2 - o2)
    local upw1, loww1 = h1 - math.max (c1, o1), math.min (c1, o1) - l1
    local loww2, cpos1 = math.min (c2, o2) - l2, (c1 - l1) / rng1
    local room = 99
    for _, x in ipairs (obst) do if x > c1 then room = math.min (room, (x - c1) / atr) end end
    local nxt = math.ceil (c1 / ROUND) * ROUND
    if nxt <= c1 then nxt = nxt + ROUND end
    room = math.min (room, (nxt - c1) / atr)
    local near = nil
    for _, x in ipairs (supp) do if x < c1 and (near == nil or x > near) then near = x end end
    local function at_sup (lp, e) return lp <= e + 0.15 * atr or (near ~= nil and lp <= near + 0.25 * atr) end

    local pa, trig = 0, ""
    local function take (p, t) if p > pa then pa, trig = p, t end end
    if c1 > o1 and c2 < o2 and c1 >= o2 and o1 <= c2 and body1 >= 1.2 * body2 and body2 >= 0.15 * atr
       and body1 >= 0.4 * atr and cpos1 >= 0.7 then take (20, "ENGULF") end
    if sweep ~= nil and l1 < sweep - 0.1 * atr and c1 > sweep and loww1 >= 0.5 * rng1 and cpos1 >= 0.6 then
        take (18, "FALSE-BRK") end
    if loww2 >= 0.5 * rng2 and rng2 >= 0.5 * atr and at_sup (l2, em2) and c1 > o1
       and c1 > math.max (o2, c2) and cpos1 >= 0.6 then take (17, "REJECT") end
    if loww1 >= 2 * body1 and loww1 >= 0.6 * rng1 and upw1 <= 0.25 * rng1 and rng1 >= 0.6 * atr
       and at_sup (l1, em1) then take (15, "PIN") end
    if brk ~= nil and c1 > brk + 0.15 * atr and c2 <= brk and c1 > o1 and body1 >= 0.55 * rng1
       and cpos1 >= 0.75 and body1 <= 2.0 * atr then take (15, "BREAKOUT") end
    if c1 > o1 and body1 >= 0.6 * rng1 and cpos1 >= 0.75 and body1 >= 0.4 * atr and body1 <= 1.5 * atr then
        take (10, "MOMENTUM") end

    -- Score 2.0: regime + trend + momentum + price action + entry + volatility - penalties
    local sT = ((ef1 > em1 and em1 > es1) and 8 or 0) + 7 * clamp ((ADX1 - 15) / 20, 0, 1)
        + 5 * clamp ((pdi - mdi) / 10, 0, 1)
    local sM = 8 * clamp ((r1 - 50) / 15, 0, 1)
    if hi1 > 0 and hi1 > hi2 then sM = sM + 7 elseif hi1 > 0 then sM = sM + 3 end
    local ext = (c1 - em1) / atr
    local sE = 12 * clamp ((room - P.room) / 2.0, 0, 1)
        + 8 * (1 - clamp ((ext - 1.0) / math.max (P.lext - 1.0, 0.1), 0, 1))
    local sV = 10 * (1 - clamp (math.abs (math.log (ATR1 / ATRB1)) / math.log (1.6), 0, 1))
    local pen = (clv < 0.45 and 6 or 0) + (r1 < r2 and 5 or 0) + (upw1 >= 0.35 * rng1 and 6 or 0)
    local score = math.floor (clamp (P.pts + sT + sM + pa + sE + sV - pen, 0, 100) + 0.5)

    local rlimit = s == 1 and P.rhi or 100 - P.rlo
    local ok = P.ok
        and em1 > es1 and c1 > es1 and es1 > es6 and ef1 > em1             -- trend
        and not (sweep ~= nil and c1 < sweep)                              -- no structure break
        and r1 > P.rmid and hi1 > 0                                        -- momentum agrees
        and not ((hi1 < hi2 and hi2 < hi3) or (P.accel and hi1 <= hi2))     -- not fading
        and whip < WMAX and r1 <= rlimit                                    -- no whipsaw / overextension
        and run (s) < XRUN and not (rhi ~= nil and h1 >= rhi and upw1 >= 0.4 * rng1)  -- no exhaustion
        and pa >= P.pamin and cpos1 >= 0.5                                  -- price action
        and body1 <= P.lbody * atr and ext <= P.lext and room >= P.room      -- not late, room to S/R
        and score >= P.min
    return ok, score
end

local prev_age = num (sig_age[1], 999)
if data_ok then
    local bok, bsc = evaluate (1)
    local sok, ssc = evaluate (-1)
    local side, sc = 0, 0
    if bok then side, sc = 1, bsc elseif sok then side, sc = -1, ssc end
    if side ~= 0 and prev_age >= P.cool then SIG_DIR, SIG_SCORE = side, sc end
    if SIG_DIR ~= 0 then
        local o0, c0 = num (open), num (close)
        NO_CHASE = o0 ~= nil and c0 ~= nil and SIG_DIR * (c0 - o0) > CHASE * ATR1
    end
end
sig_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)

plot (ema_f, "EMA 9", "#FFD54F", 1)
plot (ema_m, "EMA 21", "#29B6F6", 2)
plot (ema_s, "EMA 50", "#AB47BC", 2)
plot (res1, "Resistance", rgba(255,82,82,0.85), 2)
plot (sup1, "Support", rgba(0,230,118,0.85), 2)
plot_shape (SIG_DIR == 1 and SIG_SCORE >= 85, "CALL Strong", shape_style.arrowup, shape_size.huge, call_color, shape_location.belowbar, 0, "CALL 85+", call_color)
plot_shape (SIG_DIR == 1 and SIG_SCORE < 85, "CALL", shape_style.arrowup, shape_size.large, call_color, shape_location.belowbar, 0, "CALL", call_color)
plot_shape (SIG_DIR == -1 and SIG_SCORE >= 85, "PUT Strong", shape_style.arrowdown, shape_size.huge, put_color, shape_location.abovebar, 0, "PUT 85+", put_color)
plot_shape (SIG_DIR == -1 and SIG_SCORE < 85, "PUT", shape_style.arrowdown, shape_size.large, put_color, shape_location.abovebar, 0, "PUT", put_color)
plot_shape (SIG_DIR ~= 0 and NO_CHASE, "No Chase", shape_style.xcross, shape_size.small, "#FF9100", shape_location.top, 0, "NO CHASE", "#FF9100")
