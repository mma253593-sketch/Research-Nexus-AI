# PERFORMANCE REPORT — V1.0 vs V2.0

## Status: real-market performance validation is INCOMPLETE

No reliable historical XAUUSD M1 data (ideally IQ Option's own feed) was available in this
environment, and none was fabricated. **No claim is made that V2 is more accurate or more profitable
than V1.** The evaluation framework is built and tested; it needs real data to produce evidence.

## Framework (`qcs/eval/evaluate.lua`)

* Runs the frozen V1 baseline (`qcs/eval/baseline/XAUUSD_Smart_Entry_V1_Main.lua`) and the V2 Main
  script bar by bar through the mock runtime (a signal can only use closed candles).
* Digital Option outcome: entry at the **open** of the arrow candle; expiry 1, 2, 3, 5 candles;
  CALL wins if the expiry close is above the entry; **a tie counts as a loss**.
* Payout-aware expectancy per trade: `win_rate × payout − (1 − win_rate)`, default payout 80%
  (`--payout` to change). Break-even win rate = 1 / (1 + payout) = 55.6% at 80%.
* Reports: totals, CALL/PUT split, win/loss rate with 95% Wilson interval, expectancy, maximum drawdown
  (in stakes), maximum consecutive losses, by expiry, by regime (V2 regime at the entry bar), by
  confidence band, chronological train/validation/test (60/20/20) and 5-fold walk-forward.
* Nothing is fitted on any split: all parameters are fixed in advance, so there is no leakage from
  test periods into parameters.

```bash
lua5.3 qcs/eval/evaluate.lua --csv xauusd_m1.csv --payout 0.80 --out qcs/eval/results/real.md
```
CSV: chronological candles with a header containing `open,high,low,close` (extra columns ignored),
or five columns `time,open,high,low,close`.

## Synthetic runs (pipeline validation only — not evidence)

### 1. Leakage check: driftless random walk (12,000 candles, `results/synthetic_randomwalk.md`)

| Expiry 1 | Trades | Win rate | 95% CI | Expectancy |
|---|---|---|---|---|
| V1.0 | 418 | 52.4% | 47.6–57.1% | −0.057 |
| V2.0 | 45 | 42.2% | 29.0–56.7% | −0.240 |

On data with no predictable structure, both confidence intervals contain 50%. A look-ahead leak would
show up as win rates far above 50% here; none is visible. Both versions lose money at an 80% payout,
as they should on unpredictable data.

### 2. Mixed synthetic regimes (12,000 candles, `results/synthetic_mixed.md`)

| | V1.0 | V2.0 |
|---|---|---|
| Signals | 221 (100 CALL / 121 PUT) | 48 (24 CALL / 24 PUT) |
| Signals per 1000 bars | 18.4 | 4.0 |
| Expiry 1 win rate (95% CI) | 52.9% (46.4–59.4%) | 50.0% (36.4–63.6%) |
| Expiry 1 expectancy / trade (80% payout) | −0.047 | −0.100 |
| Max drawdown / max consecutive losses (expiry 1) | 12.0 stakes / 5 | 10.0 stakes / 5 |
| Signals in V2-RANGE / HIGH_VOL bars | 15 / 6 | 0 / 0 |

Walk-forward folds (expiry 1) swing between 25% and 69% win rate for V2 because each fold holds only
7–13 trades. **All V1/V2 confidence intervals overlap; the difference is not statistically
meaningful.** In both versions the 85–100 band did not outperform the 70–84 band on this data, which
supports the warning that the score is not a probability.

What the synthetic runs do show (behaviour, not edge):
1. V2 is about 4.6× more selective.
2. V2 never signals in RANGING or HIGH_VOL regimes; V1 did (21 of 221 signals).
3. The harness, splits and payout maths run end to end without look-ahead.

## What is needed to complete validation

1. At least several months of XAUUSD M1 candles, preferably exported from the same feed as IQ Option.
2. Run the command above; review the out-of-sample (validation/test and walk-forward) rows first.
3. Judge V2 against V1 only where confidence intervals separate; with ~4 signals per 1000 bars,
   roughly 100k+ candles are needed for a few hundred V2 trades.
4. Confirm on an IQ Option **Demo** account that live arrows match the offline replay.
