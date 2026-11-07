# L49 PR results: the lean prefilter in the CPU join (2026-11-07; ivory, CPU only)

**Branch:** `pr/cpu-join-lean-prefilter` on the fork (`wasabipesto-bot/nice`), **one commit, head `03f42b90917c3962e5689e34c5d287ccb9500975`** on fork `pr/cpu-join-fd-tops` `caef70e` (#247). The first version (`d32f579f`, 08:14 UTC) was amended after REVIEW.md (`commit --amend` was allowed) and force-pushed with lease (§ Review follow-up). PR title per the commit: "CPU overlap join: a fixed-point middle-digit prefilter". Not opened as a PR. Body: `L49/PR-BODY.md` (v1 kept as `raw/PR-BODY-v1.md`). Raw logs: `L49/raw/`.

**Worktree:** `.worktrees/pr-cpu-join-lean` (kept, clean; `target/` and `target-ab/` removed). The base worktree `.worktrees/l49-base` (detached at `caef70e`) was created twice for the base binaries and removed each time with its target.

## Review follow-up (09:00 UTC; REVIEW.md "merge with small fixes")

- **M1:** `Top.dm` dropped. The stepped path forms `dh` from `st.dm`, the divided path from `(p / pk) % bmid`; `prefilter_any` (test shapes only) recomputes D from `top.p`. **`Top` is 48 bytes again** (`const _: () = assert!(size_of::<Top>() == 48)`; layout 16 + 8 + 8 + 4×4). `stepped_tops_equal_divided_tops_on_production_fields` still compares D through `dh` (strictly increasing in D).
- **M2:** no window exists for it, and I added none. Full blocks are always seeded at every supported shape: `e² − a² ≥ (b^f0 − 1)·2b^(L−1) ≥ b^(L+f0−1)`, so floor ≥ L + f0 ≥ L + 1 ≥ k + 2 ≥ k2 (since f0 ≥ 1 for FD and k < L). So the stepped path can never see an unseeded top. Unseeded tops on the fixed-point path are clipped blocks of < ~b/2 numbers at a field end, and a join survivor on one is nearly nice. A search of every window start in b20's 4-digit band with a first block of ≤ 10 numbers (t = k = 3, f0 = 1) found none (`raw/m2/search.py`, `search-b20.txt`). Done instead: `the_test_windows_step_their_top_certificates` now asserts `full_floor ≥ k2` for every stepping window, and the body's coverage paragraph says exactly what is pinned. "Never gate" is caught by the reference comparisons. "Always gate" is a no-op on full blocks, is caught only by b10 (general form), and on fixed-point clipped blocks is not pinned.
- **L1:** `lean: mid == 2 && k > mid`; the hoisted `kb`/`bk`/`b2k` locals are gone. The test asserts `join.lean == (join.mid == 2 && jp.k > 2)`. The body and commit message say the fixed-point path covers mid = 2 with k > 2 and everything else keeps the general form, with mid = 1 / k ≥ 2 moving to `prefilter_any` (equivalent; occurs nowhere).
- **Nits:**
  - `Fx` doc: the proof's quotient is now `m`, the local is `fb`, and the cost reads "four multiplies (`A·C`, `P·δ̂` and two by `b`)".
  - `lean_prefilter_matches_the_division_form` now draws sets of every size 0..=b, with the rationale removed.
  - The body says "on the CPU a u64 shift takes any count below 64, on any target".
  - Title "a fixed-point middle-digit prefilter". CHANGELOG: "by reading each pair's digits off a fixed-point fraction, with fewer multiplications and no branches"; `#NNN` placeholder left.
  - The stray blank line is removed, the body proof's quotient renamed `m`, and the `dh` table (L5) added under "Not in this PR".
- **Tests on the amended head** (`raw/unit-tests-v2.txt`, `clippy-v2.txt`, `unit-tests-prodref-v2.txt`, `unit-tests-fullfield-v2.txt`, `unit-tests-fx-exhaustive-v2.txt`):
  - `cargo test --release -p nice_common -p nice_client`: **188 + 22 passed, 6 ignored**.
  - fmt clean; default clippy `-D warnings` clean.
  - `NICE_TEST_CPU_JOIN_REF=3`: ok, 25.8 s.
  - Whole b42: ok, 417,789,835 / 16,879,877, no hits. Reference 107 s, join 18.4 s, stride 164.8 s, all slower because another session's cargo build ran on the VM at the same time.
  - Exhaustive FX: ok, all 663,187,945,915 triples exact, 401 s (slower than the first run's 299 s because of the same outside load).
- **Sanity A/B** (`raw/ab-runs-v2.txt`, `scripts/run_ab_v2.sh` + `run_ab_v2b.sh`): 4 threads, 16 partitions, b60 1e16 and b62 1e17 s0, 4 alternating rounds, ms/partition-thread, #247 / PR. Every run had #247's counts (549,719,536 / 34,926,644 and 550,916,180 / 32,806,057).

| work | r1 (other load: 1-min load 3.7–4.7) | r2 | r3 | r4 | medians r2–r4 |
|---|---|---|---|---|---|
| b60 1e16 | 3154 / 4173 | 2642 / 2298 (×1.150) | 2558 / 2290 (×1.117) | 3258 (load) / 2390 | 2642 / **2298** |
| b62 1e17 s0 | 4304 / 2730 | 2474 / 2234 (×1.108) | 2490 / 2428 (×1.026) | 2422 / 2234 (×1.084) | 2474 / **2234** (×1.107) |

  The PR medians (2298, 2234 ms) are at or below the first version's 3-round medians (2389, 2252 ms): no regression. The other load came from another session (its cargo builds were visible in `top` around 08:43 and 09:00).
- **Perf after M1** (`raw/perf-runs-v2.txt`, 1 thread, 4 partitions, each run gated at load ≤ 2):

| symbol | b60 #247 | b60 PR (48 B) | b60 PR v1 (64 B) | b62 #247 | b62 PR (48 B) | b62 PR v1 (64 B) |
|---|---|---|---|---|---|---|
| top sort | 1.27 % (33 ms) | **1.39 % (33 ms)** | 1.84 % (43 ms) | 1.08 % (26 ms) | **1.27 % (29 ms)** | 1.57 % (35 ms) |
| `survivor` | 21.9 % | 14.5 % | 14.7 % | 22.8 % | 14.5 % | 15.1 % |
| ms / partition | 2598 | 2345 | 2340 | 2445 | 2265 | 2236 |

  The body's Why table now uses these runs (#247 and the final PR).

## Summary (first version d32f579f; still valid for the amended head except the `Top` size)

- **Verdict: keep.** Kill was "< ×1.05 at both production shapes, or any count differs": all four production-shape medians are ≥ ×1.067 and every count is identical.
- **A/B against #247's head `caef70e` (3 rounds, medians, interleaved, order alternating):**
  - **b60 1e16: ×1.091 (1 thread) / ×1.076 (4 threads); b62 1e17 slice 0: ×1.067 / ×1.106.**
  - whole 1e14 fields: b60 ×1.051 / ×1.056; b62 ×1.047 / ×1.064; **b64 ×1.119 / ×1.109**.
- **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.088 (798.5 → 868.5)**, per round 1.069–1.104. Scenarios: b58 weak ×1.097, b58 weak 1 thread ×1.093, b58 strong ×1.053, b60 weak ×1.113, b62 weak ×1.074.
- **Exact:** every timed run has #247's survivors / checked (b60 1e14 1,326,103,590 / 84,383,498; b62 1e14 1,470,093,637 / 87,495,922; b64 1e14 5,702,041,796 / 346,647,759; and the sampled production partitions); whole b42 field 417,789,835 / 16,879,877 (join = reference = stride); opt-in production reference (`NICE_TEST_CPU_JOIN_REF=3`) ok; exhaustive FX over all 663,187,945,915 (A, P, D) at bases 10–64 exact.
- **Profile (perf, 1 thread):** `CpuJoin::survivor` (range test + prefilter) was **22.9 %** of #247's join at b60 1e16 and b62 1e17 s0 (17–18 % on main before #247); **14.7 / 15.1 %** with the PR, ~590 → ~345 ms of a b60 1e16 partition (×1.7), predicting ×1.11 for the partition.
- Matches the brief's estimate (×1.06–1.10) and the L42 prototype (×1.05–1.08 standalone, on main, where the share was smaller).

## What the commit does (first version; the amended head's differences are in § Review follow-up) (`common/src/cpu_join.rs` +329/−41, of which ~200 lines are the new tests; CHANGELOG +1)

- New private `Fx` (FX): `C = ⌈2^32/b²⌉`, `q`, `r` (2^32 = q·b² + r), a `SmallDiv(b²)`; `dh(D) = D·q + ⌈D·r/b²⌉` per kept top; `digits(A, P, dh)` = (hi32(F·b), hi32(lo32(F·b)·b)) with F = A·C + P·dh mod 2^32; `pass(seen, carries, p2, p3, dh)` (FX + MT).
- New `fresh4` (MT): `(seen >> g) & 1` for the four digits ORed, six `!=`, combined with `&` (`#[allow(clippy::needless_bitwise_bool)]`, commented as deliberate). Masks stay natural-order (digit d at bit d): no bit reversal on any target.
- GM: `Top.seed: bool` replaced by `Top.gmask: u64` (seed ? mask : 0); `Top.dh: u32` added. First version: `Top.dm` kept too, 48 → 64 bytes; amended head: `dm` dropped, 48 bytes (const-asserted).
- `CpuJoin.lean = mid == 2 && k > mid` (amended head; the first version wrote it as `mid == 2 && kb == bk == b2k == 0`, the same set; every production shape). `survivor` calls `prefilter` (now the fixed-point form; the name kept so `cubecl_join`'s doc reference to `cpu_join::CpuJoin::prefilter` stays valid) when `lean`, else `prefilter_any`. The old division `prefilter`, the `smid` field and `SmallDiv::rem` are gone (the only `mid != 2 && k > mid` shape would now take `prefilter_any`, which is equivalent there; no field or window has mid ≠ 2).
- `prefilter_digits`' loop moved into a free `fresh_digits(sb, mid, seen, x2, x3)` (same code), so the tests compare the new form against the live division form.
- No knobs, no env toggles, no GPU code touched. `cpu_join.rs` has no feature-gated items.
- **Interpretation notes:** (1) `A·C` is computed per pair (as in the L42 scratch), not stored per listed bottom (Info stays 8 bytes); listed under "Not in this PR". (2) The opt-in exhaustive test reuses #246's env name `NICE_TEST_FX_EXHAUSTIVE` (one switch for both FX exhaustive tests). (3) The commit message and body describe the predicate as #246's; the RC part of #246 is explicitly left out.

## Tests (`raw/unit-tests*.txt`)

| test | result |
|---|---|
| `cargo test --release -p nice_common -p nice_client` on the head | **188 + 22 passed, 6 ignored** (`unit-tests-head.txt`; #247 had 184 + 22, 5 ignored; +4 new, +1 new ignored) |
| new `fx_digits_match_the_division` (CI) | ok: constants and dh exact for every D < b², Δ bound, 446,418,038 (A, P, D) at max A / max P, bases 10–64 |
| new `fx_digits_are_exact_everywhere` (ignored; `NICE_TEST_FX_EXHAUSTIVE=1`) | **ok: 663,187,945,915 triples, 299 s on 4 threads** (`unit-tests-fx-exhaustive.txt`; same count as #246's) |
| new `lean_membership_matches_the_masks` (CI) | ok: every digit 4-tuple per base 10–64 × two random sets (b/4, b/2 digits) + 200,000 random tuples per base vs sets of every size 0..b |
| new `lean_prefilter_matches_the_division_form` (CI) | ok: 10^6 random (A2, A3, P2, P3, D, seen) per base 10–64; asserts both outcomes occur |
| new `production_shapes_take_the_fixed_point_prefilter` (CI) | ok: PLAN_FIELDS b42–b64 lean; windows lean iff k > 2 (b10, b20 k = 2 divide) |
| existing `cpu_join` tests (windows vs reference incl. `mid_mirror`, three scans, stride, slices, prune, stepped = divided tops incl. dh/gmask, b10's 69) | ok |
| opt-in `NICE_TEST_CPU_JOIN_REF=3` | ok, 25.7 s (`unit-tests-prodref.txt`) |
| opt-in whole b42 field `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 / 16,879,877, no hits; reference 86 s, join 12.1 s (#247: 12.9 s), stride 112.9 s (`unit-tests-fullfield.txt`) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default, rustc 1.99.1) | clean on the head (`clippy-head.txt`); GPU-feature clippy not run (code not feature-gated) |

The opt-in prodref / whole-b42 runs and all timings used the build before one cosmetic edit (`hit & 1 == 0` → `(hit & 1) == 0` in `fresh4`, same parse in Rust). Rebuilt at the head: the harness binary is **byte-identical** to the timed one; the client differs in 75 bytes, all the embedded commit SHA (the timed client was built from the uncommitted tree at caef70e) and the GNU build ID (`raw/build-head.log`).

## A/B (`raw/ab-runs.txt`, `ab-summary.txt`; scripts `raw/scripts/run_ab.sh`, `table.py`, harness `l49_ab.rs` = L42's `l42_ab.rs`)

Rounds started 06:14 / 06:42 / 07:10 UTC at 1-min loads 2.00 / 1.88 / 1.97 (gate ≤ 2, none discarded); per-run loads are in the log (4-thread runs lift it to 3–4 by themselves). ms per partition-thread for sampled partitions, wall s for whole fields.

| work | thr | #247 (rounds) | spread | PR (rounds) | spread | × | per round | survivors / checked (both, every run) |
|---|---|---|---|---|---|---|---|---|
| b60 1e16, 4 partitions | 1 | 2405 (2405, 2431, 2387) | 1.8 % | 2204 (2204, 2188, 2221) | 1.5 % | **1.091** | 1.091, 1.111, 1.075 | 136,900,315 / 8,692,368 |
| b60 1e16, 16 partitions | 4 | 2569 (2606, 2515, 2569) | 3.5 % | 2389 (2453, 2389, 2318) | 5.6 % | **1.076** | 1.062, 1.053, 1.108 | 549,719,536 / 34,926,644 |
| b62 1e17 s0, 4 partitions | 1 | 2331 (2322, 2342, 2331) | 0.9 % | 2184 (2232, 2184, 2108) | 5.7 % | **1.067** | 1.040, 1.072, 1.105 | 137,605,271 / 8,194,223 |
| b62 1e17 s0, 16 partitions | 4 | 2491 (2460, 2573, 2491) | 4.6 % | 2252 (2252, 2204, 2291) | 3.9 % | **1.106** | 1.092, 1.168, 1.087 | 550,916,180 / 32,806,057 |
| b60 1e14 whole | 1 | 130.4 s | 0.4 % | 124.1 s | 1.1 % | **1.051** | 1.050, 1.051, 1.066 | 1,326,103,590 / 84,383,498 |
| b60 1e14 whole | 4 | 34.4 s | 1.8 % | 32.6 s | 1.1 % | **1.056** | 1.037, 1.056, 1.068 | same |
| b62 1e14 whole | 1 | 165.8 s | 0.4 % | 158.4 s | 1.8 % | **1.047** | 1.047, 1.045, 1.069 | 1,470,093,637 / 87,495,922 |
| b62 1e14 whole | 4 | 43.7 s | 1.5 % | 41.1 s | 0.8 % | **1.064** | 1.064, 1.052, 1.069 | same |
| b64 1e14 whole | 1 | 339.0 s | 1.1 % | 302.9 s | 1.1 % | **1.119** | 1.109, 1.119, 1.133 | 5,702,041,796 / 346,647,759 |
| b64 1e14 whole | 4 | 87.8 s | 2.0 % | 79.2 s | 1.8 % | **1.109** | 1.135, 1.092, 1.109 | same |

- #247's own times here match L42's PR measurements of #247 (b60 1e16 1t 2405 vs 2410 ms; b62 1e17 s0 1t 2331 vs 2306; b64 1e14 4t 87.8 vs 88.3 s), so the machine was in the same state.
- Single 10-s sampled runs scatter 1.04–1.17 per round; the whole-field rows are tighter (0.4–2 % spreads).
- A pre-A/B screen (`raw/screen-b60e16-1t.txt`, 3–4 alternating runs, not part of the table) gave b60 1e16 ×1.085 and b62 1e17 s0 ×1.095 at 1 thread.

## NiceMark (`raw/nicemark-*.json|stderr`, `nicemark-runs.txt`, `nicemark-summary.txt`; `scripts/run_nicemark.sh`, `nm_table.py`)

`nice_client niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json`, no `--gpu`, nothing uploaded. 4 rounds alternating (r1 base→PR, r2 PR→base, …), 07:38–08:03 UTC, every run started at load 1.85–2.00.

| | #247 (rounds) | PR (rounds) | × (medians) | per round |
|---|---|---|---|---|
| **score** | 798.5 (790.8, 792.1, 813.9, 804.9) | 868.5 (873.1, 863.9, 874.2, 860.1) | **1.088** | 1.104, 1.091, 1.074, 1.069 |
| b58_msd_weak | 1.879e12 | 2.061e12 | 1.097 | 1.132, 1.085, 1.079, 1.087 |
| b58_msd_weak_1t | 5.032e11 | 5.501e11 | 1.093 | 1.100, 1.085, 1.086, 1.100 |
| b58_msd_strong | 1.205e13 | 1.268e13 | 1.053 | 1.061, 1.071, 1.041, 1.047 |
| b60_msd_weak | 4.867e12 | 5.415e12 | **1.113** | 1.158, 1.138, 1.090, 1.082 |
| b62_msd_weak | 5.213e12 | 5.600e12 | 1.074 | 1.072, 1.076, 1.074, 1.029 |

- #247's score here (798.5) equals L42's measurement of #247 (798.7).
- NiceMark's sampling is time-bounded, so the sides sampled different partition counts and their survivor counts cannot be compared (each run's counts are in `nicemark-summary.txt`); exactness rests on the A/B and the tests.

## Profile (`raw/perf-runs.txt`; `scripts/post.sh`)

`perf record -F 1999 -D 3500` (past the ~2.8 s setup), 1 thread, 4 partitions, right after the NiceMark rounds (load 2.2–3.4 at start, not gated; shares, not times, are the point).

| symbol | b60 1e16 #247 | PR | b62 1e17 s0 #247 | PR |
|---|---|---|---|---|
| `scan_avx2` | 36.4 % | 40.3 % | 34.1 % | 38.2 % |
| thread closure (`run`, tops/FD, extend, list inlined) | 28.7 % | 30.5 % | 29.1 % | 31.9 % |
| **`survivor`** | **22.9 %** | **14.7 %** | **22.9 %** | **15.1 %** |
| `get_is_nice_with_known_lsd` | 9.9 % | 11.7 % | 10.9 % | 11.8 % |
| top sort | 1.2 % | 1.8 % | 1.1 % | 1.6 % |
| ms / partition | 2583 | 2340 | 2471 | 2236 |

## Deviations / notes

- No subagents, no Vast, nothing pushed upstream, no PR, no GitHub comments; nothing outside `L49/` and `.worktrees/` written (the base worktree was created and removed under `.worktrees/`).
- The first version needed no amend (the paren edit preceded the first commit). The review follow-up was squashed into the same commit with `commit --amend` (allowed) and pushed with `--force-with-lease` against `d32f579f`.
- The body's RC paragraph cites the L42 prototype's numbers (on main, 1 thread, 2 rounds) and says so; RC was not re-measured on top of #247.
- Not measured: other microarchitectures (AVX-512, Zen 3/4); b64 1e16 partitions (the brief asked for whole b64 1e14 fields only).

## Files

- `PR-BODY.md` (the PR description; CHANGELOG line in the commit with `#NNN`).
- `raw/ab-runs.txt`, `raw/ab-summary.txt`, `raw/screen-b60e16-1t.txt`; `raw/nicemark-*`; `raw/perf-runs.txt`.
- `raw/unit-tests.txt` (pre-paren build, full suites), `raw/unit-tests-head.txt` (head), `raw/unit-tests-prodref.txt`, `raw/unit-tests-fullfield.txt`, `raw/unit-tests-fx-exhaustive.txt`; `raw/clippy-default.txt`, `raw/clippy-head.txt`; `raw/build-base.log`, `raw/build-head.log` (checksums, binary comparison).
- `raw/scripts/`: `run_ab.sh`, `run_nicemark.sh`, `chain.sh`, `post.sh`, `table.py`, `nm_table.py`, `analyze.py`, `l49_ab.rs` (expects binaries in `<worktree>/target-ab/{base,pr}/`, since removed).
