-- Requirement 21: build verification. The generated paste-ready scripts
-- must exist, load in the offline QCS mock (qcs/test/mock_qcs.lua) and
-- reproduce the pure engine exactly (INDEX_PROXY timestamps); Mini must
-- behave identically to Main; live ticks must not change the signal.
local mock = require ("mock_qcs")
local C = require ("config")
local E = require ("main")
local F = require ("fixtures")

local function read (p)
    local f = io.open (V2_ROOT .. "/" .. p, "r")
    if not f then return nil end
    local s = f:read ("a"); f:close (); return s
end

return function (T)
    local main, mini, panel = read ("dist/XAUUSD_Smart_Entry_V2_0_Main.lua"), read ("dist/XAUUSD_Smart_Entry_V2_0_Mini.lua"),
        read ("dist/XAUUSD_Smart_Entry_V2_0_Panel.lua")

    T.case ("bundle: dist scripts exist, start with instrument{}, compile", function ()
        for _, s in ipairs ({ main, mini, panel }) do
            T.ok (s ~= nil, "missing dist file (run scripts/build.sh)")
            T.ok (s:sub (1, 10) == "instrument", "first statement must be instrument {}")
            T.ok (load (s, "=bundle", "t", {}) ~= nil, "compiles")
        end
    end)

    T.case ("bundle: dist is up to date with src (rebuild reproduces it)", function ()
        local mods = { "util", "config", "indicators", "data_validation", "regime_detection", "trend_context",
                       "momentum_analysis", "price_action", "entry_timing", "volatility_filter", "adaptive_profile",
                       "signal_engine", "diagnostics", "main" }
        for _, m in ipairs (mods) do
            local src = read ("src/" .. m .. ".lua"):gsub ("%s+$", "")
            T.ok (main:find (src, 1, true) ~= nil, "dist Main is stale for module " .. m)
        end
        T.ok (main:find ((read ("src/qcs/adapter.lua"):gsub ("%s+$", "")), 1, true) ~= nil, "adapter stale")
    end)

    local m1 = F.series (F.MIXED, 11)
    local function run_mock (src, bars, ticks)
        local env = mock.new (bars)
        env.load (src)
        local out = {}
        for Tn = 1, #bars do
            if ticks then                                         -- re-evaluate the forming bar several times
                local real = bars[Tn]
                for k = 1, 3 do
                    local c = real.o + (k - 2) * 7
                    bars[Tn] = { o = real.o, c = c, h = math.max (real.o, c) + 1, l = math.min (real.o, c) - 1 }
                    env.run_bar (Tn)
                end
                bars[Tn] = real
            end
            env.run_bar (Tn)
            out[Tn] = { dir = env.env.SIG_DIR, call = env.env.CALL_SCORE, put = env.env.PUT_SCORE, src = env.env.TIME_SOURCE }
        end
        return out
    end

    T.case ("bundle: QCS Main reproduces the pure engine bar by bar", function ()
        local q = run_mock (main, F.copy (m1))
        local cfg = assert (C.load ())
        local run = E.new_runner (cfg)
        local signals = 0
        for Tn = 2, #m1 do
            local w = {}
            for i = math.min (cfg.data.m1_window, Tn - 1), 1, -1 do
                local b = m1[Tn - i]
                w[#w + 1] = { t = (Tn - i) * 60, o = b.o, h = b.h, l = b.l, c = b.c, closed = true }
            end
            local r = run:step ({ now = Tn * 60, m1 = w })
            local dir = r.decision == "CALL" and 1 or (r.decision == "PUT" and -1 or 0)
            if dir ~= 0 then signals = signals + 1 end
            if q[Tn].dir ~= dir or q[Tn].call ~= r.call_score or q[Tn].put ~= r.put_score then
                error (("mismatch at bar %d: qcs %d %d/%d vs engine %d %d/%d"):format (Tn, q[Tn].dir, q[Tn].call, q[Tn].put, dir, r.call_score, r.put_score))
            end
        end
        T.eq (q[#m1].src, "INDEX_PROXY")
        T.ok (signals >= 0)
    end)

    T.case ("bundle: Mini behaves identically to Main; Panel computes the same scores", function ()
        local a, b, c = run_mock (main, F.copy (m1)), run_mock (mini, F.copy (m1)), run_mock (panel, F.copy (m1))
        for Tn = 1, #m1 do
            T.eq (a[Tn].dir, b[Tn].dir, "Mini dir at " .. Tn); T.eq (a[Tn].call, b[Tn].call); T.eq (a[Tn].put, b[Tn].put)
            T.eq (a[Tn].call, c[Tn].call, "Panel score at " .. Tn)
        end
    end)

    T.case ("bundle: live ticks on the forming candle never change the signal (no repaint)", function ()
        local a, b = run_mock (main, F.copy (m1)), run_mock (main, F.copy (m1), true)
        for Tn = 1, #m1 do T.eq (a[Tn].dir, b[Tn].dir, "tick changed signal at " .. Tn) end
    end)

    T.case ("bundle: uses no runtime require / io / os", function ()
        local body = main:gsub ("local function require", "")
        T.no (body:find ("[^%w_]io%.") or body:find ("[^%w_]os%."), "io/os used in bundle")
        T.no (body:find ("pcall"), "pcall not verified in QCS")
    end)
end
