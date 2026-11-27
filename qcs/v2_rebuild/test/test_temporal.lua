-- Requirements 18-19 (+ temporal integrity): determinism, no look-ahead,
-- no repaint, no hidden state, CALL/PUT mirror symmetry.
local C = require ("config")
local E = require ("main")
local F = require ("fixtures")
local D = require ("diagnostics")

local function window (m1, T, W)
    local o = {}
    for j = math.max (1, T - W), T - 1 do
        local b = m1[j]
        o[#o + 1] = { t = b.t, o = b.o, h = b.h, l = b.l, c = b.c }
    end
    return o
end

return function (T)
    local cfg = assert (C.load ())
    local m1 = F.series (F.MIXED, 11)
    local W = cfg.data.m1_window

    T.case ("deterministic: identical input -> byte-identical diagnostics", function ()
        for Tn = 260, #m1, 97 do
            local a = D.to_json (E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, cfg).diagnostics)
            local b = D.to_json (E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, assert (C.load ())).diagnostics)
            T.eq (a, b, "bar " .. Tn)
        end
    end)

    T.case ("deterministic: two full runs give identical decision streams", function ()
        local function stream ()
            local run, out = E.new_runner (cfg), {}
            for Tn = 241, #m1 do out[#out + 1] = run:step ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }).decision end
            return table.concat (out, ",")
        end
        T.eq (stream (), stream ())
    end)

    T.case ("no look-ahead: changing every candle at or after T leaves the decision at T unchanged", function ()
        local r = F.rng (5)
        for Tn = 300, #m1, 61 do
            local alt = F.copy (m1)                         -- only candles >= Tn differ
            for j = Tn, #alt do
                local b = alt[j]
                b.o = m1[j].o + (r () - 0.5) * 40; b.c = b.o + (r () - 0.5) * 20
                b.h = math.max (b.o, b.c) + r () * 3; b.l = math.min (b.o, b.c) - r () * 3
            end
            local a = E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, cfg)
            local b = E.evaluate ({ now = m1[Tn].t, m1 = window (alt, Tn, W) }, cfg)
            T.eq (D.to_json (a.diagnostics), D.to_json (b.diagnostics), "bar " .. Tn)
        end
    end)

    T.case ("no look-ahead: passing a future candle is rejected, never used", function ()
        local Tn = 500
        local w = window (m1, Tn + 1, W)                    -- includes candle Tn, which opens at `now`
        local r = E.evaluate ({ now = m1[Tn].t - 60, m1 = w }, cfg)
        T.eq (r.decision, "WAIT"); T.has (r.diagnostics.data.errors, "M1_FUTURE_CANDLE")
    end)

    T.case ("no repaint: any forming-candle tick gives the same decision as without it", function ()
        local r = F.rng (17)
        for Tn = 300, #m1, 53 do
            local ref = D.to_json (E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, cfg).diagnostics)
            for k = 1, 5 do
                local w = window (m1, Tn, W)
                local o = m1[Tn].o
                local c = o + (r () - 0.5) * 30
                w[#w + 1] = { t = m1[Tn].t, o = o, c = c, h = math.max (o, c) + 1, l = math.min (o, c) - 1 }
                local now = m1[Tn].t + 5 * k                    -- a tick inside the forming candle
                local res = E.evaluate ({ now = now, m1 = w }, cfg)
                local d = res.diagnostics
                d.timestamp = m1[Tn].t
                d.data.warnings = (function () local o2 = {} for _, x in ipairs (d.data.warnings) do if x ~= "M1_INCOMPLETE_DROPPED" then o2[#o2 + 1] = x end end return o2 end) ()
                d.data.staleness_sec = 0
                T.eq (D.to_json (d), ref, "bar " .. Tn .. " tick " .. k)
            end
        end
    end)

    T.case ("no hidden state: runner decisions equal fresh evaluations (cooldown 0)", function ()
        local c0 = assert (C.load ({ runner = { cooldown_bars = 0 } }))
        local run = E.new_runner (c0)
        for Tn = 241, #m1 do
            local x = run:step ({ now = m1[Tn].t, m1 = window (m1, Tn, W) })
            local y = E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, c0)
            if x.decision ~= y.decision then error ("state leak at bar " .. Tn) end
        end
    end)

    T.case ("CALL/PUT symmetry: mirrored prices give mirrored decisions and equal scores", function ()
        local mir = {}
        for i, b in ipairs (m1) do mir[i] = { t = b.t, o = 5400 - b.o, h = 5400 - b.l, l = 5400 - b.h, c = 5400 - b.c } end
        local flip = { CALL = "PUT", PUT = "CALL", WAIT = "WAIT" }
        local mism = 0
        for Tn = 241, #m1, 3 do
            local a = E.evaluate ({ now = m1[Tn].t, m1 = window (m1, Tn, W) }, cfg)
            local b = E.evaluate ({ now = m1[Tn].t, m1 = window (mir, Tn, W) }, cfg)
            if flip[a.decision] ~= b.decision or a.call_score ~= b.put_score or a.put_score ~= b.call_score then mism = mism + 1 end
        end
        -- floating-point rounding of mirrored prices may flip an exact tie; allow none in practice
        T.eq (mism, 0, "mirror mismatches")
    end)

    T.case ("signals only when data are valid; every WAIT carries a reason", function ()
        local run = E.new_runner (cfg)
        for Tn = 2, #m1 do
            local r = run:step ({ now = m1[Tn].t, m1 = window (m1, Tn, W) })
            if r.decision ~= "WAIT" then T.ok (r.diagnostics.data.valid, "signal on invalid data") end
            if r.decision == "WAIT" then T.ok (#r.reasons > 0, "WAIT without reason at " .. Tn) end
        end
    end)
end
