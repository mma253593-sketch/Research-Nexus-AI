-- Deterministic synthetic OHLC generators for the offline tests.
-- Prices are XAUUSD-like (around 2650, M1-sized candles). Synthetic data
-- exercises the logic; it carries no information about real market edge.
local G = {}

local function candle (o, move, vol)
    local c = o + move
    return { o = o, c = c,
             h = math.max (o, c) + math.random () * vol * 0.7,
             l = math.min (o, c) - math.random () * vol * 0.7 }
end

-- segments: list of { n = bars, drift = per bar, vol = noise, spike = prob }
local function build (segments, seed, start)
    math.randomseed (seed)
    local bars, p = {}, start or 2650
    for _, s in ipairs (segments) do
        for _ = 1, s.n do
            local move = s.drift + (math.random () - 0.5) * 2 * s.vol
            if s.revert then move = move - s.revert * (p - s.center) end   -- mean reversion (range)
            if s.spike and math.random () < s.spike then move = move * 6 end
            local b = candle (p, move, s.vol)
            bars[#bars + 1] = b
            p = b.c
        end
    end
    return bars
end

-- V1 test generator (kept identical for V1/V2 comparability)
function G.mixed (n, seed)
    math.randomseed (seed)
    local bars, p, drift, vol = {}, 2650, 0, 0.8
    for t = 1, n do
        if t % 150 == 1 then
            local r = math.random ()
            drift = (r < 0.35) and 0.18 or (r < 0.7) and -0.18 or 0
            vol = 0.5 + math.random () * 0.7
        end
        local o = p
        local move = drift + (math.random () - 0.5) * 2 * vol
        if math.random () < 0.01 then move = move * 6 end
        bars[t] = candle (o, move, vol)
        p = bars[t].c
    end
    return bars
end

function G.trend (n, seed, drift)
    local warm = 300
    return build ({ { n = warm, drift = drift * 0.5, vol = 0.6 }, { n = n - warm, drift = drift, vol = 0.6 } }, seed),
           { test_from = warm + 1 }
end

function G.range (n, seed)
    local warm = 300
    -- Ornstein-Uhlenbeck: noise around a fixed centre with a pull back to it
    return build ({ { n = warm, drift = 0, vol = 0.6 },
                    { n = n - warm, drift = 0, vol = 0.6, revert = 0.08, center = 2650 } }, seed),
           { test_from = warm + 1 }
end

function G.vol_shift (n, seed, factor)
    local shift = 500
    return build ({ { n = shift, drift = 0.05, vol = 0.6 }, { n = n - shift, drift = 0.05, vol = 0.6 * factor } }, seed),
           { shift = shift }
end

function G.reversal (n, seed)
    local flip = math.floor (n / 2)
    return build ({ { n = flip, drift = 0.15, vol = 0.6 }, { n = n - flip, drift = -0.15, vol = 0.6 } }, seed),
           { flip = flip }
end

-- Trend made of impulse legs and shallow pullbacks (dir = 1 up, -1 down)
function G.pullback (n, seed, dir)
    local segs = { { n = 300, drift = 0.05 * dir, vol = 0.6 } }
    local total = 300
    while total < n do
        segs[#segs + 1] = { n = 10, drift = 0.35 * dir, vol = 0.5 }
        segs[#segs + 1] = { n = 4, drift = -0.25 * dir, vol = 0.5 }
        total = total + 14
    end
    local bars = build (segs, seed)
    while #bars > n do table.remove (bars) end
    return bars, { test_from = 301 }
end

function G.flat (n)
    local bars = {}
    for t = 1, n do bars[t] = { o = 2650, h = 2650, l = 2650, c = 2650 } end
    return bars
end

function G.gap (n, seed)
    local bars = build ({ { n = n, drift = 0.02, vol = 0.6 } }, seed)
    for t = math.floor (n / 2), n do
        local b = bars[t]
        bars[t] = { o = b.o + 20, h = b.h + 20, l = b.l + 20, c = b.c + 20 }
    end
    return bars
end

return G
