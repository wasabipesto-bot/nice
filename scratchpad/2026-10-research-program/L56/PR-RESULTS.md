# L56 PR results: the seeded full check in the CPU join (2026-11-09; ivory, CPU only)

**Branch:** `pr/cpu-join-seeded-check` on the fork (`wasabipesto-bot/nice`), **one commit, head `5bab136e6d3e2899cd7109ebe5b2f39cd451877e`**, on fork `pr/cpu-join-two-pass-scan` `1cce00d` (L52, on #248, on #247). Title: "CPU overlap join: seed the full check with the digits the join proved". First pushed head `7012e985` (SSH, 06:30); amended in place (`commit --amend` was allowed) and force-pushed with lease (`--force-with-lease=…:7012e985`) at 06:48 over SSH, after perf showed an out-of-line iterator call in the limb split (below). Not opened as a PR. Body: `L56/PR-BODY.md` (CHANGELOG `#NNN` placeholder left). Raw logs and scripts: `L56/raw/`.

## Summary

SUMMARY

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
- **Design D's arithmetic on the CPU (measure both forms):** both forms were measured on recorded survivors (below): the column form, after writing its columns out, ×1.7–1.8 faster than L50's V3 form (U256, two quotients by b⁴, five digits per quotient by b⁵) with the same seeds; before writing them out the two tied (~50 ns). The column form is in the PR. In place, the V3 form IN-PLACE-V3.
- **`join_check` (pr/check-d 7d6956f) is not importable:** it is on the GPU stack (`pr/top-fd-round2`), not on this branch's base. Its `magic(d)` construction is reused in spirit (`Magic` is the same `⌈2^(32+s)/d⌉`, `s = ⌊log₂ d⌋`, with the same block-worst and opt-in exhaustive tests), and its limb split was redone for the CPU's inputs (`P`, `r0` instead of the record's `w6`). "Not in this PR" in the body names the merge.
- **The seed flag:** the CPU `Top`'s gate is exactly #248's `gmask != 0` condition (FD tops: `full_floor >= k2`; clipped tops: their own `cert_floor >= k2`). At every production shape and the 1e16/1e17 shapes every checked survivor's top is gated (counts in the tests).
- **No knobs**: none added; the column/long choice is by shape at setup.

## Measurements

MEAS

## Tests (all on 5bab136, release, `raw/unit-tests*.txt`, `raw/clippy-default.txt`; script `raw/scripts/tests.sh`)

| test | result |
|---|---|
| `cargo test --release -p nice_common -p nice_client` | **196 + 22 passed, 8 ignored** (`unit-tests.txt`); 1cce00d had 190 + 22, 6 ignored: +5 `cpu_check` tests, +1 `cpu_join` CI test, +2 opt-in |
| `magic_quotients_are_exact_on_the_checks_inputs` (CI) | ok: `Magic::bound() >= 2^31` for all 124 divisors b, b² (b 3–64); block-worst exact over [0, 2^31) by b², [0, b²) by b; `Magic64::bound() >= 2^63` for every b^i < 2^63, b 3–64, and `/` agreement on edges + 2,000 random x each |
| `magic_quotients_are_exact_everywhere` (opt-in `NICE_TEST_CPU_CHECK_EXHAUSTIVE=1`) | EXH |
| `the_columns_take_the_digits_of_the_square_and_the_cube` (CI) | ok: 274,661 (n, shape) pairs through the column form (each also by the long division), bases 3–64, every length, 10 shapes (f0, k2), digits vs malachite, random ends (`unit-tests-new.txt`) |
| `the_seeded_check_decides_what_the_full_check_decides` (CI) | ok: 298,153 decisions (12 nice: 69 in its shapes and ends), 81 near-nice n (≥ b − 2 distinct digits, every one of the bands of b10–22), b23–64 band ends, digit-length edges of n² and n³, adversarial, 3,000 random per base |
| `sixty_nine_is_nice`, `production_shapes_take_the_columns` (CI) | ok (b40–64 production shapes all columnar) |
| `the_full_check_is_exact_on_production_survivors` (CI) | ok: every checked survivor of 2 partitions of each PLAN_FIELDS field: b42 18,491, b50 650,120, b57 163,500, b60 46,474, b62 45,090, b64 164,685 (all gated) |
| windows (`cpu_join_matches_the_reference_on_the_test_windows`, now with `assert_checked` on every recorded survivor) | ok; 17 of 18 windows columnar (k2 3–7, f0 0–3), the b64 window (P ≥ 2^63) long |
| `the_full_check_is_exact_on_production_shapes` (opt-in `NICE_TEST_CPU_CHECK_REF=4`) | ok (`unit-tests-checkref.txt`): b60 1e16 8,692,368; b62 1e17 s0 8,194,223; b58 1e15 2,247,150; b60 1e14 93,515; b62 1e14 90,465; b64 1e14 334,391 checked survivors, all gated, all exact (19.65 M, 2 min on 4 threads) |
| `NICE_TEST_CPU_JOIN_REF=3` | ok, 32.7 s (`unit-tests-prodref.txt`) |
| whole b42 `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 / 16,879,877, hits []; 4 threads: reference 87 s, join 10.2 s, stride 112.5 s (`unit-tests-fullfield.txt`) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default, rustc 1.99.1, the harness moved out) | clean (`clippy-default.txt`) |
| DEBUGTESTS | |

The same suite also passed on the first head 7012e98 (`raw/void/7012e98-tests/`).

## Process, timeline (UTC), cleanup

- 05:45 brief read; `df -h /` 15 GB free (13 GB during the work, peak target 2.2 GB); 05:51 worktree `.worktrees/l56-seeded-check` on a new local branch `pr/cpu-join-seeded-check` at `1cce00d`, `CARGO_TARGET_DIR` inside it; L52's harness copied in as the uncommitted `common/examples/l52_ab.rs`.
- 05:51–05:57 base binaries (`raw/build-base.log`). The first base build ran while I made my first source edits, so I restored the pristine sources and rebuilt (05:55); the two builds' binaries are byte-identical (md5 `b274b8d9…` harness, `7345e2e2…` client), and the client embeds `1cce00d`.
- 05:57–06:28 implementation. In-place checks on the way (b60 1e16, 1 thread, single runs): the first column form (runtime loops) ×1.05–1.06 and 47 ns a check on recorded survivors; writing the n² columns out (macro) → 29 ns, ×1.09–1.13 in place; the V3 form with the same seeds stayed at ~51 ns (`raw/check-bench-pre.txt`).
- 06:30 commit `7012e985`, pushed over SSH; PR binaries built (`raw/build-pr.log`; the client embeds the commit).
- 06:32–06:45 chain, first run: tests all ok (`raw/void/7012e98-tests/`), perf (`raw/void/perf-runs-7012e98.txt`) showed `Check::nice` out of line and a 0.7 % symbol `Take<Enumerate<Zip<…Magic64…>>>::nth`: the clippy-driven iterator form of the limb-split loop (`skip(1)`) compiled to a call. Stopped in the main A/B's round 1 (`raw/void/ab-runs-7012e98-aborted.txt`).
- 06:46–06:49 fix: back to an index loop (`#[allow(clippy::needless_range_loop)]` with a comment), `Check::nice` `#[inline(always)]` (now inside `full_check`), the column test prints its count; module tests, clippy, fmt; `commit --amend` → `5bab136e`; `push --force-with-lease=…:7012e985` over SSH; PR binaries rebuilt (md5 `30615df0…` harness, `5cf50fe5…` client; client embeds `5bab136e`).
- 06:49–08:4x chain on `5bab136` (`raw/scripts/chain.sh`, `raw/chain.log`): tests 06:49–06:57, perf 06:58–07:00, main A/B 07:00–07:22, NiceMark 07:23–07:48, 1-thread whole fields 07:49–WHOLEEND. Every run under `nice -n 19`; gates at 1-min load ≤ 2 (≤ 1.5 for perf); no round marked DISCARD; other sessions' processes at run starts ≤ 1 core (one 4-thread b62 PR run started with 0.64 of a core taken).
- POSTLINE

## Files

- `L56/PR-BODY.md`, this file.
- `raw/build-base.log`, `raw/build-pr.log` (cargo output, md5s), `raw/build-variants.log`, `raw/commit-msg.txt`.
- `raw/unit-tests.txt`, `unit-tests-new.txt`, `unit-tests-checkref.txt`, `unit-tests-prodref.txt`, `unit-tests-fullfield.txt`, `unit-tests-debug.txt`, `unit-tests-exhaustive.txt`, `clippy-default.txt`.
- `raw/perf-runs.txt` (perf record + per-symbol shares), `raw/perfstat-runs.txt` (counters), `raw/ab-runs.txt` + `ab-summary.txt`, `raw/ab-runs-whole1t.txt` + `ab-summary-whole1t.txt`, `raw/nicemark-r*-{base,pr}.json/.stderr`, `nicemark-runs.txt`, `nicemark-summary.txt`, `raw/ab-variants.txt` (+ `vartable.py` output in this file), `raw/check-bench.txt`, `raw/check-bench-pre.txt` (before the commit), `raw/chain.log`.
- `raw/void/`: the first head's tests, perf and the aborted A/B.
- `raw/scripts/`: `build.sh`, `tests.sh`, `perf.sh`, `run_ab.sh`, `run_nicemark.sh`, `chain.sh`, `post.sh`, `variants.py` (the scratch variants), `l56_scratch_bench.rs` (the recorded-survivor bench, appended to `cpu_join.rs` only while it ran), `l52_ab.rs` (L52's harness), `perfsym.py` (L50's), `table.py` / `nm_table.py` / `perftable.py` (L52's), `vartable.py`.
