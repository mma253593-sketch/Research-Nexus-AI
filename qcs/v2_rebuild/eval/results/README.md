# Evaluation results

| File | Data | Meaning |
|---|---|---|
| `SYNTHETIC_framework_check.md` | `test/fixtures.lua` MIXED, seed 11 (deterministic, generated) | Shows that the framework runs end to end. **Not a market result.** |

No real-market report exists yet. No verified historical XAUUSD M1 data could be obtained in
the development environment. To produce one:

```bash
lua5.3 qcs/v2_rebuild/eval/backtest.lua --csv <xauusd_m1.csv> --payout <verified payout> \
       --out qcs/v2_rebuild/eval/results/<source>_<from>_<to>.md --signals /tmp/signals.jsonl
```

Record the data source, the export method and the time zone next to the report. The report
already prints the file's byte count and FNV-1a checksum.
