# TASK 03D: Numeric Validation Probe — Implementation Report

**Status: ready for the Owner to review. Not yet tested on IQ Option.**
The results in this report come from a syntax check and a Lua mock (stub) test only. They **do not prove** anything about how IQ Option behaves, and **T7, T8 and T9 are not passed**.

Scope: Diagnostic only. There are no trade signals, no CALL/PUT, no strategy, no V2 integration and no change to M1/M5/M15 weights.

## 1. Pre-development checks

| Item | Result |
|---|---|
| Branch | `claude/project-thread-47bxrs` (latest commit before work: `6beea0c`) |
| Working tree | Clean before starting (no uncommitted changes) |
| Original probe `m1_aggregate_probe.lua` | **Not edited**. sha256 `f9cc6fdef34ccff4f913c484e135ca3ef6f8fb77452ea2041ff452d0f93749a4` (same as in TASK 03C) |
| TASK 03C documents | Read `TASK03C_FINAL_VALIDATION.md`. Its main issues were: the web shows text as dots, only one bar per cycle can be shown, and a GAP bucket still has a last CLOSED value |

## 2. Files

| File | Status | Contents |
|---|---|---|
| `qcs/platform_probe/m1_aggregate_probe_v2.lua` | New | Probe v2 (22,334 characters, under 25,000) |
| `qcs/platform_probe/mock_test_m1_aggregate_probe_v2.lua` | New | Mock test (Lua stub, **not QCS**) |
| `qcs/platform_probe/TASK_03D_IMPLEMENTATION_REPORT.md` | New | This report |
| `qcs/platform_probe/TASK_03D_PLATFORM_TEST_PLAN.md` | New | Test steps on IQ Option |
| `qcs/platform_probe/m1_aggregate_probe.lua` | **Not changed** | — |

**SHA-256 of Probe v2:** `e236daecd5f972ff5ca9a57d9bcec4c8fba06be6021dcfd13343d46a02e8eb16` (22,336 bytes)
Mock test: `3e2fcf19dc77d70c1eda868322e1aacbe89451b229aadc75a916096d3f091de2`

## 3. How it works

### 3.1 Algorithm kept the same as TASK 03C
- `P` = the smallest positive `open_time` step seen so far.
- `bucket = floor(open_time / (k·P))`, where k = 5 or 15.
- The `aggregate(k)` function is copied from 03C with **the same logic**. Comparing it with `diff` shows only formatting lines and removed fields that were no longer used (`phase`, `lstart`, `full`, `gap`). It is used for:
  - the FORMING bucket value (including the live M1 bar), and
  - a cross-check against the new method (DIFF marker).
- Only real M1 OHLC and `open_time` from the chart are used. There is no `security()` and no generated data.

### 3.2 What changed, and why

| Change | Technical reason |
|---|---|
| **Last CLOSED is built from closed M1 bars only.** Each bar adds the *previous* bar (`open[1]`, `high[1]`, `low[1]`, `close[1]`, `open_time[1]`) to its bucket. A bucket is closed only when a bar from a later bucket exists. | In 03C, the closed value comes from the "forming" value the script saw on the last tick it ran. If the platform does not run the script on the final tick of an M1 bar, live values can differ from values after a reload (a repaint risk). In v2, the values come from the closed bar itself, so live and reload must be the same (mock test T7). |
| **Status OK / GAP / NODATA / FORMING / BADP** | Required by the order. OK requires: closed, N == k, `open_time` strictly increasing, and P = 60 s or 60000 ms (an M1 chart). |
| **Usable value = OK only.** The View 1 lines and View 3 candles show only OK buckets. A GAP bucket appears only in text marked `GAP`. | Rule D: a GAP value must be rejected even if it has OHLC. |
| **The first bucket of the chart is not compared for DIFF** | On bar 1, 03C does not yet know P, so it always counts the first bucket one bar short. That is not an error in the new method (see T8 in the mock test). |
| **date() uses seconds** (divides by 1000 when P = 60000) | The documentation says date() takes a UNIX timestamp. On IQ Option, P was measured as 60 (seconds), so nothing changes there. |

### 3.3 Selecting a bucket (Input)

| Input | Meaning |
|---|---|
| `Select 0=latest closed 1=by time` | 0 = show the latest closed bucket and the one before it. 1 = select by time. |
| `Select day of month (0=latest match)` | Day of the month (`date().day`). 0 = the latest match on the chart. |
| `Select hour` / `Select minute` | Chart time (OS timezone, from `date()`). In 03C, T matched the chart's time axis. |

- For M5, the probe uses the bucket at `minute − minute mod 5`. For M15, it uses `minute − minute mod 15`. For example, selecting 07:17 gives M5 07:15–07:19 and M15 07:15–07:29.
- The text shows both the time you selected (`SEL07:17`) and the actual bucket time (`B28 07:15-07:19`).
- Matching is done on any bar inside that bucket, so it still works if the M1 bar at that exact minute is missing.

### 3.4 Numeric output (one line per timeframe)

```
M5 SEL07:17 B28 07:15-07:19 OK N5/5 O3606.83824 H3612.86127 L3606.63824 C3611.93409 PRV28 07:10-07:14 OK N5/5 O... H... L... C...
M15 SEL07:17 B28 07:15-07:29 OK N15/15 O... H... L... C... PRV28 07:00-07:14 OK N15/15 O... H... L... C...
```
(Example values are from the mock and are not real prices.)

| Field | Meaning |
|---|---|
| `SEL07:17` / `LIVE` | The selected time, or latest-closed mode |
| `B28 07:15-07:19` | Bucket: day 28, first M1 bar 07:15, last M1 bar 07:19 |
| `OK` `GAP` `NODATA` `FORMING` `BADP` | Status |
| `N5/5` | Number of M1 bars used / expected N |
| `O H L C` | 5 decimal places |
| `PRV...` | The bucket immediately before (bucket − 1) with its own status. If that bucket had no bars, it shows `NODATA N0/5`. |

- `Text 0=SEL+PRV 1=SEL 2=PRV` shortens the line. A full line is about 157–162 characters; choosing SEL or PRV alone gives about 83–86.

### 3.5 Views

| View | Purpose |
|---|---|
| 1 Lines | M1 close, M5/M15 FORMING, M5/M15 last CLOSED (OK only). Markers: `5OK` `5GAP` `15OK` `15GAP`, `DIFF` (03C differs from the closed-bars method), `SEL5`/`SEL15` (the selected bucket has just closed), `NOT 1M CHART` |
| 2 Text | Two rows at the same time: **M5 at the bottom** (`shape_location.bottom`) and **M15 at the top** (`shape_location.top`). `Text place 2` switches to absolute rows y=1/y=2 as in 03C. |
| 3 Candles | `plot_candle` of last CLOSED (OK only). `Rows 2` = M15, otherwise M5. |
| 4 Snapshot | When the selected bucket closes, the script calls `error(record)` so the platform shows the message. **This stops the script.** Use it only to read the numbers. |

- `print()`: when the selected bucket closes, the record line is printed to the script log (`print() selected records`).

### 3.6 Text readability on the web (point E), with what is still unverified
- In TASK 03C, the text used `shape_location.absolute` and `shape_size.tiny`. On the web, only white dots appeared. **In the web screenshots of 03C, the text on the `5OK`/`15OK` markers (which use `top`/`bottom`) was visible.** For that reason, v2 uses `top`/`bottom` by default, which is a guess that still needs checking.
- Default text size is `large`. `Text size` goes from 1 (tiny) to 5 (huge). The sizes `normal`, `large` and `huge` are in the QCS docs and in the repo's V1 scripts.
- The default shape under each character is **transparent** (`Show shape under text = 0`), so white dots do not appear. If the platform does not draw the text, the row will be **empty** rather than dots. Set it to 1 to see where characters would be.
- `Bars per character` (default 2) spaces out the characters. On the web you may need a larger value, or need to zoom the chart.
- **None of these has been tested on IQ Option Web.** If the text still does not show, use View 4 (error message), `print()` (script log) or View 3 (candles) instead. None of these has been confirmed on the platform either.

## 4. Correctness and safety rules

| Requirement | How it is handled |
|---|---|
| Never mix bars across buckets | Each bar is added only to `floor(t/(kP))` of that bar. If time goes backwards, the bucket becomes GAP. |
| Never use an unclosed M1 bar in last CLOSED | Last CLOSED is built from `[1]` bars only, and closes only when a bar from a later bucket appears. |
| Lookahead | Only the current bar and `[1]` are read. Mock T9 shows the record is the same when the data stops at the close bar. |
| Repaint | Last CLOSED does not depend on live ticks. Mock T7 shows the values are identical whether the final tick is missed or not. |
| Incomplete data and GAP | A partial first bucket gives `GAP N3/5` (T13). A missing M1 bar gives GAP (T2). A fully missing bucket gives NODATA, with no fake bar (T3). |
| Cannot confirm a bucket is complete, so reject it | Any status other than OK gets no value in the lines or candles. |

## 5. Syntax check
- `luac5.3 -p m1_aggregate_probe_v2.lua` passed.
- `luac5.3 -p mock_test_m1_aggregate_probe_v2.lua` passed.
- Size is 22,334 characters, under 25,000.

## 6. Mock test (Lua stub, **not IQ Option**)

Run: `lua5.3 qcs/platform_probe/mock_test_m1_aggregate_probe_v2.lua`. Result: **37 passed, 0 failed**.

The stub re-runs the script on every bar. It identifies `make_series` by call order, reads `s[1]` as the previous bar's value, and can run several ticks on a bar. The data is made-up M1 bars (a sin/cos price path).

| # | Case | Result |
|---|---|---|
| T1 | Normal bucket M5/M15 + previous bucket, OHLC matches direct calculation | PASS (5) |
| T2 | GAP bucket (1 M1 missing): `GAP N4/5`, `GAP N14/15`, usable line empty, `5GAP` marker | PASS (4) |
| T3 | Whole bucket missing: PRV `NODATA`, no event when selecting the empty bucket, no fake bar | PASS (3) |
| T4 | Forming bucket: last CLOSED is the previous bucket, no record while FORMING | PASS (2) |
| T5 | Text shows `NODATA` before the bucket exists, printer works up to the last bar | PASS (2) |
| T6 | Bucket selection: day=0 tracks the latest, a specific day selects only that day | PASS (4) |
| T7 | Live ticks miss the final value: DIFF is shown, v2 is identical live and after reload, no DIFF in history | PASS (3) |
| T8 | Same algorithm as 03C: last CLOSED v2 == 03C on every OK bar (283 bars) | PASS |
| T9 | No lookahead: same record with data cut off; record appears on the first bar of the next bucket | PASS (2) |
| T10 | 5m chart: `NOT 1M CHART`, no usable value | PASS (2) |
| T11 | Millisecond timestamps give the same record | PASS |
| T12 | Snapshot (View 4): stops on the bar where M15 closes, message has both rows | PASS (2) |
| T13 | First bucket of the chart is partial, so GAP | PASS |
| T14 | M1 time goes backwards, so GAP | PASS |
| T15 | Text characters (View 2) rebuild the record exactly, M5/M15 × dsp 1/2 | PASS (4) |

**These results do not count as evidence for T7, T8 or T9 of TASK 03C.** They show only that the Lua logic behaves as designed on made-up data.

## 7. IQ Option limitations not yet confirmed

1. Whether IQ Option Web shows `plot_shape` text with `top`/`bottom` placement, at large/huge size, with a transparent shape.
2. The number of `plot_shape` calls. View 2 with both rows uses about 68 text shapes plus 8 markers. If the platform limits this, set `Rows` = 1 or 2.
3. Whether `error()` shows the full message on the chart (View 4).
4. Where `print()` output appears (script log) on Web/Desktop.
5. Whether `plot_candle` works in a separate pane, and whether hovering shows OHLC.
6. Whether `date().day` has a value. The documentation says yes, but 03C only used hour and min.
7. Long lines: a full line at dsp=2 takes about 320 bars (about 5 hours on M1). Choose `Text 1` or `2`, or dsp=1, to shorten it.
8. Whether the platform runs the script on every tick. This decides whether DIFF ever appears; it can only be checked live.
9. The probe hash can only be checked on the repo copy. It cannot be checked on the code pasted into IQ Option.

## 8. What happens next
Stop here and wait for the Owner to review and approve testing on IQ Option according to `TASK_03D_PLATFORM_TEST_PLAN.md`.
