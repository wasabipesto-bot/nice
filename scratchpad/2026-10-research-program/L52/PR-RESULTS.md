# L52 PR results: the two-pass scan in the CPU join (2026-11-08; ivory, CPU only)

**Branch:** `pr/cpu-join-two-pass-scan` on the fork (`wasabipesto-bot/nice`), **one commit, head `cd661b014156f6dc54a1e042d646cbda62454cca`**, on fork `pr/cpu-join-lean-prefilter` `7f5260b` (#248, on #247). Title per the commit: "CPU overlap join: a two-pass AND scan". The first commit (`696aa794`) was amended once for its message wording before anything was pushed (`commit --amend` was allowed); pushed over SSH at 08:43 UTC (no HTTPS fallback needed). Not opened as a PR. Body: `L52/PR-BODY.md` (CHANGELOG `#NNN` placeholder left). Raw logs and scripts: `L52/raw/`.

TBD-SUMMARY

## What the commit does (`common/src/cpu_join.rs` +292/−123 with the test; CHANGELOG +1)

- `scan` (one top against one digit-sum class) now runs `each_pass`: for each piece of up to `PIECE` = 1024 bottoms, `pass1` (dispatch: `pass1_avx512` / `pass1_avx2` / `pass1_any`) writes the passing bottoms' indices (u16) to `Scratch::idx`, then the closure runs `survivor` on each, in order. The three old functions `scan_avx512`, `scan_avx2`, `scan_any` are gone.
- Pass 1 on every path forms one byte of pass bits per 8 bottoms (AVX-512F `vptestnmq`; AVX2 2× `vpand`/`vpcmpeqq`/`vmovmskpd`; portable 8 scalar tests) and calls the shared `emit`: store `at + BIT_POS[byte]` (8 × u16, a 256-row const table) at the list end, move the end by `BIT_CNT[byte]` (256-byte const table). The last 0–7 bottoms of a piece: `pass1_rest`, store-always/advance-by-test. No branch on the bits anywhere.
- Stores are safe, bounds-checked slice writes (`idx[cnt..cnt + 8]`); invariant cnt ≤ at keeps them in range, a violation would panic. No new `unsafe` beyond the SIMD loads (same pattern as before) and the target-feature calls.
- `survivor`: `#[inline(never)]` → `#[inline(always)]` (module-level `#![allow(clippy::inline_always)]` with a comment, as `cpu_top_fd.rs` does). Body unchanged.
- `Scratch` gains `idx: Vec<u16>`, resized to `PIECE` at the start of each `run` (no-op after the first).
- New test `the_first_pass_lists_the_same_bottoms_on_every_path` (+ helpers `pass1_paths`, `random_class`): per available path, 114 class lengths 0..=1024 (edges 0,1,7,8,9,15,16,17,31,32,33,300,1023,1024 + 100 random) × densities 0/1/40/100 % against a plain filter (idx pre-filled with 0xFFFF); then lengths 1025, 2085, 5120 × 1/40/100 % through `each_pass` on three `CpuJoin`s (best, AVX2 forced, portable forced; the b10 field, only the flags matter).
- Module doc step 3 and `scan`'s doc updated. CHANGELOG line under Unreleased with `#NNN`.

**Interpretation notes:**
- "Sharing the pass-2 code and the index-buffer handling": the three paths differ only in forming the byte; `emit`, `pass1_rest`, `each_pass` and pass 2 (the `scan` closure) are shared.
- "Classes over 4,096 bottoms done in pieces instead of falling back" (roadmap item 1): done with pieces of 1024 (2 KiB list). No production class is near that (b60/b62 1e16 average ~300 a scan; the PLAN_FIELDS max 340), but one test window (b57 [20635899893042801193, +3e5), t9 k5 p1) has classes of 1353–1439, so the end-to-end reference and three-path tests run two-piece classes too (measured with a throwaway test, not committed).
- Per-8 steps on all three paths. Variants tried in single runs (b60 1e16, 1 t) and not kept: AVX2 per 16 like the prototype (1733/1740 ms vs 1742/1800 for per-8: no difference), `scan` `#[inline(never)]` (1772/1809 vs 1745/1706: no better).
- The AVX-512 path is per 8 (one `vptestnmq` → one byte → `emit`) rather than the old 32-per-step accumulation, since there is no branch to batch any more.
- The scan's previous AVX-512 detection (`avx512f` only, not also `avx2`) is unchanged; rustc's avx512f implies avx2 for codegen, and stride_filter requires both. Not in scope; noted here only.

## Tests (`raw/unit-tests*.txt`, `raw/clippy-default.txt`; script `raw/scripts/tests.sh`)

| test | result |
|---|---|
| `cargo test --release -p nice_common -p nice_client` on the head | **189 + 22 passed, 6 ignored** (`unit-tests.txt`; #248 had 188 + 22, 6 ignored; +1 new) |
| new `the_first_pass_lists_the_same_bottoms_on_every_path` (CI) | ok; ran **portable + AVX2** here: "first pass on ["portable", "avx2"]: 84860 bottoms listed alike" (`unit-tests-pass1.txt`); the AVX-512 arm is skipped by feature detection on ivory |
| existing `cpu_join` tests (windows vs reference incl. `mid_mirror`, `every_scan_finds_the_same_pairs`, stride, slices, prune, stepped = divided tops, b10's 69, FX / lean prefilter) | ok |
| opt-in `NICE_TEST_CPU_JOIN_REF=3` | ok, 25.0 s (b42 0.7, b50 11.1, b57 4.7, b60 1.7, b62 2.3, b64 4.6 s) (`unit-tests-prodref.txt`) |
| opt-in whole b42 field `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 / 16,879,877, no hits; 4 threads: reference 87 s, join 11.3 s (#248: 12.1 s in L49's run), stride 118.5 s (`unit-tests-fullfield.txt`) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default, rustc 1.99.1) | clean (`clippy-default.txt`; first run flagged two test-only lints, `manual_isolate_lowest_one` and `assert_is_empty`, fixed before the commit). GPU-feature clippy not run: `cpu_join.rs` has no feature-gated items. The uncommitted harness `common/examples/l52_ab.rs` was moved out of the tree for fmt/clippy |

The tests and the timed binaries are from the committed head `cd661b0` (the build log records the tree; the client binaries embed `cd661b014156…` and `7f5260ba…` respectively).

## AVX-512 (what ran)

- ivory: AMD EPYC-Rome (Zen 2) VM, `/proc/cpuinfo` flags avx2, bmi2, popcnt, **no avx512***. No emulator (no SDE / qemu-user) on the box.
- `pass1_avx512` was **compiled** in every build (release harness + client, release test, clippy) and its release code **read** (`objdump`, `raw/pass1-avx512.asm`): per 8 bottoms `vptestnmq (mem),zmm0,k0` → `kmovw` → `movzbl` → count load + row `vpaddw` with a `vpbroadcastw` of the offset → one `vmovdqu` 16-byte store; two bounds compares per step; the 0–7 tail branch-free (`cmp $1` / `adc`). Only AVX-512F + AVX2/AVX instructions (`kmovw`, not `kmovb`: no AVX512DQ/BW).
- **Never executed** on ivory: detection is false, so `the_first_pass…` ran portable + AVX2 and `every_scan_finds_the_same_pairs` ran AVX2 (as best and forced) vs portable.
- CI: `ubuntu-latest` = ubuntu-24.04 on Azure (from run 42358471842's log, #248's CI); no CPU model in the logs; test output captured. **Unknown** whether AVX-512.

## Files

- `L52/PR-BODY.md`, this file.
- `raw/build-base.log`, `raw/build-pr.log` (cargo output, md5s), `raw/commit-msg.txt`.
- `raw/unit-tests.txt`, `unit-tests-pass1.txt`, `unit-tests-prodref.txt`, `unit-tests-fullfield.txt`, `clippy-default.txt`.
- `raw/perfstat-runs.txt` + `perfstat-summary.txt`; `raw/ab-runs.txt` + `ab-summary.txt`; `raw/ab-runs-whole1t.txt` + `ab-summary-whole1t.txt`; `raw/nicemark-r*-{base,pr}.json/.stderr`, `nicemark-runs.txt`, `nicemark-summary.txt`; `raw/chain.log`.
- `raw/scripts/`: `build.sh`, `tests.sh`, `perfstat.sh`, `run_ab.sh`, `run_nicemark.sh`, `chain.sh`, `table.py` / `bodytable.py` / `perftable.py` / `nm_table.py`, the harness `l52_ab.rs` (= L49's `l49_ab.rs`).

TBD-CLEANUP

