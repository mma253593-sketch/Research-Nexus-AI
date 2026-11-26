# Evaluation output

* Data: SYNTHETIC mixed regimes (seeds 7, 42, 2026 concatenated), 12000 candles
* Payout assumption: 80% (break-even win rate 55.6%). Tie = loss.
* Entry at the open of the arrow candle; expiry measured in candles.

## Signals

| Version | Total | CALL | PUT | Signals per 1000 bars |
|---|---|---|---|---|
| V1.0 | 221 | 100 | 121 | 18.4 |
| V2.0 | 48 | 24 | 24 | 4.0 |

## By expiry

### Expiry 1 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 221 | 52.9% | 46.4–59.4% | -0.047 | 12.0 | 5 |
| V2.0 | 48 | 50.0% | 36.4–63.6% | -0.100 | 10.0 | 5 |

### Expiry 2 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 221 | 56.6% | 50.0–62.9% | +0.018 | 13.0 | 6 |
| V2.0 | 48 | 62.5% | 48.4–74.8% | +0.125 | 5.6 | 4 |

### Expiry 3 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 221 | 62.9% | 56.4–69.0% | +0.132 | 6.0 | 5 |
| V2.0 | 48 | 64.6% | 50.4–76.6% | +0.163 | 3.2 | 3 |

### Expiry 5 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 221 | 62.9% | 56.4–69.0% | +0.132 | 9.0 | 5 |
| V2.0 | 48 | 62.5% | 48.4–74.8% | +0.125 | 4.0 | 4 |

## By market regime (V2 regime at the entry bar), expiry 1

| Regime | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| TREND | V1.0 | 129 | 52.7% | 44.1–61.1% | -0.051 | 7.8 | 4 |
| TREND | V2.0 | 48 | 50.0% | 36.4–63.6% | -0.100 | 10.0 | 5 |
| RANGE | V1.0 | 15 | 40.0% | 19.8–64.3% | -0.280 | 4.8 | 3 |
| HIGH_VOL | V1.0 | 6 | 66.7% | 30.0–90.3% | +0.200 | 2.0 | 2 |
| LOW_VOL | V1.0 | 2 | 50.0% | 9.5–90.5% | -0.100 | 1.0 | 1 |
| TRANS | V1.0 | 69 | 55.1% | 43.4–66.2% | -0.009 | 6.4 | 5 |

## By confidence band, expiry 1

| Band | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| 70-84 | V1.0 | 79 | 57.0% | 46.0–67.3% | +0.025 | 6.2 | 4 |
| 70-84 | V2.0 | 27 | 55.6% | 37.3–72.4% | +0.000 | 4.4 | 3 |
| 85-100 | V1.0 | 142 | 50.7% | 42.6–58.8% | -0.087 | 16.0 | 6 |
| 85-100 | V2.0 | 21 | 42.9% | 24.5–63.5% | -0.229 | 9.4 | 6 |

## Chronological splits (no fitting on any split), expiry 1

| Split | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| train 0-60% | V1.0 | 128 | 53.9% | 45.3–62.3% | -0.030 | 9.0 | 5 |
| train 0-60% | V2.0 | 26 | 42.3% | 25.5–61.1% | -0.238 | 8.4 | 5 |
| validation 60-80% | V1.0 | 40 | 57.5% | 42.2–71.5% | +0.035 | 4.2 | 3 |
| validation 60-80% | V2.0 | 9 | 44.4% | 18.9–73.3% | -0.200 | 3.0 | 3 |
| test 80-100% | V1.0 | 53 | 47.2% | 34.4–60.3% | -0.151 | 8.4 | 5 |
| test 80-100% | V2.0 | 13 | 69.2% | 42.4–87.3% | +0.246 | 2.0 | 2 |

## Walk-forward (5 sequential folds), expiry 1

| Fold | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| 1 | V1.0 | 47 | 48.9% | 35.3–62.8% | -0.119 | 8.8 | 5 |
| 1 | V2.0 | 7 | 57.1% | 25.0–84.2% | +0.029 | 2.0 | 2 |
| 2 | V1.0 | 39 | 61.5% | 45.9–75.1% | +0.108 | 2.2 | 2 |
| 2 | V2.0 | 8 | 25.0% | 7.1–59.1% | -0.550 | 5.0 | 5 |
| 3 | V1.0 | 42 | 52.4% | 37.7–66.6% | -0.057 | 7.6 | 4 |
| 3 | V2.0 | 11 | 45.5% | 21.3–72.0% | -0.182 | 4.2 | 4 |
| 4 | V1.0 | 40 | 57.5% | 42.2–71.5% | +0.035 | 4.2 | 3 |
| 4 | V2.0 | 9 | 44.4% | 18.9–73.3% | -0.200 | 3.0 | 3 |
| 5 | V1.0 | 53 | 47.2% | 34.4–60.3% | -0.151 | 8.4 | 5 |
| 5 | V2.0 | 13 | 69.2% | 42.4–87.3% | +0.246 | 2.0 | 2 |
