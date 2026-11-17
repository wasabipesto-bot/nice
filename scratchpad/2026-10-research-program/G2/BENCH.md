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
