# L31 AB-COMBINED: (a) + (c) as production code on #235 + #236, RTX 3080 at 180 W (2026-11-01)

Branch **`exp/top-cert-2b`** on the fork (no PR): `e9cdac4` (#235 + #236, `exp/join-235-236`) plus one commit `eb3d7e6`. Raw logs: `ab-raw/box/` (the box's `/root/l31b/logs`). Scripts: `ab-raw/scripts/`. Analysis: `ab-raw/scripts/analyze.py box` (output in `ab-raw/analysis.txt`).

## Summary

- **Verdict: no-go, narrowly.** The bar was ≥ 5 % at both live bases with no scenario slower than 2 %.
  - **b60 meets it:** ×1.059 at 1e16 (3 rounds, per round 1.046–1.062), NiceMark b60 ×1.056.
  - **b62 does not:** ×1.045 at 1e17 (5 rounds, per round 1.023–1.057) and ×1.038 at 1e16 (6 rounds, per round 1.030–1.051). Only NiceMark's sampled b62 scenario reaches it (×1.054).
  - **Nothing is slower:** b64 ×1.022, NiceMark score ×1.041, lowest scenario b58 MSD-strong ×1.019.
  - The projection was ~7 % whole-field (43 % top share × ~18 % off the top kernel). Measured: 4–6 %. The top kernel was not profiled here, so the gap is not explained.
- **Exact everywhere.**
  - CUDA: the certificate test has #235's counts (102,365 intervals, 33,582 kept, 203,413 scanned above c0, 69,824 with the carry). It now also checks the new differences word for word against the full powers.
  - CUDA: join parity incl. b50/b54 passes, both dense fields equal the CPU join, and the whole b42 field matches the reference.
  - 1e14 counts are identical to A at b57/60/62/64, and join = stride.
  - Every A/B run's counts are identical to A's (and to L30's exact counts).
  - The same checks pass on lavapipe with naga and with the direct SPIR-V compiler.
  - WGSL lint: 0 flagged. TopKernel has 539 constant divisions, the same as A, since the new code adds none.
  - fmt and clippy (default, gpu, gpu + spirv) are clean on the pushed head. Its test binary is byte-identical to the one measured.
- **Smaller kernel.** TopKernel SPIR-V blocks: **478 → 366 at b57, 496 → 384 at b64**. The certificate test's largest part is still the unchanged lockstep part (548 blocks).
- **What would clear the bar:** see §6. Short version: add (b), the division-free digit step, after an M4 run, or ship (a) + (c) as a ~4–6 % exact change if the user relaxes the bar.

## 0. Setup

- **Box:** Vast 58629437 (`nice-research-topcert2b`) on machine **m139250**. That is the same machine as L29/L30/L31's A/Bs. Another research box (`nice-research-padding`, another 3080) was on the same host throughout, so the host CPU was shared.
  - RTX 3080 10 GB, driver 580.159.03 (CUDA 13.0 driver API), CUDA 12.8 toolkit.
  - **Power limit 180 W** (default 340, max 374; `box/box-info.txt`). Under load the card sat at the cap in every timed run: 178–180 W, mean SM clock 1424–1464 MHz at ≥ 90 % utilisation, at most 67 °C.
  - Xeon E5-2630 v4, cgroup quota 9.6 CPUs, 62 GB, 24 GB disk.
- **Trees.**
  - A = `exp/join-235-236` `e9cdac4`.
  - B = the branch as measured, `bf55ae8`. The pushed head `eb3d7e6` differs from it by 5 doc-comment lines (clippy's `doc_markdown`, §2) and the commit message. B2, built from `eb3d7e6`'s tree, is checked against B's binary in §2.
  - Shipped as `git archive` tarballs. Source md5 of `cubecl_join.rs` on the box: A `5e898ee7`, B `5d743a32`, B2 `41c49917`.
- **Binaries.** All built on the box with the pinned toolchain 1.99.1 into one target dir, one at a time, with `cargo clean -p nice_common` (and `-p nice_client`) before each build (`scripts/build.sh`, `buildclient.sh`). Test binaries are `cargo test --release -p nice_common --features <f> --no-run`.

  | binary | source | features | md5 | notes |
  |---|---|---|---|---|
  | `A` | `e9cdac4` | gpu | **8f421599** | same md5 as L30's `both`, so the tree and the build reproduce |
  | `B` | `bf55ae8` | gpu | 140f835b | the A/B and CUDA exactness binary |
  | `B_pre` | `bf55ae8` before rustfmt | gpu | 739e3979 | smoke run of the certificate test only |
  | `client_A` / `client_B` | A / B | `nice_client --features gpu` | 239e7f78 / e400919d | NiceMark |
  | `B_naga`, `B_spv`, `A_spv` | B, B, A | cubecl / cubecl-spirv | b22699f3, c6e6555b, d8481573 | lavapipe |
  | `B2` | `eb3d7e6` | gpu | see §2 | doc-only delta |

- **Harness:** `cubecl_cuda_join_throughput_fixed_fields` at L30's starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568). Each process starts with an untimed 1e14 warm-up field. The metric is `device=`, the mean device wall seconds per field, as in L30. `per_field` agrees to within 0.003 in the ratios (table §4).
- **Order (box UTC):**
  - Builds: 07:07–07:28. B first as a compile check, then rebuilt after rustfmt.
  - Smoke certificate test: 07:13–07:15.
  - CUDA exactness and the 1e14 compare runs: 07:28–07:37.
  - Lavapipe builds and tests: 07:28–07:48. fmt/clippy ran niced beside them.
  - **A/B: 07:48–08:23** (`chain_ab.sh`): b62 1e17 ×3, b62 1e16 ×3, b60 1e16 ×3, b64 1e16 ×3, each round A then B.
  - NiceMark ×3: 08:23–08:27.
  - **Extra b62 rounds: 08:27–08:42** (`post3.sh`), because b62 was split after three rounds: 1e16 r4–r6, then 1e17 r4–r5.
  - Then the B2 rebuild, fmt/clippy on B2, the host tests and the whole-field check: 08:42–08:48.
  - Nothing else ran on the box from 07:48 to 08:42.

## 1. The code (`eb3d7e6`)

`common/src/cubecl_join.rs` (+451 / −105) and one CHANGELOG line. Ported from `exp/top-cert-2`'s (a) and (c), with no switches, no breakdown stages, no profile timers and no (b).

- **`powers_diff`** (production) replaces `powers16` in `top_cert`.
  - It forms a² and a³ exactly as `powers16` did, and the differences e² − a² = δ(2a + δ) and e³ − a³ = δ(3a² + 3aδ + δ²) from δ = e − a.
  - It packs those as the u32 words `cert_power` used to compute itself as y − x.
  - δ's width `dw` is comptime. `top_kernel` passes 1 (δ < w).
  - The code is the experiment's, unchanged, plus `pack16`.
- **`ndig_fast`** replaces the binary search in `cert_power`. Its constants come from **`ndig_magic`**, which is the experiment's search with two changes:
  - It builds its bit-length table from the existing `pow_limbs16`, not from (b)'s `pow_words32`, which is not ported.
  - It has no float-to-signed casts.
- **`cert_power`** takes `d` (`nl` u32 words) instead of y. Its doc is updated. The long division, the digit scan with its selects, the remainder and the carry test are byte-for-byte #235's.
- **Tests:**
  - `powers16` moves into the test module as the reference, and is the lockstep scan's input.
  - `sub_words16` (test-only, select-based) forms the reference differences.
  - Part 0 of `cert_test_kernel` runs `powers_diff` and records in word 29 any mismatch of d², d³, a² or a³ against `powers16` + `sub_words16`. `check_cert_group` asserts it is 0.
  - Part 0 then certifies with `powers_diff`'s outputs, as production does.
  - `cert_power_lockstep` still uses the binary search, so (c) is checked against it power by power.
  - `top_cert` (part 2) takes `dw`: 1 for the production-shaped groups (asserted), `limbs` for the arbitrary intervals, whose widths reach 2^40.
  - **New host test** `ndig_fast_constants_give_the_digit_count`:
    - For every base 10–64 and every width of 1–9 words, `ndig_magic` must find constants.
    - The rule must give ndig(d), against malachite, for d = 0, 2^(L−1) and 2^L − 1 at every L, and b^i − 1, b^i and b^i + 1 at every i.
- CHANGELOG (Unreleased): "Speed up the GPU overlap join's top certificates by computing the difference of the endpoints' powers from the endpoints' difference, and its digit count from its bit length instead of a search."
- The doc comments needed 5 backtick fixes for clippy's `doc_markdown` and `doc_lazy_continuation`. They were caught by the first clippy run after the A/B binaries were built (§2).

## 2. Exactness (logs in `box/`)

| check | result |
|---|---|
| `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`, B (`x_cert.log`; also `smoke_cert.log` on B_pre) | ok, 126 s: **102,365 intervals, 33,582 kept, 203,413 powers scanned above c0, 69,824 with the carry**. Identical to #235's (L29/L30). Word 29 (`powers_diff` against the full powers) is 0 for every interval |
| `cubecl_cuda_join_matches_the_cpu_reference` (`x_ref.log`): base 10's 69; windows b20–b64 incl. **b50, b54**; b57 frontier partitions; tight, sliced and refused layouts; production shape | ok, 78 s |
| dense b58 1e15, 32 partitions (`x_dense58.log`) | ok: 254,938,965 survivors / 14,396,829 checked, asserted equal to the CPU join (= L30) |
| dense b62 1e16, 4 partitions (`x_dense62.log`) | ok: 120,013,475 / 7,355,827, asserted equal to the CPU join (= L30) |
| `NICE_TEST_JOIN_COMPARE=1`, 1e14 at b57/60/62/64, A and B (`{A,B}_cmp_e14.log`) | both pass (join = stride, found 0 = 0). **Counts identical**: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 / 88,159,810; b64 5,702,041,796 / 346,647,759 (= L30's main and combined). Plan MiB identical |
| certificate test on lavapipe (llvmpipe, LLVM 20.1.2), **naga** (`lvp_cert_naga.log`) | ok, 96 s, same counts |
| certificate test on lavapipe, **direct SPIR-V** (`lvp_cert_spv.log`) | ok, 217 s, same counts, no stack overflow |
| join parity on lavapipe, direct SPIR-V, B and A (`lvp_par_spv_{B,A}.log`) | both ok, 111 s / 110 s |
| CI's WGSL lint: `wgsl_dump_for_lint` on lavapipe naga + `scripts/wgsl-lint.py` with CI's 13 `--require`s (`wgsl_lint_B.log`) | **15 shaders, 0 flagged**, rc 0. TopKernel b57: 539 constant divisions (A: 539, L30) |
| A/B runs at 1e16/1e17 | counts identical between A and B in every run, and equal to L30's exact counts (§4) |
| `cargo fmt --all --check` (B) | clean |
| clippy `-p "*" --all-targets -D warnings`, first run (B = `bf55ae8`, `lint1_*.log`) | **failed on 5 doc lints** in the new doc comments (3 `doc_markdown` in the lib, 1 more plus 1 `doc_lazy_continuation` in the test docs). Doc-only |
| **clippy rerun on B2 = `eb3d7e6`** (doc fixes only; `lint_clippy_*.log`, `lint_summary.txt`): default; `--features nice_client/gpu`; `--features nice_client/gpu,nice_client/cubecl-spirv` | **all three clean** (rustc 1.99.1); fmt clean |
| B2's test binary against B's (`build_B2.out`) | **byte-identical**: both md5 140f835b, so every timed and exactness run above is of the pushed code |
| new host test `ndig_fast_constants_give_the_digit_count` (`host_ndig.log`; it is the only non-ignored test in `cubecl_join`, `host_cubecl_join.log`) | ok |
| whole b42 field, `NICE_TEST_JOIN_FULL_FIELD=1` (`x_whole.log`; the first attempt without the variable skipped, `x_whole_skipped.log`) | ok, 62 s: 417,789,835 join survivors, 16,879,877 checked, no hits, join = stride = CPU reference (= #235's, L29) |

## 3. SPIR-V blocks (lavapipe, `scripts/blocks.py`)

| kernel | A (`e9cdac4`) | B | change |
|---|---|---|---|
| TopKernel b57, CI's lint dump (`blocks_lint_{A,B}.txt`) | 478 | **366** | −112 |
| TopKernel b64, join parity dump (`blocks_par_{A,B}.txt`) | 496 | **384** | −112 |
| TopKernel b58 / b60 | 484 / 484 | 372 / 372 | |
| TopKernel b54 / b50 | 382 / 370 | 306 / 294 | |
| TopKernel b40 / b10 | 304 / 154 | 228 / 114 | |
| other join kernels (JoinKernel b57, TopScan, TopFill, Bucket, Check) | 109, 88, 11, 28, 84 | same | 0 |

- These match L31's experiment: (a) + (c) gave 366 at b57, and its estimate for b64 was "near 384".
- **The certificate test's kernels** (B, `blocks_cert_B.txt`):
  - Part 1, the lockstep reference, is unchanged and is the largest at 548 blocks (b57, 3 words), as in L29.
  - Part 0 is at most 334 blocks. It now holds `powers16`, `sub_words16` and `powers_diff` plus two `cert_power`s.
  - Part 2 (`top_cert`) is at most 373 blocks.
  - All are far below the ~1,900 blocks at which the 2 MiB compile thread overflowed (L29).

## 4. A/B (device s per field; interleaved A B per round)

| field | A: e9cdac4, device s (rounds; median, spread) | B: the branch (rounds; median, spread) | **speed-up (medians)** | per round | median of per-round | per_field speed-up | saving per field | SM MHz A / B | max temp |
|---|---|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | 161.93, 168.43, 166.92, 167.83, 165.74 (166.919, 3.9 %) | 158.29, 159.73, 157.94, 160.35, 160.23 (159.726, 1.5 %) | **×1.045** | 1.023, 1.054, 1.057, 1.047, 1.034 | ×1.047 | ×1.044 | −7.19 s | 1440 / 1440 | 67 °C |
| **b62 1e16**, 2 fields | 13.928, 13.872, 14.075, 13.702, 13.978, 13.779 (13.900, 2.7 %) | 13.444, 13.474, 13.411, 13.215, 13.298, 13.371 (13.391, 1.9 %) | **×1.038** | 1.036, 1.030, 1.050, 1.037, 1.051, 1.031 | ×1.036 | ×1.035 | −0.51 s | 1441 / 1457 | 66 °C |
| **b60 1e16**, 2 fields | 31.303, 31.381, 30.914 (31.303, 1.5 %) | 29.561, 29.551, 29.560 (29.560, 0.0 %) | **×1.059** | 1.059, 1.062, 1.046 | ×1.059 | ×1.057 | −1.74 s | 1441 / 1449 | 66 °C |
| b64 1e16, 2 fields | 41.054, 40.176, 40.200 (40.200, 2.2 %) | 39.338, 39.866, 39.025 (39.338, 2.1 %) | **×1.022** | 1.044, 1.008, 1.030 | ×1.030 | ×1.025 | −0.86 s | 1438 / 1424 | 66 °C |

- Spread = (max − min) / median.
- The clock is the mean SM MHz over nvidia-smi samples at ≥ 90 % utilisation. Both trees sat at the 180 W cap.
- At b62 1e16, B ran 16 MHz faster than A at the same power. That is the lighter kernel under a power cap, not noise, so no clock normalisation is applied.
- **Counts** were identical in every run of both trees: b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; found 0. These are L30's exact counts for the combined tree.
- Layouts were identical: slots 5 / 13 / 4 / 6. Plan MiB 1671 / 2050 / 1566 / 2151 for both. Host setup per field was within 0.15 s.
- **A reproduces L30's combined tree.** b62 1e17 166.92 s (L30 166.16), b62 1e16 13.90 (14.05), b60 31.30 (31.09), b64 40.20 (40.70), NiceMark 4887 (4871).
- **b62 1e17 is the noisy one.** A's five rounds span 3.9 %, against B's 1.5 %. Round 1 (×1.023) had A's fastest run. The median of the five per-round ratios is ×1.047, close to the ratio of medians.
- **b62 1e16 is tight:** six rounds at ×1.030–1.051, median ×1.036–1.038. The first three alone gave ×1.036, so the extra rounds did not move it.

### NiceMark nice-only (`--benchmark-secs 150`, A B A B A B, `NICE_API_BASE=http://127.0.0.1:9`; JSON `box/nm_*.json`)

| | A | B | speed-up (medians) | per round |
|---|---|---|---|---|
| **score** | 4836.7, 4886.8, 4895.8 (4886.8, 1.2 %) | 5091.9, 5084.8, 5086.7 (5086.7, 0.1 %) | **×1.041** | 1.053, 1.041, 1.039 |
| b58 MSD-weak (whole field), n/s | 2.18e+14 (2.156e+14–2.192e+14) | 2.269e+14 (2.257e+14–2.289e+14) | ×1.041 | 1.062, 1.030, 1.041 |
| b58 MSD-strong (whole field) | 1.24e+15 (1.205e+15–1.244e+15) | 1.264e+15 (1.259e+15–1.279e+15) | ×1.019 | 1.061, 1.016, 1.016 |
| **b60 MSD-weak** (sampled) | 4.172e+14 (4.16e+14–4.2e+14) | 4.404e+14 (4.355e+14–4.428e+14) | ×1.056 | 1.037, 1.061, 1.059 |
| **b62 MSD-weak** (sampled) | 5.383e+14 (5.367e+14–5.45e+14) | 5.675e+14 (5.641e+14–5.685e+14) | ×1.054 | 1.051, 1.056, 1.041 |

- The whole-field b58 scenarios have identical counts in A and B: MSD-weak 33,590,315,220 / 1,894,592,860, MSD-strong 4,027,773,430 / 226,773,299.
- The sampled b60/b62 scenarios draw different samples per run in both trees, so their counts differ run to run.
- Each sweep took 35–36 s.

## 5. Against the projection and L31

- **Projection** (task brief): the top kernel is 43 % of a b62 1e17 field after #235 + #236 (36.6 % at b60 1e16). (a) + (c) took ~18 % off the top kernel on #235 alone, which projects to ~7 % whole-field.
- **Measured:** 4.5 % at b62 1e17, 3.8 % at b62 1e16, 5.9 % at b60 1e16.
  - Two to three points short at b62. No profile was taken here, so it is not known whether the top kernel lost less than 18 % on this tree or whether its saving overlaps with other work.
  - At b62, 7.2 s saved of a 71.9 s top phase (L30's profile) is ×0.90 on the top phase.
- **L31 on #235 alone** gave (a) + (c) ×1.062 (b62 1e16), ×1.021 (b62 1e17, rounds 1.062 / 1.020 / 1.019) and ×1.031 (b60).
  - On the combined tree the order at b62 flips (1e17 above 1e16) and b60 is higher.
  - With 1–4 % run-to-run spreads, the b62 numbers of both studies are consistent with ~4–5 % at b62.

## 6. Verdict

| scenario | speed-up | bar |
|---|---|---|
| **b60 1e16** (3 rounds) | **×1.059** | ≥ 5 %: met |
| **b62 1e17** (5 rounds) | **×1.045** | ≥ 5 %: **not met** |
| **b62 1e16** (6 rounds) | **×1.038** | ≥ 5 %: **not met** |
| b64 1e16 (3 rounds) | ×1.022 | not slower: met |
| NiceMark score | ×1.041 | not slower: met |
| NiceMark b60 / b62 MSD-weak | ×1.056 / ×1.054 | |
| NiceMark b58 MSD-weak / MSD-strong | ×1.041 / ×1.019 | not slower: met |

**No-go: b62 is 4–4.5 % on the harness, below the 5 % bar.** So the branch was pushed as `exp/top-cert-2b`, with no PR body. Everything else a PR needs is done: exact, smaller SPIR-V, lint-clean, CHANGELOG line, a commit message written for review.

Options, for the user:
1. **Add (b) after an M4 check.**
   - On #235 alone, all three gave ×1.053–1.056 at b62 against (a) + (c)'s ×1.021–1.062. So (b)'s share is 0–3 % and unresolved.
   - It is the only remaining lever on the long division, which is still the largest stage of the kernel (33 %).
   - It needs a mayalaran run, because `mul_hi` lowers to a u64 product shifted by 32 in WGSL/MSL.
2. **Relax the bar for exact, size-reducing changes.**
   - This branch is ×1.04–1.06 at the live bases, never slower, bit-identical.
   - It cuts the top kernel by 23 % in SPIR-V blocks, which is margin for the next top-kernel change.
   - It could go up as is, described as ≈ 4–6 % at b60/b62. A PR body would still have to be written; none was, per the no-go rule.
3. **Park it** and fold (c), the larger and self-contained half, into the next PR that touches `cert_power`.
