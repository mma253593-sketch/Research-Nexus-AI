-- =====================================================================
--  MODULE 10 — diagnostics
--
--  build(parts) -> record   structured, explainable evaluation record
--  to_json(v)   -> string   deterministic JSON (sorted keys, fixed number
--                           format) so identical inputs give identical bytes
--  summary(rec) -> string   one-line human-readable summary
-- =====================================================================
local util = require ("util")
local M = {}

M.ENGINE_VERSION = "2.0.0"

local function num (x)
    if x == nil then return nil end
    if math.type and math.type (x) == "integer" then return x end
    if x == math.floor (x) and math.abs (x) < 1e15 then return math.floor (x) end
    return util.round (x, 4)
end

-- @qcs-strip-begin
local function side_record (sd)
    if sd == nil then return nil end
    local rec = { score = 0, setup = "NONE", candidates = {} }
    if sd.best then
        rec.score, rec.setup, rec.trigger = sd.best.score, sd.best.setup, sd.best.trigger
        rec.passed = sd.best.passed
        rec.gates = sd.best.gates
        rec.components, rec.penalties = {}, {}
        for _, k in ipairs (util.sorted_keys (sd.best.components)) do rec.components[k] = num (sd.best.components[k]) end
        for _, k in ipairs (util.sorted_keys (sd.best.penalties)) do rec.penalties[k] = num (sd.best.penalties[k]) end
    end
    for _, c in ipairs (sd.candidates) do
        rec.candidates[#rec.candidates + 1] = { setup = c.setup, present = c.present, score = c.score,
                                                first_gate = c.gates[1] or "PASS" }
    end
    return rec
end
-- @qcs-strip-end

function M.build (p)
    local cfg, dv = p.cfg, p.data
    local r = {
        timestamp = p.now, engine_version = M.ENGINE_VERSION, config_version = cfg.version,
        instrument = cfg.instrument, expiry_sec = 60, time_source = p.time_source or "INPUT",
        decision = p.decision, reasons = p.reasons, call_score = p.call_score or 0, put_score = p.put_score or 0,
        data = {
            valid = dv.ok, errors = dv.errors, warnings = dv.warnings,
            m1_bars = #dv.m1, m5_bars = #dv.m5, m5_source = dv.m5_source,
            missing = dv.stats.missing, staleness_sec = dv.stats.staleness_sec,
            last_closed_t = (#dv.m1 > 0) and dv.m1[#dv.m1].t or nil,
        },
    }
    if p.regime then
        local m = p.regime.metrics or {}
        r.regime = { confirmed = p.regime.regime, raw = p.regime.raw, sub = p.regime.sub, direction = p.regime.direction,
                     atr_ratio = num (m.atr_ratio), er = num (m.er), slope = num (m.slope), ema_crosses = m.crosses }
    end
    -- @qcs-strip-begin  (QCS has no text API: detailed sections are offline only)
    if p.trend then
        local t = p.trend
        r.m5_context = { bias = t.m5.bias, strength = num (t.m5.strength), available = t.m5.available }
        r.m1 = { direction = t.m1_dir, strength = num (t.m1_strength), consistency = num (t.consistency),
                 structure = t.structure, conflict_with_m5 = t.conflict }
    end
    if p.vol then
        r.volatility = { ok = p.vol.ok, reasons = p.vol.reasons, spread = p.vol.spread }
        for _, k in ipairs (util.sorted_keys (p.vol.metrics)) do r.volatility[k] = num (p.vol.metrics[k]) end
    end
    if p.momentum and p.momentum.available then
        local mo = p.momentum
        r.momentum = { dir = mo.dir, strength = num (mo.strength), accel = mo.accel, rsi = num (mo.rsi),
                       hist_atr = num (mo.hist_atr),
                       call = { exhausted = mo.side[1].exhausted, divergence_against = mo.side[1].divergence },
                       put = { exhausted = mo.side[-1].exhausted, divergence_against = mo.side[-1].divergence } }
    end
    if p.pa then
        r.price_action = { call_patterns = p.pa.side[1].patterns, put_patterns = p.pa.side[-1].patterns,
                           call_room_atr = num (p.pa.side[1].room_atr), put_room_atr = num (p.pa.side[-1].room_atr) }
    end
    if p.profile then
        r.profile = { name = p.profile.name, tradable = p.profile.tradable, setups = p.profile.setups,
                      min_score = p.profile.min_score, reason = p.profile.reason }
    end
    -- @qcs-strip-end
    r.selected_profile = p.selected and p.selected.setup or (p.profile and not p.profile.tradable and "DEFENSIVE" or "NONE")
    -- @qcs-strip-begin
    if p.sides then r.call, r.put = side_record (p.sides[1]), side_record (p.sides[-1]) end
    -- @qcs-strip-end
    return r
end

-- @qcs-strip-begin  (JSON / summary: offline tooling only)
-- ----------------------------- JSON ---------------------------------
local function esc (s)
    return (s:gsub ('[%c"\\]', function (c)
        if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" end
        return string.format ("\\u%04x", c:byte ())
    end))
end

local function is_array (t)
    local n = 0
    for _ in pairs (t) do n = n + 1 end
    for i = 1, n do if t[i] == nil then return false end end
    return true
end

function M.to_json (v)
    local tv = type (v)
    if v == nil then return "null"
    elseif tv == "boolean" then return v and "true" or "false"
    elseif tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        if math.type and math.type (v) == "integer" then return tostring (v) end
        if v == math.floor (v) and math.abs (v) < 1e15 then return string.format ("%d", v) end
        return string.format ("%.4f", v)
    elseif tv == "string" then return '"' .. esc (v) .. '"'
    elseif tv == "table" then
        local parts = {}
        if next (v) ~= nil and is_array (v) then
            for _, x in ipairs (v) do parts[#parts + 1] = M.to_json (x) end
            return "[" .. table.concat (parts, ",") .. "]"
        end
        if next (v) == nil then return "[]" end
        for _, k in ipairs (util.sorted_keys (v)) do
            parts[#parts + 1] = '"' .. esc (tostring (k)) .. '":' .. M.to_json (v[k])
        end
        return "{" .. table.concat (parts, ",") .. "}"
    end
    return '"<' .. tv .. '>"'
end

function M.summary (r)
    local reg = r.regime and r.regime.confirmed or "-"
    return ("t=%s decision=%s call=%d put=%d regime=%s profile=%s reasons=%s"):format (
        tostring (r.timestamp), r.decision, r.call_score, r.put_score, reg, r.selected_profile,
        table.concat (r.reasons or {}, "|"))
end

-- @qcs-strip-end
return M
