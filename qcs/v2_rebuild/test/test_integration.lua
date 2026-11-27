-- Requirements 20 + 22: integration through the public API, edge cases.
local C = require ("config")
local E = require ("main")
local F = require ("fixtures")
local DV = require ("data_validation")

local function window (m1, T, W)
    local o = {}
    for j = math.max (1, T - W), T - 1 do local b = m1[j]; o[#o + 1] = { t = b.t, o = b.o, h = b.h, l = b.l, c = b.c } end
    return o
end

return function (T)
    local cfg = assert (C.load ())

    T.case ("integration: full diagnostics record on every evaluation", function ()
        local m1 = F.series (F.MIXED, 11)
        local run = E.new_runner (cfg)
        local seen = { CALL = 0, PUT = 0, WAIT = 0 }
        for Tn = 241, #m1, 2 do
            local r = run:step ({ now = m1[Tn].t, m1 = window (m1, Tn, 240) })
            local d = r.diagnostics
            seen[r.decision] = seen[r.decision] + 1
            for _, k in ipairs ({ "timestamp", "engine_version", "config_version", "decision", "reasons", "data",
                                  "call_score", "put_score", "selected_profile" }) do
                T.ok (d[k] ~= nil, "diagnostics." .. k)
            end
            if d.data.valid then
                for _, k in ipairs ({ "regime", "m5_context", "m1", "volatility", "momentum", "profile" }) do
                    T.ok (d[k] ~= nil, "diagnostics." .. k .. " at " .. Tn)
                end
            end
            if r.decision ~= "WAIT" then
                T.ok (r.setup ~= nil and r.score >= d.profile.min_score, "signal has setup and score >= profile minimum")
                T.eq (d.selected_profile, r.setup)
                T.ok ((r.decision == "CALL" and d.call.passed) or (r.decision == "PUT" and d.put.passed))
            end
        end
        T.ok (seen.WAIT > 0)
    end)

    T.case ("integration: provided M5 and aggregated M5 give the same decision", function ()
        local m1 = F.series (F.MIXED, 11)
        local diff = 0
        for Tn = 300, #m1, 29 do
            local w = window (m1, Tn, 240)
            local m5 = DV.aggregate_m5 (w, m1[Tn].t, cfg)
            for _, b in ipairs (m5) do b.minutes = nil end
            local a = E.evaluate ({ now = m1[Tn].t, m1 = w }, cfg)
            local b = E.evaluate ({ now = m1[Tn].t, m1 = w, m5 = m5 }, cfg)
            if a.decision ~= b.decision or a.call_score ~= b.call_score then diff = diff + 1 end
            T.eq (b.diagnostics.data.m5_source, "provided")
        end
        T.eq (diff, 0)
    end)

    T.case ("cooldown: no new signal within cooldown_bars after a signal", function ()
        local m1 = F.series (F.MIXED, 11)
        local c0 = assert (C.load ({ runner = { cooldown_bars = 0 } }))
        local c5 = assert (C.load ({ runner = { cooldown_bars = 5 } }))
        local r0, r5 = E.new_runner (c0), E.new_runner (c5)
        local last, n0, n5 = nil, 0, 0
        for Tn = 241, #m1 do
            local x = r0:step ({ now = m1[Tn].t, m1 = window (m1, Tn, 240) })
            local y = r5:step ({ now = m1[Tn].t, m1 = window (m1, Tn, 240) })
            if x.decision ~= "WAIT" then n0 = n0 + 1 end
            if y.decision ~= "WAIT" then
                n5 = n5 + 1
                if last then T.ok (Tn - last > 5, "cooldown respected") end
                last = Tn
            end
            if y.reasons[1] == "COOLDOWN" then T.ok (y.suppressed ~= nil) end
        end
        T.ok (n5 <= n0)
    end)

    T.case ("edge: flat market (zero ranges) -> WAIT, no exception", function ()
        local m1 = F.series ({ { kind = "flat", n = 300 } }, 1)
        local r = E.evaluate (F.input (m1), cfg)
        T.eq (r.decision, "WAIT")
    end)

    T.case ("edge: extreme volatility spike -> WAIT", function ()
        local m1 = F.series ({ { kind = "trend", n = 280, drift = 0.3 }, { kind = "spike", n = 6, drift = 25 } }, 2)
        local r = E.evaluate (F.input (m1), cfg)
        T.eq (r.decision, "WAIT")
        T.ok (r.reasons[1] == "VOLATILITY_FILTER" or r.reasons[1]:find ("DEFENSIVE_HIGH_VOL") ~= nil, r.reasons[1])
    end)

    T.case ("edge: exactly minimum history evaluates; one less waits", function ()
        local m1 = F.series (F.UP, 3)
        local a = E.evaluate (F.input ({ table.unpack (m1, #m1 - cfg.data.min_m1_bars + 1, #m1) }), cfg)
        T.lacks (a.reasons, "INSUFFICIENT_HISTORY")
        T.ok (a.diagnostics.regime ~= nil, "analysis ran")
        local b = E.evaluate (F.input ({ table.unpack (m1, #m1 - cfg.data.min_m1_bars + 2, #m1) }), cfg)
        T.has (b.reasons, "INSUFFICIENT_HISTORY")
    end)

    T.case ("edge: very low and very high price levels behave identically in ATR units", function ()
        local base = F.series (F.MIXED, 11)
        local shifted = {}
        for i, b in ipairs (base) do shifted[i] = { t = b.t, o = b.o + 1000, h = b.h + 1000, l = b.l + 1000, c = b.c + 1000 } end
        local diff = 0
        for Tn = 300, #base, 41 do
            local a = E.evaluate ({ now = base[Tn].t, m1 = window (base, Tn, 240) }, cfg)
            local b = E.evaluate ({ now = base[Tn].t, m1 = window (shifted, Tn, 240) }, cfg)
            if a.decision ~= b.decision then diff = diff + 1 end
        end
        T.eq (diff, 0, "price shift changed decisions")
    end)

    T.case ("edge: weekend-style gap at the end -> WAIT (stale / reset)", function ()
        local m1 = F.series (F.UP, 3)
        local r = E.evaluate ({ now = m1[#m1].t + 48 * 3600, m1 = m1 }, cfg)
        T.eq (r.decision, "WAIT"); T.has (r.reasons, "STALE_DATA")
    end)
end
