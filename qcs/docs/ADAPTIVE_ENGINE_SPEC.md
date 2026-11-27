# ADAPTIVE ENGINE SPECIFICATION — V2.0

Every rule below is implemented in `qcs/src/core.lua`. Notation: `[1]` = last closed candle
(confirmation candle), `[2]` = the candle before it. `ATR2` = ATR(14) value at `[2]`, i.e. **before**
the confirmation candle, so a large candle cannot inflate its own thresholds (audit D2).
All price distances are expressed in ATR units, which makes every threshold volatility-adaptive
by construction.

## 1. Verified QCS functions used

| Function | Verified by |
|---|---|
| `ema`, `sma`, `rma`, `rsi`, `stdev`, `highest`, `lowest`, `max`, `abs`, `tr` | QCS docs + official library |
| `change(series, n)`, `sum(series, n)` | QCS docs "Maths Functions"; 10 / 29 uses in official library |
| `iff`, `nz` | QCS docs "Conditions"/"Troubleshooting"; used by official `adx_dms.lua` |
| `make_series`, `:set`, `get_value` | QCS docs; official `zigzag.lua`, `center_of_gravity.lua` |
| `math.max/min/abs/log/ceil/floor` | Lua 5.3 standard library (QCS is Lua 5.3 based; docs use `math.max`) |

**ADX is not a QCS built-in.** It is computed with the exact formula of the official
`quadcodescript-library/trend/adx_dms.lua`:

```
up = change(high);  dn = -change(low)
+DM = iff(up > dn and nz(up) > 0, up, 0);   -DM = iff(dn > up and nz(dn) > 0, dn, 0)
+DI = 100 * rma(+DM / rma(tr,14), 14);      -DI = 100 * rma(-DM / rma(tr,14), 14)
ADX = 100 * rma(abs(+DI - -DI) / (+DI + -DI), 14)
```

Efficiency ratio (Kaufman): `ER = abs(change(close, 20)) / sum(abs(change(close)), 20)`
(1 = straight line, 0 = pure noise).

## 2. Market regime classification (Phase 2)

Inputs on candle `[1]`: `ATRR = ATR[1] / SMA(ATR,100)[1]`, `BWR = BBwidth[1] / SMA(BBwidth,60)[1]`,
`ADX[1]`, `ER[1]`, EMA 9/21/50, `slope = (EMA50[1] − EMA50[6]) / (5·ATR[1])` (ATR per bar),
`spike = range[1] > 2.8 · ATR2`.

Rules, evaluated in priority order (`prev` = confirmed regime on the previous bar):

| Priority | Regime | Enter rule | Stay rule (hysteresis band) |
|---|---|---|---|
| 1 | **HIGH_VOL** | `spike` or `ATRR ≥ 1.60` | `ATRR ≥ 1.35` |
| 2 | **LOW_VOL** | `ATRR ≤ 0.60` and `BWR ≤ 0.85` | `ATRR ≤ 0.70` |
| 3 | **TRENDING** | `ADX ≥ 25` and `ER ≥ 0.25` and full EMA stack (9>21>50 or 9<21<50) and EMA21/50 aligned with the slope sign and `|slope| ≥ 0.02` | `ADX ≥ 20` and EMA21/50 aligned with slope sign |
| 4 | **RANGING** | `ADX < 18` and (`ER < 0.15` or `|EMA9 − EMA50| < 0.5·ATR`) | — |
| 5 | **TRANSITIONAL** | none of the above | — |

### Confirmation (anti-flapping)

* `raw` = result of the table on this bar. `cnt` = consecutive bars with the same `raw`.
* Confirmed regime changes only when `cnt ≥ 3` (input *Regime change confirm*).
* **Exception: HIGH_VOL is entered immediately** (safety: risk filters must never wait). Leaving it
  still needs 3 confirming bars and the stay band (`ATRR < 1.35`).
* State is stored in `reg_state`, `reg_cand`, `reg_cnt` (`make_series`, written from their own `[1]`).

Rationale: two hysteresis mechanisms (threshold bands + N-bar confirmation). The ER criterion is
used to *enter* a trend only: during development, ER(20) dipped on ordinary pullbacks and made the
trend state flap (measured: 49.6 → 37.5 confirmed flips per 1000 bars on the development set after
moving ER to entry-only). ADX is double-smoothed and therefore the stable "stay" criterion.

## 3. Adaptive profile (Phase 3)

| Parameter | TRENDING | TRANSITIONAL / LOW_VOL¹ | RANGING | HIGH_VOL | Bounds |
|---|---|---|---|---|---|
| Tradable | yes | TRANS: `allow_trans` (default **on**); LOW_VOL: `allow_low_vol` (default **off**) | **no** → WAIT | **no** → WAIT | — |
| Min score | `min_score` (70) | `min_score + trans_extra` (78) | — | — | clamp to [min_score, 95] |
| Min room to next level | 0.8 ATR | ×1.5 = 1.2 ATR | — | — | [min_room, 3.0] |
| Max distance from EMA21 | 2.2 ATR | ×0.75 = 1.65 ATR | — | — | [1.0, configured] |
| Max confirmation body | 1.8 ATR | ×0.85 = 1.53 ATR | — | — | [0.8, configured] |
| RSI must exceed | 50 | 52 | — | — | fixed |
| RSI block (CALL / PUT) | 78 / 22 | min(78,72) / max(22,28) | — | — | never looser than input |
| MACD histogram | > 0 | > 0 **and rising** | — | — | — |
| Price-action minimum | 10 (momentum candle allowed) | 15 (pattern required) | — | — | — |
| Cooldown | 3 bars | max(3, 5) = 5 bars | — | — | — |
| Regime score points | 15 | 6 (TRANS) / 4 (LOW_VOL) | 0 | 0 | — |

¹ LOW_VOL uses the strict profile only if `allow_low_vol` is switched on.

Rationale: thresholds only ever get **stricter** outside a confirmed trend; no regime loosens a
safety filter. HIGH_VOL and RANGING are never tradable and cannot be overridden. All profile values
are derived from the user inputs by fixed multipliers with hard bounds, so a user input cannot
produce an unstable profile.

## 4. Five-stage validator (Phase 4)

Evaluated per side (PUT = mirrored prices, RSI → 100−RSI, MACD → −MACD, +DI ↔ −DI).
The first failing rule sets the reason; any failure means WAIT.

| Stage | Reason code | Rule (CALL side) |
|---|---|---|
| 1 Market | `WARMUP` | fewer than 115 bars or any input missing/NaN, or ATR = 0 |
| 1 Market | `VOLATILE` / `RANGING` / `TRANSITION` / `LOW-VOL` | profile not tradable |
| 2 Direction | `NO-TREND` | not (EMA21 > EMA50 and C1 > EMA50 and EMA50[1] > EMA50[6] and EMA9 > EMA21) |
| 2 Direction | `REVERSAL` | C1 < last confirmed minor swing low (structure break against the trade) |
| 2 Direction | `CONFLICT` | RSI ≤ profile RSI minimum, or MACD hist ≤ 0 |
| 2 Direction | `WEAK-MOM` | hist[1] < hist[2] < hist[3] (two-bar fade), or strict profile and hist[1] ≤ hist[2] |
| 2 Direction | `WHIPSAW` | ≥ 2 EMA9/EMA21 crosses in the last 10 closed bars |
| 2 Direction | `OVEREXT` | RSI > RSI block level |
| 2 Direction | `EXHAUST` | ≥ 5 consecutive bullish closes ending at [1], or buying climax: H1 ≥ prior 50-bar high and upper wick ≥ 40% of range |
| 3 Price action | `NO-PA` | trigger points < profile minimum, or close in the lower half of the candle |
| 4 Entry | `LATE` | body[1] > late-body·ATR2, or (C1 − EMA21)/ATR2 > max distance |
| 4 Entry | `NEAR-SR` | room to nearest obstacle < profile room |
| 5 Decision | `LOW-SCORE` | Score 2.0 < profile minimum |
| 5 Decision | `COOLDOWN` | a signal was printed within the profile cooldown |

Obstacles for room: newest and previous minor pivot (strength 5), newest major pivot (strength 15),
highest high of the 50 bars before the confirmation candle, and the next round number
(`round_step`, default 10 USD; 0 disables).

Pivot rule (audit D3/D4 fix): pivot high at `[p+1]` if it is **strictly** above the `p` bars on
its left and **≥** the `p` closed bars on its right; one pivot per plateau. Stored two-deep in
`make_series` (`res1/res2`, `sup1/sup2`, `resM`, `supM`), replacing `value_when`.

"Is the entry candle still valid?" — the signal exists only on the candle right after the
confirmation candle; it is never carried to later candles. `NO CHASE` (live, not an input) warns
when the entry candle already moved > 0.35·ATR in the signal direction.

## 5. Price-action triggers and false-signal detection (Phase 6)

All measured on closed candles. `cpos = (C1 − L1)/range1`.

| Trigger | Points | Objective rule |
|---|---|---|
| ENGULF | 20 | [1] bullish, [2] bearish, C1 ≥ O2, O1 ≤ C2, body1 ≥ 1.2·body2, **body2 ≥ 0.15 ATR2** (engulfed candle meaningful), body1 ≥ 0.4 ATR2, **cpos ≥ 0.7** |
| FALSE-BRK | 18 | L1 < support − **0.1 ATR2** (real sweep), C1 > support, lower wick ≥ 50% of range, cpos ≥ 0.6. Decided on the sweep candle's own close, never on what the next candle does. |
| REJECT | 17 | [2] lower wick ≥ 50% of range, range ≥ 0.5 ATR2, touched EMA21 (+0.15 ATR) or support (+0.25 ATR); **follow-through**: [1] bullish, C1 > max(O2, C2), cpos ≥ 0.6 |
| PIN | 15 | lower wick ≥ 2·body and ≥ 60% of range, upper wick ≤ 25%, range ≥ 0.6 ATR2, **at a level** (EMA21 or support) |
| BREAKOUT | 15 | C1 > last minor resistance + 0.15 ATR2, C2 ≤ level, bullish, body ≥ 55% of range, cpos ≥ 0.75, **body ≤ 2.0 ATR2** (no climax) |
| MOMENTUM | 10 | bullish, body ≥ 60% of range, cpos ≥ 0.75, 0.4 ≤ body/ATR2 ≤ 1.5 |

The highest-point trigger is kept. False-signal detectors map to rules: false breakout (FALSE-BRK
definition and breakout quality), weak momentum (`WEAK-MOM`), exhaustion (`EXHAUST`, `OVEREXT`),
trend reversal (`REVERSAL`), EMA whipsaw (`WHIPSAW`), low-quality engulfing (ENGULF quality
clauses), rejection without follow-through (REJECT requires the follow-through candle),
signals near major S/R (`NEAR-SR` with major pivots and round numbers).

## 6. Score 2.0 (Phase 5)

Per side, 0–100, rounded to an integer. **It measures how well the technical conditions agree. It
is not a probability of winning.**

| Component | Max | Formula | Rationale |
|---|---|---|---|
| R Regime suitability | 15 | TREND 15, TRANS 6, LOW_VOL 4 | The same setup is more reliable in a confirmed trend. |
| T Trend structure | 20 | EMA stack 8 + 7·clamp((ADX−15)/20) + 5·clamp((+DI − −DI)/10) | One stack term (V1 counted 4 correlated EMA items), plus strength (ADX) and directional balance (DI), which are not EMA-derived. |
| M Momentum | 15 | 8·clamp((RSI−50)/15) + (7 if hist > 0 and rising, 3 if hist > 0) | Monotonic in RSI (fixes D1). MACD-line > 0 removed (duplicate of EMA trend). |
| P Price action | 20 | trigger points | Quality is built into the trigger definitions. |
| E Entry quality | 20 | 12·clamp((room − min room)/2) + 8·(1 − clamp((ext − 1)/(max ext − 1))) | Rewards room beyond the minimum and entries close to EMA21. |
| V Volatility quality | 10 | 10·(1 − clamp(|ln ATRR| / ln 1.6)) | 10 at baseline volatility, 0 at ×1.6 or ÷1.6; symmetric in log space. |
| Penalties | −17 | −6 if 5-bar close-location < 0.45; −5 if RSI falling; −6 if upper wick ≥ 35% of the trigger candle | Explicit conflicting evidence. |

`clamp(x)` = clamp to [0, 1]. Score bands: 85–100 Strong, 70–84 Good, 60–69 Weak (only visible if the
user lowers `min_score`), below the adaptive minimum → WAIT.

## 7. Decision and outputs

* Bull and bear are both evaluated; at most one can pass (their trend rules are mutually exclusive).
* Cooldown: `bars since last signal < profile cooldown` → WAIT (`COOLDOWN`).
* A cancel reason is published only for a complete would-be setup (trend bias + trigger + score ≥
  minimum) and only on the first bar of a streak (`WAIT_NEW`).
* Globals read by the views: `SIG_DIR`, `SIG_SCORE`, `SIG_TRIG`, `SIG_MIN`, `SIG_ROOM`, `REGIME`,
  `REGIME_RAW`, `REGIME_NEW`, `BULL/BEAR_SCORE`, `BULL/BEAR_REASON`, `BULL/BEAR_TRIG`, `TREND_DIR`,
  `WAIT_REASON`, `WAIT_SIDE`, `WAIT_NEW`, `BUY/SELL_PRESS`, `NO_CHASE`, `COOLDOWN_USED`, `PROF_*`,
  `ATR_RATIO`, `ADX_NOW`, `ER_NOW`.

## 8. Default calibration provenance

Defaults come from common technical-analysis conventions (ADX 20/25, ER windows, Bollinger 20/2)
and from **stability** checks on synthetic development data (regime flapping, filter funnel). No
parameter was optimised for win rate or on any evaluation split, and no real XAUUSD data was
available for calibration (see `PERFORMANCE_REPORT.md`).
