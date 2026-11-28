# TASK 03C: Final validation of M1 Aggregate Probe (T7, T8, T9, GAP)

- Date: 28 Nov 2026, 11:54 to 12:30 (UTC+7)
- Platform: IQ Option Web (traderoom, Claude browser pane) plus IQ Option Desktop app (view-only screenshots)
- Account: Demo/Practice only. No trades were placed during this test.
- Asset: XAUUSD (OTC). The probe ran on a 1m chart ("Blitz" tab). The real 15m chart was in a separate tab ("Digital").
- Probe file: `qcs/platform_probe/m1_aggregate_probe.lua`
  - sha256 `f9cc6fdef34ccff4f913c484e135ca3ef6f8fb77452ea2041ff452d0f93749a4`, 9793 bytes, unchanged since `bfafbbb`
  - The code was not edited during the test. Only the `View` and `Bars per character` inputs were changed.
  - Limit: the hash is for the repo copy. The code pasted into IQ Option cannot be hashed from inside the platform.
- Evidence: `/mnt/project-files/platform_probe/task03c_evidence/` (folders t8/, t9/, gap/ and t7_* files)

## Summary

| Test | Result | Evidence |
|---|---|---|
| T7 M15 full OHLC (≥3 bars) | **INCONCLUSIVE** | Only 1 M15 bar (T=07:15) could be read in full from the probe. The real 15m candle at 07:15 is consistent, but the readout is low resolution. 3 bars are required. |
| T8 Live stability (≥15 min) | **INCONCLUSIVE** (no FAIL seen) | 26 screenshots, 11:56:55–12:12:59. The lines changed level only on bars :00, :05, :10 and :15, and stayed flat between them at pixel level. Numbers could not be read, so "unchanged" cannot be confirmed to 5 decimals. |
| T9 Reload / repaint | **INCONCLUSIVE** (no FAIL seen) | Reloaded at 12:17. The line shapes before and after reload look the same. The numbers of the live-formed bars (M5 12:00/12:05, M15 11:45/12:00) could not be read before or after reload. |
| GAP integrity | **INCONCLUSIVE** (the real gap that was found: PASS) | Real data gap on 26 Nov: 1m bars 15:05–15:09 are missing. The probe shows `15GAP` on the 15:15 bar, `5OK` on 15:10 and 15:15, and no fake M5 bar for 15:05. The cases "first bar after opening" and "incomplete load" could not be checked. |

**MTF aggregation is NOT approved as the V2 data layer.** No item is PASS on every criterion. No item was found to FAIL. The INCONCLUSIVE items have not been upgraded to PASS.

## Main blocking limit (why the results are INCONCLUSIVE)

1. **IQ Option Web does not render the probe's text.** In View 2/3, every character shows only as a white dot, at both the 478 px and the 1456 px viewport (`t9/t9_web_text_view_renders_dots.jpg`). Only the Desktop app shows the text.
2. **The Desktop app is view-only for Claude.** It is a Chrome PWA, so I can take screenshots but cannot click, scroll or change settings.
3. **The text shows only 1 bar per cycle.** At `Bars per character`=2, one cycle is 220 M1 bars. The bar shown is whichever one closed when the cycle started, so a specific bar cannot be chosen.
4. **View 1 has lines only, no numbers.** The pane scale is about 0.36 price units per pixel, so it can confirm only "no visible change".

So T7, T8 and T9 cannot reach PASS with the current probe without a code change, and code changes during testing are not allowed. See "Suggested next step".

## T7: M15 full OHLC

| T (M15) | Source | O | H | L | C | N | Grid :00/:15/:30/:45 | Result |
|---|---|---|---|---|---|---|---|---|
| 07:15 | Probe View 3 (Desktop) | 3699.95728 | 3702.34794 | 3693.31164 | 3695.34386 | 15 | Yes | — |
| 07:15 | Real 15m candle (web hover, low resolution) | ≈3699.957… | ≈3702.34… | ≈3693.31… | ≈3695.34… | — | — | Consistent as far as it can be read |
| (bar 2) | — | — | — | — | — | — | — | Not obtained |
| (bar 3) | — | — | — | — | — | — | — | Not obtained |

- Earlier result (in `M1_AGGREGATE_PROBE.md`): the real 15m candle at 09:45 matches the aggregate of 1m bars 09:45–09:59. That is a platform check, not the probe's output.
- The M15 line now printing on the Desktop app (T=11:00, from about 11:20) will not be complete until about 15:00.
- Files: `t7_desktop_probe_text_M15_0715.jpg`, `t7_real15m_0715_hover.jpg`, `t7_real15m_0715_readout_lowres.png`

## T8: Live stability (View 1, 11:56:55–12:12:59, 16 min)

| Time (UTC+7) | Event | M5 last CLOSED | M15 last CLOSED |
|---|---|---|---|
| 11:56:55 | Start | Flat (bucket 11:50 is forming) | Flat (bucket 11:45 is forming) |
| 12:00:23 | Bucket change on the 12:00 bar | Steps once, `5OK` marker | Steps once, `15OK` marker |
| 12:00–12:04 | Inside the bucket | Flat in 6 screenshots | Flat |
| 12:05:26 | Bucket change on the 12:05 bar | Steps once, `5OK` | Unchanged (correct) |
| 12:05–12:09 | Inside the bucket | Flat in 7 screenshots | Flat |
| 12:10:31 | Bucket change on the 12:10 bar | Steps once, `5OK` | Unchanged (correct) |
| 12:10–12:12:59 | Inside the bucket | Flat | Flat |
| 12:15:15 (after the 15 min) | Bucket change | Steps, `5OK` | Steps, `15OK` |

- No change was seen in the middle of a bucket, and no GAP marker appeared during this period.
- Not done: numbers for the OHLC of each closed bar before and after each change. View 1 has no numbers, and the web cannot render text.
- Screenshots: about one every 35 s, in `t8/` (26 files, named by time)

## T9: Reload / repaint

| Step | Time | Result |
|---|---|---|
| Before reload | 12:17:09 | `t9/t9_before_reload_1217.jpg` (View 1, 11:25–12:17) |
| Reload | 12:17 | Navigate to `iqoption.com/traderoom` (a new page load). The probe came back automatically, but with the old saved settings (3,1); it was set back to (1,2). |
| After reload | 12:19:34 | `t9/t9_after_reload_1219.jpg` |
| Comparison | — | `t9/t9_compare_top_before_bottom_after.png`: the M5 and M15 steps fall on the same bars and the shapes look the same. |

- Not done: a T/O/H/L/C/N comparison for at least 2 M5 and 2 M15 bars formed during the live test. Their numbers cannot be read (see the main limit).
- Earlier result: the T=07:30 M5 text was identical across 2 separate loads (Desktop), but that is a historical bar, not a live-formed one.

## GAP integrity

| Case | Observed | Result |
|---|---|---|
| Missing M1 bars / market pause | **26 Nov 2026**: hovering shows the 1m bars go 15:00, 15:01, 15:02, 15:03, 15:04, then **15:10** (15:05–15:09 missing) | — |
| → M5 bucket 15:00 (5 bars) | `5OK` on the 15:10 bar | Correct |
| → M5 bucket 15:05 (0 bars) | No marker and no fake bar | Correct (nothing is stitched) |
| → M15 bucket 15:00 (10 bars) | Red `15GAP` (xcross) on the 15:15 bar | Correct |
| → M5 bucket 15:10 (5 bars) | `5OK` on the 15:15 bar | Correct |
| → Restart after data returns | The following buckets show `5OK`/`15OK` normally | Correct |
| First bar after opening the chart | IQ loads more history whenever the chart is scrolled back, so the real first bar could not be reached | INCONCLUSIVE |
| Incomplete M1 load | While loading history, the indicator briefly had a blank section, which filled in once loading finished. No wrong marker was seen, but it could not be checked carefully | INCONCLUSIVE |

- Important note for V2: when a bucket is a GAP, the "last CLOSED" line **still plots the value of the incomplete bucket**, and only the marker says `15GAP`. Any consumer must check N == k (or the gap flag) before using the value.
- Files: `gap/`, including hover images for each bar time

## Problems and limits found

1. The web version does not render the probe's text (dots only). This is the main reason for INCONCLUSIVE.
2. Claude cannot operate the Desktop app (view-only), so it cannot change settings, scroll or reload there.
3. The text shows only 1 HTF bar per cycle (110 or 220 M1 bars), and the bar cannot be chosen.
4. Reloading the web page restores the indicator's settings from an older saved state (it came back as 3,1 instead of 1,2), so check the settings after every reload.
5. After changing `View`, the indicator's scale sometimes stays wrong (for example 1790–3000) until the chart is zoomed.
6. A GAP bucket still produces a "last CLOSED" value (flagged by the marker only).
7. Hover readouts in a narrow pane are low resolution; the 6-decimal values cannot be read reliably.
8. The Desktop app shows closed binary trades on its practice account today. They were not placed during this test; this test placed no trades.

## Suggested next step (requires a new decision; not done)

To make T7, T8 and T9 provable with numbers, a new version of the probe would need an output the web can read, or text that shows a chosen bar. For example:

- An input for "T to display", or
- Text that refreshes every bucket instead of every 110 or 220 bars.

This is a code change, so it needs approval first and then a new round of testing from the beginning.
