# L42 PR results: FD top certificates in the CPU join (2026-11-06; ivory, CPU only)

**Branch:** `pr/cpu-join-fd-tops` on the fork (`wasabipesto-bot/nice`), on upstream main `6f060a9`. Head
**`c8099d94c3b6e3b1136600d5fd183c54eaaf7def`** (10:27 UTC). Not opened as a PR. Body: `L42/PR-BODY.md`. Raw logs:
`L42/raw/pr/`.
- `fba54316` (08:47): the change.
- `c8099d94` (10:27): the review follow-up (REVIEW.md S1 + nits N1–N5), as a **second commit, pushed as a
  fast-forward**. The asked-for `commit --amend` + force-push was refused by this session's permission guard
  (history rewrite), so I did not force it. Squash the two when opening the PR (or squash-merge), or amend +
  `push --force-with-lease` from a session allowed to.

**Worktree:** `.worktrees/pr-cpu-join-fd` (kept; `target/` and `target-ab/` removed at the end).

## Summary

- **A/B against main 6f060a9 (3 rounds, medians, counts identical in every run):**
  - production shapes: **b60 1e16 ×1.274 (1 thread) / ×1.289 (4 threads); b62 1e17 slice 0 ×1.264 / ×1.246**;
  - whole 1e14 fields: b60 ×1.224 / ×1.224; b62 ×1.155 / ×1.163;
  - b64 (follow-up): 1e16 partitions ×1.039 / ×1.068; whole 1e14 field ×1.076 / ×1.088.
- **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.186 (673.2 → 798.7)**. Per scenario: b58 weak ×1.141,
  b58 weak 1 thread ×1.142, b58 strong ×1.099, b60 weak ×1.336, b62 weak ×1.241.
- **Exact.** Every top equals `Base::cert`'s path: 1.86 M random stepped blocks at bases 10–64 and 3.70 M production tops.
  The opt-in production reference (16 partitions a field) and the whole-b42-field test (417,789,835 / 16,879,877) pass.
  Every timed run has main's survivor and checked counts.
- Better than the prototype's FD (×1.10–1.20, mean ×1.16), and about where the prototype's FD + lean prefilter was
  (×1.23–1.29). That comes from the plan's tightening: 14 instead of 21 word-adds a step, two long conversions per seed
  instead of five, and stepped `pc`/`dm` instead of u128 division on kept tops.

## Review follow-up (10:27, commit `c8099d94`)

- **S1:** new `cpu_top_fd::tests::a_carry_runs_through_words_of_b_minus_1` (REVIEW.md's test, doc comment added).
  Mutation check (`raw/pr/mutation-s1.txt`): passes on the branch; **fails under M1** (ripple past the carry word
  dropped, `if co && false`) and **fails under M4** (`add_word`'s `cout = c1`, dropping the `cin` carry); passes again
  after reverting (file `cmp`-identical to the pre-mutation copy).
- **N1:** `cpu_join.rs`'s module doc names `cpu_top_fd` in backticks instead of an intra-doc link.
  `cargo doc -p nice_common --no-deps`: 7 warnings, the same 7 as main's (`raw/pr/doc-pr.txt`, `doc-main.txt`); none
  from this PR. So "no warnings" holds for the PR's code; main's own seven remain.
- **N2:** `Top` derives `Clone, Copy` always and `Debug, PartialEq, Eq` under `cfg_attr(test, …)`.
- **N3:** `Base::poww` private again, with a `pub(crate) fn poww(&self) -> &[W4]` accessor (`cpu_top_fd` copies it).
- **N4:** `MAX_STEPS` private.
- **N5:** the production test's `step_by(… .max(1))`; the last live partition is added only if not already sampled.
- Tests on the follow-up: `cargo test --release -p nice_common -p nice_client` **184 + 22 passed**, 5 ignored
  (`raw/pr/unit-tests-v2.txt`); `cargo fmt --all --check` and default clippy `-D warnings` clean. The new tests' counts
  on the head are unchanged (1,860,723 blocks; 3,698,847 production tops; `raw/pr/unit-tests-stats-v2.txt`).
- **S2 body fixes:** NiceMark b60/b62 rows are "a 3e15 window of a 1e16 field"; #240's top kernel ×1.48–1.61;
  "413,250 kept; 243,907 seeded"; the method states the round loads (no rounds were discarded); the no-overflow bullet
  describes the overshoot path (steps once past P, re-seeds; addends from below P; values below phi + h fit).
- **b64 A/B** (below) added, plus a body paragraph: the CPU takes the stepped path at b64, unlike #240's GPU kernel,
  because `Base::cert` divides by a runtime base at every base.
- CHANGELOG `#NNN` placeholder left as asked.

## What the commit does

- New `common/src/cpu_top_fd.rs` (587 lines of code and docs + a 123-line test module): `TopFdSetup` (per
  `CpuJoin`, `None` when the field's arrays would not fit or b ≤ 6) and `TopFd` (per `tops()` call, one key).
  - Step: five packed digit-array adds (`detailed_fd`'s biased add with a runtime bias), each over its addend's words
    at the slice's last prefix plus the carry word, rare ripple out of line: **14 word-adds a step at b60/b62** (15 at
    b64), against the prototype's 21; plus three `W4` adds.
  - Walk: step while P is at most `MAX_STEPS` = 4 steps (4h) above the last stepped prefix of the same call; anything
    else (first prefix of a key, gap > 4h, a walk that does not land on P) seeds.
  - Seed: P, P², P³ converted by `Div64` (b^8, b^4) + `SmallDiv` per digit; DS, DC, DDC built from P's and P²'s
    digits by shifts and adds (two long conversions instead of the prototype's five); d2, d3, Δ3 by `W4` products;
    `pc`, `dm` by the old u128 expressions.
  - Certificate: `Base::cert`'s scan on the stepped digits; c0 from a bit-length table + one compare; the carry test
    screened in f64 (margin 2^-20, error < 1e-11), exact `W4` fallback inside the margin or for k < 2.
  - Kept tops: `pc` and `dm` step by one with P (h = b^o ≡ 1 mod b − 1; `dm`'s divisor b^(k−f0) is h), no u128
    division except at seeds.
- `CpuJoin::tops`: unclipped blocks through the FD state; clipped blocks (P = plo, phi) and non-FD fields through
  `Base::cert`, state untouched. No env knobs, no prototype code.
- `overlap_join.rs`: `poww`, `ndig_w`, `digit_range_mask`, `close_certificate` made `pub(crate)`; `cpu_join.rs`'s
  `SmallDiv` `pub(crate)`; `Top` derives `Debug, PartialEq, Eq` (tests).
- Interpretation note: the brief's "seed by `Base::cert`'s division" is implemented as the seed converting P, P², P³
  with the base's `Div64` reciprocal division (no hardware `div`); the seed slot is then certified from the fresh
  state, not by `Base::cert` (cheaper, and the test proves it equal).

## Tests

All on the head's code (`raw/pr/unit-tests*.txt`):

| test | result |
|---|---|
| `cargo test --release -p nice_common -p nice_client` | 183 + 22 passed at `fba54316` (`unit-tests.txt`); 184 + 22 at `c8099d94` (`unit-tests-v2.txt`); 5 ignored (opt-in) |
| new `cpu_top_fd::a_carry_runs_through_words_of_b_minus_1` (follow-up) | ok; fails under mutations M1 and M4 (`mutation-s1.txt`) |
| new `cpu_top_fd::stepped_certificates_equal_the_divided_ones` (b10–64, random band fields, all f0 with w < 2^32, o = 1–3, runs of 200 with gaps 1/2–4/5–24/backwards) | ok: 1876 setups, 1,860,723 blocks (413,250 kept, 243,907 seeds), 3654 clipped left out (`unit-tests-stats.txt`) |
| new `cpu_join::stepped_tops_equal_divided_tops_on_production_fields` (PLAN_FIELDS b42–b64, 25 partitions each, every key) | ok: 3,698,847 tops equal (`unit-tests-stats.txt`) |
| new `the_test_windows_step_their_top_certificates` | ok (FD on every window but b10's) |
| `check_partitions` (now also FD tops = divided tops): windows test | ok |
| opt-in `cpu_join_matches_the_reference_on_production_fields`, `NICE_TEST_CPU_JOIN_REF=3` and `=16` | ok, ok (26 s, 137 s) (`unit-tests-prodref.txt`) |
| opt-in whole b42 field, `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 survivors, 16,879,877 checked, no hits; reference 85 s, join 12.9 s, stride 113.7 s on 4 threads (`unit-tests-fullfield.txt`) |
| b60 / b62 1e14 whole fields, main vs PR binaries | identical: 1,326,103,590 / 84,383,498 and 1,470,093,637 / 87,495,922 (every round, 1 and 4 threads) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default features, 1.99.1) | clean (GPU-feature clippy not run, per the brief) |

## A/B against main

`raw/pr/ab-runs.txt` (script `raw/pr/scripts/run_ab.sh`, harness `raw/pr/scripts/l42_ab.rs`, summary
`scripts/analyze.py`). Two release binaries (main `6f060a9`, PR head code), interleaved, order alternating per round
(r1 main→PR, r2 PR→main, r3 main→PR), 3 rounds, medians. Round start loads (1-min): 1.64, 1.87, 1.97 → all kept
(the script waits up to 6 min for ≤ 2 before a round). Partition rows are ms per partition-thread; whole-field rows are
wall seconds.

| work | thr | main (rounds) | spread | PR (rounds) | spread | ×  | per round | survivors / checked (both) |
|---|---|---|---|---|---|---|---|---|
| b60 1e16, 4 partitions | 1 | 3069 (3058, 3069, 3071) | 0.4 % | 2410 (2423, 2410, 2339) | 3.5 % | **1.274** | 1.262, 1.274, 1.313 | 136,900,315 / 8,692,368 |
| b60 1e16, 16 partitions | 4 | 3270 (3196, 3675, 3270) | 14.6 % | 2536 (2499, 2555, 2536) | 2.2 % | **1.289** | 1.279, 1.439, 1.289 | 549,719,536 / 34,926,644 |
| b62 1e17 s0, 4 partitions | 1 | 2914 (2914, 2918, 2904) | 0.5 % | 2306 (2330, 2302, 2306) | 1.2 % | **1.264** | 1.251, 1.267, 1.259 | 137,605,271 / 8,194,223 |
| b62 1e17 s0, 16 partitions | 4 | 3044 (3149, 3032, 3044) | 3.9 % | 2443 (2476, 2443, 2436) | 1.6 % | **1.246** | 1.272, 1.241, 1.250 | 550,916,180 / 32,806,057 |
| b60 1e14 whole | 1 | 159.5 s (160.8, 158.9, 159.5) | 1.2 % | 130.3 s (129.7, 130.3, 130.9) | 0.9 % | **1.224** | 1.239, 1.219, 1.219 | 1,326,103,590 / 84,383,498 |
| b60 1e14 whole | 4 | 41.9 s (42.2, 41.3, 41.9) | 2.2 % | 34.3 s (34.9, 34.3, 34.1) | 2.4 % | **1.224** | 1.210, 1.205, 1.231 | same |
| b62 1e14 whole | 1 | 191.3 s (190.9, 192.2, 191.3) | 0.7 % | 165.6 s (165.6, 165.7, 163.7) | 1.2 % | **1.155** | 1.153, 1.160, 1.168 | 1,470,093,637 / 87,495,922 |
| b62 1e14 whole | 4 | 50.2 s (51.5, 49.9, 50.2) | 3.1 % | 43.2 s (43.1, 43.2, 43.2) | 0.2 % | **1.163** | 1.195, 1.156, 1.163 | same |

- One outlier: main's r2 b60 1e16 4-thread run (3675 ms; load 1.75 at its start), not used by the median.
- Against the prototype (SCOPING §3.4, FD alone, same harness shapes): b60 1e16 1t 2616 → 2410 ms here, b62 1e17 s0 1t
  2659 → 2306 ms (prototype FD + lean prefilter: 2407 / 2360).
- The b62 1e14 field gains least of b60/b62: per-partition bottom work (extend + lists) is 39 % of main's join there.

### b64 (review follow-up; `raw/pr/ab-runs-b64.txt`, `scripts/run_ab_b64.sh`)

Same harness and method; main = `6f060a9`, PR = the follow-up's code (`c8099d94`; hot path identical to `fba54316`).
Field start 41242006262957161709568 (`PLAN_FIELDS`' b64, the GPU PRs' b64 field). Round start loads 2.00, 1.99, 1.40
(all ≤ 2, none discarded); per-run loads were higher after 4-thread runs (load average lag).

| work | thr | main (rounds) | spread | PR (rounds) | spread | × | per round | survivors / checked (both, every round) |
|---|---|---|---|---|---|---|---|---|
| b64 1e16, 4 partitions | 1 | 4921 (4921, 4963, 4878) | 1.7 % | 4738 (4738, 4719, 4749) | 0.6 % | **1.039** | 1.039, 1.052, 1.027 | 379,345,226 / 23,071,561 |
| b64 1e16, 16 partitions | 4 | 5260 (5260, 5365, 5208) | 3.0 % | 4925 (4925, 4941, 4905) | 0.7 % | **1.068** | 1.068, 1.086, 1.062 | 1,537,343,011 / 93,506,501 |
| b64 1e14 whole (4096 partitions) | 1 | 359.0 s (359.0, 359.1, 351.7) | 2.1 % | 333.7 s (336.8, 331.5, 333.7) | 1.6 % | **1.076** | 1.066, 1.083, 1.054 | 5,702,041,796 / 346,647,759 |
| b64 1e14 whole | 4 | 96.1 s (96.1, 134.0, 91.6) | 44.2 % | 88.3 s (88.3, 89.8, 87.7) | 2.4 % | **1.088** | 1.088, 1.493, 1.045 | same |

- **b64: ×1.04–1.09**, a gain but far below b60/b62's ×1.25–1.29. Not profiled. Likely reasons: b64 partitions carry
  ~2.8× b60's survivors at 1e16 (more scan/survivor time, so a smaller certificate share), and 9.3–9.5 % of b64's
  prefixes seed (prototype measurement) against 2.3 % at b60.
- Outlier: main's r2 4-thread b64 1e14 run (134.0 s), other load; not in the median.
- The b64 1e14 counts equal the GPU PRs' main counts for the same field (#240's body, its `NICE_TEST_JOIN_COMPARE` row: 5,702,041,796 /
  346,647,759).

## NiceMark CPU nice-only

`raw/pr/nicemark-r{1..4}-{main,pr}.json` (+ `.stderr`), log `raw/pr/nicemark-runs.txt`
(`nice_client niceonly --threads 4 --benchmark-secs 150 --benchmark-json`, no `--gpu`; nothing uploaded). 4 rounds,
order alternating (r1 main→PR, r2 PR→main, …); every run started at load ≤ 2.0 (1.85–2.00).

| | main (rounds) | PR (rounds) | × (medians) | per round |
|---|---|---|---|---|
| **score** | 673.2 (674.1, 672.8, 673.6, 649.5) | 798.7 (792.6, 804.8, 806.6, 780.2) | **1.186** | 1.176, 1.196, 1.197, 1.201 |
| b58_msd_weak | 1.630e12 | 1.859e12 | 1.141 | 1.127, 1.160, 1.141, 1.139 |
| b58_msd_weak_1t | 4.349e11 | 4.968e11 | 1.142 | 1.124, 1.161, 1.165, 1.113 |
| b58_msd_strong | 1.078e13 | 1.184e13 | 1.099 | 1.111, 1.082, 1.111, 1.084 |
| b60_msd_weak | 3.754e12 | 5.016e12 | **1.336** | 1.293, 1.345, 1.340, 1.332 |
| b62_msd_weak | 4.181e12 | 5.191e12 | **1.241** | 1.235, 1.250, 1.244, 1.367 |

- main's r4 ran low on b58 weak and b62 (likely other load); medians barely move (main's score 673.6 without r4).
- The JSONs' `build_sha` reads `6f060a9` on both sides: the PR binary was built from the worktree before the commit
  (code identical to `fba54316`; binary sizes 10,990,600 main vs 11,011,328 PR). NiceMark's sampled-partition counts
  differ between sides by design (time budget), so its survivor counts are not comparable; exactness is from the
  harness runs and the tests.

## Notes

- Machine: ivory, AMD EPYC-Rome (Zen 2) VM, 4 vCPUs, AVX2 only, every run `nice -n 19`. Other load: ~25 idle-ish
  Claude CLI processes and other agents' occasional git/ssh (1-min load ~1.0–1.9 when idle).
- Follow-up builds used a scratch detached worktree `.worktrees/l42-main-ab` at `6f060a9` for main's harness (removed
  afterwards with its target).
- Builds: main client 1 min 10 s (after the deps' 1 min 29 s), target peaked at 2.0 GB (with clippy); `df -h /` 15 GB
  free at start, 13 GB at the peak. `target/` and `target-ab/` removed at the end; worktree kept.
- The A/B harness (`raw/pr/scripts/l42_ab.rs`) is a public-API-only copy of the scoping's `l42_prof` (no phase
  counters); it was copied into `common/examples/` only for the builds and is not on the branch.
- Not done: GPU-feature clippy (brief: default only); an AVX-512 or Zen 3/4 measurement (no such machine in scope).
- Not tuned: `MAX_STEPS` = 4 (plan value).