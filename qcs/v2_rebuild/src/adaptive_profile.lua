-- =====================================================================
--  MODULE 8 — adaptive_profile
--
--  select(regime, cfg) -> profile
--    profile = { name, tradable, setups = {...}, min_score, min_room_atr,
--                max_ext_atr, reason }
--  Deterministic map from the CONFIRMED regime to an explicit, bounded
--  parameter set taken from cfg.profiles (validated by config.lua):
--    TRENDING -> "TRENDING" profile (pullback / trend continuation /
--                breakout confirmation)
--    RANGING  -> "RANGING" profile (range rejection / breakout confirmation)
--    HIGH_VOL, LOW_VOL, UNSTABLE -> "DEFENSIVE": nothing tradable -> WAIT
--  No learning, no dependence on recent wins/losses. The profile min_score
--  can never be below scoring.global_min_score (enforced here as well).
-- =====================================================================
local util = require ("util")
local M = {}

function M.select (regime, cfg)
    local p = cfg.profiles[regime.regime]
    if p == nil then
        return { name = "DEFENSIVE", tradable = false, setups = {},
                 reason = "DEFENSIVE_" .. regime.regime .. (regime.sub and ("_" .. regime.sub) or "") }
    end
    return {
        name = regime.regime, tradable = true, setups = util.deepcopy (p.setups),
        min_score = math.max (p.min_score, cfg.scoring.global_min_score),
        min_room_atr = p.min_room_atr, max_ext_atr = p.max_ext_atr,
    }
end

return M
