# CHANGELOG

## 1.1.0 — V1 with two fixes (`qcs/v1/`)

* RSI score is no longer lower for RSI 74–78 (PUT: 22–26) than for RSI 51 (audit D1). Filters unchanged.
* Pivot S/R: strict left-side tie rule (no duplicate level from a flat top/bottom, D3) and tick-safe
  `make_series` memory instead of `value_when` (D4).
* Measured vs V1 (synthetic, 6 datasets): 295 of 319 signal bars identical, 17 higher score, 2 lower,
  3 new, 2 removed; duplicate levels on 0.10-quantized prices 13.5% → 1.5% of bars.
* Tests: `qcs/test/run_tests_v1.lua` (14 checks) run by `qcs/build.sh --test`.

## 3.0.0 — Precision Fast Entry (M1, 1-minute expiry)

Base: V1 (chosen by the user). V2 is archived unchanged in `qcs/archive/v2/`.

### Added
* Dual entry: **Momentum Entry** and **Pullback Entry** with separate rules (`docs/FAST_ENTRY_CONFIG.md`).
* Trend states (strong/weak up/down, sideways, transition), momentum states (acceleration, bullish/bearish, weakening, exhaustion).
* Market condition: trending, sideways, high vol, low vol, exhaustion, potential reversal.
* Signal states WAIT / CALL READY / PUT READY / CALL / PUT / EXPIRED / BLOCKED; NO CHASE kept as a separate live warning.
* Block reasons SIDEWAYS, LATE, SUPPORT, RESISTANCE, LOW CONFIDENCE, VOLATILITY, EXHAUSTION, REVERSAL, MOMENTUM, COOLDOWN.
* Score with spec weights (trend 25, momentum 20, price action 20, entry location 20, volatility 10, structure 5), raw vs final.
* Settings for every parameter, incl. entry-type switches.
* Sideways efficiency-ratio rule, sideways confirmation (2 bars), high-vol hysteresis (stay while ATR > 1.5x baseline), low-vol state.
* Test suite for all spec areas (56 checks), pullback-continuation dataset, evaluation by setup, market and session, missed-opportunity rate.
* Docs: `FAST_ENTRY_AUDIT.md`, `FAST_ENTRY_CONFIG.md`, `FAST_ENTRY_TEST_REPORT.md`.

### Changed (vs V1)
* Defaults per spec: cooldown 2 (was 3), late body 2.0 ATR (was 1.8).
* Candle measurements use ATR before the confirmation candle; pivots tick-safe with strict ties (V1 defects D2–D4).
* Pullback entries measure lateness from EMA9 (the EMA price pulled back to); Momentum entries keep the EMA21 rule.
* Main chart labels: setup type (MOMENTUM/PULLBACK) instead of pattern names; READY markers; X:LATE/X:SR/X:SIDE/X:VOL kept.

### Not done
* No real-data backtest (no data available). Not yet run on the IQ Option engine.

## 2.0.0 — Adaptive Precision Engine

Behaviour changes are intentional and listed here; nothing changed silently.

### Added
* Market regime engine: TRENDING, RANGING, HIGH_VOL, LOW_VOL, TRANSITIONAL with enter/stay
  threshold bands and 3-bar confirmation (HIGH_VOL enters immediately).
* ADX/DI (official library formula) and Kaufman efficiency ratio.
* Adaptive, bounded per-regime profile: minimum score, room, late limits, RSI limits, momentum
  acceleration, minimum price-action quality, cooldown.
* Five-stage validator with new reason codes `REVERSAL`, `WEAK-MOM`, `WHIPSAW`, `EXHAUST`,
  `TRANSITION`, `LOW-VOL`, `RANGING` (replaces `SIDEWAYS`), `WARMUP`.
* Major pivots (strength 15) and round-number levels as S/R obstacles.
* Two-candle REJECT trigger (requires follow-through).
* Main chart: regime-change flags, major S/R lines, grouped cancel markers (`X:REGIME`, `X:MOM`).
* Panel: regime strip, adaptive "Required Score" line, Regime and ADX legend values.
* Tests: 14 scenario areas, independent re-check of every signal, tick and prefix repaint tests,
  Main/Panel equality, warm-up and degenerate data (`qcs/test/run_tests.lua`, `datasets.lua`).
* Offline V1 vs V2 evaluation harness with payout-aware expectancy, splits and walk-forward
  (`qcs/eval/`), frozen V1 baseline.
* `qcs/build.sh --test`.
* Docs: audit, architecture, engine spec, test report, performance report, this changelog.

### Changed
* Score 2.0: components R/T/M/P/E/V plus penalties; monotonic RSI; removed duplicated EMA/MACD items.
* All candle measurements normalised by ATR before the confirmation candle (`ATR2`).
* Pivot storage moved from `value_when` to tick-safe `make_series`; strict left-side tie rule.
* Engulfing, pin bar, breakout and false-breakout rules gained quality clauses (see spec section 5).
* Sideways/abnormal flags replaced by the regime engine.
* Instrument names: "XAUUSD Smart Entry V2" / "XAUUSD Smart Entry V2 Panel".
* Signals are far fewer: about 4 per 1000 bars vs 18 in V1 on the synthetic mixed set.

### Fixed (audit references)
* D1 non-monotonic RSI score. D2 ATR including the candle under test. D3 duplicate pivot levels on
  equal highs/lows. D4 dependence on undocumented `value_when` re-evaluation. D5 dead LOW-SCORE marker.
  D6 hard-coded thresholds in tests.

### Not done / limitations
* No real historical data: performance validation incomplete (see `PERFORMANCE_REPORT.md`).
* Not yet run on the real IQ Option runtime.

## 1.0.0
* Initial CALL/PUT/WAIT system (commit `5bba856`).
