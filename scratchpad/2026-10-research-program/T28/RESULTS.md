# T2.8 early audit of base 62 — INTERIM (handed back at 06:46 UTC, box still running)

Labels: [measured], [derived], [assumed]. Scripts and data in `raw/`.

## 1. Instant fields (ivory, exact big integers) — done
- 8,644 base-62 fields with a zero-survivor, zero-checked submission (census 06:00 UTC, `raw/subs_0615.json`,
  `raw/fields_b62.json`). **All 8,644 proved empty** by an independent check (`raw/instant_check.py`,
  `raw/instant_check.jsonl`, `raw/instant_summary.txt`) [measured]: 8,385 leading digits 1,1 (x < 2^(1/3));
  246 another collision of the top digits the range fixes; 11 Hall on the two first-disagreement positions;
  2 needed subdivision (depth 2 and 4, ≤ 195 nodes). Zero not shown empty.
- Client certificate (54d0aac4, `common/src/overlap_join.rs`): per slice, `top_layer` BFS to depth t−p = 8 of n's
  13 digits (t=10, k=6, p=2); `Base::cert(a, e, cap=6)` = common top digits of a^j, e^j (j=2,3) at positions
  ≥ max(6, ndig(e^j−a^j)), fail on a repeat, then `close_certificate` on the d/d+1 domain at the first disagreement.
  No top in any slice ⇒ nothing launched, run_secs 0. Mine: same mathematics from definitions, no cap, general
  [lo,hi] domains and full two-set Hall, recursive splitting; soundness tests `raw/soundness.txt`.
- Reverse: of 329 run fields, 0 rejected by my field-level check; 1 (207072495, 193 survivors, 32 checked)
  proved empty by subdivision below the client's depth (506 nodes); 328 undecided at a 200k-node budget.

## 2. Re-verification — partial (box queue running)
At 06:45: 14 comparisons, 0 mismatches (2 demoux exact equalities, 6 fleet v3.4.7 + 6 box v3.4.7 within the
overrun-model bound) [measured, `raw/compare.txt`, `raw/compare_detail.jsonl`]. Queue: 41-field sample
(`raw/queue_main_sample.json`), timing round 2, then a 65-field extension (`raw/queue_ext.json`). Rerun
`raw/pull.sh && python3 compare.py` in `raw/` to finish. Hosts block proof: `raw/proof_hosts_block.txt`.

## 3. Release vs main, RTX 3080 (power-capped at 150 W, not raisable) — round 1 done
join run_secs main / v3.4.7: f1 82.1/258.4, f2 79.7/251.3, f3 99.7/298.5 (+ f4, f5 in raw/box/; f0 is a 193-survivor
field, 3.2/4.0). Ratio ≈ ×3.1 per real field [measured]; counts agree (rule 3). Derived: fleet 4060s at 338 s →
≈ 110 s on main, ≈ 3× fields per dollar-hour if the 3080 ratio carries over [assumed].

## 4. Telemetry (`raw/telemetry.txt`)
demoux 9070 XT: 327 real subs, join run_secs median 56.2 (2.5–73.3), setup 6.3, 14 slices, min_slots 5, ≈ 67.7
real fields/h. Fleet (all RTX 4060 so far): 53 real, median 338.8 (3.9–400.8), setup 15.2, 14 slices, ≈ 10.7/h.
Queue-fill frontier 207073160 (last fill 03:59 UTC); 44 % of submitted fields past the boundary instant.
Field-level predictor: 76,883 of the 86,379 remaining fields need a real run. At ≈ 78 real fields/h → ≈ 985 h →
**base 62 ends ≈ 2026-12-26** [derived; assumes constant per-field cost, fleet and demoux as now, no deploy].
Base 60 complete: all 162,076 fields check_level ≥ 1 [measured, `raw/b60_complete.txt`].
