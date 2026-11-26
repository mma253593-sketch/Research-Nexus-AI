# TEST REPORT — V3 Precision Fast Entry

Command: `qcs/build.sh --test` (build → `luac5.3 -p` → `lua5.3 qcs/test/run_tests.lua`).
Final run: **56 passed, 0 failed.** Runtime ≈ 70 s.

Scope: logic tests on deterministic synthetic data through an offline mock of the QCS runtime.
They do **not** prove compatibility with the real IQ Option engine and are **not** evidence of
real-market accuracy.

## 1. Results

| Area | Check | Result |
|---|---|---|
| Syntax | Main, Panel, Compact, Mini | PASS |
| 1 Strong uptrend | 20 CALL, 0 PUT, uptrend state 100%, all signals re-checked | PASS |
| 2 Strong downtrend | **14 PUT for V3 vs 0 for V1** on identical data, 0 CALL, pullback entries fire | PASS |
| 3 Sideways | sideways state 60% of the ranging segment, 0 signals while sideways, signal rate 9.1 vs 25.8 per 1000 bars in a trend | PASS |
| 4 High volatility | high-vol state 97% of the first 60 hot bars, 0 signals in high vol, 10-ATR spike blocked on the next bar | PASS |
| 5 Sudden reversal | 0 PUT in the up-leg, 0 CALL from 80 bars after the flip, 23 PUT after | PASS |
| 6 Pullback continuation | up 30 / down 43 pullback entries, 0 counter-trend signals | PASS |
| Functional | Momentum Entry 22, Pullback Entry 300 on mixed data; all 322 signals pass an independent re-implementation of every mandatory rule | PASS |
| Functional | block reasons SIDEWAYS, LATE, SUPPORT, RESISTANCE, EXHAUST, CONFLICT, COOLDOWN, LOW-CONFIDENCE produced | PASS |
| Functional | EXPIRED only after a signal; READY never with a signal; no duplicate signals | PASS |
| Functional | a small doji touching EMA9 is not a signal | PASS |
| Functional | NO CHASE set by a run-away entry candle without changing the signal; cleared when price moves against | PASS |
| Functional | 2.3-ATR candle gives no signal (blocked earlier as EXHAUST) | PASS |
| Repainting | 4 ticks per bar incl. ±10-ATR extremes on 12,000 bars: 0 decision changes | PASS |
| Look-ahead | decisions on 3 history prefixes identical to full history | PASS |
| Consistency | Panel, Compact, Mini vs Main: 384,000 values, 0 differences; Mini 18,037 characters | PASS |
| Warm-up / data | no state or signal in the first 115 bars; 80-bar history; flat price; 20 USD gap | PASS |

## 2. Defects found during development (and fixed)

| Found by | Issue | Fix |
|---|---|---|
| V1 diagnosis | X:LATE on PUTs in down-trends: 100% caused by the EMA21 distance rule; price retraced to EMA21 on 1–9% of bars but to the EMA9 zone on 34–58% | Pullback Entry with EMA9 reference (late rule unchanged for Momentum Entry) |
| Smoke test | sideways rule from V1 missed mean-reverting markets | added efficiency-ratio + flat EMA50 rule |
| Test 4 failed (40% < 60%) | with Hot = 1.9 the high-vol state dropped while ATR was still 1.6–1.9× baseline; a pullback signal fired inside that period | high-vol hysteresis: stays while ATR > 1.5× baseline (entry threshold unchanged) |
| Review | global variable leak (`clv_side`), unreadable setup selection | fixed before the first run |

## 3. V1 vs V2 vs V3 on identical candles (synthetic only)

`qcs/eval/evaluate.lua`, 1-minute expiry (entry = open, exit = close of the arrow candle, tie = loss), payout 80%.

| Data | Version | Signals | Win rate (95% CI) | Net stakes | Max DD | Max consec. losses |
|---|---|---|---|---|---|---|
| random walk 12k (leakage check) | V1 | 418 | 52.4% (47.6–57.1) | −23.8 | 31.4 | 6 |
| | V2 | 45 | 42.2% (29.0–56.7) | −10.8 | 14.0 | 4 |
| | V3 | 313 | 52.4% (46.9–57.9) | −17.8 | 23.2 | 5 |
| mixed regimes 12k | V1 | 221 | 52.9% (46.4–59.4) | −10.4 | 12.0 | 5 |
| | V2 | 48 | 50.0% (36.4–63.6) | −4.8 | 10.0 | 5 |
| | V3 | 327 | 54.7% (49.3–60.0) | −4.8 | 16.4 | 8 |

Reading: every confidence interval overlaps; no version is shown to be better. On a pure random walk
all versions are near 50% (no look-ahead leak) and lose money at an 80% payout. V3 produces the most
signals, including on random-walk data (26 per 1000 bars), so its extra signals are **not** evidence of
quality. Full tables (by side, setup, market, session, missed opportunities, splits) are in
`qcs/eval/results/`.

## 4. Known limitations

1. **No real XAUUSD history was available**: win rate, false-signal rate and net return on real data are unknown. Backtest is incomplete.
2. The 1-minute expiry model is candle-level (open → close). Real IQ Option entries happen seconds after the open; exact matching needs tick data.
3. Not yet run on the real IQ Option QCS engine (plot limits, live-bar re-evaluation, EMA seeding may differ from the mock).
4. QCS has no dynamic text API: the Panel shows states as fixed-text markers and numeric legend values, not a text table.
5. Session split needs a time column in the CSV; synthetic data has none.
6. V3 fires noticeably more than V2 (pullback entries dominate: 300 of 322 on mixed data); the extra signals are unproven.
7. Mean-reverting markets: 40% of bars in the synthetic range were not classified sideways (short directional swings), and 10 signals per 1,100 bars still fired there.
8. No news feed: the system cannot know about scheduled releases.
