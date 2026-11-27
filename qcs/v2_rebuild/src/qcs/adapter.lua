-- =====================================================================
--  QCS ADAPTER — runs the pure V2.0 engine inside Quadcode Script.
--  Uses only QCS calls already used by the existing QCS scripts and the
--  offline mock (qcs/test/mock_qcs.lua): input, input_group, get_value,
--  make_series / :set, open/high/low/close[i].
--
--  * Every bar, the closed-candle window is rebuilt from [1]..[W]
--    ([0] = the forming candle is NEVER read for the decision), so the
--    decision is a pure function of closed candles: no repaint on ticks.
--  * Timestamps: QCS exposes no timestamp series that has been verified
--    in this repository. Default mode 1 uses the bar index (t = index*60)
--    and reports TIME_SOURCE = "INDEX_PROXY": in that mode M5 buckets
--    are 5-bar groups (not clock aligned) and missing candles cannot be
--    detected. Mode 2 reads a `time` series ONLY if the runtime defines
--    one; otherwise it falls back to INDEX_PROXY and says so.
--  * Cooldown is kept in a make_series written from its own [1] value
--    (the tick-safe pattern of the V3 core).
--  Signal generation only — nothing here can place a trade.
-- =====================================================================
input_group {
    "XAUUSD Smart Entry V2.0",
    v2_window   = input (240, "Closed M1 candles analysed", input.integer, 200, 600),
    v2_cooldown = input (2,   "Cooldown (bars)", input.integer, 0, 20),
    v2_time     = input (1,   "Timestamps: 1 bar index, 2 time series", input.integer, 1, 2)
}

local engine = require ("main")

local function num (s, d)
    local v = get_value (s)
    if v == nil or v ~= v then return d end
    return v
end

v2_bar = make_series ()
v2_bar:set (num (v2_bar[1], 0) + 1)
v2_age = make_series ()

local N = num (v2_bar, 1)
local use_time = v2_time == 2 and type (time) == "table"
TIME_SOURCE = use_time and "TIME_SERIES" or ((v2_time == 2) and "INDEX_PROXY_FALLBACK" or "INDEX_PROXY")
local function stamp (i)
    if use_time then
        local v = (i == 0) and num (time) or num (time[i])
        if v == nil then return nil end
        if v > 1e12 then v = v / 1000 end
        return math.floor (v)
    end
    return (N - i) * 60
end

local cfg = engine.config ({ data = { m1_window = v2_window }, runner = { cooldown_bars = v2_cooldown } })
local m1 = {}
if cfg then
    for i = cfg.data.m1_window, 1, -1 do
        local o, h, l, c, t = num (open[i]), num (high[i]), num (low[i]), num (close[i]), stamp (i)
        if o and h and l and c and t then m1[#m1 + 1] = { t = t, o = o, h = h, l = l, c = c, closed = true } end
    end
end
V2 = engine.evaluate ({ now = stamp (0), m1 = m1, time_source = TIME_SOURCE }, cfg)

-- outputs read by the views
SIG_DIR, SIG_SCORE, SIG_SETUP = 0, 0, ""
CALL_SCORE, PUT_SCORE = V2.call_score, V2.put_score
WAIT_REASON = V2.reasons[1] or ""
local REG = { TRENDING = 1, RANGING = 2, HIGH_VOL = 3, LOW_VOL = 4, UNSTABLE = 5 }
REGIME_CODE = V2.diagnostics.regime and REG[V2.diagnostics.regime.confirmed] or 0
DATA_OK = V2.diagnostics.data.valid

local prev_age = num (v2_age[1], 999)
local dir = (V2.decision == "CALL") and 1 or ((V2.decision == "PUT") and -1 or 0)
if dir ~= 0 and prev_age < v2_cooldown then
    dir, WAIT_REASON = 0, "COOLDOWN"
end
if dir ~= 0 then SIG_DIR, SIG_SCORE, SIG_SETUP = dir, V2.score, V2.setup or "" end
v2_age:set (SIG_DIR ~= 0 and 0 or prev_age + 1)
