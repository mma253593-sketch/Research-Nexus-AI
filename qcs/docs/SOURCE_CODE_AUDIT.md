# SOURCE CODE AUDIT — XAUUSD Smart Entry V1.0

Audit target: commit `5bba856` (branch `claude/xauusd-entry-signal-system-1t396i`).
Audit performed **before** any V2 modification. Line numbers refer to V1 `qcs/src/core.lua`
unless another file is named.

## 0. Files inspected

| File | Lines | Status |
|---|---|---|
| `qcs/src/core.lua` | 400 | shared engine |
| `qcs/src/view_main.lua` | 119 | overlay view |
| `qcs/src/view_panel.lua` | 87 | panel view |
| `qcs/scripts/XAUUSD_Smart_Entry_Main.lua` | 521 | generated: `instrument` line + generated-note + `core.lua` + `view_main.lua` |
| `qcs/scripts/XAUUSD_Smart_Entry_Panel.lua` | 489 | generated: `instrument` line + generated-note + `core.lua` + `view_panel.lua` |
| `qcs/test/mock_qcs.lua` | 229 | offline QCS mock runtime |
| `qcs/test/run_tests.lua` | 107 | test runner |
| `qcs/build.sh` | 29 | build + `luac5.3 -p` |
| `qcs/README.md` | 182 | Thai user guide |

All required files exist. Both generated scripts were confirmed byte-identical to
`header + core.lua + view` (diff check), so there was no hand-edited drift.

## 1. Existing architecture

```
build.sh ── instrument{} header ─┬─ core.lua ─ view_main.lua  ─▶ scripts/..._Main.lua  (overlay)
                                 └─ core.lua ─ view_panel.lua ─▶ scripts/..._Panel.lua (separate pane)
```

* **Inputs** (L16–59): EMA, RSI/MACD, BB/ATR, S/R, signal filters.
* **Base series** (L63–93): EMA 9/21/50, RSI, MACD, BB, ATR = `rma(tr)`, ATR baseline `sma(atr,100)`,
  CLV, pivot windows, range high/low. All called unconditionally (correct for call-site state).
* **Pivots** (L114–125): confirmed with `pivot_len` right-side bars, stored with `value_when`.
* **Snapshot** (L134–149): every decision input is read from closed bars `[1]`, `[2]`, `[4]`.
* **Side-neutral evaluation** (L175–332): PUT is evaluated by mirroring prices and RSI, so CALL/PUT
  rules are symmetric. One function computes a 6-part score and a first-failure hard-filter reason.
* **Decision** (L335–390): regime flags (`squeeze`, `sideways`, `abnormal`), cooldown, final
  direction, cancel reason, live `NO_CHASE`.
* **State**: `bar_count`, `sig_age`, `wait_code` are `make_series` updated from their own `[1]`.
* **Views** read plain globals (`SIG_DIR`, `SIG_SCORE`, ...). Main = ~40 `plot`/`plot_shape` calls;
  Panel = `rect` score column, raw score lines, status/trend legend plots, reason markers.

## 2. Identified defects (each with supporting code)

| ID | Severity | Location | Defect | Evidence |
|---|---|---|---|---|
| D1 | Medium | L245–247 | **RSI score is non-monotonic.** RSI 50–74 scores 10–15, but 74 < RSI ≤ 78 (still allowed by the `OVEREXT` filter at L320) falls through to the third branch and scores 0 or 4. | 9 of 216 V1 signals had directional RSI > 74 (measurement script, synthetic data). |
| D2 | Medium | L142, L214, L311, L227 | **ATR normalisation includes the candle under test.** `ATR1 = atr_val[1]` contains the true range of candle `[1]`, so a huge confirmation candle raises its own "late" threshold (`body1 > late_body_atr * atr`) and shrinks its own room. | `atr = ATR1` (L214) used in L311 and L227; spike test correctly uses `ATR2` (L343), so the code is internally inconsistent. |
| D3 | Medium | L119–120 | **Pivot ties.** `>=` / `<=` accept equal highs/lows, so on a flat double top two consecutive bars are both confirmed and `res_lvl2` (L123) becomes a duplicate of `res_lvl`, losing the real second level. XAUUSD quotes are 0.01-quantised, so equal highs are common. | Not observed on float synthetic data; a structural risk with real quotes. |
| D4 | Medium | L122–125 | **`value_when` re-evaluation risk.** The live bar is recalculated on each tick in QCS. Whether `value_when` is idempotent when the same bar is evaluated repeatedly is **not documented**. If it appended on each tick, `res_lvl2` would be overwritten by a duplicate. | Docs page `value_when` gives no re-evaluation guarantee; the V1 mock makes it idempotent by construction (`mock_qcs.lua` value_when), so the tests cannot detect this. |
| D5 | Low | `view_panel.lua` (LOW-SCORE marker) + L374 | **Dead display path.** A cancel reason is reported only when `x.score >= min_score` (L374), so `LOW-SCORE` can never reach `WAIT_REASON`; the panel marker for it never fires. | L374 condition vs. panel `plot_shape(... "LOW-SCORE" ...)`. |
| D6 | Low | `run_tests.lua` L81, L84 | Tests hard-code the 70 threshold and the 3-bar cooldown instead of reading the script inputs. | Literal `70` and `3`. |

## 3. Weaknesses in signal filtering

| ID | Location | Weakness |
|---|---|---|
| W1 | L234–253 | **Double counting.** Trend (25) counts EMA stack, close>EMA21, EMA50 slope and EMA9–EMA50 spread, which are strongly correlated. MACD (15) adds `macd_line > 0` (EMA12−EMA26 > 0), which is nearly the same information as EMA9 > EMA50. RSI > 50 and MACD hist > 0 are both momentum of the same close series. |
| W2 | L306 + L316–330 | **Score saturation.** Mandatory filters already guarantee most points (stack 12 + slope 5 + MACD hist 6 + PA 8 + room 4 + volatility 5 = 40 minimum), so passing signals cluster high: 63% scored ≥ 85 and 19 of 216 scored exactly 100 (measurement). The score has little discriminating power between signals. |
| W3 | L339–343 | **No regime hysteresis.** `sideways` is recomputed from scratch on every bar. Measured: `sideways` true on 21.3% of bars but flipped 706 times in 11,640 bars (≈ 61 flips / 1000 bars), i.e. it flickers. |
| W4 | L318 | **Weak momentum passes.** Only `RSI > 50` and `hist > 0` are mandatory; a shrinking histogram (fading momentum) is only a 5-point score item (L252). |
| W5 | — | **No exhaustion / whipsaw / reversal detection.** No check for repeated EMA9/EMA21 crosses, consecutive large same-direction candles, or a structure break against the trend. |
| W6 | L259–263 | **Engulfing quality.** Only body comparison; no check of the engulfed candle size, of location (at support/EMA), or of the engulfing candle closing near its extreme. |
| W7 | L264–268 | **False-breakout trigger** accepts any one-candle sweep of the last pivot with a 40% wick; no minimum sweep depth, no check that the level was meaningful. |
| W8 | L225–228 | **Room** uses only the last two pivots and the 50-bar range extreme; a level that is not one of those is invisible. If price is above all of them `room = 99` (full points). |
| W9 | L54 | **Static thresholds.** The same min-score, late-distance, room and RSI limits apply in strong trends, choppy markets and high volatility. |
| W10 | L356–365 | Cooldown blocks both directions for `cooldown_bars`; acceptable, but a fixed length ignores the regime. |

## 4. Potential repainting issues

| Item | Assessment |
|---|---|
| Signal inputs | All read from `[1]` or older (L134–149). **No repaint path found** in signal generation. |
| Pivots | Confirmed with `pivot_len` closed right-side bars (L114–117). No look-ahead. |
| `NO_CHASE` | Reads `open`/`close` of the live bar (L385). Intentional live warning; does **not** feed `SIG_DIR`. Verified: L384–389 run after `SIG_DIR` is final. |
| `value_when` | See D4: depends on undocumented re-evaluation semantics. **Residual risk.** |
| State series | `bar_count`, `sig_age`, `wait_code` are written as functions of their own `[1]` value, so re-running the live bar overwrites, not accumulates. Safe. |
| Test strength | The tick test (`run_tests.lua` L40–54) perturbs bar `[0]` only; because the engine never reads `[0]` for decisions, the test confirms the design but cannot catch engine-level issues (D4). |

## 5. Performance bottlenecks

* Main view issues ~40 `plot`/`plot_shape` calls per bar (`view_main.lua`). QCS limits on plot count are
  **undocumented**; this is a compatibility risk rather than a measured bottleneck.
* Per bar the core builds two small tables and several closures (`make_view`, `evaluate`); negligible.
* Mock runtime: 3 datasets × 4000 bars × (1 + 6 tick re-runs) = 31 s total (measured earlier), i.e. the
  engine itself is light.

## 6. Risks introduced by the proposed V2 changes

| Risk | Mitigation |
|---|---|
| More logic → more QCS API surface | Use only functions already used by official library scripts (`change`, `iff`, `nz`, `sum`, `rma`, `abs`, `highest`, `lowest`, `make_series`, `get_value`). |
| ADX is **not** a documented built-in | Re-implement exactly as the official `trend/adx_dms.lua` does. |
| Regime state machines (hysteresis) add state | Store state only in `make_series` written from its own `[1]` (idempotent on tick re-evaluation). |
| Replacing `value_when` changes S/R behaviour | Document it; keep pivot definition, add strict tie rule. |
| More plots may hit undocumented limits | Keep Main plot count ≤ V1; move detail to Panel. |
| Adaptive thresholds may overfit | Few regime profiles, hard bounds, documented rationale, no optimisation on test data. |
| The mock is not the real engine | Keep stating that QCS runtime compatibility is unverified until run on IQ Option. |

## 7. Recommended modifications

1. Replace `value_when` with idempotent `make_series` pivot state; strict tie-break (D3, D4).
2. Normalise all candle measurements by `ATR2` (ATR before the confirmation candle) (D2).
3. Monotonic, bounded scoring with orthogonal components and explicit conflict penalties (D1, W1, W2).
4. Regime engine with ADX (library formula), ATR ratio, BB-width ratio, efficiency ratio and EMA
   structure, with N-bar confirmation hysteresis (W3).
5. Regime-dependent, bounded thresholds; WAIT in unsuitable regimes (W9, W10).
6. Five-stage validator with explicit false-signal detectors: weak momentum, exhaustion, whipsaw,
   reversal, low-quality engulfing, rejection without follow-through, false breakout (W4–W7).
7. Remove the dead LOW-SCORE marker (D5); derive test thresholds from inputs (D6).
8. Scenario-based deterministic tests, warm-up/missing-data tests, and a V1-vs-V2 evaluation harness.

## 8. Measurement method (reproducible)

V1 internals were exposed by appending `DBG_SIDE = sideways; DBG_ABN = abnormal` to a copy of
`core.lua` (no change to the repository file) and running it on the three `run_tests.lua` synthetic
datasets (seeds 7, 42, 2026; bars 121–4000 of each). Synthetic data only; these figures describe code
behaviour, not market performance.
