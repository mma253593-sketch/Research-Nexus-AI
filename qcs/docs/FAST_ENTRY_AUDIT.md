# AUDIT + PLAN — Precision Fast Entry M1 (V3)

Base chosen by the user: **V1** (commit `5bba856`, frozen copy `qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua`).
V2 work is kept in `qcs/archive/v2/`. Audit written before any V3 code change.
Line numbers = V1 `qcs/src/core.lua` (see also `SOURCE_CODE_AUDIT.md`, which audited the same file).

## 1. Checkpoints (spec §2)

| # | Area | V1 implementation | Finding |
|---|---|---|---|
| 1 | CALL/PUT conditions | One evaluator, PUT = mirrored prices (L175–332) | Symmetric, good. Only **one entry type**; no pullback logic. |
| 2 | Confidence score | 6 parts: trend 25, RSI 15, MACD 15, PA 20, room 15, vol 10 (L234–306) | Double counting (EMA items, MACD line≈EMA trend); RSI 74–78 scores less than 51 (D1); 63% of signals ≥ 85. No raw/final split, no reasons. |
| 3 | Price action | Engulf, false-break, pin, reject, breakout, momentum (L259–288) | No minimum size for engulfed candle; pin not tied to a level; reject has no follow-through; ATR includes the candle (D2). |
| 4 | EMA trend | `em>es, c>es, es>es4` + `ef>em` (L235, L316) | No strong/weak distinction; slope only sign over 3 bars. |
| 5 | RSI/MACD | RSI>50 and hist>0 mandatory (L318) | No acceleration/weakening/exhaustion states. |
| 6 | ATR / volatility | spike `range>2.8·ATR2`, hot `ATR>1.9·base` (L343) | OK; but candle-size rules use ATR1 (includes the candle). No low-volatility state. |
| 7 | Sideways | `flat and (squeeze or tangled)` recomputed each bar (L339–342) | Flickers: 61 flips / 1000 bars (measured in `SOURCE_CODE_AUDIT.md`). |
| 8 | S/R | Two latest pivots + 50-bar extreme (L192–206) via `value_when` | Duplicate levels on equal highs (D3); `value_when` tick re-evaluation undocumented (D4). |
| 9 | Late entry | `body1 > late_body·ATR1` or `(C1−EMA21) > 2.2·ATR1` (L311) | **Root cause of X:LATE in down-trends — see §2.** |
| 10 | Cooldown | `sig_age` make_series, 3 bars, blocks both sides (L356) | Correct and tick-safe. Spec default is 2. |
| 11 | Closed vs live candle | All decisions from `[1]`; live candle only for NO CHASE (L384) | Correct. |
| 12 | Main/Panel | Same core concatenated by `build.sh` | Correct. Panel cannot print dynamic text (QCS has no label/table API) — only fixed-text shapes and legend values. |

## 2. Evidence: why X:LATE blocks PUTs in down-trends

V1 replayed on synthetic down-trends (`qcs/test/datasets.lua`), counting every PUT setup cancelled with `LATE`:

| Data | PUT signals | X:LATE (PUT) | caused by EMA21 distance | caused by body size | median distance |
|---|---|---|---|---|---|
| down-trend −0.15/bar | 20 | 47 | 47 (100%) | 0 | 2.51 ATR |
| down-trend −0.25/bar | **0** | 9 | 9 (100%) | 0 | 2.48 ATR |
| mixed seed 7 | 48 | 47 | 47 (100%) | 0 | 2.47 ATR |
| mixed seed 42 | 39 | 35 | 35 (100%) | 0 | 2.54 ATR |

In the strong down-trend: close is > 2.2 ATR from EMA21 on 82% of bars, price retraces to the EMA21 zone on only 1% of bars but to the **EMA9 zone on 34%**, and RSI < 22 (PUT block) on 79% of bars.

Conclusion: in a strong trend V1 waits for a retrace to EMA21 that rarely comes, and it has no
entry type for the shallow EMA9 pullbacks that do come. The fix is **not** to loosen LATE, but to
add a Pullback Entry whose "late" reference is the EMA the price actually pulled back to.

## 3. Plan (implemented in V3)

1. Keep V1 structure, inputs and filters; set spec defaults (cooldown 2, late body 2.0).
2. Fix D1–D4: monotonic scoring, ATR before the confirmation candle (`ATR2`), strict pivot ties, tick-safe pivot state.
3. Trend states: strong/weak up/down, sideways, transition (order + slope + spread).
4. Momentum states: acceleration, bullish/bearish, weakening, exhaustion.
5. Sideways with N-bar confirmation (hysteresis); market condition: trending, sideways, high vol, low vol, exhaustion, potential reversal.
6. **Dual entry**: Momentum Entry (unchanged late rule vs EMA21) and Pullback Entry (touch of EMA9/EMA21 zone inside the trend, closes never below EMA50, rejection/bullish trigger, momentum turning back, late measured from the touched EMA).
7. Score with the spec weights (25/20/20/20/10/5), raw vs final (penalties), per-component globals.
8. States WAIT / READY / CALL / PUT / EXPIRED / BLOCKED; block reasons separated; NO CHASE stays a live warning only.
9. Tests for every spec item; evaluation harness split by setup type and session; V1 vs V3 comparison.

## 4. Risks

* More rules → more QCS surface: only functions already verified in V1/V2 are used.
* Pullback entries add signals: every one must still pass trend, momentum, room, volatility, sideways and score filters (tested).
* No real XAUUSD data: no accuracy claim is possible (see `FAST_ENTRY_TEST_REPORT.md`).
