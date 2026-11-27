# TEST REPORT — V2.0

Command: `qcs/build.sh --test` (build → `luac5.3 -p` → `lua5.3 qcs/test/run_tests.lua`).
Environment: Lua 5.3.6, offline mock of the QCS runtime (`qcs/test/mock_qcs.lua`).
Result of the final run: **47 passed, 0 failed.**

## What the tests can and cannot prove

* They verify the engine's **logic**: filters, regime rules, determinism, no repaint, no look-ahead,
  Main/Panel equality.
* They run on **synthetic** deterministic data (`qcs/test/datasets.lua`). Synthetic data says nothing
  about real-market profitability.
* The mock imitates the documented QCS execution model; it is **not** IQ Option. Platform compatibility
  (plot limits, live-bar re-evaluation, exact EMA seeding) must be confirmed on a Demo account.

## Results by required area

| Area | Test | Result |
|---|---|---|
| Syntax | `luac5.3 -p` on both generated scripts | PASS |
| A Trending | up-trend: TREND share 97% of trend segment; 5 CALL, 0 PUT; all filters re-checked | PASS |
| B Ranging | mean-reverting (Ornstein–Uhlenbeck) data: RANGE 50% of segment; 0 signals while RANGE | PASS |
| C High volatility | volatility ×3: HIGH_VOL on 98% of the first 60 hot bars; 0 signals in HIGH_VOL | PASS |
| D Low volatility | volatility ×0.3: LOW_VOL on 100% of bars 20–80; 0 signals in LOW_VOL | PASS |
| E Sudden spike | 10-ATR candle: HIGH_VOL on the next bar; no signal for 3 bars; spike not used before it closes | PASS |
| F False breakout | sweep-and-reclaim candle → `FALSE-BRK`; close below support followed by a rally → **not** `FALSE-BRK` | PASS |
| G Trend reversal | no PUT in the up-leg; no CALL from 80 bars after the flip; PUT appears after the flip | PASS |
| H Weak momentum | every signal re-checked: no 2-bar histogram fade; `WEAK-MOM` rejects setups | PASS |
| I Late entry | every signal re-checked for body and EMA21 distance; constructed 2.2-ATR candle produces no signal | PASS¹ |
| J S/R obstruction | room re-computed independently from level series for every signal; `NEAR-SR` exercised | PASS |
| K Cooldown | every pair of signals separated by more than the regime cooldown | PASS |
| L Repainting | 4 ticks per bar incl. ±10-ATR extremes on 12,000 bars: 0 decision changes; prefix test (1500/2600/3333 bars) identical history | PASS |
| M Main/Panel | 276,000 engine values compared on 12,000 bars: identical | PASS |
| N Regime switching | confirmed flips 165 < raw 259 on dataset 1; every non-HIGH_VOL change confirmed by 3 raw bars; deterministic re-run | PASS |
| Threshold | every signal score ≥ adaptive minimum ≥ 70 | PASS |
| Warm-up | no regime/signal in the first 115 bars; first signal at bar 234 | PASS |
| Missing/degenerate data | 80-bar history; flat price (ATR = 0); 20 USD gap — no error, no NaN, no signal on flat data | PASS |

¹ The constructed late candle was rejected by an earlier stage (`CONFLICT`) before reaching `LATE`.
The `LATE` rule itself is verified by the independent re-check of every signal (no signal violates it)
and by the funnel (`LATE` rejects setups on mixed data).

## Independent re-check (sections A, B, C, G, H–K)

For every printed signal, the test re-implements the mandatory rules from the engine's raw series
(EMA, RSI, MACD histogram, ATR, pivot levels, range extremes, round numbers) rather than trusting the
engine's own flags: regime tradable, trend structure, momentum, weak momentum, acceleration in strict
regimes, late body, EMA21 distance, room, cooldown, score ≥ adaptive minimum.

## Defects found and fixed during V2 development

| Found by | Problem | Fix |
|---|---|---|
| Smoke run | V2 produced only 25 signals / 11,640 bars; funnel showed `CONFLICT` dominant because a DI-direction veto duplicated EMA/MACD direction | DI kept as score component only |
| Smoke run | Raw regime flipped 158 / 1000 bars (ER(10) noise) | ER period 20, thresholds 0.25 / 0.15 |
| Diagnosis | Trend state still flapping (TREND↔TRANS) because ER dipped on pullbacks | ER used to enter a trend only; ADX + EMA alignment to stay (49.6 → 37.5 confirmed flips / 1000 bars) |
| Test B | "Range" generator (sine wave) actually produced 8-USD trending legs (ADX 49, ER 0.64) | Generator replaced by a mean-reverting process (ADX 17.6, ER 0.15) — the classifier was not changed |
| Review | Placeholder assertion that tested nothing | Removed |

## Reproduce

```bash
apt-get install -y lua5.3      # if missing
qcs/build.sh --test
```
