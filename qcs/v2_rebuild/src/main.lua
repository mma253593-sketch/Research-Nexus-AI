-- =====================================================================
--  main — public entry point of XAUUSD Smart Entry V2.0.
--
--  local engine = require ("main")
--  local cfg, errs = engine.config (overrides)      -- validated config or nil
--  local res = engine.evaluate (input, cfg)         -- pure, deterministic
--     input = { now = unix_s, m1 = {candles}, m5 = optional, time_source = optional }
--     res   = { decision = "CALL"|"PUT"|"WAIT", call_score, put_score,
--               reasons = {codes}, diagnostics = record }
--  local run = engine.new_runner (cfg)              -- adds the cooldown
--  local res = run:step (input)
--
--  evaluate() only ever looks at candles that closed at or before
--  `now` (validated by data_validation) and keeps no state, so the same
--  input always gives the same output and a past decision can never change.
--  Signal generation only: this module never places trades.
-- =====================================================================
local config            = require ("config")
local data_validation   = require ("data_validation")
local indicators        = require ("indicators")
local regime_detection  = require ("regime_detection")
local trend_context     = require ("trend_context")
local momentum_analysis = require ("momentum_analysis")
local price_action      = require ("price_action")
local entry_timing      = require ("entry_timing")
local volatility_filter = require ("volatility_filter")
local adaptive_profile  = require ("adaptive_profile")
local signal_engine     = require ("signal_engine")
local diagnostics       = require ("diagnostics")

local M = { VERSION = diagnostics.ENGINE_VERSION }

M.config = config.load

local function finish (p)
    p.reasons = p.reasons or {}
    local rec = diagnostics.build (p)
    return { decision = p.decision, call_score = rec.call_score, put_score = rec.put_score,
             reasons = rec.reasons, setup = p.selected and p.selected.setup or nil,
             score = p.selected and p.selected.score or 0, diagnostics = rec }
end

function M.evaluate (input, cfg)
    local p = { cfg = cfg, now = type (input) == "table" and input.now or nil,
                time_source = type (input) == "table" and input.time_source or nil, decision = "WAIT" }
    -- 0. an invalid configuration never produces a signal
    if type (cfg) ~= "table" or not config.validate (cfg) then
        p.cfg = { version = (type (cfg) == "table" and type (cfg.version) == "string") and cfg.version or "INVALID",
                  instrument = "XAUUSD" }
        p.data = { ok = false, errors = { "CONFIG_INVALID" }, warnings = {}, m1 = {}, m5 = {}, stats = {}, m5_source = "none" }
        p.reasons = { "CONFIG_INVALID" }
        return finish (p)
    end
    -- 1. data validation: invalid or insufficient data -> WAIT
    p.data = data_validation.prepare (input, cfg)
    if not p.data.ok then
        p.reasons = { "DATA_INVALID" }
        for _, e in ipairs (p.data.errors) do p.reasons[#p.reasons + 1] = e end
        return finish (p)
    end
    -- 2. features (computed once, shared)
    local f = indicators.compute (p.data.m1, cfg)
    local f5 = indicators.compute_m5 (p.data.m5, cfg)
    -- 3. analysis modules
    p.regime   = regime_detection.detect (f, cfg)
    p.trend    = trend_context.analyze (f, f5, cfg)
    p.momentum = momentum_analysis.analyze (f, cfg)
    p.pa       = price_action.analyze (f, cfg)
    p.vol      = volatility_filter.evaluate (f, cfg)
    p.profile  = adaptive_profile.select (p.regime, cfg)
    if not p.momentum.available or not p.trend.m5.available then
        p.reasons = { "DATA_INVALID", "INDICATORS_UNAVAILABLE" }
        return finish (p)
    end
    if not p.vol.ok then
        p.reasons = { "VOLATILITY_FILTER" }
        for _, r in ipairs (p.vol.reasons) do p.reasons[#p.reasons + 1] = r end
        return finish (p)
    end
    if not p.profile.tradable then
        p.reasons = { p.profile.reason }
        return finish (p)
    end
    -- 4. entry timing per side, then scoring + decision
    local entry = { [1] = entry_timing.analyze_side (f, 1, p.pa.side[1], p.profile, cfg),
                    [-1] = entry_timing.analyze_side (f, -1, p.pa.side[-1], p.profile, cfg) }
    local d = signal_engine.decide ({ cfg = cfg, f = f, regime = p.regime, profile = p.profile, trend = p.trend,
                                      momentum = p.momentum, pa = p.pa, entry = entry, vol = p.vol })
    p.decision, p.reasons, p.sides, p.selected = d.decision, d.reasons, d.side, d.selected
    p.call_score, p.put_score = d.call_score, d.put_score
    return finish (p)
end

-- @qcs-strip-begin  (the QCS adapter implements the cooldown with make_series)
--- sequential runner: identical to evaluate() plus a deterministic cooldown
--- (bounded state: the time of the last emitted signal only)
function M.new_runner (cfg)
    local self = { cfg = cfg, last_signal_t = nil }
    function self:step (input)
        local res = M.evaluate (input, self.cfg)
        if res.decision ~= "WAIT" then
            local cd = self.cfg.runner.cooldown_bars
            if self.last_signal_t ~= nil and input.now - self.last_signal_t < (cd + 1) * self.cfg.data.m1_period then
                res.suppressed = res.decision
                res.decision, res.reasons = "WAIT", { "COOLDOWN" }
                res.diagnostics.decision, res.diagnostics.reasons = "WAIT", res.reasons
                res.diagnostics.suppressed = res.suppressed
            else
                self.last_signal_t = input.now
            end
        end
        return res
    end
    return self
end

-- @qcs-strip-end
return M
