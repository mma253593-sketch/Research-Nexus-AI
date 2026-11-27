-- Runs every V2.0 test file. Usage (from any directory):
--   lua5.3 qcs/v2_rebuild/test/run_all.lua [file-filter]
-- Exit status 0 only when every case passed.
local root = (arg and arg[0] or ""):match ("^(.*)/test/[^/]*$") or "."
V2_ROOT = root
package.path = root .. "/src/?.lua;" .. root .. "/config/?.lua;" .. root .. "/test/?.lua;" .. root .. "/eval/?.lua;"
    .. root .. "/../test/?.lua;" .. package.path

local T = require ("tu")
local FILES = { "test_data_validation", "test_config_indicators", "test_analysis", "test_signal_engine",
                "test_temporal", "test_integration", "test_regression", "test_qcs_bundle", "test_eval" }
local filter = arg and arg[1]
for _, name in ipairs (FILES) do
    if not filter or name:find (filter, 1, true) then
        print ("== " .. name)
        T.current = name
        local fn = require (name)
        fn (T)
    end
end
local pass, fail = 0, 0
for _, r in ipairs (T.results) do if r.ok then pass = pass + 1 else fail = fail + 1 end end
print (("\n%d passed, %d failed"):format (pass, fail))
if fail > 0 then
    print ("FAILED:")
    for _, r in ipairs (T.results) do if not r.ok then print ("  " .. r.file .. " :: " .. r.name) end end
    os.exit (1)
end
print ("ALL V2.0 TESTS PASSED")
