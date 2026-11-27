-- =====================================================================
--  MODULE 7 — volatility_filter
--
--  evaluate(f, cfg) -> { ok, reasons = {codes}, metrics, spread }
--  Hard rejections (any -> WAIT), all measured on closed candles:
--    ABNORMAL_RANGE    range[n] > abnormal_range_atr * ATR[n-1]
--    VOL_EXPANSION     ATR[n] / ATR[n-k] > expansion_ratio (k = expansion_lookback)
--    LOW_INFORMATION   ATR[n] < min_atr_price (USD), or more than
--                      max_flat_candles of the last flat_lookback candles
--                      have range < flat_range_atr * ATR (frozen/thin feed)
--    NOISE             ER[n] < noise_er and the mean wick share of the
--                      last 10 candles > noise_wick_share
--  Spread / execution data is NOT available from candles; `spread` is
--  reported as "NOT_AVAILABLE" rather than estimated.
-- =====================================================================
local M = {}

function M.evaluate (f, cfg)
    local v, n = cfg.volatility, f.n
    local atr, atr_prev, atr_k = f.atr[n], f.atr[n - 1], f.atr[n - v.expansion_lookback]
    local out = { ok = true, reasons = {}, metrics = {}, spread = "NOT_AVAILABLE" }
    local function reject (code) out.ok = false; out.reasons[#out.reasons + 1] = code end
    if atr == nil or atr_prev == nil or atr_k == nil or atr_prev <= 0 or atr_k <= 0 then
        reject ("VOLATILITY_UNMEASURABLE"); return out
    end
    local range = f.H[n] - f.L[n]
    out.metrics.range_atr = range / atr_prev
    out.metrics.expansion = atr / atr_k
    if range > v.abnormal_range_atr * atr_prev then reject ("ABNORMAL_RANGE") end
    if atr / atr_k > v.expansion_ratio then reject ("VOL_EXPANSION") end
    local flat = 0
    for i = n - v.flat_lookback + 1, n do
        if f.H[i] - f.L[i] < v.flat_range_atr * atr then flat = flat + 1 end
    end
    out.metrics.flat = flat
    if atr < v.min_atr_price or flat > v.max_flat_candles then reject ("LOW_INFORMATION") end
    local wick = 0
    for i = n - 9, n do
        local r = f.H[i] - f.L[i]
        wick = wick + (r > 0 and (r - math.abs (f.C[i] - f.O[i])) / r or 1)
    end
    wick = wick / 10
    out.metrics.wick_share = wick
    local er = f.er[n] or 0
    if er < v.noise_er and wick > v.noise_wick_share then reject ("NOISE") end
    return out
end

return M
