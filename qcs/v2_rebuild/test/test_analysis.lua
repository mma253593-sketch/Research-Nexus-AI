-- Requirements 8-15: regime, trend, momentum, price action, entry timing,
-- volatility filter and adaptive profile, on hand-built feature tables
-- (exact control of every input) and on synthetic candle fixtures.
local C = require ("config")
local I = require ("indicators")
local R = require ("regime_detection")
local TR = require ("trend_context")
local MO = require ("momentum_analysis")
local PA = require ("price_action")
local ET = require ("entry_timing")
local VF = require ("volatility_filter")
local AP = require ("adaptive_profile")
local F = require ("fixtures")

-- feature table with n rows; spec values are constants or function(i)
local function feats (n, spec)
    local f = { n = n, swing_highs = spec.swing_highs or {}, swing_lows = spec.swing_lows or {} }
    for _, k in ipairs ({ "O", "H", "L", "C", "atr", "atr_base", "er", "ema_f", "ema_m", "ema_s", "rsi", "hist" }) do
        local v = spec[k]
        f[k] = {}
        for i = 1, n do
            if type (v) == "function" then f[k][i] = v (i) else f[k][i] = v end
        end
    end
    return f
end

local function trend_feats (dir, er, ratio)
    return feats (40, { C = function (i) return 2650 + dir * i end, atr = 1, atr_base = 1 / (ratio or 1), er = er or 0.5,
        ema_f = function (i) return 2650 + dir * (i - 1) end, ema_m = function (i) return 2650 + dir * (i - 3) end,
        ema_s = function (i) return 2650 + dir * (i - 8) * 1.0 end })
end

return function (T)
    local cfg = assert (C.load ())

    -- ----------------------------- regime -----------------------------
    T.case ("regime: TRENDING up / down with direction", function ()
        local up = R.detect (trend_feats (1), cfg)
        T.eq (up.regime, "TRENDING"); T.eq (up.direction, 1)
        local dn = R.detect (trend_feats (-1), cfg)
        T.eq (dn.regime, "TRENDING"); T.eq (dn.direction, -1)
    end)

    T.case ("regime: RANGING when efficiency is low and EMA50 flat", function ()
        local f = feats (40, { C = 2650, atr = 1, atr_base = 1, er = 0.1, ema_f = 2650.2, ema_m = 2650.1, ema_s = 2650 })
        T.eq (R.detect (f, cfg).regime, "RANGING")
    end)

    T.case ("regime: HIGH_VOL immediate, LOW_VOL confirmed", function ()
        local f = trend_feats (1, 0.5, 2.0)
        T.eq (R.detect (f, cfg).regime, "HIGH_VOL")
        local g = trend_feats (1, 0.5, 1.0); g.atr_base[40] = 0.5          -- only the newest bar is hot
        T.eq (R.detect (g, cfg).regime, "HIGH_VOL", "no confirmation needed for HIGH_VOL")
        local l = trend_feats (1, 0.5, 0.4)
        T.eq (R.detect (l, cfg).regime, "LOW_VOL")
    end)

    T.case ("regime: change needs confirm_bars, otherwise UNSTABLE/TRANSITION", function ()
        local f = trend_feats (1, 0.5)
        f.er[39] = 0.2                                                       -- previous bar was not trending
        local r = R.detect (f, cfg)
        T.eq (r.raw, "TRENDING"); T.eq (r.regime, "UNSTABLE"); T.eq (r.sub, "TRANSITION")
    end)

    T.case ("regime: whipsaw (repeated EMA9/21 crosses) -> UNSTABLE", function ()
        local f = trend_feats (1, 0.5)
        for i = 21, 40 do f.ema_f[i] = f.ema_m[i] + ((i % 3 == 0) and -0.5 or 0.5) end
        local r = R.detect (f, cfg)
        T.eq (r.regime, "UNSTABLE"); T.eq (r.sub, "WHIPSAW")
    end)

    T.case ("regime uses only data up to the evaluated bar", function ()
        local f = trend_feats (1, 0.5)
        local a = R.raw_at (f, 30, cfg)
        for i = 31, 40 do f.atr[i] = 50; f.er[i] = 0 end                  -- change the "future"
        T.eq (R.raw_at (f, 30, cfg), a)
    end)

    -- ----------------------------- trend ------------------------------
    T.case ("trend: M1 direction, consistency, structure, reversal", function ()
        local f = trend_feats (1)
        f.swing_highs = { { i = 20, price = 2660 }, { i = 30, price = 2670 } }
        f.swing_lows = { { i = 22, price = 2655 }, { i = 32, price = 2665 } }
        local t = TR.analyze (f, nil, cfg)
        T.eq (t.m1_dir, 1); T.eq (t.consistency, 1); T.eq (t.structure, 1); T.no (t.reversal[1])
        f.C[40] = 2660                                                       -- close below the last swing low
        T.ok (TR.analyze (f, nil, cfg).reversal[1], "structure break against CALL")
        local d = TR.analyze (trend_feats (-1), nil, cfg)
        T.eq (d.m1_dir, -1)
    end)

    T.case ("trend: M5 bias up / down / neutral and conflict flag", function ()
        local function m5 (dir)
            local c = {}
            for i = 1, 40 do c[i] = { h = 2650 + dir * i * 2 + 1, l = 2650 + dir * i * 2 - 1, c = 2650 + dir * i * 2 } end
            return I.compute_m5 (c, cfg)
        end
        T.eq (TR.m5_bias (m5 (1), cfg).bias, 1)
        T.eq (TR.m5_bias (m5 (-1), cfg).bias, -1)
        T.eq (TR.m5_bias (m5 (0), cfg).bias, 0)
        local t = TR.analyze (trend_feats (1), m5 (-1), cfg)
        T.ok (t.conflict, "M1 up vs M5 down is a conflict")
        T.ok (TR.m5_bias (m5 (1), cfg).strength > 0)
    end)

    -- ---------------------------- momentum ----------------------------
    local function mom_feats (hist, rsi)
        return feats (40, { O = 2650, C = 2650.1, H = 2651, L = 2649, atr = 1, rsi = rsi or 55,
            hist = function (i) return hist[i - 37] or 0 end })
    end
    T.case ("momentum: acceleration and deceleration", function ()
        local m = MO.analyze (mom_feats ({ 0.1, 0.2, 0.3 }), cfg)
        T.eq (m.accel, 1); T.ok (m.side[1].accelerating); T.ok (m.side[1].aligned); T.no (m.side[-1].aligned)
        local d = MO.analyze (mom_feats ({ 0.3, 0.2, 0.1 }), cfg)
        T.ok (d.side[1].decelerating); T.eq (d.accel, -1); T.ok (d.side[-1].turning)
        T.near (m.strength, 0.3 / cfg.momentum.hist_strong_atr > 1 and 1 or 0.3 / cfg.momentum.hist_strong_atr)
    end)

    T.case ("momentum: exhaustion by RSI, run length and climax candle", function ()
        T.ok (MO.analyze (mom_feats ({ 0.1, 0.2, 0.3 }, 80), cfg).side[1].exhausted, "RSI high")
        T.ok (MO.analyze (mom_feats ({ -0.1, -0.2, -0.3 }, 20), cfg).side[-1].exhausted, "RSI low")
        local f = mom_feats ({ 0.1, 0.2, 0.3 }, 55)                      -- every candle bullish -> long run
        T.ok (MO.analyze (f, cfg).side[1].exhausted, "run")
        local g = mom_feats ({ 0.1, 0.2, 0.3 }, 55)
        for i = 1, 40 do g.C[i] = (i % 2 == 0) and 2650.1 or 2649.9 end
        T.no (MO.analyze (g, cfg).side[1].exhausted)
        g.O[40], g.C[40], g.H[40] = 2650, 2653, 2653
        T.ok (MO.analyze (g, cfg).side[1].exhausted, "climax")
    end)

    T.case ("momentum: divergence from confirmed swings only", function ()
        local f = mom_feats ({ 0.1, 0.2, 0.3 }, 55)
        f.swing_highs = { { i = 28, price = 2660 }, { i = 35, price = 2662 } }
        f.rsi[28], f.rsi[35] = 70, 62
        T.ok (MO.analyze (f, cfg).side[1].divergence, "bearish divergence against CALL")
        f.rsi[35] = 69
        T.no (MO.analyze (f, cfg).side[1].divergence, "RSI gap below div_min_rsi")
        f.rsi[35] = 62; f.swing_highs[2].i = 20; f.swing_highs[1].i = 10
        T.no (MO.analyze (f, cfg).side[1].divergence, "too old")
        local g = mom_feats ({ -0.1, -0.2, -0.3 }, 45)
        g.swing_lows = { { i = 28, price = 2640 }, { i = 35, price = 2638 } }
        g.rsi[28], g.rsi[35] = 30, 38
        T.ok (MO.analyze (g, cfg).side[-1].divergence, "bullish divergence against PUT")
    end)

    -- -------------------------- price action --------------------------
    local function pa_feats (last2, extra)
        local n = 40
        local f = feats (n, { O = 2650, C = 2650.05, H = 2650.5, L = 2649.5, atr = 1 })
        f.O[n - 1], f.H[n - 1], f.L[n - 1], f.C[n - 1] = table.unpack (last2[1])
        f.O[n], f.H[n], f.L[n], f.C[n] = table.unpack (last2[2])
        for k, v in pairs (extra or {}) do f[k] = v end
        return f
    end
    local function mirror (f)
        local g = feats (f.n, {})
        for i = 1, f.n do
            g.O[i], g.C[i], g.H[i], g.L[i] = 5300 - f.O[i], 5300 - f.C[i], 5300 - f.L[i], 5300 - f.H[i]
            g.atr[i] = f.atr[i]
        end
        g.swing_highs, g.swing_lows = {}, {}
        for _, p in ipairs (f.swing_lows) do g.swing_highs[#g.swing_highs + 1] = { i = p.i, price = 5300 - p.price } end
        for _, p in ipairs (f.swing_highs) do g.swing_lows[#g.swing_lows + 1] = { i = p.i, price = 5300 - p.price } end
        return g
    end

    T.case ("price action: bullish engulfing (and mirrored bearish engulfing)", function ()
        local f = pa_feats ({ { 2650.6, 2650.7, 2649.9, 2650.0 }, { 2649.95, 2650.95, 2649.9, 2650.9 } })
        local p = PA.analyze (f, cfg)
        T.has (p.side[1].patterns, "ENGULF"); T.lacks (p.side[-1].patterns, "ENGULF")
        T.has (PA.analyze (mirror (f), cfg).side[-1].patterns, "ENGULF", "mirror symmetry")
        local weak = pa_feats ({ { 2650.6, 2650.7, 2649.9, 2650.0 }, { 2649.95, 2650.55, 2649.9, 2650.5 } })
        T.lacks (PA.analyze (weak, cfg).side[1].patterns, "ENGULF", "must engulf the prior body")
    end)

    T.case ("price action: rejection (pin) and confirmed rejection", function ()
        local pin = pa_feats ({ { 2650, 2650.2, 2649.9, 2650.1 }, { 2650.2, 2650.4, 2649.4, 2650.35 } })
        T.has (PA.analyze (pin, cfg).side[1].patterns, "REJECTION")
        local conf = pa_feats ({ { 2650.2, 2650.4, 2649.4, 2650.35 }, { 2650.35, 2650.9, 2650.3, 2650.85 } })
        T.has (PA.analyze (conf, cfg).side[1].patterns, "REJECTION_CONF")
        T.has (PA.analyze (mirror (pin), cfg).side[-1].patterns, "REJECTION")
    end)

    T.case ("price action: breakout and failed breakout against levels", function ()
        local f = pa_feats ({ { 2650, 2650.4, 2649.8, 2650.3 }, { 2650.3, 2651.4, 2650.25, 2651.3 } },
            { swing_highs = { { i = 30, price = 2650.9 } }, swing_lows = { { i = 31, price = 2649 } } })
        local p = PA.analyze (f, cfg).side[1]
        -- nearest level above the previous close is the 30-bar range high (2650.5), below the swing high
        T.has (p.patterns, "BREAKOUT"); T.near (p.breakout_level, 2650.5)
        local fb = pa_feats ({ { 2649.6, 2649.7, 2649.2, 2649.3 }, { 2649.3, 2649.9, 2648.7, 2649.8 } },
            { swing_highs = { { i = 30, price = 2652 } }, swing_lows = { { i = 31, price = 2649.0 } } })
        T.has (PA.analyze (fb, cfg).side[1].patterns, "FAILED_BREAK")
        T.has (PA.analyze (mirror (fb), cfg).side[-1].patterns, "FAILED_BREAK")
    end)

    T.case ("price action: room to next obstacle and strong close", function ()
        local f = pa_feats ({ { 2650, 2650.3, 2649.9, 2650.1 }, { 2650.1, 2650.75, 2650.05, 2650.7 } },
            { swing_highs = { { i = 30, price = 2652.2 } } })
        local p = PA.analyze (f, cfg).side[1]
        T.has (p.patterns, "STRONG_CLOSE")
        T.near (p.room_atr, 1.5, 1e-9)
    end)

    -- -------------------------- entry timing --------------------------
    local function pullback_feats (ext)
        local n = 40
        local f = feats (n, { atr = 1, rsi = 55, hist = 0.1,
            ema_f = function (i) return 2650 + 0.2 * i end, ema_m = function (i) return 2649 + 0.2 * i end,
            ema_s = function (i) return 2647 + 0.2 * i end })
        for i = 1, n do
            local e = f.ema_f[i]
            f.O[i], f.C[i], f.H[i], f.L[i] = e + 0.3, e + 0.5, e + 0.7, e + 0.2
        end
        -- counter candle touching EMA9, then a strong bullish trigger
        local e = f.ema_f[n - 1]
        f.O[n - 1], f.C[n - 1], f.H[n - 1], f.L[n - 1] = e + 0.4, e + 0.1, e + 0.5, e - 0.05
        local e9 = f.ema_f[n]
        f.O[n], f.C[n], f.H[n], f.L[n] = e9 + 0.1, e9 + 0.8 + (ext or 0), e9 + 0.85 + (ext or 0), e9 + 0.05
        return f
    end
    local prof = AP.select ({ regime = "TRENDING" }, cfg)

    T.case ("entry timing: pullback continuation detected with timing quality", function ()
        local f = pullback_feats ()
        local pa = PA.analyze (f, cfg).side[1]
        local e = ET.analyze_side (f, 1, pa, prof, cfg).PULLBACK_CONTINUATION
        T.ok (e.present, "pullback present"); T.no (e.late); T.ok (e.quality > 0 and e.quality <= 1)
        local put = ET.analyze_side (f, -1, PA.analyze (f, cfg).side[-1], prof, cfg).PULLBACK_CONTINUATION
        T.no (put.present, "no PUT pullback in an uptrend")
    end)

    T.case ("entry timing: late entry after an extended move, no room near resistance", function ()
        local f = pullback_feats (1.2)                                     -- trigger closes far above EMA21
        local e = ET.analyze_side (f, 1, PA.analyze (f, cfg).side[1], prof, cfg).PULLBACK_CONTINUATION
        T.ok (e.late, "late"); T.ok (e.late_why == "EXTENDED_FROM_EMA9" or e.late_why == "TRIGGER_TOO_LARGE", e.late_why)
        local g = pullback_feats ()
        g.swing_highs = { { i = 30, price = g.C[g.n] + 0.3 } }
        local e2 = ET.analyze_side (g, 1, PA.analyze (g, cfg).side[1], prof, cfg).PULLBACK_CONTINUATION
        T.ok (e2.no_room, "resistance 0.3 ATR ahead")
    end)

    -- ------------------------ volatility filter -----------------------
    local function vol_feats ()
        local f = feats (40, { atr = 1, er = 0.4 })
        for i = 1, 40 do f.O[i], f.C[i], f.H[i], f.L[i] = 2650, 2650.5, 2650.6, 2649.9 end
        return f
    end
    T.case ("volatility filter: normal passes; spike, expansion, flat feed and noise rejected", function ()
        T.ok (VF.evaluate (vol_feats (), cfg).ok)
        local s = vol_feats (); s.H[40] = 2655
        T.has (VF.evaluate (s, cfg).reasons, "ABNORMAL_RANGE")
        local x = vol_feats (); x.atr[40] = 2
        T.has (VF.evaluate (x, cfg).reasons, "VOL_EXPANSION")
        local fl = vol_feats (); for i = 33, 40 do fl.O[i], fl.C[i], fl.H[i], fl.L[i] = 2650, 2650, 2650, 2650 end
        T.has (VF.evaluate (fl, cfg).reasons, "LOW_INFORMATION")
        local z = vol_feats (); for i = 1, 40 do z.atr[i] = 0.01 end
        T.has (VF.evaluate (z, cfg).reasons, "LOW_INFORMATION")
        local nz = vol_feats (); for i = 1, 40 do nz.er[i] = 0.05; nz.O[i], nz.C[i] = 2650.2, 2650.25 end
        T.has (VF.evaluate (nz, cfg).reasons, "NOISE")
        T.eq (VF.evaluate (vol_feats (), cfg).spread, "NOT_AVAILABLE")
    end)

    -- ------------------------- adaptive profile -----------------------
    T.case ("adaptive profile: deterministic mapping, defensive regimes, bounded thresholds", function ()
        local t = AP.select ({ regime = "TRENDING" }, cfg)
        T.ok (t.tradable); T.has (t.setups, "PULLBACK_CONTINUATION"); T.lacks (t.setups, "RANGE_REJECTION")
        T.eq (t.min_score, 65)
        local r = AP.select ({ regime = "RANGING" }, cfg)
        T.has (r.setups, "RANGE_REJECTION"); T.lacks (r.setups, "TREND_CONTINUATION"); T.eq (r.min_score, 70)
        for _, g in ipairs ({ "HIGH_VOL", "LOW_VOL", "UNSTABLE" }) do
            local d = AP.select ({ regime = g, sub = "X" }, cfg)
            T.no (d.tradable); T.eq (#d.setups, 0); T.eq (d.name, "DEFENSIVE")
        end
        local c2 = C.defaults (); c2.profiles.TRENDING.min_score = 10                    -- bypassing validation
        T.eq (AP.select ({ regime = "TRENDING" }, c2).min_score, 60, "floor enforced")
        T.eq (AP.select ({ regime = "TRENDING" }, cfg).min_score, AP.select ({ regime = "TRENDING" }, cfg).min_score)
    end)

    T.case ("trend continuation and range rejection setups on synthetic fixtures", function ()
        -- at least one bar of each type is found somewhere in a long mixed fixture
        local E = require ("main")
        local m1 = F.series (F.MIXED, 11)
        local seen = {}
        for Tn = 241, #m1 do
            local r = E.evaluate ({ now = m1[Tn].t, m1 = { table.unpack (m1, Tn - 240, Tn - 1) } }, cfg)
            for _, s in ipairs ({ "call", "put" }) do
                local sd = r.diagnostics[s]
                if sd then for _, c in ipairs (sd.candidates) do if c.present then seen[c.setup] = true end end end
            end
        end
        for _, s in ipairs (C.SETUPS) do T.ok (seen[s], "setup never present: " .. s) end
    end)
end
