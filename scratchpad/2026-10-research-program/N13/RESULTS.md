# N13 RESULTS: the open PRs, the profile and a retune on the RX 9070 XT (wgpu, SPIR-V), 2026-11-11

Machine: demoux, AMD Radeon RX 9070 XT (RADV GFX1201, Mesa 26.1.6, Vulkan 1.4.354), Ryzen 5 5600X (12 threads),
power cap 304 W (the card sat at its cap, 303–304 W, 3.16–3.20 GHz in every timed run), the user's desktop session
running alongside. Work only under `/tmp/claude-exp-2026-11-11-amd`; raw logs copied to `raw/demoux/`, scripts in
`raw/scripts/`; `python3 raw/scripts/analyze.py raw/demoux` gives every table (→ `raw/analysis.txt`).
Provenance: **[M]** measured here, **[D]** derived, **[A]** assumed / from another report, **[E]** estimate.

**Build (production's path):** every binary is `nice_common`'s release test binary built with
`cargo test --release -p nice_common --features gpu,cubecl-spirv --no-run` (`nice -n 19`, `-j 8`, toolchain stable
1.99.1 under `$W/run.sh`): `gpu` = cuda + cubecl + cubecl-cuda (inert here), **`cubecl-spirv` = CubeCL's wgpu runtime
with its SPIR-V compiler on Vulkan**; the harness reports the device as `AMD Radeon RX 9070 XT (RADV GFX1201) (Vulkan,
wgpu<spirv>)`, which is production's telemetry string. One extra binary, `E_naga`, is built with `--features gpu,cubecl`
(wgpu through WGSL/naga) for the compiler comparison.

Trees (each + `patch_harness.py`, the field-list harness): **M** = upstream main `c0c357a`; **T250** = `ee303030` (#250);
**T251** = fork `pr/check-d` `a97e3d7` (#250 + #251; + `patch_dense_wgpu.py`, a wgpu twin of the dense CPU compare);
**T254** = fork `pr/top-fd-base64` `69c514d` (#250 + #254; + `patch_dense_wgpu.py`); **E** = fork `exp/b64-profile`
`44eee52` (main's join kernels + #250's FD, L51's profile timers and knobs) + `patchC.py` (wgpu switches: the CUDA plan
on a non-CUDA device, the walk's plane barrier, a device info line). Harness: `join_throughput_fixed_fields` (the wgpu
client), one untimed 1e14 warm-up field per process, then the listed fields with 2 in flight; seconds are the process's
wall time for its fields.

Fields (positions of the base range): b60 1e16 at 0.55 and 0.85 (1447429612114824200908, 1933629612114824200908);
b62 1e17 at 0.35 and 0.55 (6566266762397899821056, 8474866762397899821056) — **the 0.35 field is empty at 1e17** (its
field certificate fails, as on the RTX 3080 in B64), so the b62 pair measures the 0.55 field plus an empty one; a
supplementary b62 set uses the heavy field at 0.45 (7520566762397899821056); b64 1e17 and 1e16 at 0.55
(58557331862957161709568).

**Device facts [M]** (`EXP_INFO` line, tree E): runtime `wgpu<spirv>`; largest buffer (`max_page_size`) 2,147,483,644 B;
**`JoinLimits { max_binding: 2 GiB, budget: 2 GiB, vram_budget: false }`**, so the plan is the sparse one (no CUDA
denser plan) within 2 GiB on a 16 GB card; **plane size 32–64** (RADV reports `subgroupSize` 64 max), so
**`ballot_append` is off** (it needs planes of at most 32 lanes) and the append keeps the two scans; the plane features
are `Ops | Sync | NonUniformControlFlow`, i.e. **the device has a plane barrier**, but `walk_sync` is CUDA-only today.
Plans [M]: b62 1e17 at 0.45: 14 slices, 5–7 partitions per launch, 7,959 launches (the RTX 3080 under CUDA: 11 slices,
11 per launch, 3,288); b60 1e16: 2 slices, 4 per launch, 1,350 launches per field (CUDA: 9, 625); b64 1e17: 12 slices,
5–6, 7,076 (CUDA: 10, 6→13 with #250); b64 1e16: 2 slices, 6, 1,025.

**Exactness [M]** (`wgpu_join_matches_the_cpu_join_on_a_dense_field`, a wgpu twin of the CUDA dense test, device hits
and both survivor counts asserted equal to the CPU join's; `x_*`): T251 at b60 1e16 (0.55, 48 partitions: 1,626,434,378
/ 109,004,818) and b62 1e17 (0.45, 24 partitions of slice 0 of 14: 511,657,234 / 31,201,162); T254 (FD at b64) at b64
1e16 (0.55, 48 partitions: 3,584,409,792 / 222,198,195) and 1e17 (0.55, 24 partitions of slice 0 of 12:
1,789,256,479 / 110,929,129): **all ok**. Every timed run of every tree gave the same counts per field set (b60 pair
395,945,633,344 / 26,588,456,447; b62 0.35 + 0.55 349,723,261,251 / 21,540,075,002; b62 0.45 1,097,114,812,011 /
66,862,268,894; b64 1e17 3,092,989,872,066 / 191,683,594,021; b64 1e16 341,241,364,278 / 21,155,177,740; the b64
counts equal the RTX 3080's on the same fields).

## Summary

All on demoux's RX 9070 XT at its 304 W cap, wgpu with CubeCL's SPIR-V compiler (production's path); [M] measured,
[D] derived, [A] from other reports, [E] estimate. Window used 12:45–14:54 UTC; nothing of mine runs on demoux (§E).

- **A, the open PRs here [M]** (3 interleaved rounds each; A/A noise 0.2 %, rounds within 0.3–1.4 %; counts identical
  in every run and exact against the CPU join on one field per base):
  **#250 ×1.04 at b62 1e17, ×1.03 at b60 1e16; #251 on top ×1.13 / ×1.14; main → #251 ×1.17 / ×1.18; #254 on #250
  ×1.10 at b64 1e17, ×1.09 at b64 1e16.** #250 gains less than on CUDA because its denser plan is CUDA-only.
- **B, where the time goes [M]** (b62 1e17 / b60 1e16): top FD 22 % / 19 %, join 53 % / 56 %, check (main's) 17 % / 19 %,
  bucket 4 % / 3 %, setup 3 % / 1 %. Inside the join, from whole-field totals per ablation mode: AND 13 % / 17 %,
  walk rounds 3 % / 0 %, prefilter 1 % / 5 %, base ~36 % / ~33 % [D]. **Against the RTX 3080: the survivor path is
  nearly free here (4 % against 29 %), while the join's base costs ~4× as much per pair (~1.0 against 0.26 ps) and
  the check ~2× (0.20 against 0.11 ns).** The FD top test costs the same (0.14–0.15 against 0.158 ns).
- **C, the retune [M]** (b62 1e17 at 0.45 and b60 1e16 at 0.55; 2 rounds, 3–5 for anything ≥ 3 %):
  **CUDA's denser plan on this adapter (`vram_budget`) ×1.04 / ×1.04; TOP_CAP 128 (TRANSPOSE_MIN 96) ×1.04 / ×1.05;
  both together ×1.08 / ×1.11 (3 rounds)**; AND_GROUP 8 and TRANSPOSE_MIN 128 ×1.01–1.02; the walk's plane barrier
  ×1.00; naga against SPIR-V ×1.02 / ×1.00; wide u64 chunks ×0.93–0.94; EPT 1 or 3, AND_GROUP 2, TRANSPOSE_MIN 256,
  TOP_CAP 512 lose 2–13 %.
- **Ranked levers for this card:** (1) land #251 ×1.13–1.14 and #254 ×1.09–1.10 [M]; (2) give wgpu devices with
  enough memory #250's denser plan ×1.04 [M] (simple: the `vram_budget` gate in `limits_of`); (3) a smaller top batch
  on this device (TOP_CAP 128) ×1.04–1.05 [M], ×1.08–1.11 together with (2) [M] (medium: TOP_CAP is a constant
  shared with NVIDIA, where 128 loses 4 % [A, L51/B64], so it needs a per-device value); (4) the join's base, ~1/3 of
  the field here at 4× NVIDIA's cost per pair: the largest unexplained block (not profiled further in this window).

## A. The open PRs on this card [M]

A/A pair first (main, b60 pair, two processes back to back): **26.22 against 26.16 s (0.2 %)**; within each tree the
three rounds below spread by 0.3–1.4 %. 3 rounds, order rotated (`chain_A.sh`, `chain_A2.sh`); seconds = wall time of
the process's fields; "×" = earlier tree ÷ later tree, per round, then the median.

| field set | main c0c357a | #250 ee30303 | #251 a97e3d7 | main → #250 | #250 → #251 | main → #251 |
|---|---|---|---|---|---|---|
| **b62 1e17 at 0.45** (the heavy field) | 75.43, 75.97, 75.71 | 72.73, 72.24, 73.02 | 64.27, 64.57, 64.52 | ×1.037, 1.052, 1.037 → **×1.041** | ×1.132, 1.119, 1.132 → **×1.127** | **×1.173** |
| b62 1e17 at 0.35 (empty) + 0.55 | 27.60, 27.73, 27.78 | 26.57, 26.67, 26.64 | 24.00, 24.13, 24.03 | **×1.040** | **×1.107** | ×1.150 |
| **b60 1e16 at 0.55 + 0.85** | 26.30, 26.49, 26.34 | 25.56, 25.39, 25.56 | 22.33, 22.31, 22.46 | ×1.029, 1.043, 1.031 → **×1.031** | ×1.145, 1.138, 1.138 → **×1.138** | **×1.178** |

| field | #250 ee30303 | #254 69c514d | #250 → #254 |
|---|---|---|---|
| **b64 1e17 at 0.55** | 149.84, 150.30, 149.82 | 137.14, 136.92, 136.65 | ×1.093, 1.098, 1.096 → **×1.096** |
| **b64 1e16 at 0.55** | 17.08, 17.19, 17.18 | 15.82, 15.66, 15.79 | ×1.080, 1.098, 1.088 → **×1.088** |

- **#250 is worth only ×1.03–1.04 here** (its own PR measured it on CUDA), because part of it is CUDA-only: the denser plan (`SURV_PER_PREFIX_VRAM`, behind
  `vram_budget`) does not apply to this adapter, so batches keep 5–7 partitions per launch and the FD kernel re-seeds as
  often as before; only the cheaper stepped slot remains.
- **#251 is worth ×1.13–1.14** (RTX 3080: ×1.22 at b62 1e17 [M, B64 §1]): the check is 17–19 % of a field here (B),
  so the cheaper check pays well, if less than on CUDA.
- **#254 (FD at b64) is worth ×1.09–1.10** here, on the sparse plan, the same as on CUDA on #250 (×1.09 / ×1.06 [M,
  B64 PR-RESULTS]): the FD test's advantage at b64 carries over to wgpu.
- **The three together**: main → #251 ×1.17–1.18 at b62/b60 [M]; at b64, #254 on top ×1.09–1.10 [M].
- **Seconds per field next to the RTX 3080 at 300 W [M, B64]:** b62 1e17 at 0.45, main: **75.7 s here, 66.7 s on the
  3080** (device time 74.9 against 66.7); at 0.55: 26.5 s device against 21.8 s; b64 1e17 at 0.55 on #250: **149.8 s
  against 141–145 s**; on #254: 136.9 against 130.0–130.6. So this card at 304 W runs the join at 0.87–0.95× the RTX 3080
  at 300 W.

## B. Where the time goes on this card [M]

Tree E (main's join kernels + #250's FD) with the profile timers, mode c twice (b62 1e17 at 0.45; b60 1e16 at 0.55 +
0.85) and modes a, z, b, p once (`chain_B.sh`, `p_*`). Shares are of the profiled field (count probe excluded).

**A caveat specific to wgpu:** in the ablation modes the profile's per-phase split is not trustworthy here: the top
phase's timer grew from 18.2 s (mode c) to 30.9 / 35.2 / 28.7 s in modes a / z / b on the same field with the same
top kernel, while top + join stayed close to the totals. CubeCL's wgpu sync evidently lets work of the next phase be
counted in the previous one when the join is light. So the join's parts below come from **whole-field totals per mode**
(a − z, b − a, p − b, c − p), which do not depend on that split; the mode-c phase shares are given as measured but carry
the same caveat at the top/join boundary.

| phase (share of the profiled field) | 9070 XT b62 1e17 (0.45) | 9070 XT b60 1e16 (pair) | RTX 3080 b62 1e17 [A: L51, 180 W] | RTX 3080 b60 1e16 [A: L51] |
|---|---|---|---|---|
| top (FD) | 22.4 % (18.2 s) | 18.9 % | 22.8 % | 18.4 % |
| bucket | 3.9 % | 3.4 % | 2.5 % | 2.3 % |
| join (mode c's phase) | 53.2 % | 55.7 % | 55.9 % | 59.0 % |
| · AND (a − z, totals) | 13.2 % (10.7 s; 0.38 ps/pair) | 17.4 % (0.53 ps/pair) | 14.9 % (0.30 ps/pair at 340 W [A, N1]) | 15.0 % |
| · walk rounds (b − a) | 2.7 % | 0.1 % | 9.2 % | 9.0 % |
| · prefilter (p − b) | 1.2 % | 4.9 % | 19.8 % | 23.5 % |
| · stage + check (c − p) | 15.6 % | 16.5 % | (stage 1.1 % + check 12.0 %) | (0.9 % + 14.4 %) |
| · base [D: join − AND − walk − prefilter] | **~36 % (29 s; ~1.04 ps/pair)** | **~33 % (~1.0 ps/pair)** | 10.9 % (0.26 ps/pair [A, N1]) | 10.5 % |
| check (main's) | 17.0 % (0.206 ns per check) | 18.8 % (0.197 ns) | 12.0 % (0.111 ns at 340 W [A, N1]) | 14.4 % |
| slice setup (upload) | 3.3 % | 1.3 % | 4.8 % | 4.5 % |
| inputs, reads, other | ~0 % | ~2 % | 1.9 % | 1.5 % |

- **Per operation [M]:** join 1.53–1.55 ps per pair at b62 (RTX 3080 at 340 W: 1.24 [A]); FD top test **0.149 ns**
  (b62) and 0.142 ns (b60) (RTX 3080 at 340 W: 0.158 ns [A]); full check (main's) 0.20 ns (0.111 ns [A]); mean tile
  385 tops × 350 entries at b62 (0.45), 1,050 × 347 at b60; AND pass rate 3.9 % / 4.3 %; 67–70 % of the entry lanes in
  use.
- **What is different here:** (1) **the survivor path is cheap** (walk + prefilter 4 % of the field at b62 against 29 %
  on the 3080; 0.11–0.15 ps per pair against 0.67): the max-lane rounds that make NVIDIA's walk expensive cost
  little here (why is not measured: wave64 planes or RADV's scheduling are guesses [E]); (2) **the join's base is ~3× larger in share and ~4× in
  ps per pair** (the batch loads, the transposed copy and the entry waves; ~1 ps/pair against 0.26): this is where the
  card loses to the 3080, and it is the first thing to look at; (3) **the check is dearer** (0.20 against 0.11 ns,
  17–19 % of the field), hence #251's ×1.13; (4) the FD top kernel is as fast as on the 3080; (5) the plan is sparse: 5–7
  partitions per launch, 2.4× the launches of CUDA's plan.

## C. Retune on this card [M]

Tree E (+ `patchC.py`), unprofiled, b62 1e17 at 0.45 and b60 1e16 at 0.55, one process per (variant, field), every
value its own kernel; rounds 1–2 (`chain_C.sh`, round 2 reversed), round 3 for anything near or above 3 %
(`chain_C3.sh`), rounds 4–5 for the combination (`chain_C4.sh`). Ratio = the round's mean base ÷ variant (base b62:
73.81 / 73.68 / 73.75 / 73.56 / 73.70 s; b60: 13.01 / 13.01 / 13.04 / 13.01 / 13.10 s); > 1 is faster. Every run gave
the same counts. Plan unchanged (7 per launch at b62, 4 at b60) except where noted.

| knob | value | b62 1e17 (per round) | b60 1e16 (per round) | verdict |
|---|---|---|---|---|
| ENTRIES_PER_THREAD (2) | 1 | ×0.958, 0.962 | ×0.965, 0.964 | loses 4 % |
| | 3 | ×0.980, 0.972 | ×0.993, 0.969 | loses 2–3 % |
| TRANSPOSE_MIN (192) | 128 | ×1.019, 1.015, 1.019 | ×1.034, 1.020, 1.012 | **+1.8 % / +2.2 %** (< 3 %) |
| | 256 | ×0.948, 0.954 | ×0.975, 0.979 | loses 2–5 % |
| AND_GROUP (4) | 2 | ×0.959, 0.957 | ×0.964, 0.959 | loses 4 % |
| | 8 | ×1.027, 1.018, 1.023 | ×1.012, 1.013, 1.012 | **+2.2 % / +1.2 %** (< 3 %) |
| TOP_CAP (256) | **128 (TRANSPOSE_MIN 96)** | **×1.047, 1.037, 1.032 → ×1.039** | **×1.064, 1.046, 1.042 → ×1.051** | **wins 4–5 %** |
| | 512 | ×0.876, 0.871 | ×0.891, 0.893 | loses 11–13 % |
| plan: CUDA's denser plan (`NICE_EXP_VRAM=1`: `with_vram_budget`) | 12 per launch at b62 (4,458 launches against 7,959), 9 at b60 (625 against 1,350); budget still 2 GiB | **×1.039, 1.041, 1.038 → ×1.039** | **×1.045, 1.041, 1.045 → ×1.044** | **wins 4 %** |
| **TOP_CAP 128 + denser plan** | | **×1.070, 1.088, 1.076 → ×1.078** | **×1.104, 1.108, 1.105 → ×1.106** | **wins 8–11 % (the two add)** |
| walk's per-round plane barrier (`walk_sync`, CUDA-only) | on (`NICE_EXP_WALK_SYNC=1`; the device has Plane::Sync) | ×1.007, 0.997 | ×1.001, 0.996 | neutral |
| compiler | naga / WGSL (`E_naga`, `--features gpu,cubecl`) | ×1.024, 1.020 | ×0.999, 0.999 | +2 % at b62, none at b60: SPIR-V is not a loss |
| wide u64 chunk scan | `NICE_CUBECL_WIDE=1` | ×0.946, 0.941 | ×0.927, 0.936 | loses 6–7 % (as in the detailed mode under SPIR-V) |

- **Plane size and the one-ballot append [M]:** RADV reports planes of 32–64 lanes, so `ballot_append` (planes of
  at most 32) is off and #249's append keeps `plane_sum` + `plane_exclusive_sum`. Not tested forced on: with a 64-lane
  subgroup the ballot's upper half would be lost (the gate's reason), and RADV's compute subgroup size in this pipeline
  is not known from here.
- **The plan's budget [M]:** this adapter gets `JoinLimits { max_binding: 2 GiB, budget: 2 GiB }` on a 16 GB card; the
  layouts measured were 1.1–1.3 GiB (sparse plan). The denser plan keeps the 2 GiB budget and still fits (no re-runs,
  no refusals). A larger budget was not tried (it would need the binding limit raised).
- **Why TOP_CAP 128 wins here and loses on NVIDIA (×0.96 [A, L51/B64]):** not measured. Likely candidates [E]: the
  join's base dominates here, and a 128-top batch halves the transposed copy and shared-memory footprint per work item
  (more work groups resident); on NVIDIA it leaves half the threads idle in the copy.

## D. Not done

The b64 FD-parameter A/B (D) and a deeper look at the join's base (which part of it: the batch load, the transposed
copy or the entry waves) were not started; I stopped at 14:54 to give the card back early. Not measured either:
TOP_CAP 64 or other TRANSPOSE_MIN values with TOP_CAP 128; the combination at b64; a budget above 2 GiB; the ballot
append forced on; NiceMark on this card.

## E. The machine

Everything ran under `/tmp/claude-exp-2026-11-11-amd` through its `run.sh` (PIDs registered); builds under `nice -n 19`
`-j 8`. At 14:54 UTC no process of mine was alive (every registered PID checked; only the watchdog runs there, which
is not mine), and I deleted my build output (`target/`, 1.4 GB of the tmpfs, and `bin/`); the rest is left for the
16:30 watchdog. All logs and scripts are on ivory: `raw/demoux/` (runs: `.log`, `.gpu` = busy %, clock, power every
5 s; `chain_*.out`; `build_*.log`; `trees.txt`; `scripts_on_demoux/`), `raw/scripts/`, `raw/analysis.txt`.
Nothing was pushed anywhere.
