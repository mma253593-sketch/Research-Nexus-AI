# CHANGELOG

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
