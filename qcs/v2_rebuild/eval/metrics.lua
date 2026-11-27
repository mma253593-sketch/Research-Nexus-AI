-- =====================================================================
--  Evaluation metrics (pure functions).
--  trade = { t, dir = 1|-1, score, setup, regime, outcome = "win"|"loss"|"tie" }
--
--  summarize(trades, opts) -> {
--     n, wins, losses, ties,
--     accuracy       wins / (wins + losses)        gross directional accuracy (ties excluded)
--     acc_lo/acc_hi  95% Wilson interval of `accuracy`
--     expectancy     per-trade net result in stakes, ONLY when opts.payout is
--                    given: win +payout, loss -1, tie -1 (opts.tie = "loss",
--                    default, conservative) or 0 (opts.tie = "push")
--     breakeven      accuracy needed to break even = 1 / (1 + payout)
--     net, max_dd    cumulative stakes and max drawdown (payout only)
--     max_losing_streak  consecutive non-wins (ties count as losses unless push)
--  }
-- =====================================================================
local M = {}

function M.wilson (w, n, z)
    if n == 0 then return 0, 0 end
    z = z or 1.96
    local p = w / n
    local d = 1 + z * z / n
    local c = (p + z * z / (2 * n)) / d
    local m = z * math.sqrt (p * (1 - p) / n + z * z / (4 * n * n)) / d
    return math.max (0, c - m), math.min (1, c + m)
end

function M.summarize (trades, opts)
    opts = opts or {}
    local push = opts.tie == "push"
    local s = { n = #trades, wins = 0, losses = 0, ties = 0, max_losing_streak = 0 }
    local streak, eq, peak, dd = 0, 0, 0, 0
    for _, t in ipairs (trades) do
        if t.outcome == "win" then s.wins = s.wins + 1; streak = 0
        elseif t.outcome == "loss" then s.losses = s.losses + 1; streak = streak + 1
        else s.ties = s.ties + 1; if not push then streak = streak + 1 end end
        s.max_losing_streak = math.max (s.max_losing_streak, streak)
        if opts.payout then
            if t.outcome == "win" then eq = eq + opts.payout
            elseif t.outcome == "loss" or not push then eq = eq - 1 end
            peak = math.max (peak, eq); dd = math.max (dd, peak - eq)
        end
    end
    local decided = s.wins + s.losses
    s.accuracy = decided > 0 and s.wins / decided or nil
    s.acc_lo, s.acc_hi = M.wilson (s.wins, decided)
    if opts.payout then
        s.net, s.max_dd = eq, dd
        s.expectancy = s.n > 0 and eq / s.n or nil
        s.breakeven = 1 / (1 + opts.payout)
    end
    return s
end

--- groups trades by key(trade) -> ordered list of { key, trades }
function M.group (trades, key, order)
    local by, keys = {}, {}
    for _, t in ipairs (trades) do
        local k = key (t)
        if by[k] == nil then by[k] = {}; keys[#keys + 1] = k end
        by[k][#by[k] + 1] = t
    end
    if order then keys = order else table.sort (keys, function (a, b) return tostring (a) < tostring (b) end) end
    local out = {}
    for _, k in ipairs (keys) do if by[k] then out[#out + 1] = { key = k, trades = by[k] } end end
    return out
end

function M.score_bucket (score)
    if score >= 90 then return "90-100" elseif score >= 80 then return "80-89"
    elseif score >= 70 then return "70-79" elseif score >= 60 then return "60-69" end
    return "<60"
end

--- UTC session of an M1 candle open time
function M.session (t)
    local h = (t % 86400) // 3600
    if h < 7 then return "Asia 00-07 UTC" elseif h < 13 then return "London 07-13 UTC"
    elseif h < 21 then return "New York 13-21 UTC" end
    return "Late 21-24 UTC"
end

--- cumulative results after the first k signals (k = 25, 50, 100, 200, ...)
function M.by_sample_size (trades, opts)
    local out, k = {}, 25
    while k <= #trades do
        local sub = {}
        for i = 1, k do sub[i] = trades[i] end
        out[#out + 1] = { k = k, s = M.summarize (sub, opts) }
        k = k * 2
    end
    if #trades > 0 then out[#out + 1] = { k = #trades, s = M.summarize (trades, opts), all = true } end
    return out
end

--- chronological split of [1, n] by fractions -> list of { name, first, last }
function M.splits (n, cuts, names)
    local out, prev = {}, 0
    for i, f in ipairs (cuts) do
        local last = (i == #cuts) and n or math.floor (n * f)
        out[#out + 1] = { name = names[i], first = prev + 1, last = last }
        prev = last
    end
    return out
end

return M
