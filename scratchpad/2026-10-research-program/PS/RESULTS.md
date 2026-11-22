# PS: sharing shared-memory loads between neighbouring probes in phase 3b (results, 2026-11-22)

*Counts, kernels and timing for reusing the OR of a shared digit prefix between consecutive probes of the pairing
kernel's word loop. Scratch branch `exp/mo-word-width` (commits `3599f91d`, `b3967fb5` on top of `6f7559d1`; pushed to
`fork`; no pull request). Box: Vast 61919190, RTX 3080 10 GB at a 350 W limit, 2026-11-22 05:50–06:35 UTC (SM clock
1,830–1,990 MHz, 334–348 W, 41–68 °C: no thermal throttling this time). Offline: ACO (Mesa 26.0.8 RADV, GFX1201,
drm-shim) in container `g2mesa` on ivory. Labels: **[C]** exact count on the CPU from the CPU reference's objects,
**[M]** measured on the card, **[P]** predicted (model named), **[J]** judged. Brief: `BRIEF.md`. Every timing below
comes from a kernel whose per-instance counts equal the dump's (§ Exactness).*

## Verdict

**Dropped by the rule written in advance.** Every kernel that shares loads is *slower* than today's loop, on the
3080 by measurement and on the RX 9070 XT by both card models; the whole main kernel's gain is below ×1 everywhere,
far under ×1.08.

- **RTX 3080 [M]:** the best sharing kernel (`ps16_q4`) makes phase 3b ×0.78 as fast as today's W64 loop, i.e. the
  main kernel ×0.85; the one-register kernel with any level (`ps_q1`) ×0.50 → ×0.63; the prefix stack (`ps_t4`)
  ×0.69 → ×0.78. Turning the sharing off inside the same kernels changes their time by ≤ 1.5 %: the loads saved are
  not what limits these loops; the control structure that skips them is.
- **RX 9070 XT [P]:** every sharing variant raises VALU cycles per wave-iteration from 173 to 245–403, and the loop
  stays VALU-bound under both models (the LDS bound is 1.43–1.62 ms against VALU bounds of 2.5–4.1 ms). Main kernel
  ×0.46–0.77 (issue model) and the same with the LDS limit, because the LDS limit never binds.
- **The ceiling, even at zero overhead [C]:** the counts give the one-saved-OR scheme (best order, best plan) 15.1
  loads per visit in lockstep on a CUDA warp (×1.07 main kernel at zero cost) and 16.1 on a wave64 (×1.04–1.05);
  only an unbounded prefix stack reaches 14.5 / 15.0 (×1.10 / ×1.10–1.12). Those ceilings assume the skip and the
  bookkeeping cost nothing; the measured kernels show they cost far more than they save.
- **Why:** consecutive listed probes share only 2.6 leading digits on average (in the best digit order), and a
  64-lane plane holds 2 (CUDA) or 4 (RDNA) independent probe streams, so the digits a whole plane can skip are fewer
  still (1.0–2.2 of 17). Skipping per lane saves no issue slots (predication); skipping per plane needs branches,
  which split the 34 independent loads of a step into dependent batches. On the 3080 each split costs more than a
  batch of loads saves (blocks of 8: ×0.86, blocks of 4: ×0.71, with sharing off).

## 1. Loads per visit, by order and scheme [C]

`MO_SHARE=1 mo_width_dump <pip> /root/dump 12` (`box/count.sh`) → `raw/count_<pip>.txt`, tabulated by
`box/counts_table.py` → `raw/counts_table.md` (means over slices 712012851, 4977728, 4977729; the slices agree to
≤ 0.001 in every ratio). 14.19M listed (probe, round) entries per slice ("visits"), 4,032 job instances.

- **Orders** (the probe order is free within each instance; digits written in one fixed order per instance):
  `today` (digits ascending, probes as listed today), `asc` (probes sorted by their ascending digit lists), `freq`
  (digits by descending frequency among the instance's probes, probes sorted), `pos` (the certificate's position
  order: n²'s digits from the most significant down, then n³'s; probes sorted), `posi` (n² and n³ interleaved by
  significance).
- **Assignments** of a round's list to the 16 probe streams (the list is per round and all 16 lanes of a stream
  share it): `il` today's interleave (entry e → stream e mod 16), `c32` 32 contiguous segments (two per stream, one per
  entry slot, today's step count), `c16` 16 contiguous segments, one entry per step (twice today's steps).
- **Schemes:** `pad17` today (17 loads, padded); `own` the probe's own digit count; `d1` one saved partial OR with
  the optimal plan (dynamic programming over the saved level, levels ≤ 17; capping at 4, 8 or 12 changes ≤ 0.03);
  `q2`/`q4` the same with levels restricted to multiples of 2 / 4 (what a blocked kernel can use); `g2`/`g3` a stack of
  2 / 3 saved ORs (greedy plan, lookahead 32); `trie` an unbounded stack.
- **Lockstep:** a plane of 2 streams (CUDA warp 32) or 4 (wave64) pays, per step and entry slot, its largest
  per-stream load count; idle stream slots are included (`c32`: 1.6 % / 3.5 %, `c16`: 1.9 %).

Loads per visit, `summed / lockstep warp32 / lockstep wave64`, assignment `c32` (today's kernel = `today, il, pad17`
= 17.00 / 17.02 / 17.07):

| scheme | today | asc | freq | pos | posi |
|---|---|---|---|---|---|
| pad17 | 17.00 / 17.27 / 17.62 | same | same | same | same |
| own | 16.39 / 16.97 / 17.53 | 16.39 / 16.96 / 17.51 | 16.39 / 16.96 / 17.51 | 16.39 / 16.96 / 17.51 | 16.39 / 16.96 / 17.51 |
| d1 (one saved OR) | 15.85 / 16.59 / 17.28 | 14.32 / 15.26 / 16.23 | **14.15 / 15.11 / 16.10** | 15.14 / 15.93 / 16.75 | 14.47 / 15.39 / 16.35 |
| q2 | 16.17 / 16.88 / 17.48 | 14.56 / 15.54 / 16.49 | 14.46 / 15.47 / 16.45 | 15.24 / 16.08 / 16.94 | 14.77 / 15.54 / 16.32 |
| q4 | 16.38 / 16.97 / 17.52 | 15.63 / 16.66 / 17.42 | 15.42 / 16.53 / 17.36 | 16.39 / 16.96 / 17.51 | 16.24 / 16.93 / 17.50 |
| g2 | 15.81 / 16.56 / 17.25 | 14.01 / 14.92 / 15.85 | 13.86 / 14.78 / 15.71 | 14.89 / 15.55 / 16.19 | 14.18 / 15.00 / 15.86 |
| g3 | 15.81 / 16.56 / 17.25 | 13.87 / 14.69 / 15.49 | 13.74 / 14.58 / 15.39 | 14.89 / 15.54 / 16.18 | 14.10 / 14.84 / 15.59 |
| trie (unbounded) | 15.81 / 16.56 / 17.25 | 13.86 / 14.66 / 15.43 | 13.72 / 14.54 / 15.32 | 14.89 / 15.54 / 16.18 | 14.09 / 14.83 / 15.57 |

The same with `c16` (one entry per step), best order `freq`: d1 14.09 / 15.12 / 15.85; g3 13.64 / 14.54 / 15.10;
trie 13.61 / 14.48 / 14.99. With today's interleave `il`, best order `freq`: d1 15.28 / 15.63 / 15.92 (neighbours
in a stream are 16 entries apart). Full table: `raw/counts_table.md`.

Findings [C]:

- **Best order: digit frequency.** The certificate's position order, which the brief suggested, is worse (d1 15.14
  summed against 14.15): close tops share leading digits of n² and n³, and why the frequency order does better is my guess
  [J]: it sorts all 8 root classes' probes together, while the position order shares only within runs of close tops.
- **One saved OR captures most of a stack:** d1 14.15 against the unbounded trie's 13.72 (summed). Levels above 4
  almost never pay (trie4 13.79 against trie17 13.72): the mean shared prefix is 2.6 digits.
- **Restricting the levels kills it:** q4 (what blocks of 4 can use) 15.42; q2 14.46.
- **Lockstep costs a third to a half of the saving:** the 2 or 4 streams of a plane rarely skip together.
- **The stop rule of the brief** (stop if counted loads per visit are above 15 of 17): mixed, so I built the kernels.
  Summed: 13.6–14.2 (below 15). Lockstep on a CUDA warp: one OR 15.1, stack of 3 14.6. Lockstep on a wave64: one OR
  16.1, best (trie, `c16`) 15.0.

**The ceiling at zero overhead [C → P]:** main kernel gain 1 / (1 − s·(1 − r)), r = lockstep loads against today's,
s = 3b's share (3080: 0.599 measured today, § 4; RX 9070 XT: 0.72–0.87, `CW/RESULTS.md`):

| scheme (order freq) | r warp32 | 3080 main × | r wave64 | RX 9070 XT main × |
|---|---|---|---|---|
| d1, one saved OR, c32 | 0.888 | ×1.072 | 0.943 | ×1.043–1.052 |
| q2, c32 | 0.909 | ×1.057 | 0.964 | ×1.027–1.032 |
| q4, c32 | 0.971 | ×1.018 | 1.017 | ×0.985–0.988 |
| stack of 3 (g3), c32 | 0.856 | ×1.094 | 0.902 | ×1.076–1.094 |
| trie, c16 | 0.851 | ×1.097 | 0.879 | ×1.096–1.118 |
| t4 (own prefixes 1..4, plane-uniform start; `raw/write_712012851.txt` UNIFORM) | 0.875 | ×1.081 | 0.895 | ×1.081–1.100 |
| bytes only (summed, no lockstep): d1 / trie | 0.833 / 0.801 | ×1.11 / ×1.14 | same | ×1.14–1.17 / ×1.17–1.21 |

## 2. Kernels

All in `common/examples/mo_width_bench.rs` (`ps_kernel`), inputs written by `MO_SHARE_WRITE=<order>,<assignment>,<plan>
mo_width_dump` (`box/write_ps.sh`): the W64 dump with each instance's probes sorted, digits re-encoded in the order,
the round lists in that order, and per entry a plan word `n | s0 << 5 | sv << 10` (start from the saved OR at level
s0, save after digit sv − 1). Width 64, two entries per lane per step as today, the record test and the 16-byte
record store exactly as `w3b_kernel`/`g2_kernel`. Order `freq` throughout.

- **`ps_qB`** (`c32`, plan with levels multiples of B; B = 1 means any level, plan `d1`): the 17 digits in blocks of
  B behind a per-lane branch (`s0 ≤ lo < n`; a block a whole plane skips is not issued), the save as one select per
  block end. `ps_qBn`: the same kernel with sharing off (mode bit, `s0 = 0`). `ps16_qB`: assignment `c16x2` (16
  segments, two consecutive entries per step, one register).
- **`ps_u1`**: every digit behind a plane-uniform guard (plane minimum of s0, maximum of n; a lane above its s0 loads
  again, harmlessly), saves per digit.
- **`ps_t4`, `ps_t2`** (the small stack): each entry keeps its own prefix ORs at levels 1..4 (or 1..2) in registers
  (16 / 8 extra u32 for the two entry slots), starts from level min(LCP, 4), the plane skips digits below its minimum
  start; all loads are issued before the ORs (no load batch is split). `ps_t4n`: sharing off.
- **Diagnostics:** `ps_q17n` (the same segments, plan word and record path, one block of 17 digits, no sharing) and
  `ps_q8n` (blocks of 8, no sharing); `w64o_q4` (today's loop on the sorted dump).
- **`…g` variants:** the plan word read from global memory instead of a shared copy (shared size as today's,
  20,480 B; the shared copy costs 3 KB and drops the RX 9070 XT to 8 waves per SIMD).
- **Planes in step:** with contiguous segments the plane runs `⌈nlist/32⌉` steps as today; a stream past its segment's
  end runs with a zero entry (kept mask 0), as today's kernel does past the list's end. Idle stream slots: 1.6 % of
  warp slots, 3.5 % of wave64 slots (counted, above); the kernel's lane-slot count equals the dump's.
- **(b), the stack, was built only as `ps_t4`**: the one-register kernel (a) left no gain on the table — it is
  slower than today — so the brief's condition for (b) was not met; `ps_t4` was built anyway as the best-ILP design I
  could think of (loads first, one guard per skippable digit), to test whether the losses come from the scheme or
  from the branches.

## 3. RTX 3080 timing [M]

Passes `raw/micro_{d,g,h}/` (`box/micro.sh <pass> --pips 712012851,4977728,4977729 --reps 15 --launches 20
--variants …`): 15 measurements of 20 launches per (slice, variant, mode), shuffled order each rep, nvidia-smi every
20 ms; `box/cyc.py` → `raw/micro_*/cyc.md`; `box/table.py 0.599 raw/micro_d raw/micro_g raw/micro_h` →
`raw/table_3080.md`. 3b = full − no-3b of the same kernel. Ratios are against the plain W64 loop of the same pass, in
cycles. Main kernel × = 1 / (1 − 0.599 · (1 − 1/x3b)). Means over the 3 slices (spread between slices ≤ 2 %).

| variant | 3b ps per pair | 3b ms per slice | 3b Mcycles | x3b vs W64 | main kernel × |
|---|---|---|---|---|---|
| `w64` (today's loop; passes d / g / h) | 0.157 / 0.159 / 0.158 | 2.512 / 2.537 / 2.526 | 4.74 / 4.69 / 4.76 | 1 | 1 |
| `w64o_q4` (today's loop, sorted dump) | 0.156 | 2.493 | 4.71 | ×1.006 | ×1.003 |
| `ps_q17n` (segments + plan word, one block, no sharing) | 0.159 | 2.546 | 4.73 | ×0.991 | ×0.994 |
| `ps_q8n` (blocks of 8, no sharing) | 0.185 | 2.956 | 5.48 | ×0.856 | ×0.908 |
| `ps_q4n` / `ps_q4` (blocks of 4, sharing off / on) | 0.221 / 0.218 | 3.529 / 3.486 | 6.65 / 6.56 | ×0.712 / ×0.722 | ×0.805 / ×0.812 |
| `ps_q4g` | 0.231 | 3.703 | 6.94 | ×0.687 | ×0.785 |
| `ps16_q4` (c16x2, one register) | 0.202 | 3.234 | 6.09 | **×0.777** | **×0.854** |
| `ps_q2` / `ps_q2g` | 0.263 / 0.271 | 4.205 / 4.334 | 7.89 / 8.15 | ×0.600 / ×0.585 | ×0.715 / ×0.702 |
| `ps_q1n` / `ps_q1` / `ps_q1g` (any level) | 0.317 / 0.317 / 0.324 | 5.073 / 5.071 / 5.185 | 9.52 / 9.47 / 9.79 | ×0.498 / ×0.500 / ×0.487 | ×0.623 / ×0.625 / ×0.613 |
| `ps16_q1` | 0.357 | 5.718 | 10.74 | ×0.441 | ×0.568 |
| `ps_u1` / `ps_u1g` (plane-uniform per digit) | 0.432 / 0.400 | 6.907 / 6.398 | 13.00 / 12.08 | ×0.364 / ×0.394 | ×0.489 / ×0.521 |
| `ps_t4n` / `ps_t4` / `ps_t4g` (prefix stack 1..4) | 0.231 / 0.230 / 0.246 | 3.703 / 3.683 / 3.942 | 6.94 / 6.85 / 7.41 | ×0.675 / ×0.685 / ×0.643 | ×0.776 / ×0.784 / ×0.750 |
| `ps_t2` (prefix stack 1..2) | 0.207 | 3.315 | 6.14 | ×0.763 | ×0.843 |

What the table says [M + J]:

- **The skipped loads are worth ≤ 1.5 %:** on/off pairs `ps_q4`/`ps_q4n` ×1.013, `ps_q1`/`ps_q1n` ×1.00,
  `ps_t4`/`ps_t4n` ×1.006, although the plans skip 6–17 % of the digit loads (BLOCKS/UNIFORM lines in
  `raw/write_712012851.txt`: `t4` runs 28.4 of 34 digit loads per warp-iteration).
- **The structure costs:**
  - The segments and the plan word are free: `ps_q17n` = `w64`.
  - Each split of the digit sequence into guarded blocks costs a lot: blocks of 8 ×0.86, of 4 ×0.71 (sharing off).
    The SASS (`raw/cudasrc/k2.sass`) shows each block as BSSY/BSYNC with its 4 loads and their ORs inside: the 34
    independent loads of a step become dependent batches.
  - Per-lane predication instead of branches (`ps_q1`: NVCC if-converts each 1-digit block into `@P LDS.64`) keeps
    every instruction issued and adds ~5 per digit (`raw/cudasrc/k4.sass`, 1,080 against 776 instructions): ×0.50.
  - A predicated-off `LDS.64` costs as much as a real one here: `ps_t4` predicates its 8 guarded loads plane-uniformly
    and gains nothing over `ps_t4n`.
- **This box against yesterday's:** today's W64 3b is 4.69–4.76 Mcycles (yesterday 4.77–4.84 at 1.6 GHz). The card
  ran at 1.83–1.99 GHz without throttling, so cycles are the comparable unit.
- **NVRTC registers** (nvcc on the generated CUDA, sm_86): 40 (`w64`), 48 (`ps_q*`), 64 (`ps_t4`). No spills in the
  ps kernels. Occupancy is limited by shared memory, not registers; the `g` variants (today's shared size) are no
  faster, so it is not occupancy.

## 4. Phase 3b's share of the main kernel on this box [M]

`box/realk.sh 4096 3` (stops 2, 3 and 3 with `MIDOUT_ABL3B=1` of `midout_bench --cuda --fields 77777 --slices 4096
--no-cpu-check`, 3 interleaved rounds) → `raw/realk_0630/`, `box/realk_an.py raw/realk_0630 4096 2026/11/22` →
`raw/realk_0630/an.md`: main kernel 8.42–8.49 Mcycles per slice, 3b in situ 5.00–5.11, **share 0.592–0.607**
(mean 0.599), the same as yesterday (0.59–0.61). The production hosts were mapped to loopback first
(`raw/hosts_block.log`); `midout_bench` is local and no client binary ran.

## 5. RX 9070 XT, offline [P]

SPIR-V at plane width 64 from the box (`box/spv.sh`: the `cubecl-spirv` build, a compile-only lavapipe run with
`--force-w 64`, spirv-val passed every module) → `raw/aco{1,2,3}/`; ACO (Mesa 26.0.8 RADV, GFX1201) in `g2mesa` →
`raw/aco_out{1,2,3}/*.aco.txt`, `raw/aco_summary.txt`; model `box/model_ps.py raw/aco_out3 raw/aco_out1 raw/aco_out2`
→ `raw/model_ps.md`.

The model is CW's two card models on the 3b loop's per-wave-iteration cost. The digit basic blocks behind a branch
are weighted by the fraction of wave64 iterations that execute them (BLOCKS lines, slice 712012851, from the dump's
plans). Wave-iterations: 1,843,816. Main kernel M = 2.607 or 3.16 ms.

| variant | VGPRs / LDS B / waves per SIMD / spills | VALU cyc per wave-iteration (static → weighted) | LDS B per wave-iteration | 3b ms, issue model | 3b ms, with LDS limit | main ×, issue | main ×, with LDS |
|---|---|---|---|---|---|---|---|
| `w64` (today's loop) | 120 / 20,480 / 12 / 0 | 173 | 19,968 | 2.271 | 2.271 | 1 | 1 |
| `ps_q17n` (structure only, no sharing) | 192 / 23,552 / 8 / 0 | 207 | 20,480 | 2.718 | 2.718 | ×0.85–0.88 | same |
| `ps_q4g` | 120 / 20,480 / 12 / 0 | 156 + 10 blocks → 258.6 | 19,762 | 3.395 | 3.395 | ×0.70–0.74 | same |
| `ps16_q4` | 192 / 23,552 / 8 / 0 | 142 + 10 blocks → 244.9 | 20,329 | 3.215 | 3.215 | ×0.73–0.77 | same |
| `ps_q2g` | 120 / 20,480 / 12 / 0 | 196 + 18 blocks → 294.4 | 19,048 | 3.865 | 3.865 | ×0.62–0.67 | same |
| `ps_q1g` | 120 / 20,480 / 12 / 0 | 276 + 34 blocks → 402.5 | 18,751 | 5.284 | 5.284 | ×0.46–0.51 | same |
| `ps_u1g` | 120 / 20,480 / 12 / 0 | 248 + 34 blocks → 374.5 | 18,751 | 4.916 | 4.916 | ×0.50–0.54 | same |
| `ps_t4g` | 120 / 20,480 / 12 / 0 | 285 + 8 blocks → 289.4 | 18,120 | 3.799 | 3.799 | ×0.63–0.67 | same |
| `ps_t2` | 192 / 23,552 / 8 / 0 | 251 + 4 blocks → 251.8 | 18,860 | 3.306 | 3.306 | ×0.72–0.75 | same |

(The non-`g` twins of `ps_q4`/`q2`/`q1`/`u1`/`t4` are in `raw/model_ps.md`: the same VALU within 2 %, 192 VGPRs and
8 waves because of the 3 KB shared plan copy.)

- **The LDS limit never binds:** the LDS bounds are 1.43–1.62 ms, the VALU bounds 2.5–4.1 ms. So the "shared-memory
  limited" prediction equals the issue prediction, and the bytes saved buy nothing on this card either.
- **Registers:**
  - The microbenchmark's `g` kernels fit in 120 VGPRs, 12 waves per SIMD, 0 spills.
  - The real `g2_kernel` is already at 120 (its budget is set by its other phases). It would have to absorb the
    extra live state inside 3b: 2 u32 for one saved OR per entry slot (4 for `c32`), 16 u32 for `t4`. Whether ACO does
    that without spilling or dropping to 8 waves is not known without building it; I did not.
- The predicted RDNA losses come from VALU (segment index, plan decode, per-block conditions and save selects, the
  stack's selects); ACO compiles the skipped blocks as `s_cbranch_execz`/`scc` branches, so their VALU is not paid,
  but the bookkeeping outweighs it.

## 6. Exactness

- **The dump** reproduces the CPU reference on all three slices (`raw/dump_<pip>.txt`, line `REF`: flat, kept,
  words, survivors as `CW/RESULTS.md`).
- **The sorted bench files:** every `PSWRITE` line (`raw/count_*.txt`, `raw/write_*.txt`) has the same nonzero
  words, survivor bits, kept pairs and lane slots per slice as the unsorted dump. The per-instance expected counts are
  the dump's: the same (probe, chunk) pairs, reordered within each instance.
- **On the 3080 [M]:** every variant, every slice, every pass, all 4,032 instances: `EXACT … per-instance
  mismatches 0`, nonzero words and survivor bits equal to the dump's (`raw/once1/out.txt`,
  `raw/micro_{a..h}/out.txt`; 20 distinct variants × 3 slices in the timed passes d, g and h). The kernel's lane-slot count
  equals the dump's. No variant ever differed, so no timing was withheld.
- **SPIR-V on lavapipe [M]:** at its native plane width 8, 15 variants (all but the `g` twins, which differ only
  in where the plan word is read) exact on the first 48 instances of 712012851 (`raw/lvp_exact_w8.txt`, `raw/lvp_exact_w8_2.txt`). The W 64 modules for ACO come from
  compile-only runs; their counts are not evidence.
- **Provenance:** the box built from the branch's working tree synced from ivory. The three example sources on the
  box have the same SHA-256 as commit `b3967fb5` (checked at the end). Later edits only added comptime-gated variants,
  so the kernels of the earlier passes are unchanged.

## 7. What building it in would take

Not recommended. If it were ever revisited, the only design with a measured chance is not a variant of these: it
would have to skip whole loads without splitting the step's loads into dependent batches, and without per-digit
bookkeeping. Neither card's instruction set gives a cheap way to start an unrolled load sequence at a data-dependent
offset.

Concretely it would take:

- the probe order per instance (`freq` sort) in the tops stage;
- the per-entry start level written by phase 3a (LCP with the previous listed probe of the same stream segment;
  `t4` needs 3 bits, which fit in the list entry's 6 free bits);
- contiguous stream segments in 3b;
- the extra registers in `g2_kernel` (§ 5);
- the audits: the survivor set is order-independent, but `A_PROBES` and the lane-slot counter would change meaning,
  and a mutation test that corrupts the start level would be needed.

Risks: everything above, for a counted ceiling of ×1.07 (3080, one OR) to ×1.10 (unbounded stack).

## What I could not finish, and limits

- **The idea itself is closed by measurement.** The limits below do not change the verdict.
- **No RX 9070 XT measurement** (not allowed). The RDNA numbers are the two models on ACO's code. The model ignores
  occupancy (8 against 12 waves) and latency, and counts the loop body once per wave-iteration, as CW did.
- **The stack kernel** was built only as the own-prefix stack `t4`/`t2` (plane-uniform start), not as the
  greedy-planned `g2`/`g3` stack. Its plans need per-digit saves, which `ps_q1` already shows cost ×0.5.
- **Model weights:**
  - The digit-block fractions come from slice 712012851 only (the slices agree to 0.001 in the counts).
  - For `t4` they ignore idle lanes of partly valid planes (which force the guarded digits on); this flatters `t4`.
  - `ps_u1`'s fractions are the per-lane-any fractions, a lower bound of its plane-uniform guard.
- **Not tried:**
  - a variant that packs the plan into the list entry's free bits (only `t4`'s fits);
  - hand-written CUDA (all kernels are CubeCL → NVRTC).
  - The 3080's ×0.99 for `ps_q17n` says the segment structure itself is free, so neither looks like where the loss is.
- **Box state:** the box is idle (no process of mine running); its files stay until it is destroyed.

## Files

- **Branch `exp/mo-word-width`:**
  - `common/examples/mo_width_dump.rs` (certificate-order digits per top, `MO_SHARE` hook);
  - `common/examples/mo_width_dump/share.rs` (the counts, the plans, the sorted bench files, BLOCKS / UNIFORM
    statistics);
  - `common/examples/mo_width_bench.rs` (`ps_kernel` and its variants, the plan word, loading by file tag).
- **`box/`:**
  - setup and builds: `setup.sh`, `hosts_block.sh`, `build_dump.sh`, `build_bench.sh`, `build_real.sh`;
  - counts and bench files: `count.sh`, `counts_all.sh`, `write_ps.sh`, `dump.sh`;
  - timing: `micro.sh`, `cyc.py`, `table.py`, `realk.sh`, `realk_an.py`;
  - SPIR-V and offline: `spv.sh`, `lvp_exact.sh`, `cudasrc.sh`, `model_ps.py`, `counts_table.py`;
  - sequencing: `stage2.sh`, `stage3.sh`.
- **`raw/`:**
  - counts: `count_*.txt`, `counts_table.md`, `write_*.txt` (PSWRITE / BLOCKS / UNIFORM);
  - timing: `micro_{a..h}/` (a–c and e–f are single-slice exploratory passes; d, g, h are the table),
    `table_3080.md`, `once1/`, `realk_0630/`;
  - generated code: `cudasrc{,2}/` (generated CUDA, SASS);
  - offline: `aco{1,2,3}/` (SPIR-V), `aco_out{1,2,3}/` (ACO listings), `aco_summary.txt`, `model_ps.md`;
  - exactness: `lvp_exact_w8*.txt`;
  - logs: `hosts_block.log`, `box_logs/`.
