-- Whitespace-only minifier for the Compact script (same tokens, fewer characters).
-- Usage: lua5.3 qcs/tools/minify.lua <in.lua> <out.lua>
-- Outside string literals it removes indentation, collapses spaces, and drops
-- spaces next to punctuation. It never joins two "-" into a comment.
-- Equality with the Main script is enforced by qcs/test/run_tests.lua.
local PUNCT = "[%(%)%[%]{},=<>~%+%-%*/;]"
local out = {}
for line in io.lines (arg[1]) do
    local s, q = {}, nil
    line = line:gsub ("^%s+", ""):gsub ("%s+$", "")
    for i = 1, #line do
        local c = line:sub (i, i)
        if q then
            s[#s + 1] = c
            if c == q then q = nil end
        elseif c == '"' or c == "'" then
            q = c; s[#s + 1] = c
        elseif c:match ("%s") then
            local p, n = s[#s] or "", line:sub (i + 1, i + 1)
            if p == " " then
                -- already have one space
            elseif p == "-" and n == "-" then
                s[#s + 1] = " "                  -- keep "a - -b" from becoming a comment
            elseif not (p:match (PUNCT) or n:match (PUNCT) or n:match ("%s")) then
                s[#s + 1] = " "
            end
        else
            s[#s + 1] = c
        end
    end
    out[#out + 1] = table.concat (s)
end
local text = table.concat (out, "\n") .. "\n"
local f = assert (io.open (arg[2], "w"))
f:write (text)
f:close ()
print (("minify: %s (%d characters, %d lines)"):format (arg[2], #text, #out))
