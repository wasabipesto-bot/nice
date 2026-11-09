# L56 brief: the seeded full check in the CPU join (2026-11-09; L50 roadmap item 2; CPU on ivory)

## Why

`L50/ROADMAP.md`: after the two-pass scan (L52, PR-ready at 1cce00d on #248) the CPU join's full
check is ~11–12 % of a production-shaped partition and recomputes digits the join already knows.
The L50 prototype seeded the check's mask with the 16 digits the join has (the bottom's k and the
top's certificate) and started the digit scan at position 8: ×1.04–1.07 alone, **×1.07–1.11 on top
of the two-pass scan**; on 4.1 M recorded survivors the check alone is ×2.1 in that form and ×2.3
using design D's base-b² columns (`L47/SCOPING.md` §3, now implemented on the GPU in `pr/check-d`
7d6956f: `join_check` host module with the magic-multiply digit extraction and its exhaustive
tests — reuse that host code if it is importable from the CPU join; it lives in `common`). Kill:
< ×1.05 on top of L52 at both production shapes, or any survivor/checked/hit count change, or
any digit-level test failure.

## Deliverable

Branch `pr/cpu-join-seeded-check` on the fork, one squashed commit on fork
`pr/cpu-join-two-pass-scan` 1cce00d: the CPU join's full check of a survivor starts from the
digits already proved (bottom digits 0..k from the entry's mask; the top's certified digits
where the seed flag allows — careful: GPU L47's review found that seeding with the record's
*mask* is unsound because it includes closure-forced digits; the CPU `Top` has `gmask`/`seed`
semantics from #248 — use exactly what is proved) and converts only the middle digits, with
design D's base-b² column arithmetic if it is cheaper on the CPU (measure both forms). No knobs.
Tests: a count-mode comparison of the seeded check against the existing full check on every
survivor of real partitions (b60/b62 production shapes, b58 1e15, the 1e14 fields) and on
adversarial n (band edges, digits ≥ 32, near-nice numbers, b10's 69 must still be found); the
digit-extraction exactness tests (exhaustive over the constants' input range, CI-sized + opt-in);
the existing `cpu_join` tests; whole b42 (417,789,835 / 16,879,877, hits identical); the b60/b62/
b64 1e14 fields with counts identical to L52's binary; `NICE_TEST_CPU_JOIN_REF=3`. fmt; clippy -D
warnings default.

## Process (ivory, `nice -n 19`, worktree from 1cce00d with its own `CARGO_TARGET_DIR`; `df -h /` first; release only, 7 GB RAM; remove targets at the end)

1. A/B vs 1cce00d: two release binaries, interleaved with alternating order, medians, 3 rounds
   (loads noted), at 1 and 4 threads on b60 1e16-shaped and b62 1e17-shaped partitions (harness in
   `L52/raw/scripts/`), b58 1e15, whole b60/b62/b64 1e14 fields; CPU nice-only NiceMark 4 rounds.
   perf (1 thread): the check's share before/after.
2. `L56/PR-BODY.md` in `L38/PR-BODY.md`'s style (what / why with the profile share / soundness:
   which digits are proved and by what, why the seeded scan decides exactly the same predicate /
   measurements / exactness / not in this PR). Stacked on the two-pass scan (on #248, on #247).
   No program/scratchpad references. CHANGELOG line under "## Unreleased" ending
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
3. Push (HTTPS fallback to the fork if SSH is refused; never push to wasabipesto/nice). Do not open
   the PR. `L56/PR-RESULTS.md`, raw logs in `L56/raw/`. Rules: no PRs, no GitHub comments, no
   subagents, nothing else in the scratchpad or outside your worktree touched (the main checkout
   runs the live fleet). Hard stop 12:30 UTC.
