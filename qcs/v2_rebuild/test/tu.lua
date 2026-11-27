-- Minimal test harness (no external dependency). Each test file returns
-- function (T) ... end and registers cases with T.case(name, fn).
local T = { results = {}, current = nil }

function T.case (name, fn)
    local ok, err = pcall (fn)
    T.results[#T.results + 1] = { file = T.current, name = name, ok = ok, err = err }
    io.write ((ok and "  PASS  " or "  FAIL  ") .. name .. (ok and "" or ("\n        " .. tostring (err))) .. "\n")
end

local function fmt (v)
    if type (v) == "table" then
        local p = {}
        for i, x in ipairs (v) do p[i] = tostring (x) end
        return "{" .. table.concat (p, ",") .. "}"
    end
    return tostring (v)
end

function T.eq (a, b, msg)
    if a ~= b then error ((msg or "values differ") .. ": got " .. fmt (a) .. ", expected " .. fmt (b), 2) end
end
function T.ok (v, msg) if not v then error (msg or "expected true", 2) end end
function T.no (v, msg) if v then error (msg or "expected false", 2) end end
function T.near (a, b, eps, msg)
    if type (a) ~= "number" or math.abs (a - b) > (eps or 1e-9) then
        error ((msg or "not near") .. ": got " .. tostring (a) .. ", expected " .. tostring (b), 2)
    end
end
function T.has (list, x, msg)
    for _, v in ipairs (list or {}) do if v == x then return end end
    error ((msg or "missing element") .. ": " .. tostring (x) .. " not in " .. fmt (list), 2)
end
function T.lacks (list, x, msg)
    for _, v in ipairs (list or {}) do if v == x then error ((msg or "unexpected element") .. ": " .. tostring (x), 2) end end
end

return T
