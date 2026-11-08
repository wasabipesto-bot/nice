# L52 PR results: the two-pass scan in the CPU join (2026-11-08; ivory, CPU only)

**Branch:** `pr/cpu-join-two-pass-scan` on the fork (`wasabipesto-bot/nice`), **one commit, head `cd661b014156f6dc54a1e042d646cbda62454cca`**, on fork `pr/cpu-join-lean-prefilter` `7f5260b` (#248, on #247). Title per the commit: "CPU overlap join: a two-pass AND scan". The first commit (`696aa794`) was amended once for its message wording before anything was pushed (`commit --amend` was allowed); pushed over SSH at 08:43 UTC (no HTTPS fallback needed). Not opened as a PR. Body: `L52/PR-BODY.md` (CHANGELOG `#NNN` placeholder left). Raw logs and scripts: `L52/raw/`.

## Summary

- **Verdict: keep.** Kill was "< ×1.10 at either production shape, NiceMark CPU < ×1.05, or any count change": the four production-shape medians are **×1.237–1.266** (every single round ≥ ×1.221), NiceMark **×1.261**, and every count equals #248's.
- **A/B against #248's head `7f5260b`** (3 rounds, medians, interleaved, order alternating; `raw/ab-runs.txt`, `ab-summary.txt`; rounds started at 1-min load 1.36 / 2.00 / 1.94, all OK; other sessions ≤ 1.73 cores at every run start):
  - **b60 1e16: ×1.266 (1 thread, 2225 → 1758 ms/partition) / ×1.260 (4 threads, 2436 → 1934)**;
  - **b62 1e17 slice 0: ×1.237 (2110 → 1706) / ×1.237 (2371 → 1916)**;
  - b58 1e15 (NiceMark's field): ×1.300 (1 t, 32 partitions) / ×1.316 (4 t, 128 partitions);
  - whole 1e14 fields, 4 threads: b60 ×1.104 (33.8 → 30.6 s), b62 ×1.083 (42.9 → 39.6 s), b64 ×1.182 (83.9 → 71.0 s);
  - whole 1e14 fields, 1 thread (separate block after NiceMark, `raw/ab-runs-whole1t.txt`, `ab-summary-whole1t.txt`; rounds started at 1.89 / 1.41 / 1.09, others ≤ 0.27 cores): b60 ×1.100 (122.7 → 111.6 s), b62 ×1.079 (156.4 → 145.0 s), b64 ×1.162 (299.8 → 258.0 s).
- **NiceMark CPU nice-only (4 rounds, 4 threads, 150 s): score ×1.261 (864.9 → 1091.0)**, per round 1.280, 1.277, 1.257, 1.222. Scenarios: b58 weak ×1.303, b58 weak 1 thread ×1.325, b58 strong ×1.185, b60 weak ×1.234, b62 weak ×1.268 (`raw/nicemark-summary.txt`). Base 864.9 vs L49's 868.5 for #248.
- **perf stat (1 thread, per partition; `raw/perfstat-summary.txt`):** branch mispredictions **61.3 → 25.3 M** (b60 1e16) and **58.4 → 21.7 M** (b62 1e17 s0), −59 / −63 %; **IPC 2.18 → 2.81** at both; instructions +4.1 / +3.0 %; branches +7.8 / +5.2 % (the per-8 bounds check and the counted pass-2 loop; predictable); cycles −19.2 / −20.5 %.
- **Against L50's prototype** (two-pass + inlined survivor, its A/B 2: ×1.261 / ×1.301 / ×1.285 / ×1.250 at b60 1 t / b62 1 t / b60 4 t / b62 4 t, b58 ×1.325; its plain medians read a few % high there): this PR ×1.266 / ×1.237 / ×1.260 / ×1.237, b58 ×1.300 — the same gain within the noise, b62 perhaps 2–5 % lower; mispredictions land where L50's did (26 M at b60; L50 24 M at b62 with the check too), IPC 2.81 (L50 2.82 with the check).
- **Exact:** every timed run of both sides has #248's join survivors / full checks (b60 1e16 4p 136,900,315 / 8,692,368, 16p 549,719,536 / 34,926,644; b62 1e17 s0 4p 137,605,271 / 8,194,223, 16p 550,916,180 / 32,806,057; b58 1e15 32p 319,652,260 / 18,029,967, 128p 1,277,611,815 / 72,056,777; whole b60 1e14 1,326,103,590 / 84,383,498; b62 1,470,093,637 / 87,495,922; b64 5,702,041,796 / 346,647,759; no hits), equal to L49's numbers for #248; whole b42 417,789,835 / 16,879,877 (join = reference = stride); `NICE_TEST_CPU_JOIN_REF=3` ok; new pass-1 test ok on portable + AVX2.
- **AVX-512 path:** compiled (release, test, clippy) and its release code read; **never executed** (ivory is Zen 2, no AVX-512, no emulator). CI's x86 runners: **unknown** (logs show ubuntu-24.04 on Azure, no CPU model). Estimate there ×1.08–1.15 (L50 §2.7), unmeasured.

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
| opt-in whole b42 field `NICE_TEST_JOIN_FULL_FIELD=1` | ok: 1764 partitions, 417,789,835 / 16,879,877, no hits; 4 threads: reference 87 s, join 11.3 s (#248's first version: 12.1 s in L49's run; its head 18.4 s under other load), stride 118.5 s (`unit-tests-fullfield.txt`) |
| `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings` (default, rustc 1.99.1) | clean (`clippy-default.txt`; first run flagged two test-only lints, `manual_isolate_lowest_one` and `assert_is_empty`, fixed before the commit). GPU-feature clippy not run: `cpu_join.rs` has no feature-gated items. The uncommitted harness `common/examples/l52_ab.rs` was moved out of the tree for fmt/clippy |

The tests and the timed binaries are from the committed head `cd661b0` (the build log records the tree; the client binaries embed `cd661b014156…` and `7f5260ba…` respectively).

## AVX-512 (what ran)

- ivory: AMD EPYC-Rome (Zen 2) VM, `/proc/cpuinfo` flags avx2, bmi2, popcnt, **no avx512***. No emulator (no SDE / qemu-user) on the box.
- `pass1_avx512` was **compiled** in every build (release harness + client, release test, clippy) and its release code **read** (`objdump`, `raw/pass1-avx512.asm`): per 8 bottoms `vptestnmq (mem),zmm0,k0` → `kmovw` → `movzbl` → count load + row `vpaddw` with a `vpbroadcastw` of the offset → one `vmovdqu` 16-byte store; two bounds compares per step; the 0–7 tail branch-free (`cmp $1` / `adc`). Only AVX-512F + AVX2/AVX instructions (`kmovw`, not `kmovb`: no AVX512DQ/BW).
- **Never executed** on ivory: detection is false, so `the_first_pass…` ran portable + AVX2 and `every_scan_finds_the_same_pairs` ran AVX2 (as best and forced) vs portable.
- CI: `ubuntu-latest` = ubuntu-24.04 on Azure (from run 42358471842's log, #248's CI); no CPU model in the logs; test output captured. **Unknown** whether AVX-512.

## Files

- `L52/PR-BODY.md`, this file.
- `raw/build-base.log`, `raw/build-pr.log` (cargo output, md5s), `raw/commit-msg.txt`, `raw/pass1-avx512.asm` and `raw/pass1-avx2.asm` (objdump of the PR's release harness), `raw/chain.out`.
- `raw/unit-tests.txt`, `unit-tests-pass1.txt`, `unit-tests-prodref.txt`, `unit-tests-fullfield.txt`, `clippy-default.txt`.
- `raw/perfstat-runs.txt` + `perfstat-summary.txt`; `raw/ab-runs.txt` + `ab-summary.txt`; `raw/ab-runs-whole1t.txt` + `ab-summary-whole1t.txt`; `raw/nicemark-r*-{base,pr}.json/.stderr`, `nicemark-runs.txt`, `nicemark-summary.txt`; `raw/chain.log`.
- `raw/scripts/`: `build.sh`, `tests.sh`, `perfstat.sh`, `run_ab.sh`, `run_nicemark.sh`, `chain.sh`, `table.py` / `bodytable.py` / `perftable.py` / `nm_table.py`, the harness `l52_ab.rs` (= L49's `l49_ab.rs`).

## Process, timeline (UTC), cleanup

- 08:23 `df -h /` 15 GB free; worktree `.worktrees/l52-two-pass-scan` created on a new local branch `pr/cpu-join-two-pass-scan` at `7f5260b`, `CARGO_TARGET_DIR` inside it. 08:28–08:32 base binaries (harness + client) built from the untouched tree; 08:32–08:41 implementation, quick checks, tests, fmt/clippy; 08:41 commit (amended once, message only) → `cd661b0`; 08:43 PR binaries built from the commit and the branch pushed (SSH worked).
- Chain (`raw/scripts/chain.sh`, `raw/chain.log`): tests 08:44–08:50, perf stat 08:52–08:53, main A/B 08:53–09:19, NiceMark 09:20–09:46, 1-thread whole-field A/B 09:47–10:42. Every run under `nice -n 19`; gates at 1-min load ≤ 2 (≤ 1.5 for perf stat); no round marked DISCARD; the busiest other process at any run start was another session's CLI at ≤ 1.73 cores (main A/B), ≤ 0.27 (whole-field block); NiceMark runs logged no other process ≥ 20 % except one 36 % sample at a run's end.
- Peak target 2.2 GB (release harness, client, release tests, clippy). Removed at 10:43 with `bin/` (the four binaries), `wip/` and the uncommitted `common/examples/l52_ab.rs` (copy in `raw/scripts/`); the worktree is kept, clean, at `cd661b0`. `df -h /` 15 GB free after. perf was counting only (no `~/.debug` entries). Nothing else touched: the main checkout, the fleet, the server, L47/L51 and the rest of the scratchpad; no PRs, no GitHub comments, no subagents.

