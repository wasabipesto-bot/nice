# L33 PR-RESULTS: `pr/join-top-cert-2` (trim + (a) + (c) on #235), RTX 3080 at 180 W (2026-11-01)

Branch **`pr/join-top-cert-2`** on the fork: #235's head `6e7475e` (on main `fae7398`) plus one commit **`252e69e`** "Overlap join: a lighter top certificate" (`common/src/cubecl_join.rs` +470/−113 incl. docs and tests, CHANGELOG one line). PR body: `PR-BODY.md` (not opened). Raw logs: `pr-raw/box/` (the box's `/root/l33p/logs`); scripts: `pr-raw/scripts/`; analysis: `python3 pr-raw/scripts/analyze.py pr-raw/box` (output in `pr-raw/analysis.txt`).


## Summary

- **Pushed:** `pr/join-top-cert-2` at **`252e69e`** (fork), one commit on #235's `6e7475e`; PR not opened. PR body `PR-BODY.md` (title "Overlap join: a lighter top certificate: skip known-zero limbs, difference of powers, digit count from the bit length").
- **Speed vs #235** (RTX 3080, 180 W cap, interleaved, medians; per-round ranges in §4): **b62 1e17 ×1.100** (5 rounds, per round 1.089–1.122; ×1.106 over the protocol's first 3), **b62 1e16 ×1.098**, **b60 1e16 ×1.092**, **b64 1e16 ×1.019** (2 rounds), **NiceMark score ×1.108** (b60 ×1.157, b62 ×1.138, b58 ×1.090/×1.056). Every round of every field faster.
- **Implied vs main** (× #235's own ratios, L30 §4 / L29): b62 1e17 ×1.210, b62 1e16 ×1.196, b60 1e16 ×1.150, b64 1e16 ×1.015, NiceMark ×1.186.
- **Exact:** certificate test with #235's counts (102,365 / 33,582 / 203,413 / 69,824) on CUDA (both builds) and lavapipe naga + SPIR-V, with the word-for-word `powers_diff` check; join parity incl. b50/b54 (CUDA + lavapipe SPIR-V); both dense fields; whole b42; 1e14 compare counts identical to #235 at b57/60/62/64; digit-count host test; fmt; clippy ×3; WGSL lint 0 flagged (TopKernel constant divisions 539 → 270).
- **SPIR-V TopKernel blocks:** 478 → **366** (b57), 496 → **384** (b64), recounted for A and B2 on this box.
- **Missing / caveats:** no Metal (M4) run of the trimmed division (SCOPING.md §5 item 1; not in this task's scope); no per-phase profile of the top kernel; NiceMark is 3 rounds of ~36 s each; the first whole-b42 log was overwritten by a stale master copy (content preserved in `pr-raw/box/x_whole_run1_from_session.txt`) and the check was re-run on B2 (`x2_whole.log`).

## 0. The commit (one commit, three changes)

- **Trim** (from `exp/top-early-reject` `06e4c9d`, its bit 4 only, without the switch): in `cert_power`, each pass's long division runs over `lp = clamp(len(pow_limbs16(base, sp − pass·cd)), 2, nh)` limbs instead of `nh`; the first step stays the OR form `(x[top] << 16) | x[next]` on the top two live limbs. Doc: the Metal paragraph now says "the top two limbs that can be nonzero … both stored 16-bit limbs", and a new paragraph states the precondition x < b^sp and the step count (466 → 185 at b62). About 8 lines of code. None of the early-reject/compaction/histogram code was taken.
- **(a) + (c)** (from `exp/top-cert-2b` `eb3d7e6`, which sits on `exp/join-235-236`): cherry-picked onto #235. `cubecl_join.rs` applied without conflict (it touches `cert_power`, `powers_diff`, `ndig_fast`, `ndig_magic`, `top_cert` and the certificate test only); the CHANGELOG conflicted with #236's line and was resolved by writing one sentence for the whole PR. No (b) (Barrett / division-free digit step).
- CHANGELOG (Unreleased): "Speed up the GPU overlap join's top certificates by skipping the limbs of their long division that are known to be zero, computing the difference of the endpoints' powers from the endpoints' difference, and taking its digit count from its bit length instead of a search."
- rustfmt reflowed one line of the trim (`let lp = comptime!(…)`), caught by the first `cargo fmt --check` on the box; fixed and amended before any push. B = the pre-fmt build (the CUDA exactness runs); **B2 = the pushed tree** (certificate test re-run on it, A/B and lavapipe binaries are from it; §1).

## 1. Setup

- **Box:** Vast 58652022 (`nice-research-topcert3`) on machine **m139250** (the machine of L29/L30/L31's A/Bs). RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver API). **Power limit 180 W** (default 320, max 320; `box/box-info.txt`). Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB.
- **Trees** (shipped as `git archive` tarballs; `cubecl_join.rs` md5 on the box): A = #235 `6e7475e` (`9ab62cee`); B = the branch before rustfmt (`125f1385`); **B2 = `252e69e`, the pushed head** (`4c77a957`, same as the local worktree).
- **Binaries** (`scripts/build.sh`, `buildclient.sh`: pinned toolchain 1.99.1, one target dir, `cargo clean -p nice_common` [and `-p nice_client`] before each build; test binaries are `cargo test --release -p nice_common --features <f> --no-run`):

  | binary | tree | features | md5 | used for |
  |---|---|---|---|---|
  | `A` | `6e7475e` | gpu | 7718acc5 | A/B side A, 1e14 compare |
  | `B` | pre-fmt | gpu | b39bd041 | CUDA exactness (cert, parity, dense ×2, whole b42, 1e14 compare, host tests) |
  | `B2` | `252e69e` | gpu | cbc7ee2a | certificate test again; **A/B side B** |
  | `client_A` / `client_B` | A / `252e69e` | `nice_client --features gpu` | 13d16f18 / 2833f7af | NiceMark |
  | `B_naga`, `B_spv`, `A_spv` | `252e69e`, `252e69e`, A | cubecl / cubecl-spirv / cubecl-spirv | ba7f8615, 0c1ba8c2, b885d548 | lavapipe |

  B and B2 differ only by rustfmt's reflow of one line (token-identical code; the binaries differ because panic locations below that line moved up one line). `client_B` and the lavapipe binaries were built after the fix landed in `src/B` (11:38:36 UTC; `client_B` started 11:39:03).
- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568; b57 28151599893042801193 for the 1e14 compare), one untimed 1e14 warm-up field per process. Metric: `device=` (mean device wall seconds per field), as in L30/L31; `per_field` is reported alongside.
- **Order (box UTC):** builds 11:31–12:00 (B, A, clients, lavapipe ×3, B2); CUDA exactness 11:35–11:46 (beside the builds); fmt/clippy 11:31–11:40; lavapipe 11:53–12:03; `x2_cert` on B2 12:03–12:05; **A/B from 12:04:48 with nothing else on the box**, then NiceMark.

## 2. Exactness (logs in `pr-raw/box/`)

| check | result |
|---|---|
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`, B (`x_cert.log`) and **B2** (`x2_cert.log`) | ok, 124 s / 113 s: **102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry**: #235's counts. The word-for-word check of `powers_diff`'s a², a³ and differences against the full schoolbook powers is in the test (`o[29]` asserted 0 for every interval) |
| the same test on lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8), **naga** (`lvp_cert_naga.log`) | ok, 83 s, same counts |
| the same test on lavapipe, **direct SPIR-V** (`lvp_cert_spv.log`) | ok, 196 s, same counts, no stack overflow |
| `cubecl_cuda_join_matches_the_cpu_reference` (`x_ref.log`): b10's 69, windows b20–b64 incl. **b50 and b54**, the b57 frontier, tight/sliced/refused layouts, production shape | ok, 77 s |
| join parity on lavapipe, direct SPIR-V, B and A (`lvp_par_spv_{B,A}.log`) | both ok, 110 s / 119 s |
| dense b58 1e15, 32 partitions (`x_dense58.log`) | ok: 254,938,965 survivors / 14,396,829 checked, 0 overran, asserted equal to the CPU join |
| dense b62 1e16, 4 partitions (`x_dense62.log`) | ok: 120,011,252 / 7,357,888 (2,223 overran the stage, 1.9e-5), asserted equal to the CPU join |
| whole b42 field, `NICE_TEST_JOIN_FULL_FIELD=1`, on B (11:45, `x_whole_run1_from_session.txt`: its log was overwritten, see Summary) and again on **B2** (13:01, `x2_whole.log`) | both ok, 65 s / 61 s, same counts: 1764 partitions, 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference (= #235's, L29) |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64, A and B (`{A,B}_cmp_e14.log`) | both pass (join = stride, found 0). **Counts identical A = B**: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759 (= L30/L31's). Plan MiB identical (1185/1192/1359/1402) |
| host test `ndig_fast_constants_give_the_digit_count` (`host_ndig.log`); `cubecl_join::` host tests (`host_cubecl_join.log`) | ok; ok (1 passed, 11 ignored) |
| `cargo fmt --all --check` | first run (pre-fmt tree, `lint_fmt.log`): one reflow in the trim; **after the fix: clean** (`lint2_fmt.log`, `lint_fmt2.log`) |
| clippy `-p "*" --all-targets -D warnings`: default; `--features nice_client/gpu`; `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1) | **all clean**, on the pre-fmt tree (`lint_*.log`) and again on the pushed tree (`lint2_*.log`, `lint2_summary.txt`) |
| CI's WGSL lint: `wgsl_dump_for_lint` on lavapipe naga + `scripts/wgsl-lint.py` with CI's 13 `--require`s (`wgsl_lint_B.log`) | **15 shaders, 0 flagged**, rc 0. TopKernel b57: **270 constant divisions** (#235: 539, L31, whose A had #235's top kernel): the trim halves them |

## 3. SPIR-V blocks (lavapipe direct SPIR-V, `scripts/blocks.py`)

| kernel | A (#235) | B2 | change |
|---|---|---|---|
| TopKernel b57, CI's lint dump (`blocks_lint_{A,B}.txt`) | 478 | **366** | −112 |
| TopKernel b64, join parity dump (`blocks_par_{A,B}.txt`) | 496 | **384** | −112 |
| TopKernel b58 / b60 | 484 / 484 | 372 / 372 | |
| TopKernel b54 / b50 | 382 / 370 | 306 / 294 | |
| TopKernel b40 / b20 | 304 / 178 | 228 / 138 | |

- Identical to L31's (a) + (c) alone (366 / 384): the trim removes straight-line division steps and adds no block, as L33 §4 found.
- Certificate test kernels (`blocks_cert_B.txt`): the largest is still part 1, the unchanged lockstep reference, at 548 blocks (b57).

## 4. A/B: #235 (A, `6e7475e`) vs this branch (B2, `252e69e`), interleaved A B per round (`chain_ab.sh`, 12:04:48–12:44:02, then NiceMark 12:44:02–12:47:43, then b62 1e17 rounds 4–5 (`extra.sh`, 12:47:43–13:01:02) and the whole-field re-run on B2; nothing else on the box)

Metric `device=` s/field; medians; spread = (max − min)/median; per round = A/B in the same round. **Implied vs main** = this ratio × #235's own speed-up over main: b62 1e17 ×1.100 and b64 1e16 ×0.996 from L30 §4 (`6e7475e` alone, same machine m139250, 180 W 3080); b62 1e16 ×1.089, b60 1e16 ×1.053 and NiceMark ×1.071 from L29 (`d6cc9da`, #235 before its SPIR-V fix, which SPIRV-FIX.md measured at +2.4 % on a 3060, so these three are slight underestimates).

| field | #235 s/field (rounds) | spread | this PR s/field (rounds) | spread | speed-up | per round | implied vs main |
|---|---|---|---|---|---|---|---|
| b62 1e17, 1 field | **201.84** (202.91, 201.84, 205.06, 200.84, 201.63) | 2.1 % | **183.54** (180.79, 185.25, 183.54, 181.17, 185.17) | 2.4 % | **×1.100** | 1.122, 1.090, 1.117, 1.109, 1.089 | ×1.210 (#235 ×1.100) |
| b62 1e16, 2 fields | **16.68** (16.87, 16.68, 16.65) | 1.3 % | **15.19** (15.23, 15.19, 14.96) | 1.8 % | **×1.098** | 1.108, 1.098, 1.113 | ×1.196 (#235 ×1.089) |
| b60 1e16, 2 fields | **39.41** (39.41, 38.87, 39.68) | 2.1 % | **36.08** (35.51, 36.08, 36.25) | 2.1 % | **×1.092** | 1.110, 1.077, 1.095 | ×1.150 (#235 ×1.053) |
| b64 1e16, 2 fields | **52.87** (53.08, 52.65) | 0.8 % | **51.88** (51.90, 51.86) | 0.1 % | **×1.019** | 1.023, 1.015 | ×1.015 (#235 ×0.996) |

- b62 1e17, 1 field: per_field ratio ×1.098; survivors #235 1,020,728,290,324–1,020,728,381,616 | PR 1,020,728,324,993–1,020,728,387,632; checked #235 62,692,708,663–62,692,791,614 | PR 62,692,708,598–62,692,763,678; found [0]; slots 5/5
- b62 1e16, 2 fields: per_field ratio ×1.099; survivors #235 163,510,214,285–163,510,225,978 | PR 163,510,224,806–163,510,227,242; checked #235 10,030,861,316–10,030,872,309 | PR 10,030,861,003–10,030,863,056; found [0]; slots 13/13
- b60 1e16, 2 fields: per_field ratio ×1.085; survivors #235 459,050,336,759–459,051,204,212 | PR 459,050,397,339–459,050,751,549; checked #235 32,548,100,860–32,548,903,665 | PR 32,548,516,469–32,548,854,389; found [0]; slots 4/4
- b64 1e16, 2 fields: per_field ratio ×1.019; survivors #235 787,562,283,385–787,562,318,457 | PR 787,562,333,556–787,562,339,746; checked #235 47,922,100,006–47,922,130,941 | PR 47,922,078,475–47,922,084,960; found [0]; slots 6/6

NiceMark score: #235 4048 (4040, 4048, 4099; spread 1.5 %) -> PR 4484 (4481, 4549, 4484; spread 1.5 %): ×1.108; per round 1.109, 1.124, 1.094; implied vs main ×1.186

| scenario | #235 rate | spread | this PR rate | spread | speed-up |
|---|---|---|---|---|---|
| b58 msd weak | 1.72e+14 | 1.5 % | 1.875e+14 | 3.4 % | ×1.090 |
| b58 msd strong | 1.04e+15 | 2.9 % | 1.098e+15 | 5.9 % | ×1.056 |
| b60 msd weak | 3.563e+14 | 1.8 % | 4.123e+14 | 2.0 % | ×1.157 |
| b62 msd weak | 4.537e+14 | 2.1 % | 5.165e+14 | 0.3 % | ×1.138 |

- **Every round of every field is faster with the PR** (lowest per-round ratio: 1.077 at b60, 1.015 at b64).
- **Clocks** (`pr-raw/analysis.txt`, `pr-raw/smi-summary.txt`): every timed run sat at the 180 W cap (throttle 0x4, SW power cap), mean SM clock 1406–1474 MHz per run, mean power 177.8–179.9 W per run, ≤ 52 °C. B ran 6–38 MHz lower than A at the same power (more work per cycle); clock-normalised ratios are a little higher (b62 1e17 ×1.127 over 5 rounds, b62 1e16 ×1.103, b60 ×1.109, b64 ×1.032).
- **Counts:** at 1e16/1e17 survivors and checked vary run to run in **both** trees (the stage overrun is timing-dependent on #235's tree, as on main; L29 §2, SPIRV-FIX.md), by up to 2 parts per million (b60: A's survivors span 867,453, B's 354,210), and B's ranges are no wider than A's; found = 0 in every run. The exactness evidence is §2 (certificate test, 1e14 compare with identical counts, parity, dense, whole field), not these counts.
- **Against expectations:** on #235 + #236, L33 measured the trim alone at ×1.051 (b62 1e17) and L31 (a) + (c) at ×1.045. On #235 alone the top kernel is a larger share of device time (#236 removes join-kernel time, not top-kernel time), so the same seconds saved give a larger ratio here: ×1.100 at b62 1e17, about the product of the two (×1.098).
- **NiceMark** (`nm_{A,B}_r{1,2,3}.json`, `client_A` 13d16f18 / `client_B` 2833f7af): score ×1.108; no scenario slower (lowest b58 MSD-strong ×1.056, whose PR rounds spread 5.9 %).

## 5. Commands (all in `pr-raw/scripts/`, run on the box from `/root/l33p`)

- `master.sh`: `chain_cpu.sh` (builds) | after B: `chain_lint.sh` (fmt + clippy, niced), `chain_x.sh` (CUDA exactness, 1e14 compare, host tests, whole b42), `chain_lvp.sh` (lavapipe); then `chain_ab.sh`. Added while running: `b2.sh` (B2 build + fmt re-check after the reflow), `chain_lint2.sh` (fmt + clippy on the pushed tree); `chain_ab.sh` was replaced before it started (B2 certificate test first, side B = B2); `extra.sh` (b62 1e17 rounds 4–5 after NiceMark); `post_whole.sh` (whole b42 on B2). Replacements were `mv`ed in, never edited in place. `master.sh` itself was not replaced on the box, so its old last line re-ran `x_whole` without `NICE_TEST_JOIN_FULL_FIELD` after the A/B and overwrote the first whole-field log (kept as `x_whole_stale_skip.log`; the first run's output is in `x_whole_run1_from_session.txt`).
- Build: `build.sh SRC OUT FEAT` = `cargo clean --release -p nice_common; cargo test --release -j 10 -p nice_common --features FEAT --no-run` (CARGO_TARGET_DIR=/root/tgt, NICE_BUILD_SHA=test); `buildclient.sh` = `cargo build --release -p nice_client --features gpu`.
- Tests: `test.sh NAME BIN TEST [ENV…]` = `BIN --ignored --exact TEST --nocapture --test-threads 1` with `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:…` (CUDA compat path). Dense: `NICE_TEST_JOIN_DENSE=32`, and `=4` with `NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16`. Whole field: `NICE_TEST_JOIN_FULL_FIELD=1`.
- Throughput: `run.sh NAME BIN BASES FIELDS SIZE [COMPARE]` = `NICE_TEST_JOIN_FIELDS=… NICE_TEST_JOIN_SIZE=… NICE_TEST_JOIN_BASES=… NICE_TEST_JOIN_STARTS=57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields`, `NICE_TEST_JOIN_COMPARE=1` for the 1e14 compare; nvidia-smi sampled every 5 s into `NAME.smi`.
- NiceMark: `client_X niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json` with `NICE_API_BASE=http://127.0.0.1:9`.
- Lavapipe: `VK_ICD_FILENAMES=lvp_icd…json`; CI's lint = `CUBECL_DEBUG_LOG=… B_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint` + `scripts/wgsl-lint.py LOG` with CI's 13 `--require`s (from `.github/workflows/gpu-parity.yml`); SPIR-V blocks = the same dump (and the parity test's) from the `*_spv` binaries through `blocks.py`.
- Analysis: `python3 pr-raw/scripts/analyze.py pr-raw/box > pr-raw/analysis.txt`; PR tables: `python3 pr-raw/scripts/md.py pr-raw/box > pr-raw/tables.md`.
