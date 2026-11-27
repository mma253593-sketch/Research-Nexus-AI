-- Produces a shorter, behaviour-identical copy of a generated QCS script.
-- Usage: lua5.3 qcs/tools/compact.lua <in.lua> <out.lua>
-- Only layout changes: comment and blank lines are removed, trailing
-- comments stripped, and short statements joined. No token is altered.
-- Equality with the source script is enforced by qcs/test/run_tests.lua.
local src, dst = arg[1], arg[2]
local out, lines = {}, {}
for l in io.lines (src) do lines[#lines + 1] = l end

local function strip_trailing (l)
    -- remove " -- comment" when the "--" is outside string literals
    local q, i = nil, 1
    while i <= #l do
        local c = l:sub (i, i)
        if q then
            if c == q then q = nil end
        elseif c == '"' or c == "'" then
            q = c
        elseif l:sub (i, i + 1) == "--" then
            return (l:sub (1, i - 1):gsub ("%s+$", ""))
        end
        i = i + 1
    end
    return l
end

local kept = {}
for n, l in ipairs (lines) do
    if n <= 2 then kept[#kept + 1] = l
    elseif not l:match ("^%s*$") and not l:match ("^%s*%-%-") then
        kept[#kept + 1] = strip_trailing (l)
    end
end

-- A "simple statement" is one complete single-line assignment or call:
-- no block keyword, no function definition, no unfinished expression, and
-- the next line is not a continuation of it. Such lines at the same
-- indentation can be joined with "; " without changing meaning.
local KEYWORDS = { ["if"] = 1, ["elseif"] = 1, ["else"] = 1, ["for"] = 1, ["while"] = 1,
                   ["repeat"] = 1, ["until"] = 1, ["return"] = 1, ["end"] = 1, ["do"] = 1,
                   ["and"] = 1, ["or"] = 1, ["not"] = 1 }
local function simple (l, nxt)
    local first = l:match ("^%s*([%a_]+)")
    if not first or KEYWORDS[first] or l:match ("function") then return false end
    if l:match ("[,%({=%+%-%*/]%s*$") or l:match ("%f[%w]and%s*$") or l:match ("%f[%w]or%s*$")
       or l:match ("then%s*$") or l:match ("do%s*$") then return false end
    if nxt and (nxt:match ("^%s*and%f[%W]") or nxt:match ("^%s*or%f[%W]") or nxt:match ("^%s*[%+%-%*/%.]")) then
        return false
    end
    if l:match ("plot_shape") then return false end                   -- already long lines
    local assign = l:match ("^%s*local%s") or l:match ("^%s*[%w_%.]+[%w_%., ]*=[^=]")
    local call = l:match ("^%s*[%w_:%.]+%s?%b()%s*$")
    return (assign or call) and true or false
end

local function kind (l, nxt)
    if l:match ("^%s+[%w_]+%s*=%s*input[%s{(]") and l:match (",$") then return "field" end
    if simple (l, nxt) then return "stmt" .. l:match ("^(%s*)") end    -- grouped per indentation
    return nil
end

local i = 1
while i <= #kept do
    local l = kept[i]
    local k = kind (l, kept[i + 1])
    if k then
        local group, j = { l }, i + 1
        local max = (k == "field") and 2 or 3             -- 2 settings or 3 short statements per line
        local len = #l
        while j <= #kept and #group < max and kind (kept[j], kept[j + 1]) == k
              and (k == "field" or len + #kept[j] <= 140) do
            group[#group + 1] = kept[j]:gsub ("^%s+", ""); len = len + #kept[j]; j = j + 1
        end
        out[#out + 1] = table.concat (group, k == "field" and " " or "; ")
        i = j
    elseif l:match ("^input_group {$") and kept[i + 1] and kept[i + 1]:match ('^%s+"[^"]*",$') then
        out[#out + 1] = l .. " " .. kept[i + 1]:gsub ("^%s+", "")      -- input_group { "Title",
        i = i + 2
    elseif l:match ("^%s*plot_shape %(.*,$") and kept[i + 1] then
        out[#out + 1] = l .. " " .. kept[i + 1]:gsub ("^%s+", "")      -- 2-line plot_shape call
        i = i + 2
    else
        out[#out + 1] = l
        i = i + 1
    end
end

local f = assert (io.open (dst, "w"))
f:write (table.concat (out, "\n"), "\n")
f:close ()
print (("compact: %s (%d lines)"):format (dst, #out))
