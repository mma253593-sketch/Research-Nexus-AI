# TASK 03D P1: IQ Option Web Text Rendering Report

## Overall result: **INCONCLUSIVE** (leaning PASS)

**Rendering itself works.** The probe's text shows on IQ Option Web and can be read character by character without guessing.
- I read a full M5 record and a full M15 record, including bucket, O/H/L/C, N/expected N, status and PRV.

Two parts of the criteria were not completed:
1. **Live bucket change (P1.4):**
   - On the live chart, a new record line started on the correct bar (M5 at 14:05, M15 at 14:15).
   - I could not read the new values live. They print at about 1 character per minute, and the connection to the browser on Pp's computer dropped at about 14:37 (UTC+7), before the values appeared.
   - The bucket change was verified with numbers only on history (11:05 / 11:15).
2. **Statuses:**
   - Only `OK` and `NODATA` were seen.
   - `FORMING` and `GAP` did not appear during the test window.

Following the stop rule, I stopped here: no P2, and no changes to the Probe.

## Test details

| Item | Value |
|---|---|
| Date/time | 28 Nov 2026, 13:36–14:37 (UTC+7) |
| Platform | IQ Option **Web** traderoom (Claude browser pane, 800x522) |
| Account | Practice / Demo ($10,000). No trades were placed. |
| Instrument / TF | XAUUSD (OTC), **1m**, Blitz tab |
| Commit | `f78d8c9` (working tree clean) |
| Probe file | `qcs/platform_probe/m1_aggregate_probe_v2.lua` |
| SHA256 | `e236daecd5f972ff5ca9a57d9bcec4c8fba06be6021dcfd13343d46a02e8eb16` (repo, `git show f78d8c9:` and the project-files copy all match) |
| Code changes | None. Pp pasted the file into IQ and saved it. Only the settings (inputs) were changed. |
| Limit | The code inside IQ cannot be hashed from inside the platform. |

Evidence: `/mnt/project-files/platform_probe/task03d_p1_evidence/` (35 files, `p1_NN_HHMM_*.jpg/png`, where HHMM is UTC+7)

Input order for `AGG-PROBE-V2(...)`: view, sel_on, sel_day, sel_hour, sel_min, rec, rows, place, tsize, dot, dsp, idle, logp

## Results for each setting (P1.2)

| Time | Settings | Result | Evidence |
|---|---|---|---|
| 13:36 | Defaults (2,1,0,7,15,0,3,**1**,4,0,2,20,1) | **No text at all** (the pane is empty) | p1_01 |
| 13:36 | View 1 | Lines and 5OK/15OK markers render, so the script runs on the Web | p1_02 |
| 13:39 | Place 1, Text size **5** | No text | p1_03, p1_03b |
| 13:39 | Place 1, Show shape **1** | No shape and no text | p1_04 |
| 13:39 | Place 1, viewport 1456x900 | No text | p1_05 |
| 13:40 | **Place 2 (absolute)**, size 5, shape 1 | **Characters appear**, above the grey circles | p1_06, p1_06b |
| 13:40 | Place 2, size 5, shape 0 | Clear characters on 2 rows: M15 at the top (orange), M5 at the bottom (blue) | p1_07, p1_07b |
| 13:42 | Place 2, size 5, shape 0, **dsp 1** | Readable, characters do not overlap: `NODATA N0/15` | p1_09, p1_09b |

**Settings that make the text readable on the Web:** View 2, Text place **2**, Text size **5**, Show shape 0, Bars per character **1** (dsp 2 also readable).
**Text place 1 (top/bottom, the default) does not render anything on the Web.**

## Results by item (P1.3)

Settings (2,1,0,**11,0**,0,3,2,5,0,1,20,1), selected bucket 11:00 today. I read by panning the chart from 10:52 to 13:56 (p1_17 to p1_22).

M15 record (the line starts on the 11:15 bar):
```
M15 SEL11:00 B28 11:00-11:14 OK N15/15 O3641.24676 H3643.79050 L3631.19582 C3635.83443
    PRV28 10:45-10:59 OK N15/15 O3650.45876 H3651.88125 L3639.79034 C3641.49190
```
M5 record (the line starts on the 11:05 bar):
```
M5 SEL11:00 B28 11:00-11:04 OK N5/5 O3641.24676 H3643.79050 L3638.49102 C3639.40285
   PRV28 10:55-10:59 OK N5/5 O3644.96072 H3645.30139 L3639.79034 C3641.49190
```

| Item | M5 | M15 | Result |
|---|---|---|---|
| Bucket date/time | `B28 11:00-11:04` | `B28 11:00-11:14` | Readable |
| O/H/L/C (5 decimals) | Readable | Readable | Readable |
| N and expected N | `N5/5` | `N15/15` | Readable |
| Status | `OK`, `NODATA` (p1_09) | `OK`, `NODATA` | Only OK and NODATA seen. **FORMING and GAP not seen** |
| Previous bucket | `PRV28 10:55-10:59 ...` | `PRV28 10:45-10:59 ...` | Readable, separate from the selected bucket |
| M5 vs M15 | Bottom row, blue, starts with `M5` | Top row, orange, starts with `M15` | Clearly separate |

Internal consistency (not a comparison with real candles, which is P3):
- O for M5 equals O for M15 (both buckets start at 11:00).
- The PRV C of both is 3641.49190 (both end at 10:59).
- The PRV L of both is 3639.79034 (it falls in 10:55–10:59).

This P1 does not check whether the values match the real 5m/15m candles. That is P3, which is not approved.

## Bucket change (P1.4)

| Case | Observed | Result |
|---|---|---|
| History, M5 | The record line for the 11:00 bucket starts on the **11:05** bar | Verified (p1_17) |
| History, M15 | The record line starts on the **11:15** bar | Verified (p1_17) |
| Live, M5 (selected 14:00) | Before it closed, the line showed `M5 SEL14:00 B-- --:-- NODATA` (p1_12). On the **14:05** bar a new `M5 ...` line started (p1_13). | Starts on the correct bar. **Values not read** |
| Live, M15 (selected 14:00) | A new `M...` line started on the **14:15** bar (p1_15) | Starts on the correct bar. **Values not read** |
| Live, selected 14:30 | Set at 14:20. I lost the browser connection before 14:35 | Not done |

## Problems and limits found

1. **Text place 1 (top/bottom, the default) renders nothing on the Web**, not even with Show shape = 1. Only place 2 (absolute) works.
2. **Text prints at 1 character per `dsp` bars**, and a line is about 160 characters long:
   - Reading a full record from a live bucket takes about 85–160 minutes (dsp=1).
   - Older buckets (history) can be read immediately by panning.
3. **The line is frozen when it starts.** `FORMING` shows only if a line happens to start while the selected bucket is still forming. In this window, the line started before the bucket opened, so it showed `NODATA` and never `FORMING`.
4. **IQ throttles the tab when the pane is not in front.** Bars 14:10–14:15 showed as a hatched area (not loaded) and filled in when the page was used again (p1_14 → p1_15). In those cases, characters in the backfilled area did not line up with the expected positions. For live observation the pane must stay in front.
5. **The connection to the browser pane on Pp's computer dropped at about 14:37**, so the live test could not be finished.
6. The selection uses only the data that is loaded. 07:15 at the live edge after a reload showed `NODATA` (p1_07) because history did not reach back that far.
7. Typing numbers into the settings fields does not work; only the +/− buttons do. Some clicks do not register, so check with a zoom before applying.
8. The first characters of a line that falls under the indicator title (top left of the pane) are hidden. Pan the chart to read them.

## Overall assessment

| Criterion | Result |
|---|---|
| Text shows on the Web | **Yes** (place 2 only) |
| O/H/L/C, N, expected N readable | **Yes** |
| Status readable | Partly: OK/NODATA yes, FORMING/GAP not seen |
| M5/M15 and current/previous bucket can be told apart | **Yes** |
| Bucket change can be verified without guessing | History: yes. Live: start of the line yes, values not read |

**P1 = INCONCLUSIVE.** Not all criteria were completed:
- The live bucket change was not verified with values.
- FORMING and GAP were not seen.

The cause is the time it takes to print and the dropped connection, not a rendering failure.

Per the order, I stopped. No P2 and no Probe change. MTF is not approved, and the Probe was not put into V2.

## Next step (Owner's decision)
Repeat P1.4 alone with the browser pane kept in front for about 2 hours (from just before a bucket closes until the O/H/L/C has printed).
- This needs no code change.
- Settings: (2,1,0,HH,MM,1,3,2,5,0,1,20,1). rec=1 shortens the line to about 85 characters.
