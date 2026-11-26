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

local function kind (l)
    if l:match ("^%s+[%w_]+%s*=%s*input[%s{(]") and l:match (",$") then return "field" end
    if l:match ("^[%w_]+%s*=%s*make_series%s*%(%)$") then return "stmt" end
    if l:match ("^[A-Z][A-Z0-9_]*%s*=%s*[^,]+$") and not l:match ("[{(]$") then return "stmt" end
    return nil
end

local i = 1
while i <= #kept do
    local l = kept[i]
    local k = kind (l)
    if k then
        local group, j = { l }, i + 1
        local max = (k == "field") and 3 or 4             -- 3 settings or 4 short statements per line
        while j <= #kept and #group < max and kind (kept[j]) == k do
            group[#group + 1] = kept[j]:gsub ("^%s+", ""); j = j + 1
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
