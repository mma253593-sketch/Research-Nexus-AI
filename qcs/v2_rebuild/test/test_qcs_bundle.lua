-- Requirement 21: build verification. The paste-ready scripts must be
-- <= 25,000 characters, be up to date with src/, load in the offline QCS
-- mock (qcs/test/mock_qcs.lua) and reproduce the pure engine exactly
-- (INDEX_PROXY timestamps). The readable bundle must behave identically to
-- the shrunk paste-ready script, and live ticks must not change the signal.
local mock = require ("mock_qcs")
local C = require ("config")
local E = require ("main")
local F = require ("fixtures")

local function read (p)
    local f = io.open (V2_ROOT .. "/" .. p, "r")
    if not f then return nil end
    local s = f:read ("a"); f:close (); return s
end

-- the bundler's functions without writing any file
BUILD_AS_LIBRARY = true
dofile (V2_ROOT .. "/scripts/build.lua")
BUILD_AS_LIBRARY = nil

return function (T)
    local chart, panel = read ("dist/XAUUSD_Smart_Entry_V2_0.lua"), read ("dist/XAUUSD_Smart_Entry_V2_0_Panel.lua")
    local readable = read ("dist/readable/XAUUSD_Smart_Entry_V2_0_Readable.lua")

    T.case ("paste-ready scripts exist, are <= 25,000 characters, ASCII, start with instrument{}, compile", function ()
        for _, s in ipairs ({ chart, panel, readable }) do
            T.ok (s ~= nil, "missing dist file (run scripts/build.sh)")
            T.ok (s:sub (1, 10) == "instrument", "first statement must be instrument {}")
            T.ok (load (s, "=bundle", "t", {}) ~= nil, "compiles")
        end
        for _, s in ipairs ({ chart, panel }) do
            T.ok (#s <= 25000, "paste-ready script has " .. #s .. " characters (limit 25,000)")
            T.no (s:find ("[\128-\255]"), "non-ASCII byte")
        end
    end)

    T.case ("dist is up to date: rebuilding from src reproduces every file byte for byte", function ()
        local r = bundle (CHART_HEADER, "view_main.lua")
        T.eq (r, readable, "readable bundle stale")
        T.eq (paste_ready (r), chart, "chart script stale")
        T.eq (paste_ready (bundle (PANEL_HEADER, "view_panel.lua")), panel, "panel script stale")
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
            local e = env.env
            out[Tn] = { dir = e.SIG_DIR, call = e.CALL_SCORE, put = e.PUT_SCORE, kind = e.SIG_KIND, src = e.TIME_SOURCE,
                        reg = e.REGIME_CODE, ok = e.DATA_OK }
        end
        return out
    end

    T.case ("paste-ready chart script reproduces the pure engine bar by bar", function ()
        local q = run_mock (chart, F.copy (m1))
        local cfg = assert (C.load ())
        local run = E.new_runner (cfg)
        local KIND = { PULLBACK_CONTINUATION = 1, TREND_CONTINUATION = 2, BREAKOUT_CONFIRMATION = 3, RANGE_REJECTION = 4 }
        local signals = 0
        for Tn = 2, #m1 do
            local w = {}
            for i = math.min (cfg.data.m1_window, Tn - 1), 1, -1 do
                local b = m1[Tn - i]
                w[#w + 1] = { t = (Tn - i) * 60, o = b.o, h = b.h, l = b.l, c = b.c, closed = true }
            end
            local r = run:step ({ now = Tn * 60, m1 = w })
            local dir = r.decision == "CALL" and 1 or (r.decision == "PUT" and -1 or 0)
            if dir ~= 0 then signals = signals + 1; T.eq (q[Tn].kind, KIND[r.setup] * dir, "setup code at " .. Tn) end
            if q[Tn].dir ~= dir or q[Tn].call ~= r.call_score or q[Tn].put ~= r.put_score then
                error (("mismatch at bar %d: qcs %d %d/%d vs engine %d %d/%d"):format (Tn, q[Tn].dir, q[Tn].call, q[Tn].put, dir, r.call_score, r.put_score))
            end
        end
        T.eq (q[#m1].src, "INDEX_PROXY")
        T.ok (signals > 0, "fixture should produce at least one signal")
    end)

    T.case ("readable bundle == paste-ready chart == panel scores (shrinking changes nothing)", function ()
        local a, b, c = run_mock (readable, F.copy (m1)), run_mock (chart, F.copy (m1)), run_mock (panel, F.copy (m1))
        for Tn = 1, #m1 do
            for _, k in ipairs ({ "dir", "call", "put", "kind", "reg", "ok" }) do
                if a[Tn][k] ~= b[Tn][k] then error (("readable vs chart differ in %s at bar %d"):format (k, Tn)) end
            end
            T.eq (a[Tn].call, c[Tn].call, "panel score at " .. Tn); T.eq (a[Tn].dir, c[Tn].dir)
        end
    end)

    T.case ("live ticks on the forming candle never change the signal (no repaint)", function ()
        local a, b = run_mock (chart, F.copy (m1)), run_mock (chart, F.copy (m1), true)
        for Tn = 1, #m1 do T.eq (a[Tn].dir, b[Tn].dir, "tick changed signal at " .. Tn) end
    end)

    T.case ("QCS lean config check agrees with the full validator on every QCS input value", function ()
        local lean = {}
        local chunk = assert (load (qcs_variant (read ("src/config.lua")), "=config_qcs", "t", setmetatable ({ require = require }, { __index = _G })))
        lean = chunk ()
        for w = 195, 605 do
            for _, cd in ipairs ({ -1, 0, 1, 2, 5, 20, 101, 2.5 }) do
                local cfg = C.defaults (); cfg.data.m1_window = w; cfg.runner.cooldown_bars = cd
                local full = C.validate (cfg)
                T.eq (lean.validate (cfg), full, ("window %d cooldown %s"):format (w, tostring (cd)))
            end
        end
        T.no (lean.validate (nil)); T.no (lean.validate ({}))
    end)

    T.case ("bundles use no runtime require / io / os / pcall", function ()
        for _, s in ipairs ({ chart, panel }) do
            local body = s:gsub ("local function require", "")
            T.no (body:find ("[^%w_]io%.") or body:find ("[^%w_]os%."), "io/os used in bundle")
            T.no (body:find ("pcall"), "pcall not verified in QCS")
        end
    end)
end
