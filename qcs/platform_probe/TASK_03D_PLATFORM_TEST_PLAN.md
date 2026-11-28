# TASK 03D: Platform Test Plan (IQ Option)

**Start only after the Owner approves.** Use a Demo/Practice account only, and do not trade. Do not edit the code during the test.
Probe: `qcs/platform_probe/m1_aggregate_probe_v2.lua`
sha256: `e236daecd5f972ff5ca9a57d9bcec4c8fba06be6021dcfd13343d46a02e8eb16`

At every step, record the date, time (UTC+7), platform (Web or Desktop), screenshots, and the input values used.
Every result must be one of PASS / FAIL / INCONCLUSIVE. Never record PASS by guessing.

## 0. Preparation
1. Open the XAUUSD (OTC) **1m** chart. Open the real **5m** and **15m** charts in separate tabs.
2. Paste the whole Probe v2 and add the indicator `AGG-PROBE-V2`.
3. Check that the `NOT 1M CHART` marker does **not** appear (View 1).

## P1. Does the text show on the Web? (point E, must be done first)

| Step | Settings | Record |
|---|---|---|
| P1.1 | View 2, Text place 1, Text size 4 (large), Show shape 0, dsp 2 | Do you see **readable** characters in the bottom row (M5) and the top row (M15)? |
| P1.2 | If they cannot be read: try Text size 5 (huge), then dsp 3–5, then zoom the chart | Note which setting first makes them readable |
| P1.3 | If they still cannot be read: Show shape 1 | Do you see the shapes (to confirm a row exists even though the text is not drawn)? |
| P1.4 | Text place 2 (absolute) | Compare with place 1 |
| P1.5 | Do the same on Desktop | Compare Web and Desktop |
| P1.6 | Is there an error about too many plots? | If yes, try Rows 1 and Rows 2 separately |

- **PASS P1**: text can be read on the Web at one or more settings, and the settings are recorded.
- **FAIL P1**: no setting shows text on the Web. If so, go on to P2.

## P2. Other channels (if P1 fails, or to compare)

| Step | Settings | Record |
|---|---|---|
| P2.1 | View 4 (Snapshot), Select by time = a bucket that has already closed | Does the error message show up, and does it include the record text? |
| P2.2 | `print() selected records` = 1 | Where does the output appear (script log / console)? Can it be read? |
| P2.3 | View 3 (Candles) | Are the candles drawn? Does hovering show OHLC values? |

Record which channel can be read **with evidence**. Do not claim a channel works without a screenshot.

## P3. Bucket Selection + Numeric (prepares T7)
Choose the channel that is readable (from P1 or P2).

1. Select by time = 1, with day = today, and choose at least **3 M15 buckets** that have already closed (for example 07:15, 09:45, 10:30). Change only `Select hour`/`Select minute`, one bucket at a time.
2. For each bucket, record T(B)/O/H/L/C/N/status for both the selected bucket and PRV.
3. Hover over the real 15m and 5m candles for the same times and record their O/H/L/C (6 decimals).

| T (M15) | Probe O/H/L/C | N | Status | Real 15m O/H/L/C | Match? |
|---|---|---|---|---|---|

- **PASS T7**: at least 3 bars, O/H/L/C match within displayed precision, N = 15, status OK, and B times are on the :00/:15/:30/:45 grid.
- Use the same check for the M5 values on each line.

## P4. Live / Closed (prepares T8)
1. Select by time = 1 and choose an **M5 bucket that has not opened yet** (for example 5 minutes ahead of now).
2. Watch View 1 (for markers) and View 2 (for text). Screenshot about every minute.
3. Record:
   - Before the bucket opens: the text shows `NODATA`.
   - During the bucket (if a status line starts): `FORMING`, and the `M5 last CLOSED (OK)` line **does not change** within the bucket.
   - On the first bar of the next bucket: the `SEL5` marker appears and the record line starts **on that bar**, with status OK and N5/5.
   - Whether a `DIFF` marker appears live (it shows whether the platform skips the final tick).
4. Repeat for one M15 bucket.

- **PASS T8**: last CLOSED does not change within a bucket, changes only when a new bucket starts, the record values match the real candle, and a GAP is never shown as usable.
- Any movement before the bucket closes is a **FAIL**. Record the time.

## P5. Reload / Repaint (prepares T9)
1. Before reloading, record the P4 lines for at least 2 M5 buckets and 2 M15 buckets that formed live (screenshots + numbers).
2. Reload the page (or restart the app) and reopen the 1m chart. **Check the indicator settings again**; in 03C they reverted to older values.
3. Select the same buckets again and record the numbers.

- **PASS T9**: T/O/H/L/C/N/status are the same as before reloading, for every bucket.
- If live values ≠ values after reload, that is a **FAIL**. Record the DIFF markers that appeared live.

## P6. GAP (real gaps only)
1. Scroll back to find gaps that really exist. The gap on **26 Nov 2026, 15:05–15:09** is already known from TASK 03C.
2. Select 26 Nov 15:00 (day = 26, hour = 15, minute = 0):
   - Expected M15: `B26 15:00-15:14 GAP N10/15`
   - Expected M5 15:00: `OK N5/5`
   - Selecting minute = 5 for M5 should give `NODATA` (no bars).
3. Check that the `M15 last CLOSED (OK)` line is **empty** while bucket 15:00 is the last closed one, and that the red `15GAP` marker appears on the 15:15 bar.
4. The first bucket of the chart: scroll to the oldest data and check whether it shows GAP when it is incomplete. If you cannot reach the oldest bar, record INCONCLUSIVE.

## P7. Summary
Fill in this table and attach the screenshots:

| Item | Result | Evidence |
|---|---|---|
| P1 Web text | | |
| P2 Other channels | | |
| T7 (P3) | | |
| T8 (P4) | | |
| T9 (P5) | | |
| GAP (P6) | | |

Approve the MTF aggregation only if T7, T8, T9 and GAP are all PASS. That approval is the Owner's decision.
