-- Requirements 15-17: scoring, CALL/PUT/WAIT decision, conflicting signals.
-- Module outputs are stubbed so each rule is tested in isolation.
local C = require ("config")
local AP = require ("adaptive_profile")
local SE = require ("signal_engine")
local util = require ("util")

local function side (aligned)
    return { aligned = aligned, accelerating = aligned, turning = aligned, decelerating = false,
             exhausted = false, divergence = false }
end
local function entry (present, trig)
    return { present = present, trigger = trig or "ENGULF", quality = 0.8, late = false, no_room = false, ext = 0.5, room = 2 }
end

local function ctx (cfg, over)
    local rsi = {}
    for i = 1, 40 do rsi[i] = 55 end
    local c = {
        cfg = cfg, f = { n = 40, rsi = rsi },
        regime = { regime = "TRENDING", direction = 1, metrics = { er = 0.4 } },
        profile = AP.select ({ regime = "TRENDING" }, cfg),
        trend = { m1_dir = 1, m1_strength = 0.8, consistency = 0.9, structure = 1,
                  reversal = { [1] = false, [-1] = false }, m5 = { bias = 1, strength = 0.7, available = true } },
        momentum = { strength = 0.8, side = { [1] = side (true), [-1] = side (false) } },
        pa = { side = { [1] = { wick_against = 0.1 }, [-1] = { wick_against = 0.1 } } },
        entry = { [1] = {}, [-1] = {} },
    }
    for _, s in ipairs ({ 1, -1 }) do
        for _, st in ipairs (c.profile.setups) do c.entry[s][st] = entry (false) end
    end
    c.entry[1].PULLBACK_CONTINUATION = entry (true)
    if over then over (c) end
    return c
end

return function (T)
    local cfg = assert (C.load ())

    T.case ("clear CALL setup -> CALL with explained components", function ()
        local d = SE.decide (ctx (cfg))
        T.eq (d.decision, "CALL"); T.eq (d.selected.setup, "PULLBACK_CONTINUATION")
        local sum = 0
        for _, k in ipairs (util.sorted_keys (d.selected.components)) do sum = sum + d.selected.components[k] end
        T.eq (d.selected.score, math.floor (math.min (sum, 100) + 0.5), "score = sum of components")
        T.ok (d.selected.score >= cfg.profiles.TRENDING.min_score)
        T.eq (#d.selected.gates, 0)
    end)

    T.case ("mirrored stub -> PUT with the same score", function ()
        local call = SE.decide (ctx (cfg))
        local put = SE.decide (ctx (cfg, function (c)
            c.regime.direction, c.trend.m1_dir, c.trend.structure, c.trend.m5.bias = -1, -1, -1, -1
            c.momentum.side = { [1] = side (false), [-1] = side (true) }
            c.entry[1].PULLBACK_CONTINUATION, c.entry[-1].PULLBACK_CONTINUATION = entry (false), entry (true)
            for i = 1, 40 do c.f.rsi[i] = 45 end
        end))
        T.eq (put.decision, "PUT"); T.eq (put.selected.score, call.selected.score)
    end)

    T.case ("both sides qualify -> WAIT (never contradictory CALL and PUT)", function ()
        local d = SE.decide (ctx (cfg, function (c)
            c.trend.m1_dir, c.regime.direction = 0, 0
            c.regime.regime = "RANGING"; c.profile = AP.select ({ regime = "RANGING" }, cfg)
            for _, s in ipairs ({ 1, -1 }) do
                c.momentum.side[s] = side (true)
                for _, st in ipairs (c.profile.setups) do c.entry[s][st] = entry (false) end
                c.entry[s].RANGE_REJECTION = entry (true, "REJECTION_CONF")
            end
            c.trend.m5.bias, c.trend.structure = 0, 0
            for i = 1, 40 do c.f.rsi[i] = 50 end
            c.regime.metrics.er = 0.05
        end))
        T.ok (d.side[1].pass and d.side[-1].pass, "both sides pass their own gates")
        T.eq (d.decision, "WAIT"); T.eq (d.reasons[1], "CONFLICT_BOTH_SIDES")
    end)

    T.case ("opposite side too close in score -> WAIT INSUFFICIENT_MARGIN", function ()
        local d = SE.decide (ctx (cfg, function (c)
            c.entry[-1].BREAKOUT_CONFIRMATION = entry (true, "BREAKOUT")
            c.momentum.side[-1] = side (true)            -- strong enough to score, still gated
            c.trend.m5.bias = 0
        end))
        local put = d.side[-1].best
        T.ok (put ~= nil and not put.passed, "PUT present but gated")
        if d.side[1].pass.score - put.score < cfg.scoring.min_margin then
            T.eq (d.decision, "WAIT"); T.eq (d.reasons[1], "INSUFFICIENT_MARGIN")
        else
            T.eq (d.decision, "CALL")
        end
        local tight = assert (C.load ({ scoring = { min_margin = 100 } }))
        local d2 = SE.decide (ctx (tight, function (c) c.entry[-1].BREAKOUT_CONFIRMATION = entry (true, "BREAKOUT") end))
        T.eq (d2.decision, "WAIT"); T.eq (d2.reasons[1], "INSUFFICIENT_MARGIN")
    end)

    T.case ("each hard gate blocks the setup and is reported", function ()
        local cases = {
            { "EXHAUSTION", function (c) c.momentum.side[1].exhausted = true end },
            { "STRUCTURE_BREAK", function (c) c.trend.reversal[1] = true end },
            { "LATE_ENTRY_EXTENDED_FROM_EMA21", function (c) local e = c.entry[1].PULLBACK_CONTINUATION; e.late, e.late_why = true, "EXTENDED_FROM_EMA21" end },
            { "NO_ROOM", function (c) c.entry[1].PULLBACK_CONTINUATION.no_room = true end },
            { "M5_STRONG_OPPOSITE", function (c) c.trend.m5.bias, c.trend.m5.strength = -1, 0.9 end },
            { "MOMENTUM_CONFLICT", function (c) c.momentum.side[1].turning = false end },
            { "LOW_SCORE", function (c) local e = c.entry[1].PULLBACK_CONTINUATION; e.trigger, e.quality = "STRONG_CLOSE", 0
                c.trend.m1_strength, c.trend.consistency = 0, 0 end },
        }
        for _, cs in ipairs (cases) do
            local d = SE.decide (ctx (cfg, cs[2]))
            T.eq (d.decision, "WAIT", cs[1])
            T.has (d.side[1].best.gates, cs[1])
            T.has (d.reasons, "CALL:PULLBACK_CONTINUATION:" .. d.side[1].best.gates[1])
        end
    end)

    T.case ("penalties reduce the score by their configured amounts", function ()
        local base = SE.decide (ctx (cfg)).side[1].best
        local div = SE.decide (ctx (cfg, function (c) c.momentum.side[1].divergence = true end)).side[1].best
        T.eq (base.score - div.score, cfg.scoring.divergence_penalty)
        local wick = SE.decide (ctx (cfg, function (c) c.pa.side[1].wick_against = 0.5 end)).side[1].best
        T.eq (base.score - wick.score, cfg.scoring.wick_penalty)
        local m5 = SE.decide (ctx (cfg, function (c) c.trend.m5.bias, c.trend.m5.strength = -1, 0.1 end)).side[1].best
        T.eq (m5.penalties.m5_conflict, cfg.scoring.m5_conflict_penalty)
        T.lacks (m5.gates, "M5_STRONG_OPPOSITE", "weak opposite M5 is context, not a block")
    end)

    T.case ("scores are integers within 0..100 for random stub combinations", function ()
        local r = require ("fixtures").rng (99)
        for _ = 1, 300 do
            local d = SE.decide (ctx (cfg, function (c)
                c.trend.m1_strength, c.trend.consistency, c.momentum.strength = r (), r (), r ()
                c.trend.m5.bias = math.floor (r () * 3) - 1; c.trend.m5.strength = r ()
                c.momentum.side[1].divergence = r () < 0.5; c.momentum.side[1].decelerating = r () < 0.5
                c.pa.side[1].wick_against = r ()
                c.entry[1].PULLBACK_CONTINUATION.quality = r ()
            end))
            for _, s in ipairs ({ 1, -1 }) do
                for _, cand in ipairs (d.side[s].candidates) do
                    T.ok (cand.score >= 0 and cand.score <= 100 and math.floor (cand.score) == cand.score, "score range")
                end
            end
            T.ok (d.decision == "CALL" or d.decision == "PUT" or d.decision == "WAIT")
            if d.decision ~= "WAIT" then T.ok (d.selected.passed) end
        end
    end)
end
