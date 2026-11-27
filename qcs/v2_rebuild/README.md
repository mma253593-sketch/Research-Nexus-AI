# XAUUSD Smart Entry V2.0 — Adaptive Precision Engine

Signal-generation engine for **XAUUSD, M1 entries with M5 context, 1-minute expiry**.
Output per closed M1 candle: **CALL / PUT / WAIT** plus a full diagnostics record.
**It never places trades.** It makes no profitability claim and has no target win rate.

> Status: implemented and tested offline. **Not yet verified on real market data and
> not yet run on the live IQ Option / Quadcode Script runtime** (see *Limitations*).

This directory is isolated: it does not modify `qcs/v1` (V1.2), `qcs/src` and
`qcs/scripts` (V3), `qcs/archive/v2` (archived V2) or `qcs/build.sh`.

## Status

| Item | State |
|---|---|
| 10 modules + config + QCS adapter | Implemented |
| Isolated build (`scripts/build.sh`) | Implemented, passes |
| Automated tests (83 cases, 9 files) | Executed, **83 passed / 0 failed** (Lua 5.3.6) |
| Paste-ready QCS scripts ≤ 25,000 characters | Enforced by the build and a test (chart 24,738 / panel 24,120) |
| Temporal integrity (no look-ahead / no repaint / no hidden state) | Tested, passed |
| QCS bundle reproduces the pure engine in the offline QCS mock | Tested, passed |
| Backtest / evaluation framework, V1.2 comparison | Implemented, tested on synthetic data only |
| Performance on real XAUUSD data | **Not tested: no verified data was available** |
| Live QCS runtime (IQ Option) | **Not tested** |

## Quick start

```bash
sudo apt-get install lua5.3                     # Lua 5.3 interpreter + luac5.3
qcs/v2_rebuild/scripts/build.sh --test          # syntax, bundle (<= 25,000 chars), 83 tests, protected-path check
lua5.3 qcs/v2_rebuild/eval/backtest.lua --csv xauusd_m1.csv --payout 0.82 --out report.md
```

Library use (pure Lua 5.3, from the repository root):

```lua
package.path = "qcs/v2_rebuild/src/?.lua;qcs/v2_rebuild/config/?.lua;" .. package.path
local engine = require ("main")
local cfg = assert (engine.config ({ scoring = { min_margin = 15 } }))   -- validated, or nil + errors
local res = engine.evaluate ({ now = 1735704000, m1 = candles }, cfg)  -- pure, deterministic
print (res.decision, res.score, res.setup, table.concat (res.reasons, ","))
local run = engine.new_runner (cfg)          -- same + cooldown (state: last signal time only)
```

## Runtime model (verified against this repository)

* The production runtime is **Quadcode Script (Lua 5.3 based)**. The only QCS calls the V2.0
  bundle uses are the ones already used by the existing QCS scripts and modelled by
  `qcs/test/mock_qcs.lua`: `instrument`, `input`, `input_group`, `get_value`, `make_series`/`:set`,
  `open/high/low/close[i]`, `plot`, `plot_shape`, `hline`, `rgba`, `shape_*`.
* The repository has **no verified timestamp series and no verified multi-timeframe call** in QCS.
  The engine therefore takes plain candle arrays. Its M5 context is either supplied by the
  caller or **aggregated from clock-aligned M1 buckets**, using only complete buckets.
* The engine core uses only `math`, `string`, `table`, `ipairs`, `pairs`, `type`, `tostring`,
  `next` (Lua 5.3). The existing QCS scripts use only `math`, `ipairs` and `pairs`. The other
  base functions are standard Lua 5.3 but have **not been confirmed on the live QCS runtime**.

## Architecture

```
input {now, m1[], m5[]?}
  │
  ├─ 1 data_validation ── invalid / insufficient / stale ──────────────▶ WAIT (DATA_INVALID, …)
  │        closed contiguous M1 window, closed M5 (provided or aggregated)
  ├─ indicators (computed ONCE per evaluation, shared by all modules)
  ├─ 2 regime_detection   TRENDING / RANGING / HIGH_VOL / LOW_VOL / UNSTABLE (+ confirmation)
  ├─ 3 trend_context      M5 bias, M1 direction/strength/consistency, structure, reversal
  ├─ 4 momentum_analysis  MACD-hist/ATR (direction, strength, accel) + RSI (exhaustion, divergence)
  ├─ 5 price_action       engulf, rejection, breakout, failed break, strong close, levels, room
  ├─ 7 volatility_filter  abnormal range, expansion, low information, noise ──────▶ WAIT
  ├─ 8 adaptive_profile   regime → TRENDING / RANGING profile, else DEFENSIVE ────▶ WAIT
  ├─ 6 entry_timing       per allowed setup: present? late? room? timing quality
  ├─ 9 signal_engine      score + gates per side/setup → CALL / PUT / WAIT
  └─ 10 diagnostics       structured record, deterministic JSON
```

| File | Interface |
|---|---|
| `src/main.lua` | `config(overrides) → cfg, errs`; `evaluate(input, cfg) → result`; `new_runner(cfg):step(input)` |
| `src/config.lua` + `config/default_config.lua` | schema (type, bounds, integer), unknown-key and cross-field checks; `load`, `validate`, `defaults` |
| `src/data_validation.lua` | `prepare(input, cfg) → {ok, errors, warnings, m1, m5, m5_source, stats}`; `check_candle`; `aggregate_m5` |
| `src/indicators.lua` | causal array indicators: `ema, rma, sma, atr, rsi, efficiency, macd_hist, pivots`; `compute(m1)`, `compute_m5(m5)` |
| `src/regime_detection.lua` | `raw_at(f, i, cfg)`, `detect(f, cfg) → {regime, raw, sub, direction, metrics}` |
| `src/trend_context.lua` | `analyze(f, f5, cfg)`, `m5_bias(f5, cfg)`, `structure(f)` |
| `src/momentum_analysis.lua` | `analyze(f, cfg) → {dir, strength, accel, rsi, side[±1]}` |
| `src/price_action.lua` | `analyze(f, cfg) → {side[±1] = {patterns, best, room_atr, support, …}}`, `POINTS` |
| `src/entry_timing.lua` | `analyze_side(f, s, pa, profile, cfg) → {[setup] = {present, late, ext, room, quality}}` |
| `src/volatility_filter.lua` | `evaluate(f, cfg) → {ok, reasons, metrics, spread = "NOT_AVAILABLE"}` |
| `src/adaptive_profile.lua` | `select(regime, cfg) → {name, tradable, setups, min_score, min_room_atr, max_ext_atr}` |
| `src/signal_engine.lua` | `score_setup`, `evaluate_side`, `decide(ctx) → {decision, reasons, side, selected}` |
| `src/diagnostics.lua` | `build(parts)`, `to_json(v)` (sorted keys), `summary(rec)` |
| `src/qcs/adapter.lua`, `view_main.lua`, `view_panel.lua` | QCS glue (bundle only) |

PUT logic mirrors CALL logic: prices are mapped x → −x (high ↔ low), RSI → 100 − RSI and
MACD → −MACD. One rule set covers both sides, and a test checks that mirrored prices give
mirrored decisions with equal scores.

### Data contract

`candle = { t = open time (unix s, multiple of 60), o, h, l, c, closed = optional boolean }`.
A candle counts as complete when `closed == true`, or when `closed` is nil and `t + 60 <= now`.
The following produce **errors** and therefore WAIT:

* invalid OHLC or non-finite values
* misaligned timestamps
* out-of-order candles
* conflicting duplicates
* future candles
* a `closed` flag set before the candle's close time
* an incomplete candle followed by a complete one
* more missing candles than `max_missing_ratio` allows
* fewer than `min_m1_bars` contiguous candles
* stale data
* M5 that is missing, stale, misaligned, too short, or inconsistent with M1

The validator never sorts or interpolates candles. The only repairs it makes are dropping the
forming candle and dropping identical duplicates, and both are reported as warnings. A gap of
more than `max_gap_candles` missing candles resets the history (weekends, daily breaks).

### Decision rules

* **Regime** (stateless hysteresis): the raw regime of the last `confirm_bars` candles must agree,
  except HIGH_VOL, which applies immediately. A disagreement gives UNSTABLE/TRANSITION.
* **Profiles**: TRENDING allows pullback continuation, trend continuation and breakout
  confirmation (min score 65). RANGING allows range rejection and breakout confirmation (min
  score 70). HIGH_VOL, LOW_VOL and UNSTABLE map to DEFENSIVE, which always WAITs. Profile
  minimums can never be set below `global_min_score`. Nothing adapts to recent wins or losses.
* **Late entry**: extension is measured from each setup's own reference:
  * pullback: EMA9, the mean the price pulled back to (see `qcs/docs/FAST_ENTRY_AUDIT.md` §2)
  * trend continuation: EMA21
  * breakout: the broken level
  * range rejection: position within the range

  A setup is also late after a large 3-candle move or an oversized trigger candle.
* **Score** (0–100): context 25, momentum 20, price action 20, timing 20, M5 10, regime 5, minus
  penalties (opposite M5, divergence, deceleration, adverse wick). **It is not a probability**:
  it has not been calibrated, and the backtest prints a calibration table for this purpose.
* **Gates**: setup not present, exhaustion, structure break, late entry, no room, strongly
  opposite M5, momentum conflict, low score.
* **Decision**: a signal needs exactly one side with a passing setup that beats the other side's
  best present setup by `min_margin` (15). If both sides pass, the result is
  WAIT `CONFLICT_BOTH_SIDES`; if the margin is too small, WAIT `INSUFFICIENT_MARGIN`. The runner
  then applies `cooldown_bars` (2).

Every WAIT carries reason codes, for example `NO_QUALIFIED_SETUP` followed by
`CALL:PULLBACK_CONTINUATION:LATE_ENTRY_EXTENDED_FROM_EMA9`.

## QCS installation (paste-ready scripts in `dist/`)

| File | Use | Size |
|---|---|---|
| `dist/XAUUSD_Smart_Entry_V2_0.lua` | chart overlay: CALL/PUT arrows on the entry candle + setup marker (PB pullback, TR trend, BO breakout, RG range) | 24,738 characters |
| `dist/XAUUSD_Smart_Entry_V2_0_Panel.lua` | separate pane: CALL/PUT score, regime code, decision | 24,120 characters |
| `dist/readable/XAUUSD_Smart_Entry_V2_0_Readable.lua` | the same program with comments and original names — **for reading only, too long to paste** | ~68,000 characters |

1. Open XAUUSD on M1 → Indicators → Scripts → Add manually → paste → Save → Add to chart.
2. Wait for at least 200 closed candles. Enter at the **open** of an arrow candle, expiry 1 minute.

**Size limit (25,000 characters).** `scripts/build.lua` produces the paste-ready scripts in
four behaviour-preserving steps:
1. **Bundle** the QCS variant of the sources. Regions marked `@qcs-strip` hold offline-only code:
   the full config schema, the JSON and diagnostics detail, the sequential runner and the
   provided-M5 path. They are removed, and lines marked `--@qcs:` are enabled instead.
2. **Minify**: remove comments and redundant whitespace.
3. **Shrink**: rename identifiers and internal ALL-CAPS codes consistently. Lua and QCS API
   names, chart labels and the output globals are never renamed.
4. **Join** the engine lines. The QCS adapter and views keep one statement per line.

The build fails if a paste-ready script exceeds 25,000 characters. `test/test_qcs_bundle.lua`
checks that:
* the scripts are up to date with `src/`, byte for byte;
* the chart script reproduces the pure engine bar by bar in the offline QCS mock;
* the readable bundle and the shrunk script give identical outputs;
* the lean QCS config check agrees with the full validator for every value the QCS inputs allow;
* the scripts stay under the size limit.

**Timestamps in QCS.** No QCS timestamp series has been verified, so the default input
`Timestamps = 1` uses the bar index. Diagnostics then report `TIME_SOURCE = INDEX_PROXY`, and
in this mode M5 context comes from 5-bar groups that are not clock-aligned, and missing candles
cannot be detected. `Timestamps = 2` reads a `time` series only if the runtime defines one,
and otherwise reports `INDEX_PROXY_FALLBACK`.

## Backtesting

```bash
lua5.3 qcs/v2_rebuild/eval/backtest.lua --csv FILE [--payout P] [--tie loss|push] \
       [--tz-offset-min M] [--out report.md] [--signals signals.jsonl] [--no-v1]
```

* **CSV**: a header naming time (or date + time) and open/high/low/close. Unix seconds/ms and
  `YYYY-MM-DD HH:MM[:SS]` formats are accepted, plus MT4-style `YYYY.MM.DD`. The report records
  the file's byte count, FNV-1a checksum and row/parse counts as provenance. Non-chronological
  files are refused rather than sorted.
* **Timing**: the engine is evaluated at the open of candle T and sees only candles that closed
  before it. Entry is `open[T]`, expiry is `close[T]`.
* **Payout**: no payout is assumed. Without `--payout`, only gross directional accuracy is
  reported, with a 95% Wilson interval.
* **Splits**: development 0–60 %, validation 60–80 %, out-of-sample test 80–100 %, in time
  order. No parameter is fitted on any split.
* **Breakdowns**: by side, regime, setup, UTC session, score bucket (calibration) and sample
  size.
* **V1.2 comparison**: the **unmodified** `qcs/v1/scripts/XAUUSD_Smart_Entry_V1_2_Main.lua` is
  run through the offline QCS mock on the same candles with the same expiry rule.
* `eval/results/SYNTHETIC_framework_check.md` is a **synthetic** framework run. It is not a
  market result.

## Limitations

1. **No verified real XAUUSD data** could be obtained here: every market-data host tried was
   blocked by the environment's network policy. Real-market accuracy, expectancy and signal
   frequency are therefore **unknown**. All defaults are conventional or chosen for structural
   stability, and none were fitted to win rate.
2. On synthetic fixtures the engine signals about 10 times per 1,000 M1 candles. Real-data
   frequency is unknown.
3. The engine has not been run on the live QCS runtime. The open question is the base-library
   functions beyond `math`/`ipairs`/`pairs`.
4. In QCS's default index-timestamp mode, M5 context is approximate and missing candles cannot
   be detected.
5. Candle-level expiry model: real fills happen seconds after the open, at the broker's price.
   Spread and execution data are not available and are reported as `NOT_AVAILABLE`.
6. The engine cannot see news. A backtest does not guarantee future results. Binary and digital
   options carry a high risk of losing the whole stake.

## Directory

```
config/default_config.lua   all parameters (validated)
src/                        engine modules (+ src/qcs/ adapter and views)
scripts/build.sh            isolated build + tests + protected-path check
scripts/build.lua           bundler / minifier / shrinker → dist/ (fails above 25,000 characters)
test/                       run_all.lua, 9 test files, fixtures.lua (synthetic), golden.lua
eval/                       backtest.lua, metrics.lua, csv.lua, results/
dist/                       generated paste-ready QCS scripts; dist/readable/ for review (do not edit)
```
