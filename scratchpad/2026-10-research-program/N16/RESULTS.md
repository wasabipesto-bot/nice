# N16 RESULTS: a corrected profile of the join, and a harness for the RX 9070 XT's window (2026-11-12)

Provenance: **[M]** measured here (box or logs), **[D]** derived by arithmetic from [M], **[A]** assumed or taken
from another report, **[E]** estimate. "Card" = the user's RX 9070 XT (demoux, RADV, wgpu with CubeCL's SPIR-V
compiler); "3080" = the rented RTX 3080 (Vast 60317813, 280 W cap, Ryzen 5 5600X, CUDA 12.8 driver 580.126.09).
Scripts: `raw/scripts/`; box logs: `raw/box/` (`raw/box_keep/` = the must chain's round-1 logs before a name
collision overwrote one of them on the box, §B.6); Task A: `raw/taskA.txt`; Task C: `raw/taskC.txt`, dumps in
`raw/box/spv_*/`.

## Summary

- **A (N13's logs) [M/D]: the card's "base = a third of the field" is an artefact.** In the profiled ablation modes
  the 9070 XT fell to 1.47–1.93 GHz and 88–102 W (from 3.2 GHz / 290 W); N13 differenced whole-field totals across
  those clocks. Bounded honestly, at b62 1e17: **base 7–13 % (0.20–0.38 ps/pair; 3080 0.26), AND 12–19 %, walk 5–6 %,
  prefilter 15–28 %, survivor path 21–35 %, check 17 %, top 22 %** — NVIDIA's shape, not a card-specific base
  problem. Every unprofiled N13 number (PR gains, retune, TOP_CAP 128, denser plan) was at the operating point and
  stands. §A.
- **B (harness) [M]: branch `exp/n16-join-base`** (`8ca0514`, `a6cd001`, `cd8b808` on 44eee52): exact **doubling
  modes** (`NICE_EXP_JOIN_DBL`: batch loads, transposed copy, AND, shadow walk, prefilter, check kernel, entry waves,
  barriers), finer removal modes (`ABL` 5–8), work-group size (`JOIN_WG`, decoupled from TOP_CAP), the survivor stage
  size (`SCAP`), the top append's ballot forms, a partitions-per-launch cap, host-side launch accounting (`HOSTACC`) and
  a plane probe. Every exact mode passed the dense compare against the CPU join on CUDA (b60 1e16, b62 1e17) and on
  lavapipe (wgpu, SPIR-V), except `wsync`, which lavapipe does not run (caught by the dispatch check, not miscounted).
- **B (the RTX 3080's profile, 280 W) [M]:** by doubling at b62 1e17 / b64 1e17: **prefilter 15.9 / 20.8 %, AND
  14.6 / 14.6 %, check 11.3 / 11.0 %, walk 9.1 / 12.6 %, transposed copy 4.6 %, batch loads ≥ 1.4 %, barriers 0.1 %,
  entry-wave loads ≥ 0 %**; removal (unprofiled) agrees within 1–3 points (AND 16.6 %, walk + prefilter 28.4 %, stage +
  check 12.2 %), and so does L51. The 3080 keeps (raises) its clock in every light mode: the NVIDIA column, L51's and
  B64's included, is trustworthy.
- **B (launches) [M]:** on CUDA every launch fence completes inside `client.sync()` (0 pending of 2,615): batches do not
  overlap, and the host's ~1 ms per batch at b62 (2.4 s, ~4 % of the field, nearly all in CubeCL's flush) is GPU idle
  time — a possible ×1.04 for NVIDIA [E], outside this brief. Seconds against batches: 0.78–0.84 ms per batch (b60,
  b62). On wgpu (lavapipe) the opposite: every fence is pending and the host blocks in the flush for the whole field,
  so on the card HOSTACC's create + launch time is the host's own per-batch cost and the flush is GPU time.
- **C (ACO for GFX12) [M]:** the join runs as **wave64**; at 64 threads ACO drops every barrier, but the cube is
  **LDS-bound: 18.5 KiB → 12 waves per SIMD**; TOP_CAP 128 → 18, a 512-entry stage → 16, both → 24. **This explains
  TOP_CAP 128's win on the card and its loss on NVIDIA** (register-bound there; on the 3080 the stage size is neutral
  and TOP_CAP 128 loses 3–4 %). No spills, clamps or emulated 64-bit; the AND's addresses fold; the walk round costs
  ~113 instructions per entry slot (wave64 exec bookkeeping) against NVIDIA's ~66; the FD append's scans already
  compile to a ballot (forcing `ballot_append` should gain nothing). §C.
- **D [M]: branch `exp/n14-wgpu-dense-plan` (`464be8b` on 5b1d627):** the denser plan for a wgpu adapter that wgpu
  reports as `DiscreteGpu`, not a software rasterizer, with a budget ≤ 2 GiB; Apple (unified memory → IntegratedGpu),
  APUs, VMs and lavapipe keep the sparse plan. wgpu exposes no memory size, so the rule is a class rule, not a share;
  said plainly in §D. Unit test, fmt and clippy clean; the lavapipe device tests pass.
- **The window (WINDOW-PLAN.md):** one script (`go_window.sh`) builds three binaries and runs, in priority order with a
  hard `END_AT`: the doubling profile at b62 and b64 (must-have, done by ~0:39 with three and two base runs and a clock
  check at the checkpoint), the survivor/tops switches and unprofiled removal with clocks, geometry + occupancy +
  launches, Task D's A/B, and a second doubling round. Every script ran end to end on the box under CUDA and lavapipe.


## A. What N13's logs already say (re-derived with the clock of every run)

`python3 -I raw/scripts/taskA.py ../N13/raw/demoux` → `raw/taskA.txt` (all numbers in this section are [M] from
N13's logs or [D] from them).

**The profiled ablation runs were not at the card's operating point.** Busy-sample medians (≥ 80 % busy) of the
5-second samples N13 took in every run, b62 1e17 at 0.45 / b60 1e16 pair:

| mode | clock (MHz) | power (W) | top phase (s) | join phase (s) | field total excl. probe (s) |
|---|---|---|---|---|---|
| c (full) | 3228 / 3222 | 294 / 289 | 18.21 / 5.28 | 43.31 / 15.65 | 81.32 / 28.10 |
| c2 (full, again) | 3232 / 3233 | 292 / 288 | 18.10 / 5.20 | 42.67 / 15.32 | 80.34 / 27.49 |
| p (no stage, no check) | 3142 / 3204 | 248 / 260 | 18.50 / 5.39 | 42.77 / 15.51 | 68.24 / 23.20 |
| b (walk, no prefilter) | **1932 / 1842** | **102 / 101** | 28.67 / 8.44 | 30.60 / 10.86 | 67.24 / 21.83 |
| a (AND only) | **1631 / 1582** | **96 / 95** | 30.92 / 9.84 | 25.82 / 9.37 | 65.07 / 21.80 |
| z (no AND) | **1466 / 1466** | **90 / 88** | 35.20 / 10.73 | 10.72 / 3.62 | 54.38 / 16.96 |

The top phase is the same FD kernel on the same work in every mode; its time grew ×1.57 / ×1.70 / ×1.93 in b / a /
z while the clock fell ×1.67 / ×1.98 / ×2.20. So the growth is the clock, not a sync artefact (N13 §B's reading),
and the per-phase timers are honest about seconds but each mode ran at its own clock. N13's join split took
differences of whole-field totals between modes at 3.2 GHz and at 1.5 GHz. Every unprofiled run of N13 (the PR A/Bs
and the retune, 123 runs) sat at 3074–3240 MHz and 278–310 W (one run at 278 W), so **those numbers stand**.

**Three estimates of the join's parts** (b62 1e17, 2.790e13 pairs, field 81.32 s):

| part | T: totals (N13's method) | J: join-phase timer differences | JS: J × top(c)/top(mode) (clock-scaled) | robust range [D] |
|---|---|---|---|---|
| base (z) | 29.45 s, 36.2 %, 1.06 ps/pair | 10.72 s, 13.2 %, 0.38 ps/pair | 5.55 s, 6.8 %, 0.20 ps/pair | **7–13 %, 0.20–0.38 ps/pair** (3080: 0.26 [A, N1]) |
| AND (a − z) | 10.69 s, 13.2 % | 15.10 s, 18.6 % | 9.66 s, 11.9 % | 12–19 % |
| walk rounds (b − a) | 2.17 s, 2.7 % | 4.78 s, 5.9 % | 4.23 s, 5.2 % | 5–6 % |
| prefilter (p − b) | 1.00 s, 1.2 % | 12.17 s, 15.0 % | 22.66 s, 27.9 % | 15–28 % |
| stage (c − p of the join timer) | — | 0.54 s, 0.7 % | 1.22 s, 1.5 % | ~1 % |
| survivor path (join timer c − a) | 3.2 % | 17.49 s, 21.5 % | 28.1 s, 34.5 % | **21–35 %** |
| check (mode c, 3.2 GHz) | 13.85 s, 17.0 % | | | 17 % (0.21 ns per check) |
| top FD (mode c, 3.2 GHz) | 18.21 s, 22.4 % | | | 22 % |

b60 1e16 (two fields, 9.225e12 pairs, 28.10 s): base 6.3–12.9 % (0.19–0.39 ps/pair), AND 11.6–20.5 %, walk 5.3–6.3 %,
prefilter 16.6–30.0 %, check 18.8 %, top 18.8 % (T gives 33.5 % for the base, as N13 reported). The T column
reproduces N13's 36 % / 33 %; that is the check on the method, not on the card.

- **Bounds without any scaling:** z's own join timer was 10.72 s at 1466 MHz, so the base is **at most 13.2 %** of the
  b62 field (if time does not rise when the clock does) and its cost per pair at most 0.38 ps; J and JS bracket every
  part because the true clock-corrected time of a mode lies between its time at its own clock (J) and its time scaled
  fully by the clock proxy (JS; the top kernel itself scaled ×1.93 for a ×2.20 clock, so JS slightly over-corrects).
- **What falls from N13:** "base ~36 % / ~33 % of the field, ~1.0 ps per pair, 4× NVIDIA's" (it is 7–13 %, 0.20–0.38
  ps, ≈ 0.8–1.5× the 3080's 0.26); "the survivor path is nearly free here (4 % against 29 %)" (it is 21–35 %, like
  NVIDIA's 29–30 %); "the join's base is where the card loses to the 3080, the first thing to look at"; and the
  explanation of the top timer as a sync artefact.
- **What stands:** every unprofiled number (the PR gains #250 ×1.03–1.04, #251 ×1.13–1.14, #254 ×1.09–1.10; the
  retune: TOP_CAP 128 ×1.04–1.05, the denser plan ×1.04, both ×1.08–1.11; EPT, AND_GROUP, TRANSPOSE_MIN, naga, wide
  u64, walk_sync), the mode-c phase shares measured at full clock (top 22 %, check 17 %, bucket 4 %, setup 3 %), the
  per-operation costs from mode c (FD top test 0.149 ns, check 0.206 ns), and the device facts (2 GiB binding,
  sparse plan, planes 32–64).
- **The launches (H1) from N13's own runs:** the denser plan saved 2.6–2.9 s of 73.6–74.0 s at b62 with 3,501 fewer
  batches (7,959 → 4,458; 3 rounds each, s_base/s_vram): **at most 0.81 ms per batch [D]**, an upper bound because
  fewer batches are also fewer FD seeds (each batch's first slot divides its certificates out; the top phase was 2.29
  ms per batch at 7 slots in mode c). N13's logs cannot split seeds from launches: no profiled run of the denser
  plan, and the FIELD lines' `jwait` (time the host waited on a launch fence) was 0.004–0.009 s per field, which says
  where the host did not wait, not where it did (on lavapipe the wgpu host blocks in CubeCL's flush instead, §B.3;
  the same is likely on the card). N16's HOSTACC line splits it (§B.3). For scale: on the 3080 the whole per-batch
  slope is 0.78–0.84 ms (§B.3), so the card's ≤ 0.81 ms is not out of line with NVIDIA's.
- **What cannot be decided without the card:** each part's cost at 3.2 GHz (only bounds above); whether the light
  modes drop the clock unprofiled too (N13 ran them only profiled); the per-batch launch cost on RADV; and whether
  TOP_CAP 128's gain is occupancy (Task C says the join's cube is LDS-bound there; §C).

## B. The harness (branch `exp/n16-join-base`) and the RTX 3080's profile

### B.1 The branch and every switch

Fork branch **`exp/n16-join-base`** from `exp/b64-profile` `44eee52` (main c0c357a's join kernels + #250's FD top
kernel, L51's profile timers and knobs): **`8ca0514`** = N13's `patchC.py` + `patch_dense_wgpu.py` (44eee52 already
carries the field-list harness); **`a6cd001`** = the N16 switches (`raw/scripts/patch_n16_kernel.py` +
`patch_n16_host.py`); **`cd8b808`** = the stage-size switch (`patch_n16_scap.py`, added after Task C); **`32e9e19`**
(head) = HOSTACC's split of `launch_batch` into buffer creation, launches and flush (`patch_n16_hostacc2.py`, added
after lavapipe showed the wgpu host blocking inside `launch_batch`). The timed CUDA runs used `a6cd001` (N16) and
`cd8b808` (N16b); 32e9e19 changes only host counters (checked: CUDA b62/b60 and lavapipe b60 runs and the dense
compares on both, `c3.*`, `xc3_*`, `xl3_*`). Tree E's join
kernels are unchanged at the defaults; every switch is read per process from the environment and passed to the
kernel as a comptime value, so each value compiles its own kernel. `raw/scripts/modes.sh` names every combination
the chains use.

| switch | values | what it executes | counts |
|---|---|---|---|
| `NICE_EXP_JOIN_DBL` (bit mask; `d_*` modes) | 1 `d_load` | the batch loads of the top records (words 2–7 of each record into the 8 shared arrays, the clip-word OR) twice | exact |
| | 2 `d_copy` | the transposed copy (`t_tr`, 64 words per thread of 32 shared loads and bit gathers) twice | exact |
| | 4 `d_and` | the AND twice: the transposed ORs over the entry's digits (or the per-top tests on small batches) | exact |
| | 8 `d_walk` | a shadow walk before the real one: the rounds' `plane_any` vote, the lane's pop and (on CUDA) the plane barrier, no prefilter | exact |
| | 16 `d_pf` | the lean prefilter twice per walked pair, results ANDed | exact |
| | 32 `d_check` | the check kernel launched twice per batch (its hits deduplicated on the host; `ran` expects twice the cubes) | exact |
| | 64 `d_wave` | the entry waves' loads (list, `bp_r`, `ext_m`, `ext_q`) and the entry terms twice | exact |
| | 128 `d_bar` | every work-item and batch barrier twice (6 extra `sync_cube` per item and batch) | exact |
| `NICE_EXP_JOIN_ABL` (removal; `r_*` modes) | 1 / 2 / 3 / 4 | L51's a (AND only) / b (walk, no prefilter, no stage) / p (walk + prefilter, no stage) / z (no AND) | timing only |
| | 5 `r_s5` | dispatch only: the first barrier, the final count and `cube_done`; no work item | timing only |
| | 6 `r_s6` | + the work-item headers (segment table, prefix sum, list header) and their three barriers; no batch loop | timing only |
| | 7 `r_s7` | + the batch loads into shared memory and the batch barriers; no copy, no entry waves | timing only |
| | 8 `r_s8` | + the transposed copy; no entry waves (4 = z adds the entry waves' loads and loops without the AND) | timing only |
| `NICE_EXP_JOIN_WG` | 64 / 128 / (256) | the join's cube size, decoupled from `TOP_CAP` (a batch of 256 tops is loaded and transposed in loops over the cube) | exact |
| `NICE_EXP_JOIN_SCAP` (+ `_FLUSH`) | 512 / 256 / (1024) | the shared survivor stage's entries (8 KiB of the 18.5 KiB at 1024) and its flush level | exact |
| `NICE_EXP_JOIN_TCAP`, `_TMIN`, `_EPT`, `_AG` | L51's knobs | TOP_CAP, TRANSPOSE_MIN, entries per thread, AND_GROUP | exact |
| `NICE_EXP_BALLOT` | 0 / 1 / 2 | the FD top append: plane sum + exclusive scan / one-word ballot (exact only on ≤ 32-lane planes) / two-word ballot | 0, 2 exact; 1 exact on CUDA |
| `NICE_EXP_WALK_SYNC` | 1 | the walk's per-round plane barrier on a non-CUDA device that has one (CUDA has it on) | exact |
| `NICE_EXP_SLOTS` | 1 / 2 / 4 / … | a cap on partitions per launch (the plan's own when unset) | exact |
| `NICE_EXP_VRAM` | 1 | CUDA's denser plan on a non-CUDA device (N13's switch) | exact |
| `NICE_EXP_HOSTACC` | 1 | a `HOSTACC` line per process: batches, kernel launches, fences still pending after a batch, count reads, and seconds in `launch_batch` (buffers, encode, submit, flush), in `launch_fence`, waiting on fences, and reading | — |
| `NICE_EXP_INFO` | 1 | N13's `EXP_INFO` line + `EXP_PLANE wg=…` lines: what a kernel sees (`PLANE_DIM`, `CUBE_DIM`, the plane sum of 1) at 256, 128 and 64 threads | — |

Every repeat of the doubling modes is indexed with `rep · zz`, `zz` a kernel argument that is always 0, so the
compiler can neither fold the repeat away nor hoist it (verified by their cost: every doubling except the cached
entry-wave loads moved the time on the 3080, §B.2); the shadow walk's checksum is added to the count times `zz`, the second
prefilter ANDed into the first. **A doubling measures the marginal cost of one more copy of a part at full load: its
instructions and shared-memory traffic in full, its global loads mostly from cache** (`d_wave` and `d_load` are
therefore lower bounds), and it can change the kernel's registers (none spilled on the 3080; ACO's counts for d_bar in §C).

**Validation [M]:** every mode ran on CUDA (b60 1e15 smoke, `raw/box/cu_*`) and gave the base counts
where exact; the **dense compare against the CPU join** (device hits and both survivor counts) passed for every exact
mode on CUDA at b60 1e16 (0.55, 8 partitions of slice 0: `xcu60_*`, 23 modes) and b62 1e17 (0.45, 4 partitions:
`xcu62_*`, 15 modes); on lavapipe with `--features gpu,cubecl-spirv` (the wgpu path with CubeCL's SPIR-V compiler, production's build
on the card) the same dense compare passed for **every exact mode but one** at b60 1e15 (8 partitions) and b62 1e17 (2
partitions of slice 0) (`xlp60_*`, `xlp62_*`, 22 of 23 modes each): **`wsync` (the walk's plane barrier forced on) is
not run by lavapipe**: its join dispatch finished 12 of 3,540 cubes, which `ensure_ran` caught (the run fails, it
does not miscount); on the card N13 ran `wsync` with identical counts, so the window keeps it; and every chain ran end
to end on lavapipe at 1e13 with shortened lists (`raw/lavapipe/`), every exact mode giving the base counts. Every timed run below gave the base
counts in every exact mode.

### B.2 The RTX 3080's profile by doubling and by removal (the NVIDIA column) [M]

Box 60317813, RTX 3080 10 GB at its **280 W cap**, CUDA (`cubecl_cuda_join_throughput_fixed_fields`, one untimed 1e14
warm-up field per process), binary `N16` (a6cd001; `N16b` = cd8b808 for the stage modes), unprofiled, one process per
run. Every run sat at **1,740–1,785 MHz and 279 W** (busy 98–100 %) except where noted; every exact mode gave the base
counts. Base = the mean of the same round's base runs (b62: 7 base runs over the two rounds, 60.78–62.79 s, the
first run of the box's first chain the fastest; 61.82–62.79 s without it; b64: 4 runs, 142.92–143.52 s). Logs `raw/sorted/` (= `raw/box/` with the chains' prefixes restored, §B.6);
`python3 -I raw/scripts/analyze.py raw/sorted` prints every row.

| part (doubling mode) | b62 1e17 at 0.45: Δs per round | share of the field (mean) | ps per pair [D] | b64 1e17 at 0.55: Δs per round | share |
|---|---|---|---|---|---|
| base field (mode c) | 61.97 s mean (7 runs) | 100 % | | 143.12 s (4 runs) | 100 % |
| **prefilter** (`d_pf`) | +10.19, +9.50 | **15.9 %** | 0.35 | +30.75, +28.67 | **20.8 %** |
| **AND** (`d_and`) | +9.15, +8.98 | **14.6 %** | 0.33 | +21.01, +20.69 | **14.6 %** |
| **check kernel** (`d_check`) | (+9.18 r1, a build overlapped it), **+7.01** | **11.3 %** (r2) | 0.25 | +15.78, +15.66 | **11.0 %** |
| **walk rounds** (`d_walk`) | +5.60, +5.65 | **9.1 %** | 0.20 | +18.07, +18.01 | **12.6 %** |
| transposed copy (`d_copy`) | +3.10, +2.59 | 4.6 % | 0.10 | — | — |
| batch loads (`d_load`) | +1.05, +0.66 | 1.4 % (cached second read: a lower bound) | 0.03 | — | — |
| barriers (`d_bar`, 6 more per item and batch) | +0.30, −0.15 | 0.1 % | 0.00 | — | — |
| entry-wave loads (`d_wave`) | +0.04, −0.14 | 0.0 % (cached second read: a lower bound) | 0.00 | — | — |

**Removal at b62, unprofiled** (round 1's base 61.81 s): z (no AND) 26.37 s at 1,740 MHz / 279 W; a (AND only) 36.65 s
(1,725 MHz); p (walk + prefilter, no stage, no check) 54.25 s (1,800 MHz); profiled c (`prof_c`, L51's per-phase
syncs) 63.77 s at 1,785 MHz (+3.2 %). So: **AND (a − z) 16.6 %** of the field against doubling's 14.6 %; **walk +
prefilter (p − a) 28.4 %** against 25.0 %; **stage + check (c − p) 12.2 %** against the check's 11.3 %. At b60 1e16
(one field, 11.59 s): AND 12.9 %, walk + prefilter 32.8 %, stage + check 11.4 %; the dispatch-only and base-cut modes
(`r_s5`–`r_s8`) ran 3.7–4.2 s, too short for the 2-second clock samples to mean much (two were flagged at 224–246 W),
and their differences (s5→s6 0.0 s, s6→s7 +0.3 s, s7→s8 +0.2 s, s8→z +0.8 s) say the base on the 3080 is mostly the
entry waves and not the item headers, loads or copy.

- **The two instruments agree on NVIDIA within 1–3 points of the field**, and both agree with L51's ablation at
  180 W (AND 14.9 %, walk 9.2 %, prefilter 19.8 %, check 12.0 % [A]). Doubling reads slightly lower than removal for
  the survivor path (25.0 against 28.4 %), as expected: the second copy of a part can overlap the first's latency.
- **The NVIDIA column is trustworthy:** on this card the clock does not fall in the light modes; it stays or rises (z
  at 1,740, a at 1,725, p at 1,800 against c's 1,740–1,770 MHz, all at 279 W; L51's z ran at 1,412–1,965 against c's 1,432–1,478 MHz at 180 W [A,
  L51 §2]), because a lighter kernel leaves headroom under the power cap. B64's profile was taken at ~1,835 MHz in
  mode c with the same timers [A]; its removal shares carry at most the same small clock bonus as L51's (a removed
  part's cost is slightly overstated, never by the 2× seen on the 9070 XT). **The profiled mode costs 3.2 % on the
  3080 and keeps its clock; on the 9070 XT the light profiled modes lost half their clock.**
- **The base's parts on NVIDIA** (doubling): copy 4.6 %, loads ≥ 1.4 %, barriers 0.1 %, entry-wave loads ≥ 0 %;
  together ≥ 6 % of the field against L51's base of 10.9 % [A] — the rest is the cold global loads (which a doubling
  does not repeat) and the work-item headers.

### B.3 Launches and host time on CUDA [M]

`HOSTACC` (every run; its own cost is 4 `Instant::now` and 5 relaxed atomics per batch, < 1 ms per field [D]; `c_nohost`
11.59 s against the base runs' 11.59–11.76 s at b60, within their spread):

| field | batches | launches (kernels) | in `launch_batch` (host) | in `launch_fence` | fences still pending | waits | reads |
|---|---|---|---|---|---|---|---|
| b62 1e17 | 2,615 | 10,462 | **2.40–2.62 s (0.92–1.00 ms a batch)** | 56.2–58.2 s | **0** | 0 | 9 (0.05 s) |
| b64 1e17 | 4,482 | 17,928 | 0.99–1.05 s (0.22 ms) | 139.7 s | 0 | 0 | 8 (0.12 s) |
| b60 1e16 | 625 | 2,502 | 0.12–0.15 s (0.20–0.25 ms) | 10.2–10.4 s | 0 | 0 | 2 |

- **On CUDA the launch fence is synchronous:** `client.sync()` completes inside the call in every batch of every run
  (0 of 2,615 fences pending), so the device thread waits for each batch before encoding the next, and the GPU is
  idle while the host builds the next batch's inputs and launches: ~1 ms a batch at b62 (2.5 s, **4 % of the field**),
  0.2 ms at b60/b64 (1 % / 0.7 %). The pipelining `run_pass` intends (`BATCHES_IN_FLIGHT = 4`) does not happen on
  CubeCL's CUDA runtime. A non-blocking fence there is worth up to ~×1.04 at b62 on NVIDIA [E] (outside this brief;
  noted for the program).
- **Where the host's time per batch goes** (head 32e9e19's split): on CUDA it is the flush (b62: create 0.03 s, launch
  0.01 s, **flush 2.38 s** of 2.43 s; b60: 0.007 / 0.003 / 0.143 s): CubeCL's CUDA runtime submits the queued kernels
  at the flush. **On wgpu (lavapipe) the host blocks in the flush for the whole field** (b60 1e13: flush 69.3 s of 69.4 s,
  every one of 900 fences still pending, waits 0.001 s): CubeCL's wgpu server throttles submission, so on a wgpu device
  the fence wait shows nothing and the flush time is GPU time. N13's `jwait` of 0.004–0.009 s per field on the card is
  the same picture. On the card, `flush ≈ field` with the card ≥ 99 % busy means the launches are hidden; host overhead
  per batch is then create + launch.
- **Partitions per launch** (b60 1e16, `NICE_EXP_SLOTS`; plan 9 per launch, 625 batches): 4 per launch 12.25 s (1,800
  batches), 2 → 13.52 s (3,600), 1 → 16.94 s (7,200). Fit over the 7 runs: **11.09 s + 0.78 ms × batches** [D]: 0.2 ms
  of it host time (above), the rest device time per batch (the FD kernel's per-batch seed, kernel tails) [E, not
  separated]. On the 3080 the plan's 625 batches cost ~0.5 s (4 % of b60's field).
- `NICE_EXP_VRAM` is a no-op on CUDA (it already has the denser plan): 11.61 s against 11.59–11.76.
- Round 2 (`b2.ge-`, binary N16b) repeated the b60 sweep: 4 / 2 / 1 per launch +6.1 / +16.4 / +45.2 %, fit **11.03 s +
  0.78 ms × batches**; at b62, 4 per launch (8,649 batches against 2,615) cost +8.3 %, fit 59.60 s + 0.84 ms × batches.
  `c_nohost` against its base runs: −0.1 % (b60, round 2, base spread 0.1 %): the accounting costs ≤ 0.1 %.

### B.4 Geometry, occupancy, tops and survivor-path switches on CUDA [M]

b60 1e16 (`ge-`, round 1 with `N16`, round 2 with `N16b`; base 11.68 s) and b62 1e17 (`sv-`, base 62.60 s):

| variant | b60 1e16 | b62 1e17 | note |
|---|---|---|---|
| TOP_CAP 128 (`tc128`) | +3.1 % (r1), +4.3 % (r2) | +3.5 % | L51: ×0.96 at 180 W [A]; register-bound, 5 cubes/SM either way |
| stage 512 / 256 / TOP_CAP 128 + stage 512 (`sc512` / `sc256` / `tcsc`) | +0.1 % / +0.1 % / +3.2 % | +0.6 % / — / +2.4 % | exact (dense compare) |
| wg 128 / wg 128 + EPT 4 / wg 128 + TOP_CAP 128 | +9.4 % / +8.5 % / +4.4 % | | fewer threads per cube, same shared memory |
| wg 64 / wg 64 + TOP_CAP 64 | +36 % / +30 % | | |
| top append: scans (`bal0`) / two-word ballot (`bal2`) / one-word (`bal1`, CUDA's default) | | +0.6 % / −1.0 % / −1.1 % | CUDA's planes are 32 lanes: bal1 = bal2 = default; scans cost ≤ 1.7 % |
| walk plane barrier (`wsync`) | | −0.6 % | already on under CUDA: a no-op here |
| denser plan (`vram`, `tcvram`) | −0.6 %, +3.4 % | +0.2 %, +3.3 % | CUDA already has it |

- **On NVIDIA nothing here is a lever:** the stage size is neutral (the kernel is register-bound at 5 cubes per SM, so
  freeing shared memory buys nothing), TOP_CAP 128 loses 3–4 %, smaller cubes lose 4–38 %. That is the expected
  contrast with RDNA4, where Task C finds the cube LDS-bound (§C): **the window's `sc512` / `sc256` / `tcsc` rows are
  the test of that** (prediction [E]: they win on the 9070 XT as TOP_CAP 128 did, and `tcsc` more than either).

### B.5 What the NVIDIA column predicts for the card, and how to read the window

- If the card's doubling shares match the 3080's (prefilter 16–21 %, AND 15 %, check 11 %, walk 9–13 %, copy 5 %, loads,
  waves and barriers ≈ 0), the card has NVIDIA's profile and the gap per pair is uniform; the clock-corrected N13
  numbers (§A: survivor path 21–35 %, AND 12–19 %, base 7–13 %) already point there.
- Shares are of the doubled part's marginal cost at full load; to compare with a removal share, note that on the 3080
  doubling read 0.8–0.9× of removal for the survivor path and the AND and 0.93× for the check (§B.2).
- A part whose doubling costs much more on the card than on the 3080 is a card-specific bottleneck: the decision
  table in WINDOW-PLAN.md lists what each means and its fix.

### B.6 Run log and what went wrong on the box

- Box 60315324 (the brief's) never accepted a key (`bad ownership or modes for /root/.ssh/authorized_keys`; its clone
  also failed); the director replaced it with 60317813 at 06:19. All work here is on 60317813.
- Builds on the box (Ryzen 5 5600X, 12 threads): N16 169 s fresh at `-j 8`; N16b 116 s incremental; M 186 s and D 184 s
  fresh at `-j 4` beside the timing chain; the spirv-dump binary 185 s (`-j 4`). Two builds and the Task C SPIR-V dumps
  (lavapipe, 2 threads) overlapped timed CUDA runs: round 1's `d_and` and `d_check` at b62 (06:55–06:59; `d_check` r1
  read +14.9 % against r2's +11.3 %, so the table uses r2 for it), the b64 round-1 `d_check` / `c2` (M build) and
  round-1 `d_pf`/`d_walk` at b64 (N16b/D builds, 07:04–07:10; their round-2 repeats agree within 1.5 points). Round 2
  ran with nothing else on the box.
- **A naming collision** in the first version of the chains: `chain_surv` re-used the must chain's name `c2_b62_r1` and
  overwrote it on the box; the original was copied to ivory before (`raw/box_keep/`), and `raw/sorted/` holds every
  run under its chain's prefix. The chains now prefix their names (`sv-`, `ge-`, `DM-`/`DD-`), and the analysis keeps
  each chain's base runs apart.
- **A variable clash in `lib.sh`** (a shell function shares its caller's variables) made `chain_D.sh` run its b60 rows
  with a binary named `b62`; caught on the box (`b2.D*`), fixed (underscored names), and the chain re-run (`b3.D*`).




## C. What RADV's ACO generates for the join (Task C, done in ~45 minutes)

**Method [M].** Mesa 25.2.7's RADV built on the box with ACO only (`-Dllvm=disabled -Dvulkan-drivers=amd`, no
gallium; `raw/scripts/taskC_build_mesa.sh`, 7 minutes). The wgpu harness itself cannot run on RADV's null winsys
(`RADV_FORCE_FAMILY=gfx1201`): wgpu's device creation fails there with `Device(Lost)`. So the SPIR-V that CubeCL
generates was dumped on lavapipe instead (a second binary built with `--features gpu,cubecl-spirv,cubecl/spirv-dump`,
`CUBECL_DEBUG_SPIRV`; `taskC/spv_dump.sh`; b60 kernels, the same code as b62's apart from base constants), and a
60-line Vulkan program (`taskC/pipec.c`; layout from `taskC/reflect.py`) created each compute pipeline on the null
GFX1201 device under `RADV_DEBUG=shaders,shaderstats`, with no required subgroup size (as wgpu creates them) and with
32 and 64 forced. `taskC/summarize.py` → `raw/taskC.txt`; dumps in `raw/box/spv_<mode>/*.aco*.txt`. The null device
reports `subgroupSize=64, minSubgroupSize=32, maxSubgroupSize=64`.

| join kernel variant | wave | LDS / cube | VGPRs | waves per SIMD (ACO) | instructions | barriers in code |
|---|---|---|---|---|---|---|
| **production (wg 256, TOP_CAP 256, stage 1024)** | **64** | **18,944 B** | 120 | **12** | 1,357 | 16 |
| same, wave32 forced | 32 | 18,944 B | 120 | 12 | 1,317 | 16 |
| TOP_CAP 128 (`tc128`) | 64 | 13,824 B | 84 | **18** | 1,379 | 16 |
| stage 512 (`sc512`) | 64 | 14,848 B | 96 | **16** | 1,358 | 16 |
| stage 256 (`sc256`) | 64 | 12,800 B | 84 | **18** | 1,350 | 16 |
| TOP_CAP 128 + stage 512 (`tcsc`) | 64 | 9,728 B | 60 | **24** | 1,353 | 16 |
| wg 128 (`wg128`) | 64 | 18,944 B | 252 | 6 | 1,393 | 16 |
| wg 64 (`wg64`) | 64 | 18,944 B | 256 | 4 | 1,297 | **0** |
| wg 64, TOP_CAP 64 (`wg64tc`) | 64 | 11,264 B | 252 | 6 | 1,267 | **0** |
| doubled barriers (`d_bar`) | 64 | 18,944 B | 120 | 12 | 1,355 | 22 |

- **The join runs as wave64** when wgpu does not ask for a subgroup size (the dump without one equals the forced-64
  one), so a 256-thread cube is four waves and its barriers are real. **At 64 threads ACO emits no barrier at all**
  (`wg64`: 0 `s_barrier_signal` against 16), which confirms the brief's H2 guess. But a smaller cube keeps the same
  LDS per cube on fewer waves: 4–6 waves per SIMD instead of 12, so the barrier-free variant loses occupancy ×2–3
  (on the 3080, `wg64` ran ×1.1 slower, §B).
- **The kernel is LDS-bound on GFX12** [M, ACO's estimate]: 18.5 KiB per cube allows 12 waves per SIMD; registers would
  allow more (ACO then hands out 120 VGPRs because they are free). TOP_CAP 128 (13.5 KiB) → 18 waves, a 512-entry
  survivor stage (14.5 KiB) → 16, both → 24. **This is the likely explanation of N13's unexplained TOP_CAP 128 win on
  this card (×1.04–1.05) and its loss on NVIDIA (×0.96)**: on the 3080 the kernel is register-bound at 5 cubes per SM
  whatever TOP_CAP is (L51 §3.2), on RDNA4 it is LDS-bound and TOP_CAP 128 buys 50 % more waves. The stage is 8 KiB
  of the 18.5 (two 1,024-word arrays), written out once half full; L51 counted no pair past a full stage at b60/b62
  with the per-batch check (§3.4) and found the flush level flat on NVIDIA, so a smaller stage costs flushes, not
  correctness (pairs past a full stage go to the list directly). The window measures `sc512`, `sc256` and `tcsc`
  (all exact, §B).
- **No poor code of the kinds suspected (H4):** no spills, no scratch, no bounds clamps on shared-memory indices (the
  kernels are launched unchecked), no emulated 64-bit VALU in the join (the u64 masks are 32-bit pairs; the only
  64-bit operations are wave64 exec-mask SALU), 30 `mul_hi` (divisions by constants in the work-item header and the
  partition arithmetic). **The transposed AND's digit loop folds its four `t_tr` addresses into the loads' immediate
  offsets** (`ds_read_b32 … offset0:9220 / 9476 / 9732 / 9988`): ~24 instructions per digit for 4 chunks (16 VALU, 4
  LDS, the rest exec/branch), against NVIDIA's 30 with 8 of address arithmetic (L51 §4). Each digit's four loads are
  waited for before the ORs (`s_wait_dscnt 3/2/1/0`), so the loop is latency-bound unless enough waves hide it, which
  ties it to the occupancy above.
- **The transposed copy** is 33 `ds_read2_b32` + 64 `v_bfe_u32` + 64 `v_lshl_or_b32` (2 VALU per bit), as tight as it gets.
- **The walk round, prefilter included, is ~113 instructions per entry slot** (49 VALU, 62 SALU, 8 LDS; two copies, one
  per entry slot) against ~66 on NVIDIA (L51: a 41-instruction round + ~25 for the lean prefilter): wave64's exec-mask
  bookkeeping is scalar and roughly doubles the instruction count; SALU and VALU issue in parallel on RDNA, so the
  time cost is less than the count. With 64 lanes per plane each round also waits for the slowest of 64 lanes, not 32.
  The stage append compiles to `ds_append` (one LDS op per wave, not per lane).
- **The FD top kernel** is wave64 with 84 VGPRs, 18 waves per SIMD, no LDS, 6,204 instructions. **Its plane sum and
  exclusive scan of 0/1 already compile to a ballot** (`v_mbcnt_lo/hi` + `s_bcnt1`, one each), so forcing
  `ballot_append` on (`bal1` / `bal2`) can at most remove the select that forms the 0/1: no gain expected on RADV; the
  window measures it anyway (§B, `chain_surv`). `bal1` is unsound on 64-lane planes in principle (the upper 32 lanes'
  bits are dropped); `bal2` reads both words. On CUDA both were exact (32-lane planes), see §B.
- Instruction counts next to NVIDIA's SASS (L51 §4, b62 join kernel): NVIDIA ~1,046–1,208 SASS instructions,
  46–48 registers, 5 cubes per SM (register-bound); RDNA4 1,357 instructions, LDS-bound at 12 waves per SIMD.


## D. A candidate branch for the denser plan on wgpu (Task D)

Branch **`exp/n14-wgpu-dense-plan`** on the fork, one commit **`464be8b`** on upstream main `5b1d627` (made by
`raw/scripts/patch_taskD.py`, then `cargo fmt`). No changelog line, no PR.

**What the runtime can know on wgpu [M, from the sources in the build's registry].** CubeCL 0.10's wgpu runtime
reports only `max_page_size` (= the adapter's `max_storage_buffer_binding_size`; 2,147,483,644 B on the 9070 XT
under RADV, 128 MiB on lavapipe) and an alignment; **nothing about the device's memory size**. The adapter's
`wgpu::AdapterInfo` is visible where the client is created (`CubeclContext::new_default`): its name, backend and
`device_type`. Vulkan maps `VkPhysicalDeviceType` onto it (discrete / integrated / virtual / CPU); wgpu's Metal
backend (wgpu-hal 29.0.4, `PrivateCapabilities::device_type`) reports **IntegratedGpu wherever the device has unified
memory**, so the Apple M4 is `IntegratedGpu`; lavapipe and llvmpipe are `Cpu`; the macOS runner's paravirtual GPU and
VMs are `VirtualGpu`.

**The rule** (`wgpu_dense_plan` in `cubecl_join.rs`, used by `limits_of` for a wgpu runtime): the denser plan
(`JoinLimits::with_vram_budget`, i.e. `SURV_PER_PREFIX_VRAM` survivors per prefix and partition where the FD top
kernel runs) when **the adapter is `DiscreteGpu`, its name is not a software rasterizer's
(`is_software_rasterizer`), and the budget is at most 2 GiB**. The adapter's name and type are noted once in
`new_default` / `new_default_async` (`note_wgpu_adapter`), so `limits_of` keeps its signature.

- Includes: the RX 9070 XT under RADV (2 GiB binding → 2 GiB budget, the configuration N13 measured ×1.04 with the
  denser plan [M, N13]), other discrete desktop cards whose drivers report a 2 GiB binding.
- Excludes: integrated GPUs and APUs (IntegratedGpu), every Apple Silicon Mac including the M4 (unified memory →
  IntegratedGpu), lavapipe/llvmpipe/SwiftShader (Cpu, and by name), VMs and paravirtual devices (VirtualGpu),
  unknown types (Other), and **a discrete card whose Vulkan driver reports 4 GiB bindings** (budget 4 GiB).
- **How sound it is:** not a measured share of memory, because wgpu has none to give. The denser plan does not raise
  the budget; it fills more of it (layouts grow toward the budget instead of 1.1–1.3 GiB on the sparse plan [M,
  N13]). With a 2 GiB budget that is at most a quarter of an 8 GB card, the same share CUDA's rule targets; on a
  discrete card with 4 GB or less and a 2 GiB binding it would be up to half its memory. **No sound rule exists
  that tells a 4 GB discrete card from a 16 GB one on wgpu today**; the 2 GiB cap and the discrete-only class are the
  narrowest rule available, and `JoinCeiling` still halves a layout a device does not run. If that residual risk is
  unacceptable, the alternative is an opt-in (an environment variable or a client flag) rather than a rule.
- **Tests [M, box]:** a unit test `the_denser_plan_on_wgpu_takes_discrete_adapters_only` (11 adapter cases: RADV
  9070 XT, RTX 3080, Arc A770 → yes; M4, 780M APU, llvmpipe as Cpu and as a misreported DiscreteGpu, Microsoft Basic
  Render Driver, Apple paravirtual, Other, a 4 GiB-binding discrete card → no) passes; `cargo fmt --all --check`
  clean; `cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings` clean (toolchain
  1.99.1, as `rust-toolchain.toml` pins); lavapipe device tests: the 7 wgpu join tests that need a device (`cubecl_join_matches_the_cpu_reference`,
  `join_matches_the_reference_on_a_whole_field`, `join_sample_runs_partitions_of_a_production_field`,
  `top_certificates_match_the_lockstep_scan_and_the_cpu`, `top_fd_matches_the_top_kernel`, `fx_digits_are_exact_everywhere`,
  `cubecl_niceonly_keeps_join_and_stride_apart_by_ticket`) **pass on lavapipe** for D (208 s) and for main (208 s);
  lavapipe is `Cpu`, so D keeps the sparse plan there, as intended.
- **On CUDA (the script's A/A, `b3.DM-`/`b3.DD-`):** both binaries take the denser plan on CUDA, so M and D are the same
  plan (2,615 / 625 batches) and gave identical counts; per round ×0.984–1.021 at b62 and ×0.991–1.000 at b60, i.e.
  the box's noise, not D.
- **In the window:** `chain_D.sh` runs main 5b1d627 (M) against this branch (D) at b62 1e17 and b60 1e16, three
  rounds; D should show the denser plan's batch counts (4,458 against 7,959 at b62 in N13) and ×1.04.


## Files

- `RESULTS.md` (this file), `WINDOW-PLAN.md` (the window, minute by minute, with the decision table), `BRIEF.md`.
- `raw/scripts/` — everything the window runs: `env.sh`, `modes.sh`, `lib.sh`, `wrun.sh`, `build.sh`,
  `setup_window.sh`, `go_window.sh`, `chain_must.sh`, `chain_surv.sh`, `chain_geo.sh`, `chain_geo62.sh`, `chain_D.sh`,
  `chain_x.sh`, `chain_smoke.sh`, `analyze.py`, `pull.sh`; the box's drivers `setup_box.sh`, `go_box.sh`, `go_box2.sh`,
  `go_box3.sh`, `go_lavapipe.sh`, `dryrun_window.sh`; the patches as scripts (`patch_n16_kernel.py`,
  `patch_n16_host.py`, `patch_n16_scap.py`, `patch_taskD.py`); Task A `taskA.py`; Task C `taskC_build_mesa.sh`,
  `taskC_dump.sh` (the wgpu-on-null-RADV attempt that fails at device creation), `taskC/` (`spv_dump.sh`, `aco.sh`,
  `pipec.c`, `reflect.py`, `summarize.py`).
- `raw/box/` — every log of the box (both chains' raw names), `raw/sorted/` — the timed CUDA runs under their chains'
  prefixes (what the tables read), `raw/box_keep/` — round 1 of the must chain as first copied, `raw/box_dryrun/` — the
  window's dry run (final branch head), `raw/lavapipe/` — the lavapipe end-to-end chains and dense compares, `raw/box/spv_<mode>/` — CubeCL's SPIR-V, its disassembly, the layout and ACO's dumps per mode.
- `raw/taskA.txt`, `raw/taskC.txt`; `raw/n16.bundle`, `raw/n16b.bundle`, `raw/D.bundle` (the
  branches as shipped to the box).
