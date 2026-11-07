Stacked on #246 (itself on #241): their commits are the base of this branch; the new work is the last two commits. The first (the static bucket order) is the main change; the second checks the join's survivor stage once per top batch (its own section below).

## What

Each batch's top stage used to bucket the tops in three steps. The top kernels certified each top of each slot, appended its record, wrote its bucket word to `top_b` and counted it into its `nroots` buckets (one per digit-sum root). `top_scan_kernel` turned the counts into per-bucket offsets, fill cursors and one work item per (slot, bucket). `top_fill_kernel` then wrote every kept top's id into the list (`tl`) of each bucket it probes. The join gathered each bucket's tops through that list.

This PR orders the top layer once per slice instead, so that every slot's buckets come out as contiguous runs of records:

- **A top's buckets depend on the slot only through a rotation.** A top `P = P0·b^p + v` of slot v goes to bucket `(key, (root − pc) mod (b−1))` for each root, with `pc = (c0 + v) mod (b−1)`, `c0 = P0 mod (b−1)` (`b^p ≡ 1 mod b−1`) and `key = P0 mod b` at the key level (else 0). Key and c0 are fixed by the prefix. Call `g = key·(b−1) + c0` the prefix's group (`nb` groups, as many as buckets). For every slot, bucket `(key, cls)` holds exactly the kept tops of one group per root, group `(key, (root − cls − v) mod (b−1))`.
- **Host:** `JoinDevice::new` sorts the slice's top layer by group (a counting sort, stable) and uploads each group's first index `goff[g]` (`nb + 1` words). The tlay entry carries `g` and `goff[g]` in the two words that held `P0 mod (b−1)` and the key.
- **Top kernels:** a kept top goes into its group's segment of the slot's records, at `slot·ntlay + goff[g] + at`, where `at` comes from one counter per (slot, group), `grp_cnt` (the per-batch scratch `bucket_cnt` was, same size). `top_fd_kernel` takes one atomic per plane: a plane of sorted prefixes is almost always of one group, and a plane that straddles two takes one per kept lane. `top_kernel` takes one per top, inside its branch. A prefix gives at most one top per slot, so a segment cannot overflow.
- **Join:** work item w is bucket `w mod nb` of slot `w / nb` (no `work` array). Threads `r < nroots` read their group's offset and count, and thread 0 places the segments in shared memory. The batch load maps bucket position q to its segment and reads record `start + q − cum`. Consecutive threads now read consecutive 32-byte records instead of gathering them by id through `tl`. A batch still takes up to 256 tops across segment boundaries, so batch sizes (and the transposed-AND threshold) are as before. The work item's list offset, entry base, entry count and key digit are kept in shared memory and read once per wave, which keeps the kernel within 48 registers.
- **Gone:** `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`, `work`, `cursor` and the per-slot top count. That is two launches per batch, and `nroots` counting atomics per kept top in the top kernels. `STAGES` goes from 6 to 4.
- **Plan:** the footprint drops `tl`, `top_b`, `work` and `cursor` and adds `goff`. Layouts are 11–29 % smaller. Slots per launch, slices and batches are unchanged on every field below; the survivor bound still sets them.

## Why

Measured on #246 on an RTX 3080 at the same 180 W cap, with one device sync per kernel group: `top_scan_kernel` + `top_fill_kernel` took 9.7 s of a 100.2 s b62 1e17 field (9.7 %) and 1.77 s of a 19.6 s b60 1e16 field (9.0 %). That is 0.25 ns per kept top (3.8·10^10 kept tops per b62 1e17 field). The fill does two returning atomics on contended bucket cursors and two scattered 4-byte stores per kept top at b62, eight of each at b64. The join then read `tl` and gathered each top's record by a random id, once per bucket that lists it.

## Soundness

- **Same tops per bucket.** By the identity above, the kept tops of a bucket's `nroots` groups are exactly the kept tops whose class `(root − pc) mod (b−1)` is the bucket's for some root, with the same key: the tops the fill used to list there. The roots are distinct mod `b − 1`, so the groups are disjoint, and each kept top is still in exactly `nroots` buckets. Only the order inside a bucket changes, and that was atomic order before. Every pair the AND and the prefilter see is the same, so every count is unchanged.
- **Records.** Every kept top is written once. Its index is its group's segment start plus a unique place from the group's counter: an aggregated atomic plus the plane's exclusive prefix, or a per-lane atomic. Segments are disjoint and at most as long as the group. The check reads `top_rec` by the index the join staged, as before.
- **Indices.** Records stay below `slots · ntlay`, as before. The host checks that every prefix fits 64 bits, as before, and, new, that a base has at most 8 digit-sum roots (the most of any base up to 64; the join keeps a bucket's segments in 8 shared words).

## Measurements

**Card:** RTX 3080 10 GB (driver 580.159.03) on a rented box whose host caps it at **180 W** (default 340 W). Every timed run sat at the cap (176–180 W).

**Method:**
- #246 (`f3fb390`) and this PR, same box, two binaries. Rounds were interleaved with the order alternating (#246, PR; PR, #246; #246, PR), with nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b57 28151599893042801193, b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds. "Per round" is #246's time over the PR's in the same round. MHz is the mean SM clock per side. "Cycles" is the ratio of device seconds × clock.

| field | #246 s/field (rounds) | this PR s/field (rounds) | speed-up | per round | MHz #246 / PR | cycles |
|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **100.38** (98.06, 100.38, 100.44) | **86.68** (85.97, 86.68, 86.73) | **×1.158** | 1.141, 1.158, 1.158 | 1491 / 1482 | ×1.174 |
| b62 1e16, 2 fields | **8.347** (8.35, 8.35, 8.35) | **7.276** (7.28, 7.25, 7.28) | **×1.147** | 1.147, 1.152, 1.147 | 1485 / 1506 | ×1.151 |
| **b60 1e16**, 2 fields | **19.675** (19.67, 19.68, 19.74) | **17.049** (17.05, 17.05, 17.22) | **×1.154** | 1.154, 1.154, 1.146 | 1483 / 1473 | ×1.150 |
| b64 1e16, 2 fields | **28.335** (28.34, 28.31, 28.46) | **23.189** (23.19, 23.13, 23.43) | **×1.222** | 1.222, 1.224, 1.215 | 1462 / 1478 | ×1.220 |
| b57 1e14, 3 fields | 0.664 (0.67, 0.65, 0.66) | 0.606 (0.61, 0.59, 0.61) | ×1.096 | 1.105, 1.095, 1.096 | | |
| b60 1e14, 3 fields | 0.607 (0.61, 0.61, 0.60) | 0.575 (0.57, 0.58, 0.57) | ×1.056 | 1.066, 1.048, 1.047 | | |
| b62 1e14, 3 fields | 0.518 (0.53, 0.51, 0.52) | 0.491 (0.50, 0.48, 0.49) | ×1.055 | 1.056, 1.045, 1.055 | | |
| b64 1e14, 3 fields | 0.723 (0.73, 0.72, 0.72) | 0.703 (0.71, 0.69, 0.70) | ×1.028 | 1.028, 1.041, 1.028 | | |

- At b62 1e17 that is 13.7 s saved per field, more than the scan and the fill cost (9.7 s). The rest comes from the join's batch load, which reads consecutive records, and from the top kernels' lost counting atomics (below).
- It is not clock: both sides ran at the same clocks, and the cycle ratios equal the time ratios.
- b64 gains most: it has 8 roots, so the fill did 8 atomics and 8 stores per kept top, and `top_kernel` 8 counting atomics.

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 6 rounds, alternating):

| | #246 | this PR | speed-up |
|---|---|---|---|
| **score** | median 6638.4 (6594.3–6681.4) | median 7431.0 (7372.2–7501.0) | **×1.119** (per round 1.114, 1.117, 1.121, 1.103, 1.138, 1.122) |
| b58 MSD-weak (whole field) | 3.076e14 n/s | 3.523e14 | ×1.145 |
| b58 MSD-strong (whole field) | 1.354e15 | 1.413e15 | ×1.043 |
| b60 MSD-weak (sampled) | 6.357e14 | 7.333e14 | ×1.153 |
| b62 MSD-weak (sampled) | 7.869e14 | 9.007e14 | ×1.145 |

**The top stage alone** (`cubecl_cuda_top_fd_timing`, the first 40 batches of a production plan's first slice, ns per top prefix and partition, medians of 6 rounds per side). The FD kernel is faster with the sorted layer and the group append. It no longer does `nroots` counting atomics and the bucket-word store per kept top, and the sorted order costs it nothing visible. `top_kernel` is unchanged.

| field | `top_fd_kernel` #246 / PR | `top_kernel` #246 / PR |
|---|---|---|
| b62 1e17, consecutive partitions | 0.2291 / 0.2173 (×1.054) | 0.3629 / 0.3610 |
| b62 1e17, every other partition | 0.3566 / 0.3456 (×1.032) | 0.3564 / 0.3550 |
| b60 1e16, consecutive partitions | 0.2283 / 0.2153 (×1.060) | 0.3403 / 0.3424 |
| b60 1e16, every other partition | 0.3302 / 0.3187 (×1.036) | 0.3279 / 0.3304 |

## Exactness

All on the RTX 3080 (CUDA) unless marked lavapipe, on this code as of the GPU session. Since then only comments, one variable name and the tests changed (the new host test and the sentinel, below).

- `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69; windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions; sliced windows; and the production shape.
- `cubecl_cuda_top_fd_matches_the_top_kernel`, adapted: ok, 26 fields, 279 batches (23 with a clipped block), 237,907,266 tops (the same totals as before this PR). Both top kernels give the same count per (slot, group) and the same sorted records in every segment. Every record's prefix belongs to its segment's group, and no segment overruns.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept.
- Dense fields, asserted equal to the CPU join:
  - b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked.
  - b62 1e16, 4 partitions: 120,013,475 / 7,355,827.
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): ok. 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0. Counts identical to #246's: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759.
- Every timed field above has #246's survivors and full checks in every round (at 1e16, the two fields' totals):
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - NiceMark's whole-field scenarios: identical in all 12 runs (b58 MSD-weak 33,590,315,220 join survivors, MSD-strong 4,027,773,430).
- `join_plan` and `cubecl_join` unit tests: ok. A new host test, `sorted_layer_and_segments_match_the_cpu_buckets`, runs without a device (8 s in a debug build): on b10, the 17 test windows and the b62 and b64 1e14 fields (key level on and off; 2 to 8 roots), it checks that the sorted layer is a stable permutation by group with the right words and offsets, and that for any kept subset of a partition's tops the join's segment walk, simulated in u32 at two slots, reads each bucket exactly the tops `cpu_join` lists there (492,116 buckets).
- Since the GPU runs, `run_tops` (the FD-vs-top-kernel test's helper) fills `top_rec` with a sentinel before each kernel's run and asserts no counted record is left at it, so a skipped record write cannot hide behind the other kernel's record at the same index. That version has run on the CPU build only (clippy, the host tests); CI's lavapipe job is the first to run it on a device.
- lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups), every wgpu test of `cubecl_join` (CPU-reference parity incl. b50/b54, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler (8 passed each).
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 14 shaders, 0 flagged (the two deleted kernels' shaders are gone; JoinKernel b57: 29 constant divisions).
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.

## Registers

From the driver's JIT of the PTX each process compiled at run time (NVRTC, as CubeCL runs it; CubeCL's source differs slightly from process to process, so the allocation moves):

| kernel | #246 | this PR |
|---|---|---|
| `join_kernel` | 47–48, no spills in 37 of 37 images | 46–48, no spills in 30 of 37; 40 + 8–32 B of spills in 7 |
| `top_fd_kernel` | 108–111 | 108–112 |
| `top_kernel` | 80 | 97–103 |

- **The spilling variant is new with this PR.** In about one image in five (7 of 37), the driver's JIT allocates the join 40 registers and spills 8–32 B, in the per-work-item and per-wave code (not in the chunk loop or the walk). #246's join never did: 37 of 37 images here, and 100 of 100 processes in an earlier session. The 47/48 wobble was there before; it moves with CubeCL's per-process order of the shared arrays.
- The kernel is the same at every field size for a base (the 1e14 and the production fields have the same join parameters), so production processes will get the spilling variant at about that rate. That none of the 12 timed 1e16/1e17 processes did is not a guarantee: at about one in five per process, 0 of 12 has roughly an 8 % chance.
- Where it occurred (four 1e14 A/B processes), the runs were −2.7 % to +1.8 % against the same field's spill-free runs, within those fields' 2–4 % spread. It was not timed on a production field; for scale, nvcc's 40-register spill variant of #246's join cost about 1.5 % of a field.
- The join stays at 5 cubes per SM, set by its shared memory (+84 bytes per cube here), whichever variant the JIT picks.
- `top_kernel` went from 80 to ~100 registers (3 to 2 cubes per SM). It runs a whole batch only at power-of-two bases (b64); elsewhere it takes only the clipped blocks. The top-stage timing above is at b62 and b60, where it does not run whole. At b64 it was not timed alone: the whole-field ×1.222 at b64 includes it.

## Second commit: the survivor stage checked once per top batch

The join kernel stages the pairs that pass the prefilter in shared memory and writes them to the survivor list once the stage is half full. It checked the stage after every chunk of 32 tops: two barriers and a shared load per chunk. The second commit checks it once per batch of up to 256 tops, after the batch's last wave. The first of the two barriers there also orders the clearing of the batch's clip words after every thread's last chunk, as the per-chunk barriers did before.

**Exactness.** A batch can still overrun the stage: it can add up to 256 tops times the bucket's entries, far more than the 1,024 the stage holds. That was already handled: a pair that finds the stage full goes to the survivor list directly, with the same list atomic and the same bound. Those pairs passed the prefilter too, so the list holds the same entries either way, and no pair is lost. If the list itself overflows, the batch's count says so and the batch runs again, as before. The commit only moves where the barriers are, and the counts below are unchanged.

**Measured** on the same box after the A/B above: the first commit alone against both commits, 3 interleaved rounds (device s per field):

| field | first commit | both commits | speed-up | per round | MHz first / both | cycles |
|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | 86.27 (85.39, 86.58, 86.27) | **83.86** (83.60, 83.86, 84.60) | **×1.029** | 1.021, 1.032, 1.020 | 1504 / 1455 | ×1.060 |
| b62 1e16, 2 fields | 7.244 (7.23, 7.28, 7.24) | 7.071 (7.07, 7.05, 7.27) | ×1.024 | 1.023, 1.032, 0.996 | 1490 / 1485 | ×1.037 |
| **b60 1e16**, 2 fields | 17.116 (17.02, 17.13, 17.12) | **16.745** (16.60, 17.00, 16.75) | **×1.022** | 1.025, 1.008, 1.022 | 1461 / 1448 | ×1.034 |
| b64 1e16, 2 fields | 23.144 (23.15, 23.10, 23.14) | 22.465 (22.46, 22.48, 22.36) | ×1.030 | 1.031, 1.028, 1.035 | 1466 / 1458 | ×1.045 |

- NiceMark nice-only, 2 rounds: score ×1.019 (per round 1.024, 1.014); b58 MSD-weak ×1.030, MSD-strong ×1.014, b60 ×1.009, b62 ×1.024. The whole-field scenarios' join survivors are identical.
- Both commits together against #246: about ×1.19 at b62 1e17 (100.38 → 83.86 s) and ×1.18 at b60 1e16 (19.675 → 16.745 s), from runs in two A/B sessions on the same box.
- Exactness on the two commits (the GPU runs used the same kernel code; since then only comments, one variable name and the tests changed): the 1e14 compare at b57/60/62/64, `cubecl_cuda_join_matches_the_cpu_reference`, both dense fields, the whole b42 field, the FD-vs-top-kernel and certificate device tests (same totals as above), lavapipe with naga and direct SPIR-V (8 passed each), the WGSL lint (14 shaders, 0 flagged), fmt and clippy ×3. Every timed field has the counts above in every round.

## Not in this PR

- **No CPU change.** The CPU join forms each partition's buckets on the host and is unaffected.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
