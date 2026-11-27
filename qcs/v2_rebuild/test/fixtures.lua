-- =====================================================================
--  SYNTHETIC test fixtures (NOT market data). Deterministic: a 31-bit
--  LCG instead of math.random, so every Lua build produces identical
--  candles. Used only to exercise code paths; never reported as market
--  performance.
-- =====================================================================
local F = {}

F.T0 = 1735689600   -- 2025-01-01 00:00:00 UTC (multiple of 300)

function F.rng (seed)
    local s = seed % 2147483647
    if s <= 0 then s = s + 2147483646 end
    return function ()
        s = (s * 48271) % 2147483647
        return s / 2147483647
    end
end

--- segments: { kind = "trend"|"range"|"flat"|"spike", n, drift, vol, amp }
function F.series (segments, seed, start_price, t0)
    local r = F.rng (seed or 1)
    local p, t = start_price or 2650, t0 or F.T0
    local out, center = {}, nil
    for _, sg in ipairs (segments) do
        center = p
        for k = 1, sg.n do
            local o = p
            local vol = sg.vol or 0.6
            local c
            if sg.kind == "trend" then c = o + (sg.drift or 0.3) + (r () - 0.5) * 2 * vol
            elseif sg.kind == "range" then
                local target = center + (sg.amp or 3) * math.sin (k / 6)
                c = o + (target - o) * 0.5 + (r () - 0.5) * 2 * vol
            elseif sg.kind == "flat" then c = o
            elseif sg.kind == "spike" then c = o + (sg.drift or 15) * ((k % 2 == 1) and 1 or -1)
            else c = o + (r () - 0.5) * 2 * vol end
            local wick = (sg.kind == "flat") and 0 or (sg.wick or 0.3)
            local h = math.max (o, c) + r () * wick
            local l = math.min (o, c) - r () * wick
            out[#out + 1] = { t = t, o = F.r2 (o), h = F.r2 (h), l = F.r2 (l), c = F.r2 (c) }
            -- keep OHLC consistent after rounding
            local b = out[#out]
            b.h = math.max (b.h, b.o, b.c); b.l = math.min (b.l, b.o, b.c)
            p, t = b.c, t + 60
        end
    end
    return out
end

function F.r2 (x) return math.floor (x * 100 + 0.5) / 100 end

function F.now_after (m1) return m1[#m1].t + 60 end

--- deep copy of a candle list
function F.copy (m1)
    local o = {}
    for i, b in ipairs (m1) do o[i] = { t = b.t, o = b.o, h = b.h, l = b.l, c = b.c, closed = b.closed } end
    return o
end

function F.input (m1, extra)
    local x = { m1 = m1, now = F.now_after (m1) }
    for k, v in pairs (extra or {}) do x[k] = v end
    return x
end

F.UP     = { { kind = "range", n = 120, amp = 2, vol = 0.5 }, { kind = "trend", n = 200, drift = 0.35, vol = 0.6 } }
F.DOWN   = { { kind = "range", n = 120, amp = 2, vol = 0.5 }, { kind = "trend", n = 200, drift = -0.35, vol = 0.6 } }
F.RANGE  = { { kind = "range", n = 320, amp = 3, vol = 0.45 } }
F.MIXED  = { { kind = "range", n = 200, amp = 3, vol = 0.5 }, { kind = "trend", n = 300, drift = 0.3, vol = 0.7 },
             { kind = "range", n = 300, amp = 4, vol = 0.6 }, { kind = "trend", n = 300, drift = -0.3, vol = 0.7 },
             { kind = "walk", n = 400, vol = 0.8 }, { kind = "trend", n = 300, drift = 0.25, vol = 0.9 } }

return F
