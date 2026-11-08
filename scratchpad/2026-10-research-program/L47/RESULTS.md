# L47 RESULTS: the check kernel, design D — built, exact, ×1.088 / ×1.124 (2026-11-08)

Box: Vast 59671449 (`nice-research-l47-check`), RTX 3080 10 GB, driver 580.159.03, host cap 180 W, Xeon E5-2630 v4
(cgroup 9.6 CPUs), CUDA 12.8 toolkit. Base: fork `pr/top-fd-round2` d813aea. Branch `exp/check-d`.

## Summary

- **Step 0 (floor and wave tail):** a gather-only check (list entry + record words 0, 1, 6 per survivor) takes
  **3.36 s per b62 1e17 field** and 0.76 s per b60 1e16 field — 0.745 TB/s, 98 % of the 3080's DRAM bandwidth —
  under the 4.5 s build line, so built. The old kernel: 8.79 s / 2.13 s. Cube sweep: 2048 cubes −3.7 % / −3.8 %,
  one exact wave (408) +2.8 % / +1.6 %: the tail is at the **low end** (~4 %), not 6–16 %.
- **Built** (`exp/check-d`, then `pr/check-d`): design D as scoped — base-b² limbs from r0, record word 6 and the
  exact H; u32 schoolbook n² and n³; every quotient a proven multiply-high; a gate on n² + n³'s low 10 digits; a
  device work counter; count and probe modes; `join_check` with the host mirror and its tests. No record change, no
  `/` or `%`, one code path. The kernel runs **at the floor: 3.19 s (b62 1e17) and 0.74 s (b60 1e16)**, ×2.8 / ×2.9.
- **Codegen gate met:** 39–40 registers, 0 spills, no local/shared memory; **330 issued per warp-iteration on the
  b62 common path** (gate ≤ ~360), + 249 for the rest of n³. Screen: g ∈ {8, 10, 12} flat (±2 %, memory-bound);
  one entry per lane per take beats 4 and 8 (−7 % of the check; 39 vs 47 registers → 6 cubes/SM).
- **Exactness:** every test passed (§5): the new count/probe device test (1,413,630 real survivors + 96,042 synthetic
  n, 22 distinct shapes, digit counts, gate and masks = CPU; strengthened after the review, §11), `check_all` (b10's 69), whole b42 (417,789,835 / 16,879,877,
  join = stride = reference), the 1e14 COMPARE b57/60/62/64, dense fields, FD-vs-top with sentinels, certificates,
  host tests incl. the exhaustive quotient test (114 divisors × every x < 2^31), lavapipe naga + SPIR-V (§7).
- **A/B against d813aea** (§6, 3 interleaved rounds, medians, device s per field): **b62 1e17 ×1.088** (74.65 → 68.64;
  per round 1.077, 1.086, 1.107; cycles ×1.099), **b60 1e16 ×1.124** (15.20 → 13.52; 1.137, 1.105, 1.124; cycles
  ×1.140), b62 1e16 ×1.085, b64 1e16 ×1.070; 1e14 b57/60/62/64 ×1.078 / ×1.046 / ×1.015 / ×1.003; counts identical.
  **NiceMark ×1.056** (6 rounds, per round 1.050–1.066; scenarios ×1.039–1.077). **The bar is met** (≥ ×1.05 at both
  production fields, no NiceMark scenario below ×0.98, exactness clean): `pr/check-d` pushed, `PR-BODY.md` written,
  no PR opened.

## 0. Step 0: the floor and the wave tail (old kernel, profile on)

Binary `S0` (`53b52a6`: d813aea + the profile commit + `NICE_EXP_CHECK=gather` / `NICE_EXP_CHECK_CUBES`), profile on
(`NICE_EXP_GPU_PROFILE=1`: the device synchronised around each kernel group, so the check's seconds are its own),
b62 1e17 (1 field) and b60 1e16 (2 fields, per-field mean), 2 rounds with the order reversed in round 2. Check
seconds per field (raw/box/s0_*.log, `s0table.py`):

| field | old kernel, 1024 cubes (production) | 2048 cubes | 408 cubes (one wave) | gather only, 1024 | gather only, 408 |
|---|---|---|---|---|---|
| b62 1e17 | **8.786** (8.710, 8.862) | 8.463 (8.470, 8.455) | 9.030 (9.091, 8.969) | **3.359** (3.371, 3.346) | 3.578 (3.571, 3.584) |
| b60 1e16 | **2.127** (2.139, 2.115) | 2.047 (2.048, 2.046) | 2.160 (2.154, 2.166) | **0.761** (0.761, 0.761) | 0.790 (0.789, 0.790) |

- **The floor:** the gather-only kernel (the list entry and record words 0, 1, 6 per survivor, XOR-folded into a
  never-true compare) takes **3.36 s per b62 1e17 field** (0.76 s at b60 1e16): below the 4.5 s build line, so
  build. It moves 62.58e9 × (8 + 32) B = 2.50 TB in 3.36 s = **0.745 TB/s, 98 % of the 3080's 760 GB/s**: the
  gather is DRAM-bound at one record sector per survivor, so repeats of a top within a warp save nothing measurable.
  The floor for any check that gathers P per survivor is ~3.4 s here.
- **The wave tail is at the low end:** 2048 cubes instead of 1024 save 3.7 % (b62) / 3.8 % (b60) of the old kernel;
  one exact wave (408 cubes) is 2.8 % / 1.6 % *slower* than 1024. The loss is the per-thread share's granularity in
  the grid-stride loop, about 4 % of the check, not the 6–16 % the scoping bracketed.

## 1. What was built (`exp/check-d`)

- `common/src/join_check.rs` (new, host, no feature gate): `CheckShape` (b, L, s2, s3, f0, k2, g with its bounds
  checked: b 3–64, b^f0 and b^(k2−f0) below 2^31, every column below 2^31), `magic(d)` (m = ⌈2^(32+s)/d⌉,
  s = ⌊log2 d⌋, exact for every x < 2^31 by x·e < 2^(32+s)), `inverse_mod_2_64`, `wide_div` (16-bit-chunk long
  division for an H of 2^31 or more, test windows only), and `mirror(sh, P, w6, r0)`: the kernel's arithmetic step for
  step on the host with every sum and product overflow-checked. Tests (ship with the PR): `magic_quotients_are_exact_on_
  the_kernels_inputs` (closed-form bound for every b and b² at bases 3–64, plus the block-worst element of every block
  of d over every input range the kernel feeds: columns/chunks < 2^28 by b², limb splits < b² by b, the production
  record parts w6 < b^5 at bases 40–64), `magic_quotients_are_exact_everywhere` (opt-in, every x < 2^31 for every
  divisor), `inverses_and_wide_division_are_exact`, `mirror_matches_natural_at_every_base` (bases 10–64, every digit
  length with n < 2^96, four (f0, k2) shapes, adversarial + random n: limbs of n, n², n³, both masks, the distinct
  count against `get_num_unique_digits`, the gate against its definition), `gate_is_a_necessary_condition_of_the_
  full_check` (b10's 69; bases 10–24 where n² is often distinct), `shapes_of_the_join_fields_are_supported`.
- `check_kernel` (new body, `candidate_check` untouched): per survivor one list entry (t, r0) and record words 0, 1, 6;
  H = (P − w6)/b^(k2−f0) by a 64-bit subtract, a shift and a multiply by the odd part's inverse; n's base-b² limbs
  part by part (r0, w6, H; an odd boundary completes the pending limb); n² by schoolbook columns (doubled cross
  products + square + carry), each normalised by one magic quotient by b², every limb split into two digits by a
  magic quotient by b and OR-ed into a 64-bit mask; the gate's g/2 low limbs of n³ the same way; the rest of n³ only
  under `if pass` (n² and n³'s low g digits distinct by popcount); nice iff popcount = b. Comptime base, L, s2, s3,
  f0, k2, g, chunk, mode. Modes: hits, probe (n rebuilt from the limbs), count (four words per entry: distinct
  count, gate, mask lo/hi, no gate). No `/` or `%`, no shared memory, no u64 division, one code path for every runtime.
- Work distribution: each plane takes `PLANE_DIM × chunk` entries from a counter (`ran[4]`, a fifth word of the
  per-batch `ran` buffer, which `ensure_ran` ignores) with one atomic by lane 0 and a broadcast, asking for the next
  chunk before working on the current one; lanes take entries `cur + j·PLANE_DIM + lane`. 2048 cubes (cubes past
  the list exit at once). The PR keeps chunk = 1 (one entry per lane per take, §3) and drops the inner loop.
- The PR (`pr/check-d`, one commit on d813aea) is that kernel without the exp knobs and the profile, plus the
  CHANGELOG line and the CI lint's `--require CheckKernel@57` removed (the kernel has no constant division left for
  the lint to recognise, which that requirement demands).
- Device tests: `cubecl_{,cuda_}check_counts_match_the_cpu` — count mode on the real survivor lists of b10's window,
  every window, the production fields of `PLAN_FIELDS` at 1e14 (2 partitions) and the b57 frontier field (0, 1000,
  3248), and on a synthetic list of adversarial + random n per field shape (H narrow and wide); probe mode on the same
  lists (n rebuilt from the limbs = the list's n).
- exp knobs (not for merge): `NICE_EXP_CHECK_G`, `NICE_EXP_CHECK_K`, `NICE_EXP_CHECK_CUBES`, the profile commit.

## 2. First look (binary D: K = 4, g = 10; profile on, one round)

- 1e14 b62/b60/b64 (1 field each): counts exact (88,159,810 / 180,517,288 / 346,647,759 checked), check 0.038 /
  0.028 / 0.046 s per field (old kernel at b62: 0.045 s; the gather-only kernel 0.040 s).
- **b62 1e17: check 3.387 s per field** (old kernel 8.786 s mean of step 0's two rounds; gather floor 3.359 s): the
  new kernel runs at the DRAM floor. Profiled device time 72.75 s (old 77.53 s).
- b60 1e16: check 0.744 s per field (old 2.127; gather floor 0.761).
- So the arithmetic is no longer what the check costs: at ~333 issued per warp-iteration (§4: 322 on the common path,
  249 more in ~5 % of warps) and ~360 cycles of ALU pipe, 1.96e9 warp-iterations on 272 schedulers at ~1.47 GHz are
  1.6–1.8 s per b62 1e17 field, about half the gather [D]. The scoping's "D ≈ max(compute, memory)" holds
  with memory winning: measured 3.19–3.39 s (K = 1 / K = 4) against its 2.7–4.2 s, central 3.4 s.

## 3. Screen: the gate's digits g and the entries per lane K (profile on, binary D)

Check s per field (rounds), 2 rounds with the order reversed in round 2 (raw/box/scr_*.log); b62 1e16 and b60 1e16,
2 fields each; K = 4 unless named, g = 10 unless named. Registers and the b62 common path from the runtime's JIT of
each variant's own PTX (`ptxjit.py` + `sasscount.py`, raw/box/scr_jit.txt):

| variant | b62 1e16 | b60 1e16 | regs (b62) | b62 common path / rest of n³ |
|---|---|---|---|---|
| old kernel (S0, 1024 cubes) | 0.713, 0.712 | 2.150, 2.151 | 38 (L44's nvcc) | 1,046 per warp-iteration (scoping §2) |
| g = 8 | 0.288, 0.289 | 0.739, 0.742 | 40 | 304 / 267 |
| g = 10 | 0.282, 0.278 | 0.747, 0.750 | 47 | 322 / 249 |
| g = 12 | 0.279, 0.283 | 0.743, 0.749 | 47 | 341 / 230 |
| **K = 1** | **0.261, 0.263** | | **39** | 330 / 249 |
| K = 8 | 0.296, 0.297 | | 47 | 322 / 249 |

At b62 1e17 (one round each): **K = 1 3.185 s** (1470 MHz), K = 2 3.048 s (1512 MHz), K = 4 3.387 s (§2, 1475 MHz).
b60 1e16, K = 1: 0.740 s (K = 4: 0.747, 0.750).

- **g is flat** within ±2 % at both fields (the kernel sits at the gather's floor, §2): the gate's cost moves between
  the common path and the rest of n³ without changing the time. g = 10 ships (the scoping's choice, the middle).
- **K = 1 is the fastest of 1, 4 and 8**: −7 % against K = 4 at b62 1e16, −6 % at b62 1e17 (3.185 against 3.387 s;
  below the gather kernel's 3.359 s, whose grid-stride loop has its own tail), −1 % at b60 1e16. The JIT gives the
  K = 1 kernel 39 registers against 47 (the inner loop and its counter go away), which lifts the check to 6 cubes per
  SM from 5; K = 8 is slower again.
  K = 2 measured 4 % faster than K = 1 at b62 1e17 in its one round, 1.6 % in cycles (it ran 42 MHz higher): about
  0.1 s per field, 0.15 % of it, inside a single round's noise and not screened at 1e16. The PR's kernel takes one
  entry per lane per take, which drops the inner loop from the code.

## 4. Codegen (runtime path: NVRTC PTX → driver JIT, `ptxjit.py`; SASS regions by `sasscount.py`)

Gate: ≤ 48 registers, 0 spills, no local memory, ≤ ~360 instructions per warp-iteration on the b62 common path.

- Binary D (K = 4, g = 10), the sanity process at 1e14: b62 **47** registers, b60 40, b64 47; no spills, no local
  memory, no shared memory; SASS 744 / 696 / 720 instructions. Per entry (the inner loop body): b62 **633**, of
  which the rest of n³ under the gate 249 and the never-taken hit write-back 62, so **322 issued per warp-iteration on
  the b62 common path** (FMA 140, ALU 168, LD 5, branch 9; the scoping's model: 315), b60 304, b64 298 (shifts for
  the quotients, more ALU). The cube's rest is 249 / 221 / 228, paid by the warps with a lane past the gate (4.6 %
  of warps in the scoping's simulation of b62 1e17's survivors).
- K = 1 (the shipped form): b62 39 registers, common path 330 (the counter's atomic and broadcast per entry).
- **PR tree (`5be672c`, timed; one entry per lane, no inner loop)**, the 1e14 COMPARE process (b57, b60, b62, b64): **39, 39,
  39, 40 registers, no spills, no local memory**, SASS 664 / 688 / 736 / 712. b62: per entry 641 instructions, of
  which the rest of n³ 249 and the never-taken hit write-back 62: **common path 330 per warp-iteration** (FMA 140,
  ALU 170, LD/ATOM 6, branch/sync 14; the counter's atomic, broadcast and loop are ~10 of it); b57 302, b60 312,
  b64 306 (rest of n³ 209 / 221 / 228).
  **Gate met** (≤ 48 registers, 0 spills, no local memory, ≤ ~360 on the b62 common path). Every A/B process's
  check kernel (24 images): 39 or 40 registers, no spills (§7).

## 5. Exactness (PR head `5be672c`, binary P, CUDA unless marked)

- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64, one field each): join = stride, found 0 on both; 4,850,227,888 /
  268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759 (L38's and L46's
  counts). (The stride path runs `candidate_check`, untouched, so it stays an independent reference.)
- **New: `cubecl_cuda_check_counts_match_the_cpu`** (count mode: every list entry's distinct-digit count, gate and
  digit mask against the CPU; probe mode: every n rebuilt from its limbs against the list's n): **ok, 1,413,630
  list entries and 96,042 synthetic n, 3,599 past the gate**, 25 lists over 22 distinct shapes (b10's window, the 17
  windows, the six production fields of `PLAN_FIELDS` at 1e14, the b57 frontier field a second time by mistake;
  corrected in §11), H narrow and wide
  (b57/b58/b60/b64 windows), f0 0–3, k2 3–8, 76 s. (Binary D, K = 4, ran it first: 1,413,630 + 37,933, before the
  synthetic n were drawn from each shape's band.)
- `cubecl_cuda_join_matches_the_cpu_reference` (`check_all`): ok, 131 s — b10's [47, 100) → [69] through the new
  check (`run_field`), the 17 windows (prefilter survivors and hits = CPU), the b57 frontier partitions 0/1000/3248,
  4 windows in tight layouts (re-runs and splits), 5 windows whole = sliced, 5 windows after a refused layout, the
  production shape tight and refused.
- `cubecl_cuda_top_fd_matches_the_top_kernel` (#249's sentinel records): ok, 26 fields, 279 batches (23 with a clipped
  block), 375,887,645 tops, 400 s (the check is not in this test; inherited list).
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413
  above c0, 69,824 with the carry (as L46).
- Dense fields equal to the CPU join: b58 1e15, 32 partitions, 254,938,965 / 14,396,829; b62 1e16, 4 partitions,
  120,013,475 / 7,355,827 (L46's).
- **Whole b42 field** (`NICE_TEST_JOIN_FULL_FIELD=1`, b42 [9682651996416, +1e13), 1,764 partitions): join = stride =
  CPU reference, **417,789,835 join survivors, 16,879,877 checked, hits []** (reference 59 s, join 2.83 s, stride
  3.17 s).
- Host unit tests: `join_plan::` 8 passed; `cubecl_join::` 7 passed (17 device tests ignored); `join_check::` 5 passed
  (1.2 s, release): the magic bound for every divisor and the block-worst enumeration over the kernel's input
  ranges, inverses and wide division, the mirror against `Natural` at bases 10–64, the gate against the full check,
  the production shapes.
- `magic_quotients_are_exact_everywhere` (`NICE_TEST_CHECK_EXHAUSTIVE=1`): **114 divisors (b and b² at bases 3–64, not
  powers of two) exact on every x < 2^31**, 131 s on the box's 9.6 CPUs.
- Every timed run of the A/B (§6), both sides: the exact counts (below).
(lavapipe and lint: §7)

## 6. A/B: d813aea (B) against the PR (P, `5be672c`), same box, nothing else running

Method as L46: `cubecl_cuda_join_throughput_fixed_fields` after one untimed 1e14 warm-up field per process, at L30's
starts (b60 1366406074057412100454, b62 7997740455941656911841, b64 41242006262957161709568); b62 1e17 one field,
the 1e16 fields two (per-field means); 3 interleaved rounds (B P, P B, B P); then the 1e14 set (b57/60/62/64, 3
fields each, 3 rounds); NiceMark nice-only (`--benchmark-secs 150`) 6 rounds alternating. s/field = mean device wall
time per field; "cycles" = device seconds × the run's mean SM clock (nvidia-smi every 5 s, samples at ≥ 90 % use).
`ab.py` (raw/scripts) builds the table from raw/box/ab_*.log. The clock is sampled every 5 s, so a 1e16 run
(~12–30 s) has 2–6 samples at ≥ 90 % use, the first of which can catch the clock still high after the warm-up
field (1,725 MHz in one P run): its cycles column is noisy; b62 1e17 (~15 samples per run) is the one to read for clock, and even there single samples
catch inter-batch idle bursts (1,920 MHz) and dips (1,245 MHz), so the clock means carry ±2–3 %. The medians agree:
over the three b62 1e17 runs per side (44 / 40 samples at ≥ 90 % use) both sides sat at 179.6 W and 1440 MHz.

| field | B (d813aea) s/field (rounds; spread) | P (this PR) s/field (rounds; spread) | speed-up (per round) | cycles | MHz B / P |
|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **74.649** (73.28, 74.65, 75.97; 3.6 %) | **68.642** (68.05, 68.75, 68.64; 1.0 %) | **×1.088** (1.077, 1.086, 1.107) | ×1.099 | 1478 / 1461 |
| b62 1e16, 2 fields | **6.249** (6.26, 6.24, 6.25; 0.4 %) | **5.762** (5.79, 5.75, 5.76; 0.8 %) | **×1.085** (1.082, 1.086, 1.085) | ×1.080 | 1442 / 1477 |
| **b60 1e16**, 2 fields | **15.201** (15.36, 14.94, 15.20; 2.8 %) | **13.521** (13.51, 13.52, 13.53; 0.2 %) | **×1.124** (1.137, 1.105, 1.124) | ×1.140 | 1457 / 1449 |
| b64 1e16, 2 fields | **22.267** (22.31, 21.80, 22.27; 2.3 %) | **20.818** (20.82, 20.78, 20.83; 0.2 %) | **×1.070** (1.072, 1.049, 1.069) | ×1.070 | 1447 / 1444 |

Counts identical on both sides in every round: b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16
163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 /
47,900,853,327; found 0. The PR's side is also steadier (spread 0.2–1.0 % against 0.4–3.6 %).

| field | B s/field (rounds; spread) | P s/field (rounds; spread) | speed-up (per round) |
|---|---|---|---|
| b57 1e14, 3 fields | 0.579 (0.56, 0.58, 0.58; 3.1 %) | 0.537 (0.56, 0.53, 0.54; 5.0 %) | ×1.078 (1.005, 1.090, 1.078) |
| b60 1e14, 3 fields | 0.564 (0.56, 0.56, 0.57; 1.2 %) | 0.539 (0.54, 0.54, 0.54; 1.5 %) | ×1.046 (1.054, 1.046, 1.052) |
| b62 1e14, 3 fields | 0.488 (0.49, 0.50, 0.48; 3.7 %) | 0.481 (0.46, 0.48, 0.49; 6.2 %) | ×1.015 (1.063, 1.037, 0.984) |
| b64 1e14, 3 fields | 0.683 (0.70, 0.68, 0.67; 3.2 %) | 0.681 (0.68, 0.68, 0.69; 1.5 %) | ×1.003 (1.022, 1.010, 0.983) |

The 1e14 fields (0.5–0.7 s each, three per process) gain or are neutral within their spreads; counts identical
(b57 13,041,966,398 / 721,059,706; b60 8,995,820,166 / 602,561,220; b62 4,229,527,892 / 259,080,525; b64
13,236,144,651 / 805,128,380; found 0).

NiceMark nice-only (`client_B` from d813aea, `client_P` from the PR tree; `--benchmark-secs 150`, ~35 s per run),
6 rounds, order alternating:

| | B | P | P vs B |
|---|---|---|---|
| **score** | 7801.7, 7842.8, 7930.8, 7873.2, 7906.2, 7907.4 (median **7889.7**) | 8261.3, 8361.7, 8332.5, 8323.2, 8303.7, 8413.0 (median **8327.8**) | **×1.056** (per round 1.059, 1.066, 1.051, 1.057, 1.050, 1.064) |
| b58 MSD-weak (whole field), n/s | 3.715e14 | 4.000e14 | ×1.077 |
| b58 MSD-strong (whole field) | 1.440e15 | 1.497e15 | ×1.039 |
| b60 MSD-weak (sampled) | 7.969e14 | 8.444e14 | ×1.060 |
| b62 MSD-weak (sampled) | 9.658e14 | 1.024e15 | ×1.060 |

No scenario below ×0.98 (lowest ×1.039: MSD-strong, whose join leaves an eighth of MSD-weak's survivors, so the
check is a smaller share of it). The
whole-field scenarios' join survivors are identical in all 12 runs (b58 MSD-weak 33,590,315,220, MSD-strong
4,027,773,430); the sampled ones sample a different number of partitions per run, so only their rates compare.

Reading it [D from the table]: at b62 1e17 the PR saves 6.0 s per field (B 74.65 → P 68.64, medians), against the
profiled check difference of 5.6 s (8.79 → 3.19); at b60 1e16 1.68 s per field against 1.39 s profiled. The
two need not agree: the profile's syncs idle the GPU between kernel groups and change the clock under the cap on
both sides; the unprofiled A/B is the measurement. b64 gains least, probably because the old kernel's quotients by
64^5 and 64 were shifts there, which made its check the cheapest of the four (b64's check alone was not profiled).

## 7. lavapipe, WGSL lint, fmt, clippy

- fmt + clippy (`-p "*" --all-targets -D warnings`: default, `--features nice_client/gpu`, `--features
  nice_client/gpu,nice_client/cubecl-spirv`; rustc 1.99.1): the timed tree `5be672c` failed fmt (8 hunks) and clippy
  (12 findings in `join_check` and the new tests: `many_single_char_names`, `missing_panics_doc`, `manual_ilog2`,
  `manual_is_multiple_of`, `too_many_lines`, `type_complexity`); fixed in the head (host code and tests only; the
  kernel's text is unchanged but for rustfmt's line breaks and a comment). `acba803`: clippy ×3 clean; its one fmt hunk
  fixed in `46d48ae` (fmt clean). The final head's own fmt/clippy and re-test: below.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's requires less
  `CheckKernel@57`): **14 shaders, 0 flagged, rc 0**; `CheckKernel b57: 0 constant divisions` (in the dump, nothing
  for the lint to see — hence the workflow change); JoinKernel b57 29, TopKernel b57 268, TopFdKernel b57 194 as before.
- lavapipe (llvmpipe, LLVM 20.1.2, 8-lane subgroups), every wgpu test of `cubecl_join` on the P tree, naga (WGSL):
  **9 passed, 274 s** — incl. the new count/probe test (1,413,630 + 96,042, 3,599 past the gate, the same totals as
  CUDA, ~1–2 min), CPU-reference parity with b10's 69, the FD-vs-top-kernel test (21 fields, 142 batches, 1,018,088
  tops), the certificate test, the production-field sample, the ticket test.
- The same on CubeCL's direct SPIR-V compiler (`cubecl-spirv`): **9 passed, 446 s**, the count test's totals the same
  again.
- **The final head (`0f3332d` = `pr/check-d`)**, rebuilt and re-run on the box after everything above (`final.sh`,
  raw/box/fin_*, *_FIN.log): fmt clean; clippy ×3 (default, gpu, gpu+spirv; rustc 1.99.1) clean; `join_check::` 5
  passed + the exhaustive test (114 divisors, 130 s); `cubecl_cuda_check_counts_match_the_cpu` ok (same totals);
  `cubecl_cuda_join_matches_the_cpu_reference` ok; 1e14 COMPARE b62: join = stride, 1,439,469,648 / 88,159,810, found
  0. Its diff from the timed tree `5be672c`: rustfmt, clippy's host/test fixes (`ilog2` for `31 − leading_zeros`,
  `is_multiple_of`, allow attributes, `# Panics` sections, a `cfg_attr` for the device tests' reference without the
  `cubecl` feature), doc comments, one assert message, the CHANGELOG line's wording. No kernel code changed (rustfmt
  only re-wrapped five statements of it).
- On ivory (debug, no `cubecl` feature, `nice -n 19`, own target dir removed after): `join_check::` 5 passed, 3.6 s.
- **Registers in every A/B process** (`ptxjit.py` over the 24 P processes' PTX caches, raw/box/ab_P_jit.txt): check
  kernel 39 registers in 18 images, 40 in 6 (b64), **0 spills, no local memory in all 24**.

## 8. What next (not done)

- **The gather is the check now.** The new kernel sits at the gather-only kernel's time (3.19 against 3.36 s at b62
  1e17; 0.74 against 0.76 at b60 1e16), which itself runs at 98 % of the 3080's DRAM bandwidth with one record
  sector + one list entry per survivor. The next lever is bytes, not instructions: (a) carry P and w6 in the survivor
  list instead of the top index (P lo, P hi, w6, r0), so the check reads 16 coalesced bytes per survivor instead of
  8 + a 32-byte sector (−60 % of its bytes; the join's stage would hold 4 words per staged survivor, +8 KiB of shared
  memory per cube at `SURV_SH_CAP` = 1024, where the join sits at 5 cubes/SM by its 18.5 KB — L44 §3f's occupancy
  concern, to re-price);
  (b) order the list so a top's survivors share a sector read (they already are adjacent, and the floor shows no
  reuse at the DRAM level). Bound: the check is ~4 % of the field after this PR and its arithmetic alone needs
  ~1.6–1.8 s (§2), so (a) is worth at most ~2 % of a b62 1e17 field.
- K = 2 (one round, ×1.04 at b62 1e17 over K = 1) is within noise; not worth a loop back in the kernel.

## 9. Files and branches

- Fork `exp/check-d` (head `1187527c`): d813aea + the profile commit (`NICE_EXP_GPU_PROFILE`) + step 0's knobs
  (`53b52a6`, binary S0) + design D with `NICE_EXP_CHECK_G/K/CUBES` (`7973b691`, binary D) + test fixes. Not for merge.
- Fork **`pr/check-d`** (`0f3332d`): one commit on d813aea (the PR). Timed and tested tree `5be672c` (binary P,
  client_P); the head adds only rustfmt, clippy's host/test fixes and comments, re-tested on the box (§7). (Built
  as `exp/check-d-pr`, deleted from the fork once `pr/check-d` was pushed.)
- `PR-BODY.md` (no PR opened); `raw/scripts/` (setup, build, buildclient, run, test, chain_s0/screen/sanity/x/ab/lvp/
  lint, queueX2, orch, final, rebuildP, lintF/lintF2, p2, tables, prof.py, s0table.py, sasscount.py, ptxjit.py, ab.py,
  nm_table.py, shapes.py, pull.sh; the scoping's scripts as before); `raw/box/` (every log, smi trace and SASS dump of
  the session; `sass/` binary D, `sass_P/` the PR tree); `raw/ivory_join_check_tests.log`.

## 10. The box

Vast 59671449 can be destroyed: nothing is running on it (the last job, `final.sh`, ended 07:49 UTC) and every log,
smi trace, SASS dump and table is in `raw/box/` (pulled 07:50 UTC). Box time used: ~2 h of the 7 h (05:50–07:50).

## 11. Review fixes (REVIEW.md, after the session; box 59687089)

The independent review (`REVIEW.md`: merge with small fixes, no correctness defect) asked for M1–M3, D1–D3 and
optionally L1–L7. Applied to `pr/check-d` (amended, one commit on d813aea) and re-run on a second box, Vast
59687089 (RTX 3080, 280 W cap, driver 595.99.02, 5 CPUs). No timing was re-run: the kernel's arithmetic and loop
are unchanged.

- **Test, M1:** `check_counts` now calls `ensure_ran` on every batch before reading its list, reads the list with
  `read_list` (the unsorted half of `read_checked`, which `ensure!`s the cap instead of clamping; L7), and requires a
  non-empty real list on every `PLAN_FIELDS` field. The global floor stays.
- **Test, M2:** `synthetic` adds per shape the band's ends (lo, lo + 1, hi − 1, hi − 2), the last n whose square or
  cube stays below a power of b, both ends with their low i digits all 0 or all b − 1 (every i), and both ends' top
  digits over a low half of all b − 1, all 0, or alternating 0 and b − 1. The b64 production shape now gets edge n.
- **Test, M3:** the b57 frontier field ran twice (it is in `PLAN_FIELDS`); now once, and each distinct shape's
  synthetic list runs once. (The original run was 25 lists over 22 distinct shapes, not "26 shapes" as §5 said.)
- **Kernel, L1:** a fourth test-only mode, gated, writes the count words with the gate applied as the hits mode
  applies it (the rest of n³ only in passing lanes); the test compares it with the CPU (passing entries: the full
  digits; failing ones: the gate's digits only). No nice number is known above base 10, so the gated path meets a
  real hit only at b10 (69, in `check_all`); the gated mode covers its control flow on every gate-passing survivor.
- **Kernel, L2:** documented that the counter relies on full planes (256-thread cubes, plane widths a power of two
  up to 128, plane ops in plane-uniform control flow) rather than adding plane reductions to a measured kernel.
- **Test, L3:** gated mode runs on 3 cubes (real lists) and 1 cube (synthetic lists), so every plane loops; the
  `>= cap` assertion is replaced by an exact one: the counter ends at the list rounded up to whole takes plus one
  take per plane (`cubes · 256` entries), checked on every run.
- **L5/L6:** the kernel takes the `CheckShape` itself as its comptime argument and uses its methods (`nl`, `ql`,
  `cl`, `gl`, `part`, `h_wide`, `h_div`) instead of recomputing them; the host mirror (`Mirror`, `mirror`, `qdiv`,
  `wide_div`, `magic_bound`) is test-only.
- **Body, D1–D3 and notes:** both instruction counts are per warp-iteration (32 survivors); the A/B's identical counts
  are the join's, so the check's evidence is the device test and the hit comparisons; the b57 1e14 row's clock
  (P 1905 against B 1635 MHz); the shared-atomic question on A100/H100 (unmeasured); the full-plane note; the gated
  mode and the dispatch check in the test description; H "about 2^40".

Results on box 59687089, tree `ec7b773` (the fixes before rustfmt; logs in raw/box2/):
- `cubecl_cuda_check_counts_match_the_cpu`: **ok, 52 s: 24 fields (64 batches), 1,168,717 list entries and 84,652
  synthetic n over 22 distinct shapes, 3,047 past the gate**, in count, gated (3 or 1 cubes, exact counter end
  asserted) and probe modes; every batch's `ensure_ran` passed; every production field had survivors. Synthetic n per
  shape: 3,941–4,051 after dedupe: 4,000 random draws plus the adversarial and edge n that fall in the band, at the
  production shapes b42 32, b50 43, b57 41, b60 51, b62 44, b64 44 (before: 11, 13, 14, 15, 15 and 0;
  `raw/scripts/edge_count.py` ports the test's lists and reproduces the box's totals); b10 53. (Fewer real entries than §5's 1,413,630 because the b57
  frontier field no longer runs twice.)
- `cubecl_cuda_join_matches_the_cpu_reference` (`check_all`, b10's 69): ok, 127 s. 1e14 COMPARE b62: join = stride,
  1,439,469,648 / 88,159,810, found 0. `join_check::` 5 passed; the exhaustive test, 114 divisors, ok.
- lavapipe (llvmpipe, LLVM 20.1.2, 8-lane subgroups), the same test: **naga ok (203 s), direct SPIR-V ok (321 s)**,
  65 lists (the device's limits batch one field differently), the same totals as CUDA.
- clippy ×3 on `ec7b773` (default, gpu, gpu+spirv; rustc 1.99.1): clean. fmt: 4 hunks (line wraps), applied.
(the final head below)
