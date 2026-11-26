# Evaluation output

* Data: SYNTHETIC driftless random walk (leakage check, seed 99), 12000 candles
* Payout assumption: 80% (break-even win rate 55.6%). Tie = loss.
* Entry at the open of the arrow candle; expiry measured in candles.

## Signals

| Version | Total | CALL | PUT | Signals per 1000 bars |
|---|---|---|---|---|
| V1.0 | 418 | 198 | 220 | 34.8 |
| V2.0 | 45 | 25 | 20 | 3.8 |

## By expiry

### Expiry 1 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 418 | 52.4% | 47.6–57.1% | -0.057 | 31.4 | 6 |
| V2.0 | 45 | 42.2% | 29.0–56.7% | -0.240 | 14.0 | 4 |

### Expiry 2 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 418 | 50.7% | 45.9–55.5% | -0.087 | 44.8 | 6 |
| V2.0 | 45 | 42.2% | 29.0–56.7% | -0.240 | 12.4 | 4 |

### Expiry 3 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 418 | 51.0% | 46.2–55.7% | -0.083 | 41.2 | 10 |
| V2.0 | 45 | 46.7% | 32.9–60.9% | -0.160 | 8.8 | 3 |

### Expiry 5 candle(s)

| Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|
| V1.0 | 418 | 53.6% | 48.8–58.3% | -0.035 | 41.6 | 7 |
| V2.0 | 45 | 46.7% | 32.9–60.9% | -0.160 | 10.0 | 4 |

## By market regime (V2 regime at the entry bar), expiry 1

| Regime | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| TREND | V1.0 | 140 | 48.6% | 40.4–56.8% | -0.126 | 20.4 | 5 |
| TREND | V2.0 | 44 | 43.2% | 29.7–57.8% | -0.223 | 13.0 | 4 |
| RANGE | V1.0 | 89 | 50.6% | 40.4–60.7% | -0.090 | 16.0 | 4 |
| TRANS | V1.0 | 189 | 56.1% | 49.0–63.0% | +0.010 | 7.6 | 6 |
| TRANS | V2.0 | 1 | 0.0% | 0.0–79.3% | -1.000 | 1.0 | 1 |

## By confidence band, expiry 1

| Band | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| 70-84 | V1.0 | 134 | 57.5% | 49.0–65.5% | +0.034 | 8.0 | 5 |
| 70-84 | V2.0 | 25 | 40.0% | 23.4–59.3% | -0.280 | 7.8 | 4 |
| 85-100 | V1.0 | 284 | 50.0% | 44.2–55.8% | -0.100 | 35.0 | 9 |
| 85-100 | V2.0 | 20 | 45.0% | 25.8–65.8% | -0.190 | 8.6 | 5 |

## Chronological splits (no fitting on any split), expiry 1

| Split | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| train 0-60% | V1.0 | 256 | 50.8% | 44.7–56.8% | -0.086 | 27.8 | 6 |
| train 0-60% | V2.0 | 31 | 38.7% | 23.7–56.2% | -0.303 | 11.8 | 4 |
| validation 60-80% | V1.0 | 91 | 53.8% | 43.7–63.7% | -0.031 | 11.4 | 6 |
| validation 60-80% | V2.0 | 7 | 42.9% | 15.8–75.0% | -0.229 | 3.0 | 3 |
| test 80-100% | V1.0 | 71 | 56.3% | 44.8–67.3% | +0.014 | 5.6 | 5 |
| test 80-100% | V2.0 | 7 | 57.1% | 25.0–84.2% | +0.029 | 2.0 | 2 |

## Walk-forward (5 sequential folds), expiry 1

| Fold | Version | Trades | Win rate | 95% CI | Expectancy / trade | Max DD (stakes) | Max consec. losses |
|---|---|---|---|---|---|---|---|
| 1 | V1.0 | 75 | 54.7% | 43.4–65.4% | -0.016 | 6.8 | 4 |
| 1 | V2.0 | 10 | 40.0% | 16.8–68.7% | -0.280 | 4.4 | 4 |
| 2 | V1.0 | 91 | 46.2% | 36.3–56.3% | -0.169 | 18.4 | 5 |
| 2 | V2.0 | 14 | 35.7% | 16.3–61.2% | -0.357 | 5.6 | 4 |
| 3 | V1.0 | 90 | 52.2% | 42.0–62.2% | -0.060 | 13.6 | 6 |
| 3 | V2.0 | 7 | 42.9% | 15.8–75.0% | -0.229 | 2.4 | 2 |
| 4 | V1.0 | 91 | 53.8% | 43.7–63.7% | -0.031 | 11.4 | 6 |
| 4 | V2.0 | 7 | 42.9% | 15.8–75.0% | -0.229 | 3.0 | 3 |
| 5 | V1.0 | 71 | 56.3% | 44.8–67.3% | +0.014 | 5.6 | 5 |
| 5 | V2.0 | 7 | 57.1% | 25.0–84.2% | +0.029 | 2.0 | 2 |
