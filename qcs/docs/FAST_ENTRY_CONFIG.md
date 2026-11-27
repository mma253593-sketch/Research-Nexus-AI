# CONFIGURATION & RULES — V3 Precision Fast Entry (M1, 1-minute expiry)

All values are editable in the indicator Settings. Defaults are **starting values for testing**,
not values proven to be profitable. `ATR2` = ATR(14) of the candle *before* the confirmation candle.

## 1. Settings (defaults)

| Group | Setting | Default | Note |
|---|---|---|---|
| Trend | EMA Fast / Medium / Slow | 9 / 21 / 50 | spec |
| Trend | EMA50 min slope | 0.02 ATR per bar | added: slope requirement (spec §4.1) |
| Trend | Strong trend spread | EMA9−EMA50 ≥ 1.0 ATR (and slope ≥ 2× min) | added: strong vs weak |
| Momentum | RSI Period / CALL block / PUT block | 14 / 78 / 22 | spec |
| Momentum | MACD | 12 / 26 / 9 | spec |
| Volatility | BB Period / Deviation | 20 / 2.0 | spec |
| Volatility | ATR / Baseline | 14 / 100 | spec |
| Volatility | Squeeze / Flat / Spike / Hot | 0.75 / 0.25 / 2.8 / 1.9 | spec |
| Volatility | Hot stays while ATR > baseline × | 1.5 | added: high-vol hysteresis (§6) |
| Volatility | Cold: ATR < baseline × | 0.5 | added: low-volatility state |
| Volatility | Sideways efficiency ratio period / threshold | 20 / 0.15 | added: second sideways rule (§6) |
| Volatility | Sideways change confirm | 2 bars | added: anti-flicker |
| S/R | Pivot / Range / Min SR distance | 5 / 50 / 0.8 ATR | spec |
| Signal | Min confidence | 70 | spec |
| Signal | Cooldown | 2 bars | spec |
| Signal | Late body / Late distance / No chase | 2.0 / 2.2 / 0.35 ATR | spec |
| Signal | Exhaustion run | 5 same-colour candles | from V1 behaviour |
| Entry Types | Momentum Entry / Pullback Entry | on / on | spec §5 |
| Entry Types | Pullback zone / lookback | EMA9 + 0.3 ATR / 3 bars | added |

## 2. Market condition (closed candle, priority order)

| Code | Condition | Rule | Trading |
|---|---|---|---|
| 3 | High volatility | range > 2.8·ATR2, or ATR > 1.9·baseline; **stays** while ATR > 1.5·baseline | blocked |
| 4 | Low volatility | ATR < 0.5·baseline | blocked |
| 2 | Sideways | (EMA21 3-bar move < 0.25·ATR2 **and** (BB width < 0.75·avg or │EMA9−EMA50│ < 0.3·ATR2)) **or** (efficiency ratio(20) < 0.15 **and** │EMA50 slope│ < 0.04 ATR/bar); changes only after 2 confirming bars | blocked |
| 5 | Exhaustion | trend side with RSI beyond its block or ≥ 5 same-colour candles or a climax wick at a new 50-bar extreme | blocked for that side |
| 6 | Potential reversal | EMA21 still on the trend side but close beyond the last confirmed swing low/high | blocked for that side |
| 1 | Trending | EMA 9>21>50 (or reverse), close beyond EMA50, EMA50 slope > 0.02 ATR/bar | tradable |
| 0 | Transition | none of the above | trend rules decide |

Trend state: **2** strong up (spread ≥ 1 ATR and slope ≥ 0.04), **1** weak up, **−1/−2** mirror, **0** sideways, **5** transition.
Momentum state: **2** acceleration up (hist > 0 and rising, RSI rising), **1** bullish, **−1/−2** mirror, **0** neutral; weakening = hist falling two bars in a row.

## 3. Dual entry (PUT = exact mirror of CALL)

### Momentum Entry (all required)
1. Trend: EMA9 > EMA21 > EMA50, close > EMA50, EMA50 slope > min.
2. Momentum: MACD hist > 0, RSI > 50, histogram not weakening.
3. Not exhausted: RSI ≤ 78, < 5 same-colour candles, no climax wick.
4. Price action: ENGULF, BREAKOUT, MOMENTUM or FALSE-BRK with close in the top 40% of the candle.
5. Not late: body ≤ 2.0·ATR2 and (close − **EMA21**) ≤ 2.2·ATR2.
6. Room to next resistance ≥ 0.8·ATR2.
7. Score ≥ 70; cooldown passed; market tradable.

### Pullback Entry (all required)
1. Main trend: EMA21 > EMA50, EMA9 > EMA50, EMA50 slope > min, and the confirmation candle **closed back above EMA9**.
2. A real pullback in the last 3 closed candles: at least one low inside the EMA9 zone (EMA9 + 0.3·ATR2), at least one counter-trend candle, retrace range ≥ 0.4·ATR2, and **no close below EMA50** (pullback, not reversal).
3. No structure break: close not below the last confirmed swing low.
4. Momentum returning: MACD hist rising, RSI rising and > 45, not exhausted.
5. Price action: REJECT, PIN, ENGULF or RESUME (bullish candle closing above EMA9 after the touch), close in the top 40%.
6. Not late: body ≤ 2.0·ATR2 and (close − **EMA9**) ≤ 2.2·ATR2 — the reference is the EMA the price pulled back to.
7. Room ≥ 0.8·ATR2; score ≥ 70; cooldown; market tradable.

Touching EMA9 alone never produces a signal (tested). A Momentum setup rejected as LATE is never
re-used later; a new, independent Pullback setup must form.

## 4. Price-action definitions (minimum sizes vs ATR2)

| Trigger | Points | Rule (CALL) |
|---|---|---|
| ENGULF | 20 | bullish engulfs bearish body, body ≥ 1.2× previous, previous body ≥ 0.15 ATR, body ≥ 0.4 ATR, close in top 30% |
| FALSE-BRK | 18 | low < last swing low − 0.1 ATR, close back above it, lower wick ≥ 50%, close in top 40% |
| REJECT | 17 | previous candle lower wick ≥ 50% at EMA21/support, range ≥ 0.5 ATR; this candle bullish and closes above it |
| PIN | 15 | lower wick ≥ 2× body and ≥ 60% of range, upper wick ≤ 25%, range ≥ 0.6 ATR, at EMA9/EMA21/support |
| BREAKOUT | 15 | close > last swing high + 0.15 ATR (previous close below), body ≥ 55% of range, ≤ 2 ATR, close in top 25% |
| RESUME | 12 | after a pullback touch: bullish, close above EMA9, body ≥ 0.3 ATR, close in top 40% |
| MOMENTUM | 10 | bullish, body ≥ 60% of range and 0.4–1.5 ATR, close in top 25% |

## 5. Confidence score (0–100, per side, not a win probability)

| Category | Max | Formula |
|---|---|---|
| Trend | 25 | EMA order (full 10 / partial 5) + 8·slope/(3·min) + strength (strong 7 / weak 3) |
| Momentum | 20 | RSI 8·(RSI−50)/15 (pullback: (RSI−45)/20) + MACD (acceleration 12, positive 6, pullback turning up 8) |
| Price action | 20 | trigger points (only triggers valid for the setup type) |
| Entry location | 20 | 10·(room − 0.8)/2 + 10·(1 − (distance − 0.5)/(2.2 − 0.5)) |
| Volatility | 10 | 10·(1 − │ln(ATR/baseline)│ / ln 1.9) |
| Market structure | 5 | rising swing lows 3 + close above last swing high 2 |
| Penalties | −16 | 5-bar close-location < 0.45: −5; upper wick ≥ 35%: −6; RSI falling on a momentum entry: −5 |

Raw score = sum of categories; final score = raw − penalties (clamped 0–100). Bands: 85–100 Strong,
75–84 Good, 70–74 Moderate, < 70 WAIT. Mandatory rules are checked separately: a high score never
overrides a failed rule. Panel legend shows raw score and price-action points; the other parts are
exposed as `SC_TREND`, `SC_MOM`, `SC_PA`, `SC_LOC`, `SC_VOL`, `SC_STRUCT`, `SC_PEN`.

## 6. States and warnings

| Code | State | Meaning |
|---|---|---|
| 2 / −2 | CALL / PUT | enter at the open of this candle, 1-minute expiry |
| 1 / −1 | CALL READY / PUT READY | trend intact, price inside the EMA9 pullback zone, MACD turning, no trigger yet — **not an entry** |
| 3 | EXPIRED | the previous candle had a signal; it is over, do not use it now |
| 4 | BLOCKED | a complete setup existed but a rule blocked it (reason shown) |
| 0 | WAIT | nothing to do |

Block reasons: SIDEWAYS, LATE, SUPPORT (PUT blocked), RESISTANCE (CALL blocked), LOW CONFIDENCE
(score within 10 points of the minimum), VOLATILITY, EXHAUSTION, REVERSAL, MOMENTUM, COOLDOWN.
**NO CHASE** is a separate live warning on the entry candle (price already moved > 0.35·ATR from
the open). It never changes the signal state.
