-- =====================================================================
--  indicators — array indicators over a window of CLOSED candles.
--
--  Every function takes plain arrays (index 1 = oldest) and returns an
--  array of the same length; positions without enough history are nil.
--  Value at index i only uses inputs at indices <= i (causal), so the
--  value of a closed candle never changes when later candles arrive
--  within the same window start.
--
--  Seeding: EMA/RMA start from the SMA of their first n inputs, ATR/RSI
--  use Wilder smoothing (official QCS library formulas: rma = 1/n).
--
--  indicators.compute(m1, cfg) computes all features ONCE per evaluation;
--  every analysis module reads this shared table (no recomputation).
-- =====================================================================
local M = {}

--- exponential (alpha = 2/(n+1)) or Wilder (alpha = 1/n) smoothing, SMA seeded
local function smooth (src, n, alpha, first)
    local out, sum, cnt, prev = {}, 0, 0, nil
    for i = 1, #src do
        local x = src[i]
        if x ~= nil and i >= (first or 1) then
            if prev == nil then
                sum, cnt = sum + x, cnt + 1
                if cnt == n then prev = sum / n; out[i] = prev end
            else
                prev = prev + alpha * (x - prev); out[i] = prev
            end
        end
    end
    return out
end
function M.ema (src, n) return smooth (src, n, 2 / (n + 1)) end
function M.rma (src, n) return smooth (src, n, 1 / n) end

--- simple moving average of src over [i-n+1-lag, i-lag] (rolling sum, O(len));
--- a nil input restarts the window
function M.sma (src, n, lag)
    lag = lag or 0
    local out, sum, cnt = {}, 0, 0
    for j = 1, #src do
        local x = src[j]
        if x == nil then sum, cnt = 0, 0
        else
            sum, cnt = sum + x, cnt + 1
            if cnt > n then sum, cnt = sum - src[j - n], n end
            if cnt == n and j + lag <= #src then out[j + lag] = sum / n end
        end
    end
    return out
end

function M.true_range (H, L, C)
    local out = {}
    for i = 1, #H do
        if i == 1 then out[i] = H[i] - L[i]
        else out[i] = math.max (H[i] - L[i], math.abs (H[i] - C[i - 1]), math.abs (L[i] - C[i - 1])) end
    end
    return out
end

function M.atr (H, L, C, n) return M.rma (M.true_range (H, L, C), n) end

--- Wilder RSI; flat input (no gains and no losses) gives 50
function M.rsi (C, n)
    local up, dn = {}, {}
    for i = 2, #C do
        local d = C[i] - C[i - 1]
        up[i], dn[i] = math.max (d, 0), math.max (-d, 0)
    end
    local au, ad = smooth (up, n, 1 / n, 2), smooth (dn, n, 1 / n, 2)
    local out = {}
    for i = 1, #C do
        local u, w = au[i], ad[i]
        if u ~= nil and w ~= nil then
            if w == 0 then out[i] = (u == 0) and 50 or 100 else out[i] = 100 - 100 / (1 + u / w) end
        end
    end
    return out
end

--- Kaufman efficiency ratio: |C[i]-C[i-n]| / sum |C[j]-C[j-1]| (0 noise .. 1 straight)
function M.efficiency (C, n)
    local out, d, path = {}, {}, 0
    for i = 2, #C do
        d[i] = math.abs (C[i] - C[i - 1])
        path = path + d[i]
        if i - n >= 2 then path = path - d[i - n] end
        if i > n then out[i] = path > 1e-12 and math.abs (C[i] - C[i - n]) / path or 0 end
    end
    return out
end

--- MACD histogram (line - signal)
function M.macd_hist (C, fast, slow, sig)
    local f, s = M.ema (C, fast), M.ema (C, slow)
    local line = {}
    for i = 1, #C do if f[i] ~= nil and s[i] ~= nil then line[i] = f[i] - s[i] end end
    local sg = smooth (line, sig, 2 / (sig + 1), slow)
    local out = {}
    for i = 1, #C do if line[i] ~= nil and sg[i] ~= nil then out[i] = line[i] - sg[i] end end
    return out
end

--- confirmed swing pivots. sgn = 1 highs, -1 lows. Pivot at j needs
--- strictly beyond the p bars on the left and >= the p bars on the right,
--- all of which must exist (closed) -> confirmed p bars after it happened.
function M.pivots (X, p, sgn)
    local out = {}
    for j = p + 1, #X - p do
        local v, ok = sgn * X[j], true
        for k = j - p, j - 1 do if not (v > sgn * X[k]) then ok = false; break end end
        if ok then for k = j + 1, j + p do if not (v >= sgn * X[k]) then ok = false; break end end end
        if ok then out[#out + 1] = { i = j, price = X[j] } end
    end
    return out
end

--- full feature set for a validated, chronological window of closed M1 candles
function M.compute (m1, cfg)
    local ind = cfg.indicators
    local O, H, L, C, T = {}, {}, {}, {}, {}
    for i, b in ipairs (m1) do O[i], H[i], L[i], C[i], T[i] = b.o, b.h, b.l, b.c, b.t end
    local atr = M.atr (H, L, C, ind.atr_len)
    local f = {
        n = #m1, O = O, H = H, L = L, C = C, T = T,
        ema_f = M.ema (C, ind.ema_fast), ema_m = M.ema (C, ind.ema_mid), ema_s = M.ema (C, ind.ema_slow),
        atr = atr,
        atr_base = M.sma (atr, ind.atr_base_len, 1),     -- baseline excludes the candle itself
        rsi = M.rsi (C, ind.rsi_len),
        er = M.efficiency (C, ind.er_len),
        hist = M.macd_hist (C, ind.macd_fast, ind.macd_slow, ind.macd_signal),
    }
    local p = ind.pivot_len
    local ph, pl = M.pivots (H, p, 1), M.pivots (L, p, -1)
    local function last (list, k)
        local o = {}
        for i = math.max (1, #list - k + 1), #list do o[#o + 1] = list[i] end
        return o
    end
    f.swing_highs, f.swing_lows = last (ph, ind.max_levels), last (pl, ind.max_levels)
    return f
end

--- M5 context features (from closed M5 candles)
function M.compute_m5 (m5, cfg)
    local ind = cfg.indicators
    local H, L, C = {}, {}, {}
    for i, b in ipairs (m5) do H[i], L[i], C[i] = b.h, b.l, b.c end
    return { n = #m5, C = C, ema_f = M.ema (C, ind.m5_ema_fast), ema_s = M.ema (C, ind.m5_ema_slow),
             atr = M.atr (H, L, C, math.min (ind.atr_len, math.max (2, #m5 - 1))) }
end

return M
