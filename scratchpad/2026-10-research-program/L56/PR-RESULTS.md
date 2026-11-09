# L56 PR results: the seeded full check in the CPU join (2026-11-09; ivory, CPU only)

**Branch:** `pr/cpu-join-seeded-check` on the fork (`wasabipesto-bot/nice`), **one commit, head `0fc06a05769c1a05a708b05165dd922a17141c7c`** (after the review; see Review follow-up), on fork `pr/cpu-join-two-pass-scan` `1cce00d` (L52, on #248, on #247). Title: "CPU overlap join: seed the full check with the digits the join proved". Pushed three times over SSH, each later one an in-place `commit --amend` (allowed) force-pushed with lease: `7012e985` (06:30, first version), `5bab136e` (06:48, the limb-split fix below; **every measurement is of this one**), `5c218b78` (08:59, comments only: the module doc's limb description, two intra-doc links; its harness has byte-identical `.text`, `.rodata` and `.data`, and 3 panic-location line numbers differ in `.data.rel.ro`; the full suite passed on it again, `raw/unit-tests-final.txt`). Not opened as a PR. Body: `L56/PR-BODY.md` (CHANGELOG `#NNN` placeholder left). Raw logs and scripts: `L56/raw/`.

## Review follow-up (09:32–10:00 UTC; REVIEW.md "merge with small fixes", no soundness defect)

- **M-1 (the verdict path's `true` untested beyond one limb):** added the reviewer's `the_verdict_agrees_with_count_mode_on_any_mask` to `cpu_check::tests` as written (two `% 2 == 0` changed to `.is_multiple_of(2)` for clippy; same random stream). On the head: **1,195,784 verdicts, `true` at every limb count** (long division 7,492; NL 1–8: 7,161, 34,454, 23,646, 14,888, 13,234, 12,325, 8,893, 4,195), 0.9 s of the module's 6.6 s. **Under both mutants it fails** and every other test of the module and the join's check tests pass (`raw/mutants.txt`, script `raw/scripts/mutants.sh`, source restored from a copy after each, `git diff` empty after): **M4** (`if !COUNT && $j % 2 == 1 && (sc.repeat || $j == 3)`) fails at b3 n = 80, f0 2, k2 7, ends [8, 8]; **M4b** (`… || $j == 5`, inside the production shape's middle) fails at b3 n = 270, f0 3, k2 8, ends [11, 8]: `nice` false, count mode true. (Run on `13613004` and again on the final head `0fc06a05`; the first logs in `raw/void/13613004-tests/`.)
- **L-1 (b58 explanation):** body now says b58 does not check a larger share of its pairs (5.64 % vs 6.35 % / 5.95 %), but does more checks per µs (1.36 vs 1.25), and that even that predicts only ~×1.13.
- **L-2:** `e = min(2·nl, 10)` at bases 39–64 (8 at b40, 10 from b42) in the module doc and the body, "`e/2 − 1` more quotients (three at b40, four above)" in the body and "three or four more" in the commit message; `n² < (b²)^(2·nl)` in both comments (`cpu_check.rs` column loop and the top-carry `debug_assert`) and the body; the "×1.5–1.8" line now says it is against the chunked long division (the bench table's V3 rows), not the PR's own `long` fallback (one quotient by `b` per digit, never taken in production).
- **N-4, stated early:** a new "What each half is worth" bullet in the body's What: the top-digit seeding buys only ×1.010 / ×1.023 in place (38–41 → 28–29 ns per check on recorded survivors), kept because proved and pinned, droppable for a simpler PR.
- **L-3:** the inner `from` (index into `dx`) in `Base::cert_parts` renamed `run`, with a comment; `Cert::from` / the loop's `first` unchanged.
- **N-3:** comments at `Fx::pass` and `prefilter_digits` that `mid_bits` re-reads their digits. **Not done:** N-1 (ZST trace), N-2 (`limbs` visibility, `bf0`), N-5, N-6 (body length / `<details>`); "Not in this PR" now says the second of the two PRs to land should unify `Magic` (§6).
- **L-4:** fmt/clippy re-run on the final head (`raw/clippy-default-v2.txt`, both clean); the earlier logs stay for `5bab136`.
- **Tests on `0fc06a05`** (`raw/unit-tests-v2*.txt`, script `raw/scripts/tests_v2.sh`): `cargo test --release -p nice_common -p nice_client` **197 + 22 passed, 8 ignored**; `NICE_TEST_CPU_JOIN_REF=3` ok; whole b42 ok (417,789,835 / 16,879,877, hits [], reference 85 s, join 10.3 s, stride 111.5 s); `cargo fmt --all --check` and `cargo clippy -p "*" --all-targets -- -D warnings` clean (the first clippy run on `13613004` flagged the two `% 2 == 0` in the new test; fixed).
- **Code generation unchanged:** the harness built at `0fc06a05` and at the timed `5bab136e` has identical `.text`, `.rodata` and `.data`; 68 bytes of `.data.rel.ro` differ (panic locations' line numbers, shifted by the added lines) (`raw/codegen-v2.txt`). So every timing below stands for the head.
- **Cleanup:** the worktree's `target/` (2.2 GB) and `/tmp/l56cg` removed at 09:58; the worktree is clean at `0fc06a05`; no perf was run, so no `~/.debug` entries; `df -h /` 15 GB free.
- **Commit:** amended in place (`raw/commit-msg.txt`; the previous message in `raw/commit-msg-v1.txt`), `13613004` → `0fc06a05` (local), pushed over SSH with `--force-with-lease=…:5c218b78` at 09:57. The previous body and results are kept as `raw/PR-BODY-v1.md`, `raw/PR-RESULTS-v1.md`.

## Summary

- **Verdict: keep.** Kill was "< ×1.05 on top of L52 at both production shapes, any survivor/checked/hit count change, or any digit-level test failure": the production-shape medians are **×1.117 / ×1.136 (1 thread) and ×1.139 / ×1.109 (4 threads)** at b60 1e16 / b62 1e17 slice 0, every count equals L52's binary's, and every digit-level test passes (including 19.65 M recorded survivors of the timed shapes, the opt-in exhaustive quotient test, and a debug build with overflow checks).
- **A/B against `1cce00d`** (3 rounds, interleaved, alternating, medians; `raw/ab-runs.txt`, `ab-summary.txt`, `ab-runs-whole1t.txt`, `ab-summary-whole1t.txt`):
  - b60 1e16: **×1.117** (1 t, 1743 → 1560 ms/partition), **×1.139** (4 t, 1899 → 1667);
  - b62 1e17 slice 0: **×1.136** (1 t, 1693 → 1491), **×1.109** (4 t, 1769 → 1596);
  - b58 1e15: ×1.168 (1 t, 32 p), ×1.167 (4 t, 128 p);
  - whole 1e14 fields, 4 threads: b60 ×1.069 (29.1 → 27.2 s), b62 ×1.106 (38.8 → 35.1 s), b64 ×1.110 (69.1 → 62.3 s);
  - whole 1e14 fields, 1 thread: b60 ×1.090 (113.1 → 103.8 s), b62 ×1.088 (146.3 → 134.5 s), b64 ×1.119 (266.0 → 237.8 s).
- **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.155 (1091.0 → 1259.6)**, per round 1.170, 1.139, 1.168, 1.121; b58 weak ×1.191, b58 weak 1 t ×1.160, b58 strong ×1.106, b60 weak ×1.107, b62 weak ×1.148 (`raw/nicemark-summary.txt`). The base equals L52's own PR-side median (1091.0).
- **The check's share (perf, 1 thread, `raw/perf-runs.txt`): 14.8 % → 4.9 % (b60 1e16), 16.1 % → 4.7 % (b62 1e17 s0)**; per check 119 → 36 ns and 133 → 34 ns in place. Counters (`raw/perfstat-summary.txt`): cycles −8.6 % / −12.7 %, IPC 2.85 → 3.12 / 2.79 → 3.17, instructions flat, mispredictions 24.3 → 22.8 M / 20.7 → 19.1 M a partition.
- **On recorded survivors (`raw/check-bench.txt`):** old 125.5 / 131.6 ns; **this PR 28.5 / 29.3 ns (×4.40 / ×4.49)**; the same column form without the top's digits 38.2 / 41.0 (×3.29 / ×3.21); L50's V3 form 50.3 / 50.8 with the same seeds (×2.50 / ×2.59) and 60.5 / 61.1 with the 16 low digits (×2.07 / ×2.15). Digits converted before the verdict 9.62 / 9.77 → 1.83 / 1.80; 96.2 / 96.6 % decided by the first four middle digits; 0.072 / 0.058 % reach n³. Every checked survivor of the timed shapes is gated (its top's digits are used); 16.0 / 17.8 top digits on average.
- **In place, the variants (`raw/ab-variants.txt`, 3 rounds, 1 t, 4 binaries interleaved):** the PR over the same check without the top's digits ×1.010 (b60) / ×1.023 (b62); over the V3 form with the same seeds ×1.051 / ×1.028.
- **Exactness verdict:** the check takes as known exactly (a) positions 0..k of n² and n³ (the bottom's mask, as listed), (b) positions k..k2 (the prefilter's four digits, recomputed by the same `Fx::digits` / `mid_values`), and (c) only where the top gates the prefilter (`floor >= k2`), the certificate's **pre-closure common digits** (`Cert::common`) at positions `from[j]..s_j` — never the closure-forced digits (L47's warning), whose d/d+1 position (`from[j] − 1`) is converted as a middle digit. The tests pin it: on every checked survivor of the windows, of 2 partitions of each PLAN field (CI) and of 4 partitions of each timed shape (opt-in, 19.65 M), the seeds are asserted equal to the true digits at those positions (and disjoint), the count mode's middle digits equal the true digits position by position, its distinct count equals `get_num_unique_digits`, its repeat flag equals `!get_is_nice`, and the verdict equals `get_is_nice`; the quotients are exact by the closed-form bound for every divisor, block-worst over the inputs in CI, and every x < 2^31 opt-in (114 divisors, 493 s).

## What the commit does (+1299/−69 in the first version; `common/src/cpu_check.rs` new, `cpu_join.rs`, `cpu_top_fd.rs`, `overlap_join.rs`, `lib.rs`, CHANGELOG +1)

- **`overlap_join.rs`:** new `Cert { mask, common, from }` and `Base::cert_parts` (the old `cert` body, now also returning the pre-closure common digits and each power's lowest common position: `c0`, or the position above the d/d+1 digit, or `s_j` if none); `Base::cert` = `cert_parts(..).map(|c| c.mask)` (same signature, same result: every GPU/reference caller unchanged). Test `cert_reference` returns the parts (positions read from both endpoints' digits); `the_fast_certificate_matches_the_reference` compares `cert_parts` with it and `cert` with its mask.
- **`cpu_top_fd.rs`:** `TopFdSetup::cert` returns `Option<Cert>` (the same `pos` it already walked; no new work in the loop); `stepped_certificates_equal_the_divided_ones` compares whole `Cert`s against `cert_parts`.
- **`cpu_join.rs`:**
  - `Top`: `gmask: u64` → `gate: bool` (+ `Top::gmask()`), new `seed: u64` (= `Cert::common` if gate, else 0) and `ends: [u8; 2]` (= `Cert::from` if gate, else `(s2, s3)`), `pc: u32` → `u8`. Still 48 bytes (const assert). `CpuJoin::top()` builds it (inline(always)) for FD and clipped tops alike.
  - `survivor` (inlined in pass 2) now ends in a call to `full_check` (`#[inline(never)]`): `low = bmask | mid_bits(..)` (the prefilter's four digits again: `Fx::digits` ×2 at the lean shape, `mid_values` + `divrem_small` otherwise; `prefilter_any` was split into `mid_values` + `prefilter_digits` for that), the record (tests only), `check.nice(p, r0, low, seed, ends)`, `n` built only for a hit or the record.
  - The test record is now `Vec<Checked { n, p, r0, low, top, ends }>`.
  - `get_is_nice` / `get_is_nice_with_known_lsd` no longer used by the join (the stride walk still uses the latter).
- **`cpu_check.rs` (new, ~900 lines with tests):** `Magic` (u32 multiply-high quotient, exact below 2^31; shift for powers of two), `Magic64` (u64, exact below 2^63; the power-of-two form is `m = 2^(64 − t)`, `s = 64`), `Check { b, k2, w, nl, by_b, by_bb, by_pe, bf0, eh, by_l }`:
  - `Check::new(b, l, s2, s3, f0, k2, p_max)` picks the column form (`nl` = limbs of `n`, 1–8) iff `nl <= 8`, `P_max < 2^63`, `e > f0` and `b^(l−e) < 2^31` for `e` = the largest even `<= 2nl` with `b^e < 2^63` (10 at b39–64), and the column bound `nl(b⁴+b²) < 2^31`; else the long division (`nl = 0`). Rejects shapes whose cube could exceed 2^256.
  - `nice()` (`#[inline(always)]`, a `match` on `nl` into `columns::<NL, false>`, or `long::<false>`); `count()` (tests): the same code with `COUNT = true` (no early exit, records every digit taken by power and position).
  - `limbs::<NL>`: `(H, W) = by_pe.divrem(P)`; `L = W·b^f0 + r0`; `q_i = ⌊L/b^(2i)⌋` by `by_l[i]` (independent); limb `i < eh` = `q_i − q_{i+1}·b²`; limbs above from `H` by `by_bb`.
  - `columns::<NL, COUNT>`: n² columns written out by a `macro_rules!` for `j = 0..16` (`if j < 2·NL`), so every index is a constant; `Scan::take(j, pos, d, on)` is branch-free (`bit = (on as u64) << d`, `repeat |= seen & bit != 0`); the early exit tests `repeat` after odd columns; then n³ = n²·n by a loop of columns, breaking at `ends[1]`.
  - Tests (below).

**Interpretation notes:**
- **Design D's arithmetic on the CPU (measure both forms):** both forms were measured on recorded survivors (below): the column form, after writing its columns out, ×1.7–1.8 faster than L50's V3 form (U256, two quotients by b⁴, five digits per quotient by b⁵) with the same seeds; before writing them out the two tied (~50 ns). The column form is in the PR. In place, the V3 form is ×1.03–1.05 slower than the PR (variants table).
- **`join_check` (pr/check-d 7d6956f) is not importable:** it is on the GPU stack (`pr/top-fd-round2`), not on this branch's base. Its `magic(d)` construction is reused in spirit (`Magic` is the same `⌈2^(32+s)/d⌉`, `s = ⌊log₂ d⌋`, with the same block-worst and opt-in exhaustive tests), and its limb split was redone for the CPU's inputs (`P`, `r0` instead of the record's `w6`). "Not in this PR" in the body names the merge.
- **The seed flag:** the CPU `Top`'s gate is exactly #248's `gmask != 0` condition (FD tops: `full_floor >= k2`; clipped tops: their own `cert_floor >= k2`). At every production shape and the 1e16/1e17 shapes every checked survivor's top is gated (counts in the tests).
- **No knobs**: none added; the column/long choice is by shape at setup.

## Measurements

Machine, harness, fields, gates, rounds: as L52 (`raw/scripts/run_ab.sh`, `run_nicemark.sh`, `perf.sh`; the harness is L52's `l52_ab.rs`). Base = `1cce00d` (L52's head) built untouched in this worktree; PR = `5bab136`.

**Main A/B** (`raw/ab-runs.txt`; rounds started at 1-min load 1.29 / 1.86 / 1.97, all OK; other sessions ≤ 1 core at any run start, the most 0.64 core at r1 b62 4 t PR, which is that case's slow round):

| case | base (rounds) | spread | PR (rounds) | spread | speed-up | per round | counts (both sides, every round) |
|---|---|---|---|---|---|---|---|
| b60 1e16, 1 t, 4 p | 1743 (1718, 1743, 1759) | 2.4 % | 1560 (1537, 1560, 1594) | 3.6 % | **×1.117** | 1.118, 1.117, 1.104 | 136,900,315 / 8,692,368 |
| b62 1e17 s0, 1 t, 4 p | 1693 (1693, 1654, 1727) | 4.3 % | 1491 (1494, 1482, 1491) | 0.8 % | **×1.136** | 1.133, 1.116, 1.159 | 137,605,271 / 8,194,223 |
| b60 1e16, 4 t, 16 p | 1899 (1888, 1923, 1899) | 1.8 % | 1667 (1656, 1667, 1681) | 1.5 % | **×1.139** | 1.140, 1.154, 1.129 | 549,719,536 / 34,926,644 |
| b62 1e17 s0, 4 t, 16 p | 1769 (1802, 1769, 1759) | 2.4 % | 1596 (1683, 1596, 1550) | 8.4 % | **×1.109** | 1.071, 1.109, 1.135 | 550,916,180 / 32,806,057 |
| b58 1e15, 1 t, 32 p | 415 (415, 409, 418) | 2.1 % | 355 (355, 350, 356) | 1.9 % | ×1.168 | 1.168, 1.170, 1.173 | 319,652,260 / 18,029,967 |
| b58 1e15, 4 t, 128 p | 444 (433, 453, 444) | 4.3 % | 381 (381, 437, 367) | 18.5 % | ×1.167 | 1.139, 1.035, 1.210 | 1,277,611,815 / 72,056,777 |
| b60 1e14 whole, 4 t (s) | 29.1 (30.0, 29.1, 29.1) | 3.1 % | 27.2 (27.2, 27.1, 27.2) | 0.5 % | ×1.069 | 1.102, 1.072, 1.067 | 1,326,103,590 / 84,383,498 |
| b62 1e14 whole, 4 t (s) | 38.8 (38.9, 38.8, 38.4) | 1.3 % | 35.1 (35.3, 35.1, 35.0) | 0.7 % | ×1.106 | 1.103, 1.106, 1.096 | 1,470,093,637 / 87,495,922 |
| b64 1e14 whole, 4 t (s) | 69.1 (69.1, 67.5, 69.7) | 3.2 % | 62.3 (62.3, 63.0, 61.4) | 2.6 % | ×1.110 | 1.110, 1.071, 1.136 | 5,702,041,796 / 346,647,759 |

**Whole 1e14 fields, 1 thread** (`raw/ab-runs-whole1t.txt`; separate block after NiceMark, rounds at 1.89 / 1.15 / 1.53; no other process ≥ 20 % at any run start): b60 113.1 → 103.8 s **×1.090** (1.076, 1.067, 1.091); b62 146.3 → 134.5 s **×1.088** (1.076, 1.088, 1.090); b64 266.0 → 237.8 s **×1.119** (1.139, 1.082, 1.119); counts as above.

Every count equals L52's (`L52/PR-RESULTS.md`, the same shapes) and L49's for #248; no hits anywhere.

**NiceMark** (`raw/nicemark-*.json`, `nicemark-runs.txt`, `nicemark-summary.txt`; 07:23–07:48, every run started at 1-min load 1.93–2.00, no other process ≥ 20 %): score 1091.0 (1092.0, 1090.0, 1081.5, 1120.2) → 1259.6 (1277.7, 1241.2, 1263.6, 1255.7), **×1.155**. Scenarios as in the summary above. Counts within a side agree wherever the sampled prefix matches.

**perf** (`raw/perf-runs.txt`, 3 events at 1999 Hz, 1 thread, 2 partitions, from 3.5 s; symbol shares):

| | b60 base | b60 PR | b62 base | b62 PR |
|---|---|---|---|---|
| `CpuJoin::run` (tops, lists, pass 2 with the prefilter) | 61.3 % | 67.1 % | 61.0 % | 67.3 % |
| `pass1_avx2` | 18.7 % | 21.5 % | 14.3 % | 17.6 % |
| **check** (`get_is_nice_with_known_lsd` / `full_check` with `Check::nice` inlined) | **14.8 %** | **4.9 %** | **16.1 %** | **4.7 %** |
| tops sort | 1.7 % | 1.8 % | 1.5 % | 1.8 % |

(The first head 7012e98 had `Check::nice` out of line at 6.0 / 7.9 % plus `full_check` 1.4 / 1.5 % and the stray iterator 0.7 / 0.8 %: `raw/void/perf-runs-7012e98.txt`.)

**Counters** (`raw/perfstat-runs.txt`, `perfstat-summary.txt`; 2 rounds, 4 partitions, per partition):

| shape | side | instructions | branches | mispredictions | cycles | IPC | ms/partition |
|---|---|---|---|---|---|---|---|
| b60 1e16 | base | 1.623e10 | 2.009e9 | 24.3 M (1.21 %) | 5.691e9 | 2.85 | 1746 |
| b60 1e16 | PR | 1.622e10 | 1.999e9 | 22.8 M (1.14 %) | 5.199e9 | 3.12 | 1601 |
| b62 1e17 s0 | base | 1.541e10 | 1.872e9 | 20.7 M (1.11 %) | 5.532e9 | 2.79 | 1695 |
| b62 1e17 s0 | PR | 1.530e10 | 1.876e9 | 19.1 M (1.02 %) | 4.831e9 | 3.17 | 1481 |

The instruction count is flat: the column form runs about as many instructions per check as the old one, but they are independent products and quotients instead of a chain of dependent 64-bit quotients, so IPC rises. (The perf-record instruction shares in this VM track the cycle shares and are not used.)

**The check alone on recorded survivors** (`raw/check-bench.txt`; `raw/scripts/l56_scratch_bench.rs` appended to `cpu_join.rs` only while it ran; every checked survivor of the first 2 sampled partitions; 3 repetitions; ns a check, medians):

| form | seeds | b60 1e16 | × | b62 1e17 s0 | × |
|---|---|---|---|---|---|
| old `get_is_nice_with_known_lsd` | 6 low | 125.5 (123.5, 125.5, 126.2) | 1 | 131.6 (133.7, 131.1, 131.6) | 1 |
| L50 V3 (U256, b⁴ ×2, b⁵ chunks) | 16 low | 60.5 | ×2.07 | 61.1 | ×2.15 |
| L50 V3 | low + top | 50.3 | ×2.50 | 50.8 | ×2.59 |
| columns | 16 low | 38.2 | ×3.29 | 41.0 | ×3.21 |
| **columns (PR)** | **low + top** | **28.5** | **×4.40** | **29.3** | **×4.49** |

Verdict differences between all forms: 0. Before the commit, with the columns as runtime loops, the column form was 47–50 ns (with top) and tied V3 (`raw/check-bench-pre.txt` has the version after writing them out, 28–31 ns).

**Variants in place** (`raw/ab-variants.txt`, `ab-variants-summary.txt`; builds `raw/build-variants.log` from `raw/scripts/variants.py`, reverted after; 08:41–08:45, rounds at 1.92 / 1.24 / 1.13; ms/partition, 1 thread, 4 partitions):

| case | base | PR | no top digits | V3 form, same seeds | PR over no-top | PR over V3 |
|---|---|---|---|---|---|---|
| b60 1e16 | 1780 | 1612 (×1.104) | 1627 (×1.094) | 1694 (×1.051) | ×1.010 | ×1.051 |
| b62 1e17 s0 | 1686 | 1528 (×1.103) | 1564 (×1.078) | 1571 (×1.073) | ×1.023 | ×1.028 |

Counts identical across the four binaries.

## Tests (all on 5bab136, release, `raw/unit-tests*.txt`, `raw/clippy-default.txt`; script `raw/scripts/tests.sh`)

| test | result |
|---|---|
| `cargo test --release -p nice_common -p nice_client` | **196 + 22 passed, 8 ignored** (`unit-tests.txt`); 1cce00d had 190 + 22, 6 ignored: +5 `cpu_check` tests, +1 `cpu_join` CI test, +2 opt-in |
| `magic_quotients_are_exact_on_the_checks_inputs` (CI) | ok: `Magic::bound() >= 2^31` for all 124 divisors b, b² (b 3–64); block-worst exact over [0, 2^31) by b², [0, b²) by b; `Magic64::bound() >= 2^63` for every b^i < 2^63, b 3–64, and `/` agreement on edges + 2,000 random x each |
| `magic_quotients_are_exact_everywhere` (opt-in `NICE_TEST_CPU_CHECK_EXHAUSTIVE=1`) | **ok: "114 divisors exact on every x below 2^31"**, 493 s on 4 threads (`unit-tests-exhaustive.txt`) |
| `the_columns_take_the_digits_of_the_square_and_the_cube` (CI) | ok: 274,661 (n, shape) pairs through the column form (each also by the long division), bases 3–64, every length, 10 shapes (f0, k2), digits vs malachite, random ends (`unit-tests-new.txt`) |
| `the_seeded_check_decides_what_the_full_check_decides` (CI) | ok: 298,153 decisions (12 nice: 69 in its shapes and ends), 81 near-nice n (≥ b − 2 distinct digits, every one of the bands of b10–22), b23–64 band ends, digit-length edges of n² and n³, adversarial, 3,000 random per base |
| `sixty_nine_is_nice`, `production_shapes_take_the_columns` (CI) | ok (b40–64 production shapes all columnar) |
| `the_full_check_is_exact_on_production_survivors` (CI) | ok: every checked survivor of 2 partitions of each PLAN_FIELDS field: b42 18,491, b50 650,120, b57 163,500, b60 46,474, b62 45,090, b64 164,685 (all gated) |
| windows (`cpu_join_matches_the_reference_on_the_test_windows`, now with `assert_checked` on every recorded survivor) | ok; 17 of 18 windows columnar (k2 3–7, f0 0–3), the b64 window (P ≥ 2^63) long |
| `the_full_check_is_exact_on_production_shapes` (opt-in `NICE_TEST_CPU_CHECK_REF=4`) | ok (`unit-tests-checkref.txt`): b60 1e16 8,692,368; b62 1e17 s0 8,194,223; b58 1e15 2,247,150; b60 1e14 93,515; b62 1e14 90,465; b64 1e14 334,391 checked survivors, all gated, all exact (19.65 M, 2 min on 4 threads) |
| `NICE_TEST_CPU_JOIN_REF=3` | ok, 32.7 s (`unit-tests-prodref.txt`) |
| whole b42 `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 / 16,879,877, hits []; 4 threads: reference 87 s, join 10.2 s, stride 112.5 s (`unit-tests-fullfield.txt`) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default, rustc 1.99.1, the harness moved out) | clean (`clippy-default.txt`) |
| debug build (overflow checks and `debug_assert!`s on, incl. `top()`'s gate ⇒ `from >= k2`): `cpu_check` tests, the windows, the production survivors, stepped tops, b10's 69 | ok, 9 passed, 59 s (`unit-tests-debug.txt`) |

The same suite also passed on the first head 7012e98 (`raw/void/7012e98-tests/`).

## Process, timeline (UTC), cleanup

- 05:45 brief read; `df -h /` 15 GB free (13 GB during the work, peak target 2.2 GB); 05:51 worktree `.worktrees/l56-seeded-check` on a new local branch `pr/cpu-join-seeded-check` at `1cce00d`, `CARGO_TARGET_DIR` inside it; L52's harness copied in as the uncommitted `common/examples/l52_ab.rs`.
- 05:51–05:57 base binaries (`raw/build-base.log`). The first base build ran while I made my first source edits, so I restored the pristine sources and rebuilt (05:55); the two builds' binaries are byte-identical (md5 `b274b8d9…` harness, `7345e2e2…` client), and the client embeds `1cce00d`.
- 05:57–06:28 implementation. In-place checks on the way (b60 1e16, 1 thread, single runs): the first column form (runtime loops) ×1.05–1.06 and 47 ns a check on recorded survivors; writing the n² columns out (macro) → 29 ns, ×1.09–1.13 in place; the V3 form with the same seeds stayed at ~51 ns (`raw/check-bench-pre.txt`).
- 06:30 commit `7012e985`, pushed over SSH; PR binaries built (`raw/build-pr.log`; the client embeds the commit).
- 06:32–06:45 chain, first run: tests all ok (`raw/void/7012e98-tests/`), perf (`raw/void/perf-runs-7012e98.txt`) showed `Check::nice` out of line and a 0.7 % symbol `Take<Enumerate<Zip<…Magic64…>>>::nth`: the clippy-driven iterator form of the limb-split loop (`skip(1)`) compiled to a call. Stopped in the main A/B's round 1 (`raw/void/ab-runs-7012e98-aborted.txt`).
- 06:46–06:49 fix: back to an index loop (`#[allow(clippy::needless_range_loop)]` with a comment), `Check::nice` `#[inline(always)]` (now inside `full_check`), the column test prints its count; module tests, clippy, fmt; `commit --amend` → `5bab136e`; `push --force-with-lease=…:7012e985` over SSH; PR binaries rebuilt (md5 `30615df0…` harness, `5cf50fe5…` client; client embeds `5bab136e`).
- 06:49–08:4x chain on `5bab136` (`raw/scripts/chain.sh`, `raw/chain.log`): tests 06:49–06:57, perf 06:58–07:00, main A/B 07:00–07:22, NiceMark 07:23–07:48, 1-thread whole fields 07:49–08:39. Every run under `nice -n 19`; gates at 1-min load ≤ 2 (≤ 1.5 for perf); no round marked DISCARD; other sessions' processes at run starts ≤ 1 core (one 4-thread b62 PR run started with 0.64 of a core taken).
- 08:39–08:57 `raw/scripts/post.sh`: debug-build tests (08:40–08:41), the variant builds and their A/B (08:41–08:45), the recorded-survivor bench (08:45–08:47), the exhaustive quotient test (08:47–08:56).
- 08:57–09:00 comments-only amend (module doc's limb description had kept the first design's `W`/`H` split; two intra-doc links to cfg(test) items, one public doc linking a private item); fmt, clippy, `cpu_check` tests, the full suite again; pushed `5c218b78` (lease on `5bab136e`).
- 09:01–09:03 cleanup: the worktree's `target/` (peak 2.9 GB), `bin/` (base, pr, wip, notop, v3 binaries) and the uncommitted `common/examples/l52_ab.rs` removed (the copy in `raw/scripts/` is L52's file; the worktree copy had only been reformatted by `cargo fmt --all`); `/tmp/l56-wip` (perf data, scratch copies) removed; the four perf build-id cache entries my first exploratory `perf record` runs (without `-N`) added under `~/.debug` removed. The worktree is kept, clean, at `5c218b78`. `df -h /`: 15 GB free (as at the start). Nothing else touched: the main checkout (only `git worktree add` registered the worktree), the fleet, the server, L53/L54 and the rest of the scratchpad; no PRs, no GitHub comments, no subagents; no Vast.

## Files

- `L56/PR-BODY.md`, this file.
- `raw/build-base.log`, `raw/build-pr.log` (cargo output, md5s), `raw/build-variants.log`, `raw/commit-msg.txt`.
- `raw/unit-tests.txt`, `unit-tests-new.txt`, `unit-tests-checkref.txt`, `unit-tests-prodref.txt`, `unit-tests-fullfield.txt`, `clippy-default.txt` (on 5bab136), `unit-tests-debug.txt`, `unit-tests-exhaustive.txt` (5bab136 + the comment edits), `unit-tests-final.txt` (the full suite on 5c218b78).
- `raw/perf-runs.txt` (perf record + per-symbol shares), `raw/perfstat-runs.txt` (counters), `raw/ab-runs.txt` + `ab-summary.txt`, `raw/ab-runs-whole1t.txt` + `ab-summary-whole1t.txt`, `raw/nicemark-r*-{base,pr}.json/.stderr`, `nicemark-runs.txt`, `nicemark-summary.txt`, `raw/ab-variants.txt` + `ab-variants-summary.txt`, `raw/check-bench.txt`, `raw/check-bench-pre.txt` (before the commit), `raw/chain.log`.
- `raw/void/`: the first head's tests, perf and the aborted A/B.
- `raw/scripts/`: `build.sh`, `tests.sh`, `perf.sh`, `run_ab.sh`, `run_nicemark.sh`, `chain.sh`, `post.sh`, `variants.py` (the scratch variants), `l56_scratch_bench.rs` (the recorded-survivor bench, appended to `cpu_join.rs` only while it ran), `l52_ab.rs` (L52's harness), `perfsym.py` (L50's), `table.py` / `nm_table.py` / `perftable.py` (L52's), `vartable.py`.
