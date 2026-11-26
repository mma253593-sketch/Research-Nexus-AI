# V2 ARCHITECTURE — XAUUSD Smart Entry V2.0 "Adaptive Precision Engine"

Status: design written after the audit (`SOURCE_CODE_AUDIT.md`) and before implementation.
Platform: IQ Option, XAUUSD, primary timeframe M1, Quadcode Script (Lua 5.3 based).

## 1. What stays the same (deliberately)

| Kept from V1 | Why |
|---|---|
| `build.sh` → `header + core.lua + view` | Main and Panel can never diverge in logic. |
| All decisions from closed candles `[1]`/older | No repaint by construction. |
| Signal printed on the entry candle, confirmation candle one bar back | Same reading habit for the user. |
| Side-neutral evaluation by price mirroring | CALL/PUT symmetry is guaranteed, not hand-maintained. |
| `NO_CHASE` as a separate live warning | Never feeds the decision. |
| Indicator set EMA 9/21/50, RSI 14, MACD 12/26/9, BB 20/2, ATR 14 | Requirement of the original spec. |

## 2. Pipeline

```
 closed-candle snapshot ([1], [2], [3] ...)
        │
        ▼
 ┌──────────────────────┐   raw regime per bar  ┌───────────────────────────┐
 │ Regime classifier    │──────────────────────▶│ Hysteresis state machine  │── REGIME (confirmed)
 │ ADX, ATR ratio,      │                       │ enter/exit bands + N-bar  │
 │ BB-width ratio, ER,  │                       │ confirmation (make_series)│
 │ EMA structure        │                       └───────────────────────────┘
 └──────────────────────┘                                   │
                                                            ▼
                                         ┌────────────────────────────────┐
                                         │ Adaptive profile (bounded)     │
                                         │ min score, room, late, RSI ext,│
                                         │ momentum strictness, cooldown  │
                                         └────────────────────────────────┘
                                                            │
        ┌───────────────────────────────────────────────────┘
        ▼                    evaluated for CALL and for mirrored PUT
 Stage 1 Market ─▶ Stage 2 Direction ─▶ Stage 3 Price action ─▶ Stage 4 Entry ─▶ Stage 5 Decision
 (regime, vol)     (trend, momentum,    (quality-filtered        (late, EMA21     (score ≥ adaptive
                    conflict, weak mom,  triggers, false-signal   distance, room,  min, cooldown)
                    whipsaw, reversal,   detectors)               candle validity)
                    exhaustion)
        │
        ▼
 Score 2.0 (0–100 per side, orthogonal components − conflict penalties)
        │
        ▼
 Globals for views: SIG_DIR, SIG_SCORE, SIG_TRIG, REGIME, BULL/BEAR_SCORE, WAIT_REASON, ...
```

Any mandatory failure in stages 1–4 forces WAIT with the first failing reason code.

## 3. Module layout (single file `core.lua`, sections in this order)

1. Inputs (grouped; conservative defaults; bounded ranges).
2. Base series (all series functions called unconditionally every bar).
3. ADX/DI exactly as the official `quadcodescript-library/trend/adx_dms.lua`.
4. Efficiency ratio `abs(change(close,n)) / sum(abs(change(close)), n)`.
5. Pivot state (minor and major strength) in `make_series`, replacing `value_when`.
6. Closed-candle snapshot into plain Lua numbers via `get_value`.
7. Regime classifier + hysteresis state machine.
8. Adaptive profile.
9. Stage validators + Score 2.0 (side-neutral).
10. Decision, cooldown, cancel reason, live NO_CHASE.

Views: `view_main.lua` (chart) and `view_panel.lua` (score, regime strip, reasons).

## 4. State handling (tick-safe)

Every persistent value is a `make_series` whose new value is a pure function of
closed-bar data and **its own `[1]` value**. Re-running the live bar any number of times writes the
same value again, so tick re-evaluation cannot accumulate state. This replaces V1's `value_when`
(undocumented re-evaluation semantics, audit D4).

## 5. Compatibility risks (QCS runtime)

| Risk | Level | Handling |
|---|---|---|
| ADX is not a documented built-in | Medium | Formula copied from official library script; uses `change`, `iff`, `nz`, `rma`, `abs`, all used by official scripts. |
| `sum`, `change` | Low | Documented in Maths Functions; used by 29 official scripts. |
| Lua-number reads via `get_value(x[i])` in loops | Low | Same pattern as official `center_of_gravity.lua`. |
| Number of plot calls | Unknown | Not documented. Main view kept at roughly V1's count; detail moved to Panel. |
| Live-bar re-evaluation semantics | Unknown | Design is idempotent (section 4) regardless of how often the engine re-runs. |
| `plot_shape` negative offset | Low | Documented `offset` param; negative offset used by official `zigzag.lua` (`plot`). Same as V1. |
| The mock runtime is not IQ Option | Inherent | Tests verify logic, not platform compatibility. Must be confirmed on a Demo account. |

## 6. Non-goals

No backtest UI, no order execution, no external data, no profit claims. The offline evaluation
harness (`qcs/eval/`) is a developer tool that runs outside IQ Option.
