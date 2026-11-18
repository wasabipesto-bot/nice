# G2 GPU benchmark (base 64, RTX 3080 at 260 W, Vast 61025183): results 2026-11-17

## Verdict: stop. Measured ratio ×5.1 against the same-session main (×4.8 with the review's overhead allowance)

| stop number (REVIEW.md) | measured | result |
|---|---|---|
| all-in kept 64-pair word ≤ 25 ps | **32.0 ps** (31.7–32.0 over 3 rounds) | **fails** |
| per stored bottom ≤ 25 ps | 18.5–19.8 ps | passes |
| end-to-end > 1.06 fs per admissible n = stop (the review's ×5 at 5.3 fs) | **1.24 fs** | **fails** |
| same line against this session's main, 6.35 fs (×5 = 1.27 fs, ×6 = 1.06 fs) | **×5.13** (×5.05–5.17 over main's 3 rounds) | between ×5 and ×6: the rule says stop unless one named component is the culprit and has a measured fix. I found none: the one attempt at the obvious culprit, v11 below, came out slower |
| 9070 XT run needs ×6 or better | ×5.1 | **not earned** |

- **End to end, 1.24 fs per admissible n:**
  - **Kernel plus preparation: 1.123 fs**, measured. Rounds gave 1.1240, 1.1230 and 1.1226. A second super-unit gave 1.1224.
  - **Tops: +0.049 fs.** This is B64.1's FD top test (0.104 ns) times 4.69e-7 tests per admissible n, with every f0 4 top tested, as the prototype does.
  - **Survivors: +0.066 fs.** This is 2.634e-6 survivors per admissible n, costed in two parts:
    - prefilter and stage at B64.1's 20 ps per AND survivor (upper end), +0.053 fs;
    - 6.1 % of them through main's check at 0.084 ns, +0.013 fs.
- **Same-session main: 6.254, 6.386 and 6.402 fs, mean 6.35.** These are the client's own processing times for ten b64 1e17 fields at 0.05–0.95, with the 3 empty fields counted.
- **Ratio: 6.35 / 1.24 = ×5.13.**
- **Not included:** host and launch overhead per super-unit. The review allows 8 % for it, which gives ×4.75.
- The kernel I measured is not the staged draft. The draft ran at 4.93 fs (×1.3). The ten variants below took it to 1.12 fs. Every variant reproduced every unit's survivor set.

## Measured (3 rounds, card idle before each binary, no builds while timing, nvidia-smi at 100 ms)

Final kernel = v10 (`g2bench.cu`, `nvcc -O3 -arch=sm_86 -std=c++17 -DKVER=10 -DMINB=3`), 200 launches per mode, medians.
Super-unit π′ = 712012851. Counts per super-unit: 1,042,046 parents; 33,705,647 stored children; 250,486,772 flat
incidences; 123,163,397 kept incidences; 11,768,560 survivors; 4.4679e12 admissible n.

| component | round 1 | round 2 | round 3 | per admissible n |
|---|---|---|---|---|
| prep (roots → sorted parent records), per parent | 433 ps (0.452 ms) | 433 ps | 431 ps | 0.101 fs |
| bottom side alone (probes off), per stored child | 18.5 ps (0.624 ms) | 19.8 ps (0.666 ms) | 18.5 ps (0.624 ms) | 0.140–0.149 fs |
| per flat incidence, skip off (b − a) | 17.6 ps | 17.6 ps | 17.8 ps | — |
| **per kept word all-in (c − a)**: skip tests, list, OR, survivor records | **32.0 ps** | **31.7 ps** | **32.0 ps** | 0.874–0.883 fs |
| same without the survivor append (NOOUT build, c − a) | 27.5 ps | 27.4 ps | 27.7 ps | 0.76 fs |
| full kernel | 4.570 ms | 4.566 ms | 4.566 ms | 1.022 fs |
| **end to end, prep + full kernel** | **1.1240 fs** | **1.1230 fs** | **1.1226 fs** | |
| the staged draft (v1, unchanged), end to end | 4.934 fs | 4.933 fs | 4.932 fs | (word 163 ps) |
| power / SM clock while busy, v10 | 203 W / 1808 MHz | 200 W / 1815 MHz | 148 W / 1772 MHz | max 61 °C |
| main while busy | 258 W / 1798 MHz | 258 W / 1786 MHz | 258 W / 1786 MHz | max 73 °C |

- **Second super-unit, π′ = 391856203.** I dumped it with `g2proto dumpsu` on ivory (one thread, nice 19).
  - Its counts are within 0.2 % of the first's.
  - It cost the same: 1.1224 fs end to end, 32.0 ps per kept word, 18.5 ps per child, 431 ps per parent. Every unit's set is equal.
- **Kernel resources (v10, k_main10 full mode):**
  - 72 registers, 32,200 B static LDS, 256 threads.
  - 3 blocks per SM, i.e. 24 of 48 warps.
  - No spills in the inner loop. There are 24 B of stack, in per-block setup only.
- **Main:** upstream main 7e0113fc with `--features gpu,cubecl-cuda`, using CubeCL CUDA.
  - Runs were m1 06:03, m2 06:42 and m3 07:09 UTC. Field times were reproducible to 2 %.
  - `summarize_main.py`'s "warm-up recv to last recv" wall printed 5.631 for m3. That figure is wrong: in m3 the client claimed field 900001 before the warm-up field, so the start point fell after the first field. The table therefore uses the sum of the client's own "Processed" times (`box_out/summary_main_corrected.txt`).

## Against the predictions (b64, fs per admissible n)

| term | author central | author F2-fixed | review low / **central** / high | **measured** |
|---|---|---|---|---|
| 64-pair words + skip tests (+ flagging) | 0.397 | 0.472 | 0.391 / **0.641** / 1.086 | **0.88** (c − a) |
| children + chunking + sort (+ prep) | 0.049 | 0.049 | 0.060 / **0.118** / 0.228 | **0.24** (0.14 bottom side + 0.10 prep) |
| tops (+ order) | 0.016 | 0.016 | 0.029 / **0.041** / 0.049 | 0.049 (B64.1 FD, every top) |
| survivors + check | 0.053 | 0.053 | 0.053 / **0.087** / 0.150 | 0.066 (+ records, inside the word) |
| other | 0.027 | 0.031 | 0.016 / **0.077** / 0.206 | not measured |
| **total** | 0.542 | 0.621 | 0.550 / **0.965** / 1.721 | **1.24** (1.34 with the review's 8 %) |
| word, ps | 12.7 | — | 13.5 / **21.8** / 29.3 | **32.0** |

- **The word is above the review's high end.** The review predicted 21.8 ps; I measured 32.0.
- **The bottom side and prep together are twice the review's central** (0.24 fs against 0.118). The prep is costed per super-unit from the 9.3M depth-4 roots, and that alone is 0.10 fs.

## Where the word's 32 ps goes, and why it stops here

- The inner loop is **bound by LDS issue**.
  - Each kept word needs 17 independent 8-byte slice loads, and the loads are already conflict-free (two wavefronts per warp load).
  - The LDS floor is about 1.06 clk per word-slot per SM, roughly 8.7 ps per slot at 1.8 GHz.
  - The measured dense cost is 17.6 ps per flat slot, about 2× that floor.
- **The common-mask skip does not pay its 49 % on a SIMT lane grid.**
  - Lanes are chunks: each half-warp takes one probe across 16 chunks.
  - Chunks a probe skips still occupy their lane, and still cost the whole warp's LDS issue.
  - With whole-probe skipping, 60.5 % of the lane slots do work. Full mode is only 10 % faster than skip off (4.57 against 5.08 ms).
  - v11 tried finer, 8-chunk lists. Slot use rose to 66 %, but the kernel got slower.
- **The survivor append costs 4.5 ps per kept word.** That is 10.9M 16-byte records (one per nonzero word; 1.08 survivors each).
- What would be needed for ×6 (1.06 fs all-in): a word of about 25 ps with everything else unchanged. That means either a lane-dense way to use the skip without bank conflicts or extra LDS issue, or fewer than 17 loads per word. I did not find either.

## Exactness

- **Every variant (v1–v11, every mode that produces survivors) reproduced all 64 units' survivor sets of both super-units.**
  - The sets are 11,768,560 and 11,769,950 n, with 0 outside a clipped top.
  - The GPU parent order and class segments equal the CPU's stable sort in every run.
  - Children, chunks, flat incidences, kept incidences and survivors equal the CPU reference's counts exactly (`cpu_ref.txt`).
  - Full CPU-ref runs: `box_out/exact_v10_full_cpu_ref.log` and `box_out/su2_v10.log`.
- **From v5 on, survivors leave the kernel as one record per nonzero word:** top or (unit, probe slot), the first parent of the chunk, and the 64-bit word.
  - The host expands each record by re-deriving the chunk's 64 certified children, as a survivor check would.
  - It then checks the set.

## What I changed (all variants in `bench/variants/`, dev logs in `bench/box_out/dev_*.log`)

Dev numbers use 3 launches per mode with a cold clock, so they are about 5 % above the protocol numbers. Full-mode ms / word ps / end-to-end fs:

| variant | change | full ms | word ps | e2e fs |
|---|---|---|---|---|
| v1 | staged draft, unchanged: compiled and exact first time | 22.4 | 175 | 5.26 |
| v2 | warp-aggregated survivor atomics (one per survivor before); TILE 512, 4 blocks/SM | 13.8 | 103 | 3.33 |
| v3 | slices v-major (bank pair = chunk), lane = chunk, lock-step probe streams | 16.6 | 128 | 3.95 |
| v4 | **probe digits precomputed as bytes (padded with a zero slice), OR fully unrolled** | 9.60 | 71 | 2.39 |
| v5 | probe list per 16-chunk round (whole skipped probes cost nothing); per-word records with ballot-first append; prep via select-if | 8.00 | 58 | 2.02 |
| v6 | phase 1 with one barrier per 256 parents; 64×64 transpose by 5 shfl_xor stages instead of 128 ballots | 6.47 | 47 | 1.67 |
| v7 | survivor records into warp-private 256-record slabs (the dependent global atomic per warp step was ~0.4 ms) | 6.08 | 44 | 1.58 |
| v7+prep3 | roots as r4 only; sort pairs carrying the 16-byte parent record (prep 1.09 → 0.50 ms) | 6.07 | 44 | 1.47 |
| v8 | LDS 47 → 32 KB (child masks recomputed in phase 2, no prob_i): 3 blocks/SM | 5.33 | 38 | 1.30 |
| v9 | two list entries per lane per step | 5.07 | 36 | 1.25 |
| **v10** | parent records read straight from the sort (no split pass); digits by one 16-byte LDS load | **4.89** | **34** | **1.20** |
| v11 | half-round (8-chunk) lists for a denser skip — **slower, rejected** | 5.27 | 37 | 1.28 |

The algorithm and the order are unchanged throughout: same chunks, same kept incidences, same survivors.

## What could differ on the RX 9070 XT (wgpu / SPIR-V), and what a CubeCL port needs

- **Ratio:** the kernel is LDS-issue-bound and main is ALU- and survivor-path-heavy, so the two scale differently. RDNA4 has 128 B/clk of LDS per CU and 64 CUs at about 2.9 GHz, against 68 SMs at 1.8 GHz here. That could favour G2 by up to about 1.5× in raw LDS throughput, but only a run would tell. The 3080 result does not earn that run under the stated rule.
- **LDS:**
  - The kernel uses 32.2 KB per 256-thread group. Production sits at 18.9 KiB for occupancy.
  - Over half of it is the probe tables: 9.2 KB of digits and 2.3 KB of lists, sized to 576 probes (this super-unit's maximum is 561).
  - Then the slices (8.3 KB) and the pending indices (5.1 KB).
  - To get to ~19 KiB would need 8-chunk rounds or probe tables split per root class, and either costs lane density.
- **64-lane planes:**
  - The lane = chunk layout needs 16 lanes per probe, so a 64-lane plane takes 4 probes, and the bank argument holds per 16 lanes.
  - The transpose becomes the natural 64×64 case: lane = row, 6 shuffle stages, with no 32-bit halves.
  - The ballot-first append and the slab prefix need u64 ballots, i.e. `subgroupBallot` as uvec4.
- **CubeCL SPIR-V atomic-store rule:** the compiler keeps only the first of several atomic stores of one value in a block.
  - The kernel uses no atomic stores. Its shared atomics are `atomicAdd` slot grabs for the probe lists, and the counter resets are plain stores behind barriers.
  - Its global atomics are `atomicAdd` with a returned value (slab ids, counts).
  - So the rule does not bite as written, but any rewrite of the list counters into atomic stores would.
- **u64:** everything is u64 (masks, slices, words). This needs the SPIR-V Int64 capability and int64 atomics for the 64-bit counters, or 32-bit counters, which suffice here.

## Box log, rules and files

- **Production hosts** were mapped to 127.0.0.1 and ::1 before any client ran. The block was proven before each of the 3 main runs: every production host refused connection (curl exit 7), and github answered 200. Proofs are in `box_out/proof_*.txt`. The client talked only to the local stub on 127.0.0.1:8400. Nothing was pushed, and there were no PRs and no subagents.
- **One stray `nvidia-smi -lms 100` sampler:**
  - It was left by an ssh call that hung, and ran from 06:58 to about 07:15. I found and killed it.
  - During that time it overlapped the second super-unit run, so that run's power samples are mixed. Its timing is unaffected.
  - It also overlapped the first 6 minutes of main m3. m3's field times match m2 to 0.2 %.
- **Harness refusals:** none.
- **Scripts (`bench/`):**
  - `drive.sh` was re-pointed at this box.
  - `box/build_main.sh` now uses upstream/main; the box's clone had `origin` = the fork.
  - `box/round.sh` is new: the timing round.
- **Results (`bench/box_out/`):**
  - kernel timing rounds: `round{1,2,3}_{v1staged,v10,v10o}.log` with `smi_r*`;
  - second super-unit: `su2_v10.log`;
  - main: `client_m*.log`, `out_m*.jsonl`, `smi_m*.csv`, `summary_m*.txt`, `summary_main_corrected.txt`;
  - build logs: `build_v*.log` (ptxas);
  - SASS of the final kernel: `sass_v10_m2.txt`.
- **Final source:** `bench/g2bench.cu` (KVER 10 default; it holds every kernel version) = `bench/variants/g2bench_final.cu`.
- **Second super-unit's inputs:** `bench/su64_391856203/`.

## CubeCL port on CUDA (2026-11-17 10:30–12:00 UTC, Vast 61056498, RTX 3080 at a 280 W cap, same box and session for all rows)

**Verdict:**
- The CubeCL port (`G2/PORT-NOTES.md`, branch `g2-cubecl-local` at `8579db48`, `--features cubecl-cuda`) is
  **exact at 32-lane planes on real hardware**: both super-units, every unit's survivor set, the counts, the GPU
  preparation's parent order, and 0 kernel errors. It also passed with the ballot transpose and with one entry per
  step.
- It costs **×1.37 the hand-written CUDA v10: 1.573 fs against 1.147 fs** per admissible n, end to end.
- **The whole gap is outside the 64-pair word.** Phase 3 runs at parity: kept word all-in 32.5–34.4 ps against
  v10's 32.9.
- Against the same-session main (6.396 fs), the port as it stands is **×3.79** (×5.07 for v10), with tops and
  survivor checks (+0.115 fs) added to both.

| (ms, median of 200 launches; 3 rounds) | v10 (hand CUDA) | CubeCL A1 (shuffle transpose, ballot ranks) | CubeCL A0 (plane-scan ranks, the port as of 10:25) |
|---|---|---|---|
| preparation | 0.425 / 0.447 / 0.444 (cub select-if + radix sort) | 1.027 / 1.039 / 1.034 (hist + scan + scatter + bucket sort) | 1.03 |
| bottom side (probes off) | 0.628 / 0.635 / 0.638 | 1.971 / 1.991 / 1.764 | 2.19–2.39 |
| phase 3 (full − probes off) | 4.05 / 4.06 / 4.05 | 4.03 / 4.00 / 4.23 | 6.2–7.0 |
| full kernel | 4.680 / 4.694 / 4.689 | 5.998 / 5.990 / 5.997 | 8.18–9.41 |
| **end to end, fs per admissible n** | **1.143 / 1.151 / 1.149** | **1.572 / 1.573 / 1.574** | 2.06–2.34 |
| busy power / SM clock | 168 / 147 / 130 W, 1.73–1.76 GHz | 201 / 180 / 189 W, 1.78–1.85 GHz | ~210 W, 1.81–1.88 GHz |

- **Main, same session:**
  - ten base-64 1e17 fields at 0.05–0.95 (B64.1) through the stub, production hosts blocked and proven
    (`raw/cuda_box/proof_*.txt`);
  - **6.396 fs** per admissible n (812.2 s of client processing, 3 empty fields), at 276 W and 1.79 GHz.
- **Where CubeCL loses** (phase-cut timing of the bottom side, `--cut`):
  - shuffle transpose 0.80 ms;
  - common masks by shared `fetch_or` 0.40 ms (v10 had them free inside the transpose);
  - probe setup 0.18 ms;
  - the rest (phase 1, barriers) 0.75 ms, against v10's whole bottom side of 0.63 ms;
  - the preparation +0.59 ms.
- **The first fix**, made on this box: the plane scans in the ordered compaction and the record append became a
  ballot and population counts. That took A0 → A1, 2.33 → 1.57 fs. CubeCL lowers `plane_exclusive_sum` /
  `plane_sum` to shuffle loops on CUDA.
- **The noted next fixes** (unmeasured):
  - common masks from the transpose's registers, not shared atomics;
  - one 16-byte parent record per load;
  - a radix-sort preparation as v10's.
  If they reach v10's bottom side and prep, the port returns to about ×5.
- **Not counted in main's number:** a 1-job CubeCL compile-log run (about 1 s of GPU) happened at 11:13, during
  main's first field.
- Raw: `G2/port/raw/cuda_box/`.
- **Run-to-run timing of the CubeCL kernel is bimodal on this box.**
  - Within a process, the 200-launch medians are stable.
  - Across processes, the full kernel sits at either ~6.0 ms or ~7.4–7.6 ms, and skip-off at 6.2–8.1 ms. The batch
    size changes nothing: the queued-launch build `02075501` gave 1.57–1.93 fs with batches of 1008 and of 4032.
  - v10 was stable to ±0.4 % in every run.
  - The 1.573 fs above is the low mode, seen in all three A1 rounds. The window driver's dry run on this box gave
    A at 1.66–2.02 fs, with launches of 1008 synced one by one.
  - The cause is not found. Candidates: CubeCL's memory pool placement, or a clock state at process start.

## CubeCL port after fixes (2026-11-17 13:09–13:56 UTC, Vast 61073296, RTX 3080 at a 300 W cap, one session)

**The fixed port (`997339bc`) is exact at 32 lanes with the new common masks**:
- both super-units;
- survivor sets, counts, the GPU preparation's records, order, class segments and top digits;
- 0 kernel errors;
- `--cmask 0` also exact.

**It is slower, not faster: 2.13–2.44 fs end to end.** For comparison, the pre-fix port was 1.573 fs on the
previous box, and hand CUDA v10 is 1.115 fs here.

| component (ms, per-launch medians of 200) | v10 | fixed port F | F, `--cmask 0` | F without records | pre-fix A1 (same box) | 02075501 (host-only change on A1) |
|---|---|---|---|---|---|---|
| preparation | 0.42 | **0.705 / 0.707** (from 1.03) | 0.70 | — | — | — |
| bottom side (probes off) | 0.624 / 0.630 | **1.75–1.80** (from 1.97–2.16) | 1.76–2.14 | 1.79–1.80 | 1.97–2.16 | 1.77–1.95 |
| full kernel | 4.54 | **8.80–10.20** | 9.0 | 5.39 / 5.40 | 5.80 / 7.19 / 5.80 | 7.19–7.21 |
| end to end, fs per admissible n | 1.115 / 1.114 | **2.440 / 2.127** | 2.17 / 2.17 | — | — | — |

- **Repeated processes of F** (modes 0 and 2, six processes): the full kernel took 8.99, 10.19, 10.00, 10.19, 8.99
  and 8.99 ms. Median 9.5, **minimum 8.99**.
- **Output-buffer size makes no difference:** with batches of 1008, 2016 and 4032 the full kernel was 9.0 ms each
  time.
- **A second protocol, `--burst`**, queues 400 launches and syncs once, so its numbers include host-side buffer
  creation between launches. It ranked the same way: F 2.76 / 2.92, F `--cmask 0` 2.82 / 2.77, pre-fix 2.11 /
  2.10, and v10 (events) 1.12 / 1.11 fs.
- **What it means:**
  - **The fixes did what they were for.** The preparation fell by 0.33 ms and the bottom side by about 0.25 ms.
  - **The record path in phase 3 got about 3 ms slower** (full minus no-records: 3.6 ms, against 0.4 ms for A1).
    The same 3b code is in both.
  - The same jump in quantized steps of about 1.4 ms (5.8 → 7.2 → 8.8 → 10.2) already appeared between two pre-fix
    builds that differ only in comptime-dead code and host code: A1 against 02075501.
  - CubeCL's generated CUDA places the shared arrays at different offsets in every build: `prob_d` lost its 16-byte
    alignment, and `pend_p` moved to 0 (`raw/cuda_box2/cuda_src/*_k2.cu`).
  - **My reading, not proven:** the record path is sensitive to CubeCL's shared-memory layout or its scheduling on
    this kernel, not to the fixes' arithmetic.
- **Main:** not re-run on this box (time went to the bisection). The same-session main values from today are 6.35
  and 6.396 fs, on other 3080s.
  - Against those, the fixed port is ×2.6–2.9 (best run: 6.396 / (2.127 + 0.115) = ×2.85).
  - The pre-fix port was ×3.8; v10 is ×5.1.
- Raw: `G2/port/raw/cuda_box2/`.
- **Follow-up at 14:00: every shared array padded to a multiple of 128 bytes** (`b2624def`), so that every array
  is 128-byte aligned in any placement.
  - Exact on lavapipe (4 jobs) and on this 3080 (whole super-unit, GPU prep).
  - **The timing became stable: 2.1249 / 2.1262 / 2.1263 / 2.1261 fs** in four processes (full 8.795–8.797 ms).
  - The bimodality across builds and processes is gone, so the placement lottery was the variance.
  - The slowdown remains, so it is real code, not layout. The record path (full against no-records) still costs
    about 3.4 ms more than in the pre-fix build.
  - The generated CUDA of the record path has the same structure in both builds; the cause is not found.
- **Bisection so far:**
  - The no-records kernel is unchanged at 5.4 ms.
  - `--cmask 0` is just as slow, so the common masks are not the cause.
  - That leaves the parent-record and top-digit changes, or their side effects, in the phase 3 record path.
- **Found at 14:10: the precomputed top digits are the culprit.**
  - The digits come from `tdig_kernel` and are copied into each cube's probe table, instead of being made in the
    cube.
  - On the same binary, `--tdig 1` against `--tdig 0` gave a full kernel of 8.796 / 8.798 ms against 5.998 / 5.998.
  - The table contents are identical (exact either way). The cause is a CUDA codegen effect not yet understood.
  - **`--tdig 0` is now the default** (head `9ff100e6`).
- **Final four rounds, same session** (per-launch medians, GPU prep included):

  | round | 1 | 2 | 3 | 4 |
  |---|---|---|---|---|
  | **fixed port (`--tdig 0`), fs** | **1.4995** | **1.4991** | **1.5006** | **1.4989** |
  | v10, fs | 1.1139 | 1.1214 | 1.1173 | 1.1146 |

  - Fixed port: **median 1.4993, minimum 1.4989 fs**.
  - Components: prep 0.70 ms, probes off 1.75 ms, full 5.998 ms.
  - **CubeCL/v10 = ×1.34** (×1.37 before the fixes, 1.573 fs).
  - The gain is the preparation alone. The bottom-side gain is offset inside the full kernel: full stays at the
    pre-fix low mode, 6.0 ms.
  - Exact at W = 32 with `--tdig 0` on both super-units.
- **Against today's same-session main values** (6.35 and 6.396 fs, not re-run on this box): **×3.93–3.96**,
  counting tops and survivor checks.

## Tuned port on CUDA (2026-11-18, Vast 61250912, 240 W)

RTX 3080 capped at **240 W by its host** (power.limit 240 W, max 366 W, not raisable from inside); 16 threads; driver
610.57.04, CUDA 12.8 (nvcc V12.8.93), rustc 1.100.0, CubeCL 0.10.0. **One session, 13:06–13:57 UTC; every number in
this section is from it and from no other box.** Raw: `G2/port/raw/cuda_box3/` (`out/` logs and 100 ms `smi_*.csv`,
`build_*.log`, `scripts/`).

**Builds (all on the box):** v10 = `bench/g2bench.cu` (`nvcc -O3 -arch=sm_86 -std=c++17 -DKVER=10 -DMINB=3`, md5
`180d7ac6`); P = port `9ff100e6` (`--features cubecl-cuda`, own target dir, md5 `7e099d7d`); T = tuned port
`4170a781` (md5 `0b71eb26`; A = `--tdig 0`, D = `--tdig 1`, same binary); main = upstream `7e0113fc`
`nice_client --features gpu,cubecl-cuda` (md5 `1431dbc1`). Code from GitHub + `port/g2-cubecl-local.bundle`.
- **Build trap, caught before any timing:** the first P build, in the same `CARGO_TARGET_DIR` as T from a second
  worktree, "finished in 0.15 s" and produced T's binary byte for byte (identical md5). Cargo's fingerprint did not
  see the other worktree's sources as changed. P was rebuilt in its own target dir and checked by string (T has the
  "one root pass" prep message, P does not). One aborted start of round 1 (13:13, during v10) is in `out/runs.log`.

**Exactness at W = 32, tuned head `4170a781`, CUDA runtime: EXACT.** Both super-units (712012851, 391856203), whole
(4,032 jobs, one launch), GPU prep, `--tdig 0` and `--tdig 1`, plus `--prep2 0` once (su1, tdig 0): every unit's
survivor set equal to the prototype's, counts equal to the CPU reference in all three modes, the prep's records,
order, class segments and top digits equal to the CPU's, 0 kernel errors (plane, pmax, slab) — `ALL CHECKS PASSED` in
all 5 runs (`out/x_*.log`). Fill is 1024 (16-chunk rounds) by default at W = 32, so the default runs are the fill-1024
proof. This is the first time the tuned 32-lane path ran anywhere.

**Timing:** six rotated rounds (orders v10 P A D / P A D v10 / A D v10 P / D v10 P A, then the first two again), card
idle before each binary, nothing else running, one `nvidia-smi -lms 100` sampler per binary; super-unit 712012851,
GPU prep on, 200 launches per mode, per-launch medians; `--no-sets` (counts still checked: every timing run passed).

| (ms; fs per admissible n) | r1 | r2 | r3 | r4 | r5 | r6 | **median** |
|---|---|---|---|---|---|---|---|
| **v10** prep (cub) | 0.434 | 0.452 | 0.440 | 0.436 | 0.450 | 0.450 | **0.445** |
| v10 probes off | 0.665 | 0.669 | 0.669 | 0.673 | 0.674 | 0.675 | 0.671 |
| v10 full kernel | 4.886 | 4.886 | 4.886 | 4.926 | 4.883 | 4.886 | **4.886** |
| **v10 end to end, fs** | 1.1907 | 1.1946 | 1.1920 | 1.2003 | 1.1936 | 1.1941 | **1.1938** |
| **P** (`9ff100e6`) prep | 0.711 | 0.711 | 0.711 | 0.712 | 0.711 | 0.711 | **0.711** |
| P probes off | 1.953 | 1.884 | 1.870 | 1.865 | 1.879 | 1.984 | 1.881 |
| P full kernel | 6.485 | 6.572 | 6.536 | 6.519 | 6.585 | 6.528 | **6.532** |
| **P end to end, fs** | 1.6108 | 1.6302 | 1.6219 | 1.6183 | 1.6330 | 1.6202 | **1.6210** |
| **A** (`4170a781 --tdig 0`) prep | 0.647 | 0.640 | 0.647 | 0.646 | 0.649 | 0.647 | **0.647** |
| A probes off | 1.748 | 1.671 | 1.770 | 1.732 | 1.710 | 1.702 | 1.721 |
| A full kernel | 5.371 | 5.350 | 5.320 | 5.298 | 5.283 | 5.323 | **5.322** |
| **A end to end, fs** | 1.3470 | 1.3407 | 1.3357 | 1.3303 | 1.3276 | 1.3362 | **1.3359** |
| **D** (`4170a781 --tdig 1`) prep | 0.648 | 0.645 | 0.648 | 0.646 | 0.645 | 0.647 | **0.647** |
| D probes off | 1.695 | 1.684 | 1.674 | 1.713 | 1.695 | 1.699 | 1.695 |
| D full kernel | 5.250 | 5.262 | 5.250 | 5.276 | 5.259 | 5.301 | **5.261** |
| **D end to end, fs** | 1.3199 | 1.3222 | 1.3199 | 1.3256 | 1.3213 | 1.3314 | **1.3217** |

- **Power and clock while busy** (means over the run's busy samples, 6 rounds): v10 132–172 W, 1.66–1.74 GHz; P
  186–221 W, 1.66–1.74 GHz; A 184–206 W, 1.53–1.63 GHz; D 181–206 W, 1.55–1.65 GHz. Peaks reach the 240 W cap; the
  active clock-event reason in every busy sample is 0x4 (SW power cap). Max 66 °C. Nothing throttled below the cap.
- The CubeCL timings were **stable across processes** (A 1.328–1.347, D 1.320–1.331, P 1.611–1.633 fs): no bimodality.
- Against yesterday's 300 W box: v10 1.194 against 1.115–1.121 (×1.07), P 1.621 against 1.499 (×1.08). The 240 W cap
  costs both kinds of kernel about the same, so same-session ratios carry.

**Ratios, same box, same session:**

| | end to end (fs) | / v10 | tuning gain over P | against main (mean of m1/m2, 6.619 fs), +0.115 fs tops and survivor checks |
|---|---|---|---|---|
| v10 | 1.1938 | ×1.000 | — | **×5.06** |
| P (pre-tuning) | 1.6210 | ×1.358 | — | **×3.81** |
| A (tuned, `--tdig 0`) | 1.3359 | **×1.119** | ×1.213 | **×4.56** |
| D (tuned, `--tdig 1`) | 1.3217 | **×1.107** | ×1.226 | **×4.61** |

(m1 or m2 alone moves each ratio by at most 0.01.)

**Main on this box, same session:** upstream `7e0113fc` production client, `niceonly --gpu`, against the local stub on
127.0.0.1:8400 only, B64.1's ten base-64 1e17 fields at 0.05–0.95 plus the 1e14 warm-up (`bench/box/queue_b64.json`,
`run_main.sh`, unchanged). Production hosts mapped to 127.0.0.1 and ::1 before any client ran, proven at 12:59 and again
before each main run (curl exit 7 for all four hosts, github 200: `proof_hosts_block.txt`, `out/proof_block_before_m*.txt`).
Method as before: sum of the client's own "Processed" times.
- **m1 (13:22–13:37): 841.72 s = 6.629 fs** per admissible n (fields 98.2 116.5 1.1 120.0 1.0 128.6 168.5 1.1 18.8 188.1 s;
  3 empty).
- **m2 (13:43–13:57): 839.27 s = 6.609 fs** (98.0 116.1 1.1 119.7 1.0 128.4 167.9 1.1 18.8 187.2 s). **Mean 6.619 fs**,
  m1/m2 within 0.3 %; 238–239 W mean, 1.70 GHz (5 s samples). Main is ×1.035 slower here than on yesterday's 280 W box (6.396).

**Against today's offline predictions (TUNE-RESULTS.md):**
- **1.25–1.45 fs: held** (A 1.336, D 1.322), at a 240 W cap that costs about 7 % against the 300 W box the prediction
  was referenced to (v10 1.194 here against 1.12).
- **×1.1–1.3 of v10: held, at the low end** (A ×1.12, D ×1.11; was ×1.34 yesterday, ×1.36 for P here).
- **Full kernel 5.0–5.6 ms: held** (5.26–5.32 ms at 240 W). **Prep 0.45–0.6 ms: missed** (0.647 ms; P 0.711): the
  one-pass prep saved only 0.06 ms on CUDA.
- **D no longer slower than A: held.** D is 1.1 % faster (full kernel −0.06 ms, probes off −0.03 ms), the sign the
  ACO model predicted for the card (setup removed). The +2.8 ms `--tdig 1` penalty is gone, consistent with the
  3a atomics being its mechanism.
- **The remaining gap to v10** (D − v10 = 0.57 ms per super-unit): full kernel +0.38 ms, prep +0.20 ms (0.647 against
  cub's 0.445). The probes-off row is not comparable (nvcc drops v10's transpose and setup there, TUNE-RESULTS B1).
