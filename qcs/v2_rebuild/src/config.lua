-- =====================================================================
--  config — schema, validation and merging of engine configuration.
--
--  config.load(overrides) -> cfg, errors
--      Deep-merges `overrides` onto the defaults and validates the result.
--      `cfg` is nil when any error is found (never a partially valid cfg).
--  config.validate(cfg) -> ok, errors      (errors = sorted list of strings)
-- =====================================================================
local util = require ("util")
local defaults = require ("default_config")

local M = {}

M.SETUPS = { "PULLBACK_CONTINUATION", "TREND_CONTINUATION", "BREAKOUT_CONFIRMATION", "RANGE_REJECTION" }

-- { min, max, integer? } for every numeric leaf. Unknown keys are errors.
local NUM = {
    data = {
        m1_period = { 60, 60, true }, m5_period = { 300, 300, true },
        m1_window = { 100, 2000, true }, min_m1_bars = { 100, 2000, true }, min_m5_bars = { 10, 400, true },
        m5_min_minutes = { 1, 5, true }, max_staleness_sec = { 1, 600, true }, max_gap_candles = { 0, 30, true },
        max_missing_ratio = { 0, 0.2 }, m5_tolerance_rel = { 0, 0.01 },
    },
    indicators = {
        ema_fast = { 2, 100, true }, ema_mid = { 3, 200, true }, ema_slow = { 4, 400, true },
        atr_len = { 2, 100, true }, atr_base_len = { 10, 500, true }, rsi_len = { 2, 100, true },
        er_len = { 5, 100, true }, macd_fast = { 2, 100, true }, macd_slow = { 3, 200, true },
        macd_signal = { 2, 100, true }, m5_ema_fast = { 2, 100, true }, m5_ema_slow = { 3, 200, true },
        pivot_len = { 2, 10, true }, max_levels = { 1, 20, true },
    },
    regime = {
        hv_atr_ratio = { 1.1, 5 }, lv_atr_ratio = { 0.1, 0.95 }, er_trend = { 0.05, 0.95 },
        er_range = { 0.01, 0.9 }, slope_min = { 0, 1 }, whipsaw_lookback = { 5, 100, true },
        whipsaw_crosses = { 1, 50, true }, confirm_bars = { 1, 10, true },
    },
    volatility = {
        abnormal_range_atr = { 1, 20 }, expansion_ratio = { 1.05, 10 }, expansion_lookback = { 1, 50, true },
        flat_range_atr = { 0, 1 }, flat_lookback = { 3, 100, true }, max_flat_candles = { 0, 100, true },
        min_atr_price = { 0, 100 }, noise_er = { 0, 1 }, noise_wick_share = { 0, 1 },
    },
    momentum = {
        exhaust_rsi_high = { 55, 100 }, exhaust_rsi_low = { 0, 45 }, exhaust_run = { 2, 20, true },
        climax_body_atr = { 0.5, 20 }, div_min_rsi = { 0, 50 }, div_max_age = { 3, 200, true },
        hist_strong_atr = { 0.01, 5 },
    },
    price_action = {
        engulf_min_body_atr = { 0, 5 }, pin_wick_ratio = { 0.3, 0.95 }, breakout_buffer_atr = { 0, 2 },
        level_touch_atr = { 0, 3 }, strong_close = { 0.5, 1 }, range_lookback = { 5, 200, true },
    },
    entry = {
        late_move_atr = { 0.5, 20 }, max_trigger_body_atr = { 0.3, 10 }, breakout_max_ext_atr = { 0.2, 5 }, pullback_lookback = { 1, 20, true },
        pullback_zone_atr = { 0, 3 }, room_cap_atr = { 1, 50 },
    },
    scoring = {
        global_min_score = { 50, 95, true }, min_margin = { 0, 100 }, m5_conflict_penalty = { 0, 50 },
        m5_block_strength = { 0, 1 }, divergence_penalty = { 0, 50 }, decel_penalty = { 0, 50 }, wick_penalty = { 0, 50 },
    },
    runner = { cooldown_bars = { 0, 100, true } },
}
local PROFILE_NUM = { min_score = { 50, 100, true }, min_room_atr = { 0, 10 }, max_ext_atr = { 0.2, 10 } }
local PROFILE_NAMES = { RANGING = true, TRENDING = true }

local function check_num (errs, path, v, spec)
    if not util.finite (v) then errs[#errs + 1] = path .. ": must be a finite number"; return end
    if spec[3] and math.floor (v) ~= v then errs[#errs + 1] = path .. ": must be an integer" end
    if v < spec[1] or v > spec[2] then
        errs[#errs + 1] = ("%s: %s outside [%s, %s]"):format (path, tostring (v), tostring (spec[1]), tostring (spec[2]))
    end
end

function M.validate (cfg)
    local errs = {}
    if type (cfg) ~= "table" then return false, { "config: must be a table" } end
    if type (cfg.version) ~= "string" or cfg.version == "" then errs[#errs + 1] = "version: must be a non-empty string" end
    if cfg.instrument ~= "XAUUSD" then errs[#errs + 1] = "instrument: must be XAUUSD" end
    for _, sec in ipairs (util.sorted_keys (cfg)) do
        if sec ~= "version" and sec ~= "instrument" and sec ~= "profiles" and NUM[sec] == nil then
            errs[#errs + 1] = sec .. ": unknown section"
        end
    end
    for _, sec in ipairs (util.sorted_keys (NUM)) do
        local t = cfg[sec]
        if type (t) ~= "table" then errs[#errs + 1] = sec .. ": missing section"
        else
            for _, k in ipairs (util.sorted_keys (NUM[sec])) do check_num (errs, sec .. "." .. k, t[k], NUM[sec][k]) end
            for _, k in ipairs (util.sorted_keys (t)) do
                if NUM[sec][k] == nil and not (sec == "data" and (k == "dedupe_identical" or k == "m5_source")) then
                    errs[#errs + 1] = sec .. "." .. tostring (k) .. ": unknown key"
                end
            end
        end
    end
    local d, ind, rg, sc = cfg.data or {}, cfg.indicators or {}, cfg.regime or {}, cfg.scoring or {}
    if type (d.dedupe_identical) ~= "boolean" then errs[#errs + 1] = "data.dedupe_identical: must be boolean" end
    if d.m5_source ~= "auto" and d.m5_source ~= "provided" and d.m5_source ~= "aggregate" then
        errs[#errs + 1] = "data.m5_source: must be auto|provided|aggregate"
    end
    -- profiles
    if type (cfg.profiles) ~= "table" then errs[#errs + 1] = "profiles: missing section"
    else
        for _, name in ipairs (util.sorted_keys (cfg.profiles)) do
            local p = cfg.profiles[name]
            local base = "profiles." .. tostring (name)
            if not PROFILE_NAMES[name] then errs[#errs + 1] = base .. ": unknown profile (TRENDING|RANGING)"
            elseif type (p) ~= "table" then errs[#errs + 1] = base .. ": must be a table"
            else
                for _, k in ipairs (util.sorted_keys (PROFILE_NUM)) do check_num (errs, base .. "." .. k, p[k], PROFILE_NUM[k]) end
                if type (p.setups) ~= "table" or #p.setups == 0 then errs[#errs + 1] = base .. ".setups: non-empty list required"
                else
                    for i, s in ipairs (p.setups) do
                        if not util.contains (M.SETUPS, s) then errs[#errs + 1] = ("%s.setups[%d]: unknown setup %s"):format (base, i, tostring (s)) end
                        if name == "TRENDING" and s == "RANGE_REJECTION" then errs[#errs + 1] = base .. ".setups: RANGE_REJECTION not allowed in TRENDING" end
                        if name == "RANGING" and (s == "PULLBACK_CONTINUATION" or s == "TREND_CONTINUATION") then
                            errs[#errs + 1] = base .. ".setups: continuation setups not allowed in RANGING"
                        end
                    end
                end
                if util.finite (p.min_score) and util.finite (sc.global_min_score) and p.min_score < sc.global_min_score then
                    errs[#errs + 1] = base .. ".min_score: below scoring.global_min_score"
                end
                for _, k in ipairs (util.sorted_keys (p)) do
                    if PROFILE_NUM[k] == nil and k ~= "setups" then errs[#errs + 1] = base .. "." .. tostring (k) .. ": unknown key" end
                end
            end
        end
        for _, name in ipairs ({ "RANGING", "TRENDING" }) do
            if cfg.profiles[name] == nil then errs[#errs + 1] = "profiles." .. name .. ": missing" end
        end
    end
    -- cross-field rules
    local function lt (a, b, an, bn) if util.finite (a) and util.finite (b) and not (a < b) then errs[#errs + 1] = an .. " must be < " .. bn end end
    lt (ind.ema_fast, ind.ema_mid, "indicators.ema_fast", "indicators.ema_mid")
    lt (ind.ema_mid, ind.ema_slow, "indicators.ema_mid", "indicators.ema_slow")
    lt (ind.macd_fast, ind.macd_slow, "indicators.macd_fast", "indicators.macd_slow")
    lt (ind.m5_ema_fast, ind.m5_ema_slow, "indicators.m5_ema_fast", "indicators.m5_ema_slow")
    lt (rg.er_range, rg.er_trend, "regime.er_range", "regime.er_trend")
    lt (rg.lv_atr_ratio, rg.hv_atr_ratio, "regime.lv_atr_ratio", "regime.hv_atr_ratio")
    if util.finite (d.min_m1_bars) and util.finite (d.m1_window) and d.min_m1_bars > d.m1_window then
        errs[#errs + 1] = "data.min_m1_bars must be <= data.m1_window"
    end
    if util.finite (d.min_m1_bars) and util.finite (ind.atr_base_len) and util.finite (ind.atr_len)
       and util.finite (ind.ema_slow) and util.finite (ind.macd_slow) and util.finite (ind.macd_signal) then
        local need = math.max (ind.atr_base_len + ind.atr_len + 1, 2 * ind.ema_slow, ind.macd_slow + ind.macd_signal + 10)
        if d.min_m1_bars < need then errs[#errs + 1] = ("data.min_m1_bars must be >= %d for the indicator lengths"):format (need) end
    end
    if util.finite (d.min_m5_bars) and util.finite (ind.m5_ema_slow) and d.min_m5_bars < ind.m5_ema_slow + 3 then
        errs[#errs + 1] = "data.min_m5_bars must be >= indicators.m5_ema_slow + 3"
    end
    table.sort (errs)
    return #errs == 0, errs
end

local function merge (base, over, path, errs)
    for _, k in ipairs (util.sorted_keys (over)) do
        local v = over[k]
        if type (v) == "table" and type (base[k]) == "table" and k ~= "setups" then merge (base[k], v, path .. k .. ".", errs)
        else base[k] = util.deepcopy (v) end
    end
end

function M.defaults () return util.deepcopy (defaults) end

function M.load (overrides)
    local cfg = M.defaults ()
    local errs = {}
    if overrides ~= nil then
        if type (overrides) ~= "table" then return nil, { "overrides: must be a table" } end
        merge (cfg, overrides, "", errs)
    end
    local ok, verrs = M.validate (cfg)
    if not ok then return nil, verrs end
    return cfg, {}
end

return M
