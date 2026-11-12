# T2.3 audit: sampled re-verification of nice-only submissions, bases 58 and 60 (2026-11-12)

DRAFT in progress (results section filled at the end). Labels: **[measured]** read off the API or a run,
**[derived]** computed from measured numbers, **[assumed]** stated without a measurement.

## 1. Census (ivory, public API, read-only)

Scripts `raw/census_fields.py`, `raw/census_subs.py` (bounded id ranges only: fields 206.7M–207.1M by 100k ids
with `base_id=in.(58,60)`; submissions 264.0M–294.5M by 100k ids with `search_mode=eq.niceonly` and the b58/b60
field-id window; 0.2 s apart; User-Agent nice-audit-census; 4 + 305 requests, 3 min). Data
`raw/fields_b58_b60.json`, `raw/subs_b58_b60.json` (compact columns), grouping `raw/census_cells.py`,
table `raw/census_table.md`.

- b58: 93,573 fields of 1e15 [measured], all check_level 1; every field has ≥ 1 qualified nice-only
  submission; 93,585 qualified submissions (12 fields twice).
- b60: 162,076 fields of 1e16 [measured]; 146,268 have a qualified submission; 15,808 (9.76 % of the range) have
  none and are check_level 0, i.e. not searched yet (outside this audit). 159,541 qualified submissions, 13,234
  fields searched more than once (mostly the re-searches after the M4 disqualification).
- 11,473 disqualified submissions (the M4 pre-#222 set), excluded from cells.
- Every qualified submission with valid_numbers > 0 has survivors > 0, and every one with valid_numbers = 0
  has survivors = checked = 0 [measured]: no field shows a join that "dropped everything". Empty fields
  (decided by the CPU-side MSD filter before any join runs) are excluded from the sample populations.
- Cells (GPU family × build): see `raw/census_table.md`. Shares are per submission, so a base's shares
  sum to slightly more than its searched fraction.

