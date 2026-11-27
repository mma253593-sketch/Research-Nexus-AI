-- =====================================================================
--  util — small pure helpers shared by every V2.0 module.
--  Uses only the Lua 5.3 base library (math, string, table): this is the
--  subset the existing QCS scripts already rely on.
-- =====================================================================
local M = {}

local HUGE = math.huge

--- true when x is a finite number (not nil, not NaN, not +/-inf)
function M.finite (x)
    return type (x) == "number" and x == x and x ~= HUGE and x ~= -HUGE
end

function M.clamp (x, a, b)
    if x < a then return a elseif x > b then return b end
    return x
end

--- clamp to [0, 1]
function M.unit (x) return M.clamp (x, 0, 1) end

--- round half away from zero to `d` decimals (deterministic formatting)
function M.round (x, d)
    local m = 10 ^ (d or 0)
    if x >= 0 then return math.floor (x * m + 0.5) / m end
    return -math.floor (-x * m + 0.5) / m
end

function M.sign (x)
    if x > 0 then return 1 elseif x < 0 then return -1 end
    return 0
end

--- shallow copy of an array slice [a, b]
function M.slice (arr, a, b)
    local out = {}
    for i = math.max (a, 1), math.min (b, #arr) do out[#out + 1] = arr[i] end
    return out
end

--- deep copy for plain data tables (no cycles, no metatables)
function M.deepcopy (v)
    if type (v) ~= "table" then return v end
    local o = {}
    for k, x in pairs (v) do o[k] = M.deepcopy (x) end
    return o
end

--- keys of a table in sorted order (deterministic iteration)
function M.sorted_keys (t)
    local ks = {}
    for k in pairs (t) do ks[#ks + 1] = k end
    table.sort (ks, function (a, b)
        local ta, tb = type (a), type (b)
        if ta ~= tb then return ta < tb end
        return a < b
    end)
    return ks
end

function M.contains (arr, x)
    for _, v in ipairs (arr) do if v == x then return true end end
    return false
end

return M
