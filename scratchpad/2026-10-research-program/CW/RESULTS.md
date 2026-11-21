# CW: wider words per lane in phase 3b (results, 2026-11-21)

*Microbenchmark of the main kernel's phase 3b at 64, 128 and 256 children per lane word. Scratch branch
`exp/mo-word-width` (from `10ddbf17`, worktree `~/projects/nice/.worktrees/mo-word-width`, pushed to `fork`; no pull
request). Box: Vast 61761289, RTX 3080 10 GB at its default 320 W limit, 2026-11-21 06:00–06:55 UTC. Offline: ACO
(Mesa 26.0.8 RADV, GFX1201, drm-shim) in container `g2mesa` on ivory. Labels: **[M]** measured (command, raw file),
**[P]** predicted (model named), **[J]** judged. Brief: `BRIEF.md`.*

## Verdict

**On the RTX 3080 the whole main kernel would gain ×1.09 at the best width (128) [M + D]: well under ×1.15. For
the RX 9070 XT the answer depends on one number the offline compile cannot give: how fast that card's shared memory
(LDS) is.**

- **The prescribed card model** (`model_4s.py`: issue-bound, wave64 = two passes, efficiency 0.77) predicts
  ×1.27–1.35 for the main kernel at width 128 and ×1.49–1.67 at width 256 [P]. That passes the ×1.15 bar, so **by
  the rule written in advance the idea is not dropped.**
- **The same model with the project's own LDS limit added** (`G2/port/model_rdna4.py`: 128 B/clk per CU) predicts
  **×1.10–1.16** at width 128 and ×1.09–1.15 at width 256 [P]. That is at or below the bar. Wider words keep the bytes
  read from shared memory the same, so at width 128 the loop becomes LDS-bound.
- **The 3080 shows that limit in practice.** Per pair, the instruction count of the 3b loop falls by 30–45 % at
  width 128 (ACO counts, which I use as a stand-in). Yet the 3080's phase 3b gets only ×1.17 faster, and stops at
  78 % of the card's LDS peak (W64 runs at 66 %) [M + D].
- **My judgement [J]:** the honest prediction for the RX 9070 XT is ×1.10–1.16. ×1.27 or more is possible only if
  that card's LDS serves more than 128 B/clk per CU. AMD documents 32 LDS banks per CU for RDNA 3.5, which is
  consistent with 128 B/clk; I found no figure for RDNA 4.
- **What would settle it:** one run of this microbenchmark on the RX 9070 XT. It is ready: the SPIR-V path builds,
  and it is exact on lavapipe. About an hour of the card.
- **Something else that matters (found on the way):**
  - The wide record must stay today's 16-byte record per nonzero 64-bit half. Writing whole 32- or 64-byte records
    adds DRAM writes, which the card measured as bandwidth-bound: 0.32 ms for 175 MB.
  - At width 256, the obvious shared layout has a 2-way bank conflict on the 3080. It makes width 256 ×1.6 *slower*
    than width 64 (4.2 against 2.7 ms). A one-select swizzle by stream parity removes the conflict.

## The table [3080: M, pass d; RX 9070 XT: P]

3080: `raw/micro_d/` (`box/micro.sh d --pips 4977728,4977729,712012851 --reps 15 --launches 20 --variants …`,
analysed by `box/cyc.py` → `raw/micro_d/cyc.md`). The table gives the means over the 3 slices. There were 15
measurements of 20 launches per (slice, variant, mode), interleaved in a shuffled order. The SM clock was logged every
20 ms: mean 1,595–1,606 MHz, 260–266 W, no rep below 1,575 MHz.

"Pair" = (top, child) tested: children × probes per job, summed (`Counts::pairs`: 16.03e9, 16.00e9 and 15.97e9 for
slices 4977728, 4977729 and 712012851). 3b = full − no-3b (the same kernel, with its copies and barriers but no 3b
loop).

RX 9070 XT: ACO listings `raw/aco/*.aco.txt` → `raw/preflight_cw.md`, `raw/ldsbytes.txt`; dynamic loop counts from
the dumps (`box/steps.py` → `raw/steps.txt`); model `box/model_cw.py` → `raw/model_cw.md` (slice 712012851 shown;
the other two agree within 0.5 %).

| width (variant) | 3080 3b ps per pair | 3080 3b ms per slice | 3080 3b Mcycles | ×3b vs 64 (3080) | ACO VALU cyc / LDS ops per wave-iteration | entries per step | LDS B per wave-iteration | VGPRs / LDS B / waves per SIMD / spills | RX 9070 XT 3b ms, issue model (VALU ÷ 0.77) | RX 9070 XT 3b ms, with LDS bound (÷ 0.77) |
|---|---|---|---|---|---|---|---|---|---|---|
| 64 (`w64`, the real 3b) | 0.187 | 2.994 | 4.798 | 1 | 173 / 39 (`g2_kernel` h5l: 171 / 39) | 32 | 19,712 | 120 / 20,480 / 12 / 0 | 2.27 | 2.27 |
| 128, 1 entry per lane (`w128v1`, 16-B vector reads) | **0.161** | **2.579** | **4.102** | **×1.17** | 122 / 37 | 32 | 18,688 | 120 / 20,480 / 12 / 0 | **1.60** | **1.92** |
| 128, 1 entry, u32 reads (`w128s1`) | 0.162 | 2.596 | 4.132 | ×1.16 | 122 / 37 (same code) | 32 | 18,688 | same | 1.60 | 1.92 |
| 128, 2 entries per lane (`w128s2`) | 0.163 | 2.615 | 4.185 | ×1.15 | 223 / 73 | 64 | 37,120 | same | 1.53 | 1.99 |
| 256, 1 entry, swizzled (`w256x1`) | 0.166 | 2.657 | 4.199 | ×1.14 | 224 / 71 | 64 | 36,096 | same | 1.54 | 1.94 |
| 256, 2 entries, swizzled (`w256x2`) | 0.173 | 2.764 | 4.413 | ×1.09 | 424 / 141 | 128 | 71,936 | same | 1.49 | 1.97 |
| 256, 1 entry, not swizzled (`w256v1`) | 0.26 (pass b) | 4.22 (pass b) | — | ×0.64 (bank conflict) | 179 / 71 | 64 | 36,096 | same | 1.23 | 1.94 |

Notes:

- The RX 9070 XT model uses F = 2.85 GHz, 128 SIMD32, wave-iterations = 4 × loop steps, and LDS = 128 B/clk per CU ×
  64 CUs. W64's VALU bound is 1.749 ms and its LDS bound 1.557 ms. Every width ≥ 128 is LDS-bound at 1.48–1.53 ms
  (bounds, before ÷ 0.77).
- **Whole main kernel at the best width (128, 1 entry):**
  - **3080: ×1.09** [M + D]. The full-field stops give a main kernel of 8.49 Mcycles per slice, of which 3b is 5.06.
    The micro's 3b ratio is 0.855. 1 / (1 − 0.596 × 0.145) = ×1.095; the micro's absolute saving (0.70 Mcycles
    against 8.49) gives ×1.089.
  - **RX 9070 XT, issue model: ×1.27–1.34** [P], against a measured main kernel of 3.16 or 2.607 ms (below).
  - **RX 9070 XT, with the LDS bound: ×1.13–1.16** [P].
  - **RX 9070 XT, issue-only, anchored on the card's measured prototype: ×1.20** [P/J]. On the card the prototype's
    3b ran at about its VALU bound, not ÷ 0.77 of it (`G2/WINDOW-RESULTS.md`: full without records 2.718 ms minus
    probes off 0.928 ≈ 1.79 ms for 3a + 3b, against 3b's VALU bound of 1.71–1.75). So the saving is 0.515 ms on 3.04.
  - **Width 256, swizzled:** 3080 ×1.08; RX 9070 XT ×1.30–1.39 issue / ×1.12–1.15 with LDS. Unswizzled on the RX
    9070 XT it would be ×1.49–1.67 issue-only, but that layout has the conflict the 3080 shows, and RDNA's bank
    behaviour for it is not known offline.
- **3080 LDS floor [D]:**
  - Shared bytes per slice are 27.8 GB at width 64, 28.0 at 128 and 28.2 at 256 (lane slots × 17 × 8 B × W/64). At
    68 SMs × 128 B/clk × 1.60 GHz that is a floor of 1.99–2.02 ms for phase 3b at every width.
  - Measured: W64 2.99 ms (66 % of LDS peak), W128 2.58 (78 %), W256 2.66 (76 %).
  - **Fewer bytes is the only lever left on this card.** The ×1.5 that would remain to the floor is not reachable by
    width.
- **Record store** (full − no-store, the records not written) [M]: W64 0.229 ms, W128 0.144–0.169, W256 0.30–0.34
  ms. In this microbenchmark each wide record is W/64 of today's 16-byte records, zero halves included. W128 hides
  its doubled bytes under the LDS-bound loop on the 3080; on the RX 9070 XT the card measured records as
  DRAM-bound.

## Phase 3b's share of the main kernel

**RTX 3080 [M]:**
- `box/realk.sh 4096 3` → `raw/realk_0622/`, analysed by `box/realk_an.py` → `raw/realk_0622/an.md`.
- Field 77777, all 4,096 slices (its first two are the dumped 4977728 and 4977729), timing stops of
  `midout_bench --cuda`:
  - stop 2 (tops + parents), stop 3 (+ main kernel), stop 3 with `MIDOUT_ABL3B=1`, stop 6;
  - the head's own binary (`10ddbf17`, without the ablation code) at stop 3 as a control.
- 3 interleaved rounds.
- The card throttled thermally (89–93 °C; SM clock 1,598 → 1,263 MHz across the rounds), so every run is converted to
  SM cycles (wall × mean clock over its interval).

| round | main kernel ms / slice | main Mcycles / slice | 3b in situ (stop 3 − ablated) Mcycles | share | head binary − branch binary at stop 3 |
|---|---|---|---|---|---|
| r1 | 5.435 | 8.476 | 5.142 | 0.607 | −0.129 Mcycles (−1.5 %) |
| r2 | 6.030 | 8.499 | 4.985 | 0.587 | −0.036 |
| r3 | 6.367 | 8.492 | 5.040 | 0.593 | +0.015 |

- **3b is 0.59–0.61 of the main kernel on the 3080.** The main kernel in cycles is stable to ±0.2 % while the clock
  moved by 20 %.
- The microbenchmark's W64 3b (4.80 Mcycles) is 0.95 of the in-situ ablation (5.06).
- The ablation is fault bit 1 << 20 in `g2_kernel`: `nlist` reads as 0, so the 3b loop does not run. One `select`
  outside the loops; the control row shows no measurable change.
- A 256-slice pass (`raw/realk_0617/`) is dominated by the field's fixed setup and is not used.
- How phases 1, 2, 3a and 4 were separated from 3b:
  - **in the real kernel**, by that ablation (stop 3 − stop 3 ablated);
  - **in the microbenchmark**, by `mode 0`: the same kernel with every round's copies into shared memory and its
    barriers, but no 3b loop;
  - phases 1, 2 and 3a are not in the microbenchmark at all: their outputs are read from the dump.

**RX 9070 XT [P]:**
- The model's W64 3b is 2.27 ms (issue ÷ 0.77). That is 0.72 of a main kernel of 3.16 ms and 0.87 of the measured
  2.607 ms.
  - 3.16 ms = stop 3's measured 3.843 ms minus the model's tops + parents, 0.60–0.76 ms.
  - The 2.607 ms main is the measured stop difference, which `DESIGN.md` §2 says is too low because tops and parents
    were measured off the operating point.
- The prototype's measured components put 3a + 3b at about 1.79 of 3.04 ms (0.59).
- Band: **0.59–0.87**.

## Exactness

- **The dump reproduces the CPU reference** (`raw/dump_<pip>.txt`, line `REF`). `box/dump.sh` ran
  `mo_width_dump <pip> /root/dump 10`, which rebuilds `slice_join`'s objects in its order. On all three slices its W64
  totals equal `cpu::slice_join_threads`'s counters exactly:
  - flat 251,447,411 / 250,962,492 / 250,486,772; kept 123,690,652 / 123,347,626 / 123,163,397;
  - words 10,986,804 / 10,932,841 / 10,929,765; survivors 11,830,109 / 11,771,511 / 11,768,560, clipped 0.
  - These also equal `CEIL/RESULTS.md`'s Q0 table for 712012851 and 4977728.
  - The step count of the 3b loop at W64 on 712012851 (460,954) equals the count `G2/port/model_rdna4.py` took from
    the real kernel.
  - Survivor bits are the same at every width (they must be); nonzero words fall from 10.99M (W64) to 10.37M (128)
    and 9.46M (256) on 4977728.
- **Every variant, every slice, every instance [M]:** the kernel's nonzero words (records in its slabs, summed per
  instance through a slab → instance map) and survivor bits equal the dump's for all 4,032 instances. That held in
  every pass before any timing (lines `EXACT … per-instance mismatches 0` in `raw/micro_{a,b,c,d}/out.txt`: 4 passes ×
  3 slices × 6–10 variants). The kernel's own lane-slot count equals the dump's. No variant ever differed, so no
  timing was withheld.
- **SPIR-V path [M]:** the same binary built with `cubecl-spirv` ran every variant exact on lavapipe at its native
  W 8, for the first 48 instances of 712012851 (`raw/lvp_exact_w8.txt`). The W 64 modules for ACO came from a
  compile-only lavapipe run (`raw/aco/spv_run_w64_on_lvp8.txt`; counts there are not evidence). spirv-val (Vulkan
  1.3) passed every module.
- **The W64 kernel is the real 3b [M]:**
  - **ACO:** the 3b loop is valu 173 / salu 49 / LDS 39 (38 `ds_read_b64` + 1 `ds_read2_b32`) per wave-iteration,
    against `g2_kernel`'s 171 / 50 / 39, same op mix (`raw/ldsbytes.txt`; the reference is G2's `h5l_narrow` dump of
    the same kernel text).
  - **CubeCL's CUDA source** (`CUBECL_DEBUG_LOG`, `box/cudasrc.sh`, `box/cudacmp.py` → `raw/cudasrc/cmp.md`): 72
    shared loads, 49 AND, 40 SHR, 4 ballots, 8 popc, 1 shuffle in both loops. The ORs are 72 against 70 (the
    nonzero tests), the global stores 4 against 3 (my slab → instance write), and the atomics 1 against 2 (the real
    kernel's slab-overflow error counter).

## Other measurements, and why pass d is the one in the table

- **Passes a–c** (`raw/micro_{a,b,c}/`) ran the variants in a fixed order. Their ratios moved between passes:
  - W256x1 against W64: ×1.20 in b, ×1.07 in c.
  - Cause: under this card's power and thermal limits the clock follows the power of the launch before. The
    bank-conflicted W256 variants draw less power, and the variant after them ran faster.
- **Pass d** shuffles the order every rep and logs the clock per measurement; its spread between slices is under 2 %.
- Earlier passes agree on the ordering: the best widths are within 2 % of each other; W64 is slowest except the
  unswizzled W256.

## What building it in would take (the rule's second branch) [J]

Only width 128 with one entry per lane is worth it (equal registers, best by both measures). It would need:

1. **Phase 2 and the chunk layout.**
   - Keep phase 1 and the 64-child transpose as they are.
   - Treat chunks 2j and 2j+1 of a round as one 128-child chunk. The shared row becomes `[(v + 65·q) · 4 + k]`, or,
     for no change at all to phase 2, two 8-byte reads at `q = 2j, 2j + 1`; the 3080's banks then conflict for half
     the stream pairs, so the 16-byte row is better.
2. **Common masks and 3a.**
   - A 128-chunk's common digits are those common to both halves: `cmv128[v]` bit j = bit 2j & bit 2j+1 of today's
     `cmv`. That is one AND and a bit compaction in the one-wave `cmv` build.
   - 3a's kept mask has 8 bits; the list entry format is unchanged.
3. **3b.** Lane = 128-chunk (`q = t % 8`), 32 probe streams, one entry per lane, four words; the microbenchmark's
   `w128v1` loop as it is.
4. **Records.**
   - Keep today's 16-byte record per nonzero 64-bit half, so that the expansion, the conservation law (bits read =
     bits written) and the record count stay as they are.
   - This needs a rank per half: two ballots per entry instead of one, in the rare store path.
   - Storing the whole 128-bit word instead doubles record bytes: on the RX 9070 XT that is about +0.3 ms of DRAM
     writes (the card's measured 550 GB/s), which cancels the gain.
5. **The expansion** is unchanged with that record format.
6. **Execution checks.**
   - `A_PROBES`, `A_CHILD` and `A_JOBS` are unchanged. `C_LSLOTS` changes meaning (halved).
   - The sampled CPU check is unchanged (the survivor set does not depend on the width).
   - `Counts::kept` / `words` at width 128 are different numbers; the CPU reference would need a width parameter
     for the audits that compare them. This dump program has one.
   - Mutation tests M17/M26-style (order, skip) still survive; add one that pairs the wrong halves.
7. **On the RX 9070 XT:** ACO gives the same 120 VGPRs, 12 waves per SIMD and no spills as today's 3b at width 128,
   one entry per lane (`raw/preflight_cw.md`). The whole kernel's budget is set by its other phases and is
   unchanged.
8. **Risks:**
   - (a) The LDS bound: the decisive unknown above. If it holds, the gain is ×1.10–1.16 and not worth the change.
   - (b) RDNA bank behaviour of the 16-byte rows (ACO splits them into two `ds_read_b64`).
   - (c) The 3080 gains only ×1.09, so a narrow-path change for one card's sake.
   - (d) A new audited kernel; the cleanup's "byte-identical" property of today's 3b is lost.

**Recommendation:** run `mo_width_bench` (SPIR-V build) on the RX 9070 XT for `w64,w128v1,w256x1` before deciding.
If W128's 3b is not at least ×1.35 faster there than W64's, drop the idea.

## What I could not finish, and limits

- No RX 9070 XT measurement (not allowed; the decisive number above).
- I ran no head-built SPIR-V dump of `g2_kernel`. The ACO reference is G2's `h5l_narrow` module (2026-11-19), whose
  3b loop the cleanup kept byte-identical by its own account.
- The 3080 main-kernel gain combines the measured in-situ share with the microbenchmark's ratio [D]. A width-128
  `g2_kernel` was not built or timed.
- The card throttled thermally; everything is also given in cycles. Clocks were not locked: the brief said the card
  is not capped, so I did not change its configuration.
- The 3b list order in the dump is probe order; the real kernel's is the order of 3a's atomic appends
  (nondeterministic). It is the same set and the same count of steps.

## Files

- **Branch** `exp/mo-word-width` (commits `b8a75bbd`…).
  - `common/examples/mo_width_dump.rs`: the CPU dump.
  - `common/examples/mo_width_bench.rs`: three widths × variants of 3b, the exactness check, timing.
  - `g2_kernel`'s ablation bit (`MIDOUT_ABL3B`); `Cargo.toml` example entry.
- **`box/`:**
  - `setup.sh`, `hosts_block.sh` (production hosts to loopback; proof `raw/hosts_block.log`; no client binary ever
    ran);
  - `build.sh`, `dump.sh`, `micro.sh`, `realk.sh`, `spv.sh`, `cudasrc.sh`;
  - `steps.py`, `cyc.py`, `realk_an.py`, `ldsbytes.py`, `model_cw.py`, `cudacmp.py`.
- **`raw/`:** dumps' logs, micro passes a–d, real-kernel stops, ACO listings and SPIR-V, CUDA sources, the model's
  output.

Sources consulted for the LDS figure:
[ROCm, RDNA WGP (32 LDS banks per CU on RDNA 3.5)](https://rocm.docs.amd.com/projects/rocprofiler-compute/en/develop/conceptual/rdna/wgp.html),
`G2/port/model_rdna4.py` (128 B/clk/CU).
