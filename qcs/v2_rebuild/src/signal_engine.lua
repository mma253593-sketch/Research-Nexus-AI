-- =====================================================================
--  MODULE 9 — signal_engine (scoring + decision)
--
--  score_setup(ctx, s, setup, E) -> { score, components, penalties, gates }
--  decide(ctx) -> { decision = "CALL"|"PUT"|"WAIT", reasons, side = {...} }
--
--  ctx = { cfg, regime, profile, trend, momentum, pa, entry, vol }
--
--  SCORE (0..100, integer). It measures how strongly the measured
--  conditions agree. It is NOT a win probability (it has not been
--  calibrated on verified market data).
--    context    0..25  continuation: M1 direction on side s (10) + 8 x M1
--                      strength + 7 x consistency.  range setups: 15 x (1 -
--                      ER/er_trend) + 10 if swing structure not against s
--    momentum   0..20  continuation: aligned 8 + 6 x strength + accelerating 6
--                      (or turning 3).  range rejection: turning 10 + RSI(n-1)
--                      in side frame <= 40: 5 + aligned 5
--    price act. 0..20  pattern points of the trigger (price_action.POINTS)
--    timing     0..20  20 x entry quality
--    m5         0..10  bias on side s: 6 + 4 x strength; neutral: 4; opposite: 0
--    regime     0..5   5 when the confirmed regime supports side s
--    penalties         M5 opposite, divergence against s, decelerating
--                      momentum, adverse wick >= 35% of the trigger candle
--  GATES (any -> the setup cannot fire): SETUP_NOT_PRESENT, EXHAUSTION,
--    STRUCTURE_BREAK, LATE_ENTRY_<why>, NO_ROOM, M5_STRONG_OPPOSITE,
--    MOMENTUM_CONFLICT, LOW_SCORE.
--  DECISION: WAIT unless exactly one side has a passing setup AND it beats
--    the other side's best present setup by >= scoring.min_margin.
-- =====================================================================
local util = require ("util")
local price_action = require ("price_action")

local M = {}

local CONTINUATION = { PULLBACK_CONTINUATION = true, TREND_CONTINUATION = true }

function M.score_setup (ctx, s, setup, E)
    local cfg, tr, mo = ctx.cfg, ctx.trend, ctx.momentum
    local ms, pa = mo.side[s], ctx.pa.side[s]
    local sc = cfg.scoring
    local range_mode = setup == "RANGE_REJECTION" or (setup == "BREAKOUT_CONFIRMATION" and ctx.regime.regime == "RANGING")
    local comp, pen, gates = {}, {}, {}

    if range_mode then
        local er = ctx.regime.metrics.er or 0
        comp.context = 15 * (1 - util.unit (er / cfg.regime.er_trend)) + ((tr.structure ~= -s) and 10 or 0)
    else
        comp.context = (tr.m1_dir == s) and (10 + 8 * tr.m1_strength + 7 * tr.consistency) or 0
    end
    if setup == "RANGE_REJECTION" then
        local r1 = ctx.f.rsi[ctx.f.n - 1]
        r1 = (s == 1) and r1 or (100 - r1)
        comp.momentum = (ms.turning and 10 or 0) + ((r1 <= 40) and 5 or 0) + (ms.aligned and 5 or 0)
    else
        comp.momentum = (ms.aligned and (8 + 6 * mo.strength) or 0)
            + (ms.accelerating and 6 or (ms.turning and 3 or 0))
    end
    comp.price_action = E.trigger and price_action.POINTS[E.trigger] or 0
    comp.timing = 20 * (E.quality or 0)
    local m5 = tr.m5
    comp.m5 = (m5.bias == s) and (6 + 4 * m5.strength) or ((m5.bias == 0) and 4 or 0)
    local rdir = ctx.regime.direction or 0
    comp.regime = ((ctx.regime.regime == "TRENDING" and rdir == s) or ctx.regime.regime == "RANGING") and 5 or 0

    if m5.bias == -s then pen.m5_conflict = sc.m5_conflict_penalty end
    if ms.divergence then pen.divergence = sc.divergence_penalty end
    if ms.decelerating then pen.deceleration = sc.decel_penalty end
    if pa.wick_against >= 0.35 then pen.adverse_wick = sc.wick_penalty end

    local total, ptotal = 0, 0
    for _, k in ipairs (util.sorted_keys (comp)) do total = total + comp[k] end
    for _, k in ipairs (util.sorted_keys (pen)) do ptotal = ptotal + pen[k] end
    local score = math.floor (util.clamp (total - ptotal, 0, 100) + 0.5)

    local function gate (g) gates[#gates + 1] = g end
    if not E.present then gate ("SETUP_NOT_PRESENT") end
    if ms.exhausted then gate ("EXHAUSTION") end
    if (CONTINUATION[setup] or setup == "BREAKOUT_CONFIRMATION") and tr.reversal[s] then gate ("STRUCTURE_BREAK") end
    if E.late then gate ("LATE_ENTRY_" .. E.late_why) end
    if E.no_room then gate ("NO_ROOM") end
    if (CONTINUATION[setup] or setup == "BREAKOUT_CONFIRMATION") and m5.bias == -s and m5.strength >= sc.m5_block_strength then
        gate ("M5_STRONG_OPPOSITE") end
    local mom_ok
    if setup == "PULLBACK_CONTINUATION" or setup == "RANGE_REJECTION" then mom_ok = ms.turning
    elseif setup == "TREND_CONTINUATION" then mom_ok = ms.aligned and not ms.decelerating
    else mom_ok = ms.aligned end
    if not mom_ok then gate ("MOMENTUM_CONFLICT") end
    if score < ctx.profile.min_score then gate ("LOW_SCORE") end

    return { setup = setup, score = score, trigger = E.trigger, components = comp, penalties = pen, gates = gates,
             present = E.present, passed = #gates == 0, ext = E.ext, room = E.room }
end

--- evaluates every allowed setup on one side and picks the best
function M.evaluate_side (ctx, s)
    local list = {}
    for _, setup in ipairs (ctx.profile.setups) do
        list[#list + 1] = M.score_setup (ctx, s, setup, ctx.entry[s][setup])
    end
    local best_pass, best_present
    for _, r in ipairs (list) do   -- profile order breaks ties deterministically
        if r.passed and (best_pass == nil or r.score > best_pass.score) then best_pass = r end
        if r.present and (best_present == nil or r.score > best_present.score) then best_present = r end
    end
    return { candidates = list, pass = best_pass, best = best_pass or best_present }
end

function M.decide (ctx)
    local call, put = M.evaluate_side (ctx, 1), M.evaluate_side (ctx, -1)
    local out = { side = { [1] = call, [-1] = put }, reasons = {} }
    local cs = call.best and call.best.score or 0
    local ps = put.best and put.best.score or 0
    out.call_score, out.put_score = cs, ps
    if call.pass and put.pass then
        out.decision = "WAIT"; out.reasons[1] = "CONFLICT_BOTH_SIDES"; return out
    end
    local win, other, name = nil, nil, nil
    if call.pass then win, other, name = call.pass, ps, "CALL" elseif put.pass then win, other, name = put.pass, cs, "PUT" end
    if win then
        if win.score - other < ctx.cfg.scoring.min_margin then
            out.decision = "WAIT"; out.reasons[1] = "INSUFFICIENT_MARGIN"; return out
        end
        out.decision, out.selected = name, win
        return out
    end
    out.decision = "WAIT"
    out.reasons[1] = "NO_QUALIFIED_SETUP"
    for _, x in ipairs ({ { "CALL", call }, { "PUT", put } }) do
        local b = x[2].best
        if b then out.reasons[#out.reasons + 1] = x[1] .. ":" .. b.setup .. ":" .. b.gates[1] end
    end
    return out
end

return M
