-- Configuration validation + indicator correctness (supports reqs 8-14).
local C = require ("config")
local I = require ("indicators")
local E = require ("main")
local F = require ("fixtures")

return function (T)
    T.case ("default configuration is valid", function ()
        local cfg, errs = C.load ()
        T.ok (cfg, table.concat (errs, "; "))
        T.eq (cfg.version, "2.0.0")
    end)

    T.case ("configuration: bounds, types, unknown keys and cross-field rules rejected", function ()
        local bad = {
            { o = { scoring = { min_margin = -1 } }, e = "scoring.min_margin: -1 outside [0, 100]" },
            { o = { indicators = { ema_fast = 2.5 } }, e = "indicators.ema_fast: must be an integer" },
            { o = { indicators = { ema_fast = 30 } }, e = "indicators.ema_fast must be < indicators.ema_mid" },
            { o = { regime = { er_range = 0.5 } }, e = "regime.er_range must be < regime.er_trend" },
            { o = { data = { bogus = 1 } }, e = "data.bogus: unknown key" },
            { o = { data = { m5_source = "web" } }, e = "data.m5_source: must be auto|provided|aggregate" },
            { o = { profiles = { TRENDING = { min_score = 55 } } }, e = "profiles.TRENDING.min_score: below scoring.global_min_score" },
            { o = { profiles = { RANGING = { setups = { "TREND_CONTINUATION" } } } }, e = "profiles.RANGING.setups: continuation setups not allowed in RANGING" },
            { o = { profiles = { TRENDING = { setups = { "MAGIC" } } } }, e = "profiles.TRENDING.setups[1]: unknown setup MAGIC" },
            { o = { data = { min_m1_bars = 100, m1_window = 240 } }, e = "data.min_m1_bars must be >= 115 for the indicator lengths" },
            { o = { instrument = "EURUSD" }, e = "instrument: must be XAUUSD" },
            { o = { extra = {} }, e = "extra: unknown section" },
        }
        for _, b in ipairs (bad) do
            local cfg, errs = C.load (b.o)
            T.eq (cfg, nil, "must reject " .. b.e)
            T.has (errs, b.e)
        end
    end)

    T.case ("invalid configuration never produces a signal", function ()
        local m1 = F.series (F.UP, 5)
        local cfg = C.defaults (); cfg.scoring.min_margin = "x"
        local r = E.evaluate (F.input (m1), cfg)
        T.eq (r.decision, "WAIT"); T.has (r.reasons, "CONFIG_INVALID")
        T.eq (E.evaluate (F.input (m1), nil).decision, "WAIT")
    end)

    T.case ("overrides merge deeply and do not mutate defaults", function ()
        local cfg = assert (C.load ({ scoring = { min_margin = 20 }, profiles = { TRENDING = { setups = { "TREND_CONTINUATION" } } } }))
        T.eq (cfg.scoring.min_margin, 20); T.eq (cfg.scoring.global_min_score, 60)
        T.eq (#cfg.profiles.TRENDING.setups, 1)
        T.eq (C.defaults ().scoring.min_margin, 15)
    end)

    T.case ("EMA / SMA / RMA match hand computation", function ()
        local x = { 1, 2, 3, 4, 5, 6 }
        local e = I.ema (x, 3)
        T.eq (e[2], nil); T.near (e[3], 2); T.near (e[4], 3); T.near (e[6], 5)
        local s = I.sma (x, 3)
        T.eq (s[2], nil); T.near (s[3], 2); T.near (s[6], 5)
        local sl = I.sma (x, 3, 1)
        T.eq (sl[3], nil); T.near (sl[4], 2); T.near (sl[6], 4)
        local r = I.rma ({ 2, 2, 2, 8 }, 2)
        T.near (r[2], 2); T.near (r[3], 2); T.near (r[4], 5)
    end)

    T.case ("rolling SMA and efficiency ratio equal naive formulas", function ()
        local m1 = F.series (F.MIXED, 3)
        local Cs = {}
        for i, b in ipairs (m1) do Cs[i] = b.c end
        local s, er = I.sma (Cs, 20, 1), I.efficiency (Cs, 20)
        for i = 30, #Cs, 37 do
            local sum = 0
            for j = i - 20, i - 1 do sum = sum + Cs[j] end
            T.near (s[i], sum / 20, 1e-6)
            local path = 0
            for j = i - 19, i do path = path + math.abs (Cs[j] - Cs[j - 1]) end
            T.near (er[i], math.abs (Cs[i] - Cs[i - 20]) / path, 1e-9)
        end
    end)

    T.case ("RSI: flat = 50, only gains = 100, only losses = 0; ATR of constant range", function ()
        local flat, up, dn = {}, {}, {}
        for i = 1, 30 do flat[i] = 10; up[i] = i; dn[i] = 100 - i end
        T.eq (I.rsi (flat, 14)[30], 50); T.eq (I.rsi (up, 14)[30], 100); T.eq (I.rsi (dn, 14)[30], 0)
        local H, L, Cc = {}, {}, {}
        for i = 1, 30 do H[i], L[i], Cc[i] = 11, 10, 10.5 end
        T.near (I.atr (H, L, Cc, 14)[30], 1)
    end)

    T.case ("pivots are confirmed only after p closed bars (no look-ahead)", function ()
        local H = { 1, 2, 3, 9, 3, 2, 1 }
        T.eq (#I.pivots (H, 3, 1), 1); T.eq (I.pivots (H, 3, 1)[1].i, 4)
        local early = { 1, 2, 3, 9, 3, 2 }          -- only 2 bars after the peak: not confirmed
        T.eq (#I.pivots (early, 3, 1), 0)
        local plateau = { 1, 2, 3, 9, 9, 2, 1, 0 }   -- one pivot per plateau (left strict, right >=)
        T.eq (#I.pivots (plateau, 3, 1), 1)
        local lows = { 9, 8, 7, 1, 7, 8, 9 }
        T.eq (I.pivots (lows, 3, -1)[1].price, 1)
    end)
end
