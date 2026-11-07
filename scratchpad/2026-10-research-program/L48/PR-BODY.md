## What

Stacked on #249 (which is on #246 and #241).

The FD top kernel (#240) takes each top-layer prefix through a batch's consecutive partitions. A slot that steps from P − 1 to P updates the packed base-b digits of P² and P³ by additions, steps e^k − a^k in binary, and then certifies the block from those digits. Most of a b62 1e17 field's top certificates are such stepped slots. The rest are seeds: the first slot of each prefix in each batch, which divides P² and P³ into digits.

This PR makes a stepped slot cheaper and, on CUDA, seeds rarer:

- **Carry c0 and the carry test's bound.** For each power, c0 = max(cap, ndig(e^k − a^k)) (where its certificate starts) and dm = b^c0 − 1 − (e^k − a^k) are kept from slot to slot.
  - A step subtracts the step of e^k − a^k from dm. Only when that borrows (the difference reached b^c0, which is rare) is the difference recovered as b^c0 − 1 − dm and c0 and dm formed again.
  - The carry test, (x mod b^c0) + (e^k − a^k) ≥ b^c0, becomes x mod b^c0 > dm: the borrow of one subtraction.
  - A stepped slot no longer reads the power table (`ndig_fast`'s compare and the test's b^c0) and no longer runs `ndig_fast`.
- **No bookkeeping above the run.** The digit scan tracks x's run of (b − 1)s from c0 up, digit by digit. Once the run has ended, every later digit lies above c0, so a word after that point only sets its digits' bits in both masks.
- **No block endpoints for a step.** Only P = plo and P = phi can be clipped, and a step uses neither a nor e. A slot that steps and is neither skips forming them and the clip test.
- **Carries only when there are some.** The step's base-b additions and binary steps propagate a carry or borrow past the addend's words only when there is one. The binary addends use comptime bounds on their length: 2wδ < 2w², 6w²δ < 6w³, Δ3 < 3w²·2^(32·limbs + 2).
- **One ballot for the append, on planes of up to 32 lanes.** In #249's `top_slot`, the plane's count of kept tops and each lane's rank are popcounts of one `plane_ballot`, instead of a `plane_sum` and a `plane_exclusive_sum`.
  - This is gated on the device's largest plane size (`ballot_append`: at most 32 lanes). CubeCL's C++ backends return only a ballot's first 32 bits; HIP truncates a 64-lane ballot to them.
  - So devices with 64-lane planes (CDNA through `cubecl-hip`, Metal on AMD GPUs, and Vulkan devices that report 64-lane subgroups) keep the two scans.
  - #249's per-(slot, group) destination is unchanged.
- **More partitions per launch on CUDA.** Where the join's budget is a quarter of the device's memory (CUDA), a batch of a field the FD kernel certifies is planned for one prefilter survivor per top-layer prefix and partition instead of two (`SURV_PER_PREFIX_VRAM`; measured 0.53 at b62 1e17).
  - Where that bound set the batch size, batches get up to twice the partitions, so about half the seeds and launches.
  - Unchanged: slices (`max_slice_prefixes` keeps `SURV_PER_PREFIX` = 2), every non-CUDA runtime's plan, and power-of-two bases, where the FD kernel does not run.

## Why

After #246 the FD top kernel was about a quarter of a b62 1e17 field (25 s of 100 s on an RTX 3080 at 180 W) and a fifth of a b60 1e16 field. #249 took the scan and fill passes out, so its share of what is left is larger.

An ablation of its stepped slot (RTX 3080) put the main costs at:

| part of a stepped slot | share |
|---|---|
| the two power-table reads and `ndig_fast` | about 22 % |
| the scan's per-digit bookkeeping | 27 % |
| the append | 17 % |
| the step's additions | 13 % |

A seed costs about twice a stepped slot (2.4 times after this PR). At 4–7 partitions per launch, one slot in four to seven is a seed.

## Soundness

- **c0 and dm.**
  - e^k − a^k only grows from one slot to the next. While it stays below b^c0, ndig(e^k − a^k) ≤ c0. Since ndig never decreases, max(cap, ndig) and its clamp to the power's digit count stay at c0.
  - The difference reaches b^c0 exactly when dm − step < 0, the subtraction's borrow. Then b^c0 − 1 − dm (mod 2^(32·nl)) is the difference itself, and c0 and dm are formed as at a seed.
  - For c0 below the power's digit count s, b^c0 ≤ b^(s − 1) ≤ x < 2^(32·nl), so dm fits its words. At c0 = s the carry test is skipped, as before, and c0 cannot grow, so nothing is re-formed.
  - (x mod b^c0) + d ≥ b^c0 ⟺ x mod b^c0 > b^c0 − 1 − d = dm.
- **Where c0 changes.** No production-size field, and none of the fields timed below, crosses a c0 change within a slice: c0 is constant from plo to phi there. The re-forming branch is reached by the device test's b20 windows (at P = 201 for the square, P = 231 for the cube). A new host test, `top_fd_test_windows_step_across_a_c0_change`, checks that those windows still cross a change for each power, so they are not trimmed away later.
- **Above the run.** The run ends only at a digit at or above c0, so every later digit is above c0. The per-digit step then sets the digit's bit in both masks, cannot end the run, and adds nothing to x mod b^c0. The short path does exactly that.
- **Clipping.** P·w ≥ s for P > plo, and P·w + w − 1 ≤ e − 1 for P < phi, so only plo and phi can be clipped. A step reuses the previous slot's state and needs neither endpoint.
- **Ballot.** The popcount of the ballot's first word, and the popcount of its bits below a lane, are the sum and the exclusive prefix sum of the 0/1 flags when the plane has at most 32 lanes. `ballot_append` enforces that, and a host test documents the gate.
- **Early-exit carries.**
  - A packed word plus the bias, with no carry in, comes back unchanged: no byte reaches 256 and every byte keeps bit 7, so the bias is taken back and the carry out is 0.
  - In binary, x + 0xFFFFFFFF + 1 = x with carry 1.
  - Skipping those words is the same as running them, and the words above the comptime bounds are zero.
- **The plan.** Only the batches' survivor bound changes. The budget and largest-binding bounds are the same, so every layout still fits the budget the way the plan says. A batch whose survivors overflow its list is re-run in smaller batches, as before; no run below re-ran a batch.

## Memory

On CUDA the large fields now plan up to their budget, where the survivor bound used to keep them well below it. The largest layout over each field's slices, on this RTX 3080 (budget 2,469 MiB, a quarter of the card):

| field | partitions per launch | layout MiB | batches per field |
|---|---|---|---|
| b62 1e17 | 5 → 11 | 1,463 → 2,393 | 6,439 → 3,288 |
| b60 1e16 | 4 → 9 | 1,367 → 2,199 | 1,350 → 625 |
| b62 1e16 | 13 → 16 (cap) | 1,825 → 2,393 | 532 → 296 |
| b64 1e16 | 6 (unchanged: no FD kernel) | 1,519 | 683 |

The join's layout grows by 31–64 % at 1e16 and up, still within a quarter of the card. Slices are the same on both sides (b62 1e17: 11; b60 and b62 1e16: 2 per field).

Elsewhere the plan is unchanged. On wgpu the budget comes from the adapter's binding limit, or 4 GiB with 64-bit indexing, not from the device's memory. The denser plan would raise a 4–6 GB card or an 8 GB Mac from ~2.6 to ~3.9 GiB at b60 1e16, and that was not measured. So it is scoped to CUDA (`JoinLimits::vram_budget`, set in `limits_of` for the CUDA runtime).

**Survivor-list headroom halves.** A batch planned at one survivor per prefix and partition is half full at that rate and about 80 % full at the densest rate measured (1.6, dense b57 fields). It overflows above about 2 survivors per prefix and partition: 2.0–2.1 at b62 1e17 and b60 1e16 on this card, where it was 4.5–4.7. Where the 16-partition cap binds first (fields up to about 1e15), the headroom is larger. The overflow re-run path is unchanged. The constant's doc comment says so.

## Measurements

**Card:** RTX 3080 10 GB (driver 580.159.03) on a rented box whose host caps it at **180 W** (default 340 W). The timed runs sat at the cap (median 180 W, 95 % of samples above 171 W).

**Method:**
- #249 (`87958fd`) and this PR, same box, two binaries. Rounds were interleaved with the order alternating (#249, PR; PR, #249; #249, PR), with nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds. "Per round" is #249's time over the PR's in the same round.
- The timed build applied the CUDA plan at b64 too. This commit keeps b64's plan (no FD kernel there); its b64 check is below.

| field | #249 s/field (rounds) | this PR s/field (rounds) | speed-up | per round |
|---|---|---|---|---|
| **b62 1e17**, 1 field | **82.80** (82.03, 83.25, 82.80) | **73.44** (73.03, 75.14, 73.44) | **×1.127** | 1.123, 1.108, 1.127 |
| b62 1e16, 2 fields | **6.989** (6.91, 7.05, 6.99) | **6.191** (6.30, 6.19, 6.17) | **×1.129** | 1.096, 1.139, 1.133 |
| **b60 1e16**, 2 fields | **16.431** (16.69, 16.43, 16.43) | **14.770** (14.70, 14.83, 14.77) | **×1.112** | 1.136, 1.108, 1.112 |
| b64 1e16, 2 fields (timed build: 12 partitions per launch) | 21.983 (21.60, 22.04, 21.98) | 21.868 (21.93, 21.86, 21.87) | ×1.005 | 0.985, 1.008, 1.005 |
| b60 1e14, 3 fields | 0.557 (0.56, 0.56, 0.55) | 0.547 (0.55, 0.55, 0.55) | ×1.018 | 1.018, 1.018, 1.007 |
| b62 1e14, 3 fields | 0.486 (0.50, 0.46, 0.49) | 0.459 (0.45, 0.50, 0.46) | ×1.059 | 1.097, 0.918, 1.059 |
| b64 1e14, 3 fields | 0.673 (0.69, 0.66, 0.67) | 0.688 (0.69, 0.65, 0.69) | ×0.978 | 1.007, 1.026, 0.973 |

- At b62 1e17 that is 9.4 s saved per field, at b60 1e16 1.7 s.
- **Clock.** At b62 1e17 the PR's side ran 12 MHz slower at the same cap (1,474 against 1,486 MHz), so the cycle ratio is ×1.140. The 1e16 runs are too short (3–7 clock samples a run) for a cycle ratio.
- **The 1e14 fields** run 16 partitions per launch on both sides (the cap binds first). At b64 they run the same kernels and plan on both sides, so b64 1e14's ×0.978 shows the runs' scatter (3–7 % per side).
- **The final b64 check.** At b64 1e16 this commit runs #249's kernels and plan (6 partitions per launch, 683 batches). Interleaved with #249 for 3 rounds it measured ×0.991 (0.991, 0.983, 0.998) in time and about ×0.998 in cycles (its side ran 8–11 MHz lower each round): the runs' scatter for the same work. One more round of this commit at b62 1e17 and b60 1e16 gave ×1.139 and ×1.117, with the same plans as above.

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 6 rounds, alternating):

| | #249 | this PR | speed-up (per round) |
|---|---|---|---|
| **score** | median 7850.3 | median 8104.9 | **×1.032** (1.039, 1.039, 1.035, 1.022, 1.043, 1.032) |
| b58 MSD-weak (whole field) | 3.747e14 n/s | 3.831e14 | ×1.022 (1.006–1.033) |
| b58 MSD-strong (whole field) | 1.463e15 | 1.475e15 | ×1.009 (0.972–1.020) |
| b60 MSD-weak (sampled) | 7.755e14 | 8.157e14 | ×1.052 (1.030–1.080) |
| b62 MSD-weak (sampled) | 9.454e14 | 9.977e14 | ×1.055 (1.035–1.089) |

- NiceMark samples partitions so that every top certificate is a seed. It gets the ballot, the cheaper carry test and the larger batches (b60 window: 5 → 10 partitions per launch, still 2 slices; b62: 6 → 12, 2 slices), not the stepped-slot work.
- The b58 MSD-strong scenario is about one second long and scatters by ±3 % per round.

**The top stage alone** (`cubecl_cuda_top_fd_timing`, ns per top prefix and partition, medians of 6 rounds per side):
- The first 40 batches of the first slice of each side's production plan, and 40 batches of every other partition, where every slot seeds.
- The stepped slot is (k·c − g)/(k − 1) for k partitions per launch, normalised by `top_kernel`'s time in the same round.

| field | #249: k, FD per slot, all-seed, stepped | this PR: k, FD per slot, all-seed, stepped |
|---|---|---|
| b62 1e17 | 5, 0.2070, 0.3234, 0.1781 | 11, **0.1371** (−33.8 %), 0.2963, **0.1239** (−30.4 %) |
| b60 1e16 | 4, 0.2061, 0.3037, 0.1735 | 9, **0.1358** (−34.1 %), 0.2806, **0.1186** (−31.6 %) |

**On #246, before #249** (RTX 3080 at 170 W, the same changes except the CUDA scoping and the 32-lane gate): b62 1e17 ×1.082, b60 1e16 ×1.070, NiceMark ×1.029. The FD kernel's share of a field is larger after #249, so the same cut is worth more.

**Parts** (on #246, one binary with each part behind a switch, 2 interleaved rounds; the kernel alone, 6 rounds):
- Carrying c0 and dm, with the short path above the run and the endpoint skip, take 24 % off a stepped slot (b62 1e17 0.2045 → 0.1554 ns per prefix and partition) and gave ×1.041 / ×1.031 on the fields.
- The ballot takes another 5 points of the slot.
- The early-exit carries take 2.6–3.7 % of the slot.
- The plan change gives about 2 points of the field.

## Exactness

All on the RTX 3080 (CUDA) unless marked lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups).

- **The changed certificate code is pinned by `cubecl_cuda_top_fd_matches_the_top_kernel`**, #249's version: both top kernels on the same batches, per slot and group the same counts and the same sorted entries in the same segments, in one slot group and in several. It passes with 26 fields, 279 batches (23 with a clipped block) and 375,887,645 tops. It also passes with the ballot gate forced off (the two-scan append that 64-lane planes take), and on the timed build (423,133,750 tops).
- The CPU reference, the dense fields, the whole b42 field and the 1e14 compare cover the whole join:
  - `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69; windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions, tight and refused; sliced windows; and the production shape.
  - Dense fields, asserted equal to the CPU join: b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked (16 per launch, 0 re-runs); b62 1e16, 4 partitions: 120,013,475 / 7,355,827 (11 per launch, 0 re-runs).
  - Whole b42 field: 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
  - `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0, counts identical to #249's.
- Every timed field above has #249's survivors and full checks in every round:
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - No batch was re-run. NiceMark's whole-field b58 scenarios gave identical join survivors.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok. It tests the division-path certificate (`top_cert`), which this PR does not change.
- Host tests (`join_plan::`, `cubecl_join::`): ok, including the new `vram_budgets_get_larger_batches_in_the_same_slices`, `top_fd_test_windows_step_across_a_c0_change` and `the_ballot_append_is_for_planes_of_at_most_32_lanes`.
- lavapipe (8-lane subgroups, so the ballot path): every wgpu test in `cubecl_join` passes with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler. That covers join parity, the FD-vs-top-kernel test (21 fields / 142 batches / 1,018,088 tops), the certificate test, the production-field sample and the ticket test.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 14 shaders, 0 flagged.
- CubeCL's direct SPIR-V compiler gives TopFdKernel 278–296 basic blocks at b57–b64, below TopKernel's 363–381.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.

## Registers

From the driver's JIT of NVRTC's PTX (the runtime's own path) and from `nvcc -cubin -arch=sm_86 -O3` on CubeCL's CUDA, 1e14 fields at b62 and b60 (both give the same numbers):

| kernel | #249 | this PR |
|---|---|---|
| `top_fd_kernel` b62 | 112 registers, 3,760 SASS instructions | 108, 4,360 |
| `top_fd_kernel` b60 | 108, 3,576 | 107, 4,176 |

- No spills; still 2 blocks of 256 per SM.
- The static SASS grows by the rarely taken branch that re-forms c0 and dm (two `pw_minus1`s and an `ndig_fast` per power) and by the early-exit branches. A stepped slot runs neither in the common case.

## Not in this PR

- **x mod b^c0 from only the words near c0.** This left out the words that end four or more digits below c0, with an exact fallback when the remaining test falls within b^p. It measured 2–4 % *slower* per stepped slot: the left-out words are the cheap ones, and the extra test costs as much. Not taken.
- **Slices cut at one survivor per prefix too.** That gave similar whole-field gains on #246, but NiceMark's sampled b60 window went from 2 slices to 1 and lost 2.4 % (×0.972–0.980 in six rounds). So slices keep their size.
- **The denser plan on wgpu, and at power-of-two bases** (see Memory).


🤖 Generated with [Claude Code](https://claude.com/claude-code)
