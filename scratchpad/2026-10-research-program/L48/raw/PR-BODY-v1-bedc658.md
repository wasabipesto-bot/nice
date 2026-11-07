## What

Stacked on #246 (and #241).

The FD top kernel (#240) takes each top-layer prefix through a batch's consecutive partitions. A slot that steps from P − 1 to P updates the packed base-b digits of P² and P³ by additions, steps e^k − a^k in binary, and then certifies the block from those digits. Most of a b62 1e17 field's top certificates are such stepped slots; the rest are seeds, the first slot of each prefix in each batch, which divide P² and P³ into digits.

This PR makes a stepped slot cheaper and seeds rarer:

- **Carry c0 and the carry test's bound.** Each power's c0 = max(cap, ndig(e^k − a^k)) and dm = b^c0 − 1 − (e^k − a^k) are kept from slot to slot. A step subtracts the step of e^k − a^k from dm; only when that borrows (the difference reached b^c0, which happens rarely) is the difference recovered as b^c0 − 1 − dm and c0 and dm formed again. The carry test, (x mod b^c0) + (e^k − a^k) ≥ b^c0, becomes x mod b^c0 > dm: one subtraction whose borrow is the answer. A stepped slot no longer reads the power table (`ndig_fast`'s compare and the test's b^c0) and no longer runs `ndig_fast`.
- **No bookkeeping above the run.** The digit scan tracks x's run of (b − 1)s from c0 up digit by digit. Once the run has ended, every later digit lies above c0, so a word after that point only sets its digits' bits in both masks.
- **No block endpoints for a step.** Only P = plo and P = phi can be clipped, and a step uses neither a nor e, so a slot that steps and is neither skips forming them and the clip test.
- **One ballot for the append.** The plane's count of kept tops and each lane's rank are popcounts of one `plane_ballot` instead of a `plane_sum` and a `plane_exclusive_sum` (up to 128 lanes a plane).
- **Carries only when there are some.** The step's base-b additions and binary steps propagate a carry or borrow past the addend's words only when there is one, and the binary addends use comptime bounds on their length (2wδ < 2w², 6w²δ < 6w³, Δ3 < 3w²·2^(32·limbs + 2)).
- **`SURV_PER_PREFIX` 2 → 1.** A batch is planned for one prefilter survivor per top-layer prefix and partition instead of two (measured: 0.53 at b62 1e17). Where the survivor bound set the batch size, that allows up to twice as many partitions per launch, so half as many seeds per field and fewer launches. Slices keep their size: `max_slice_prefixes` now uses its own `SLICE_SURV_PER_PREFIX` = 2, because a wider slice's field certificate prunes less (with slices cut at 1 too, NiceMark's sampled b60 window went from 2 slices to 1 and lost 2.4 %).

## Why

After #246 the FD top kernel is about a quarter of a b62 1e17 field (25 s of 100 s on an RTX 3080 at 180 W) and a fifth of a b60 1e16 field. An ablation of its stepped slot (RTX 3080) put about 22 % of it on the two power-table reads and `ndig_fast`, 27 % on the scan's per-digit bookkeeping, 17 % on the append and 13 % on the step's additions. A seed costs about twice a stepped slot (2.4 times after this PR), and at 4–7 partitions per launch a seed is one slot in four to seven.

## Soundness

- **c0 and dm.** e^k − a^k only grows from one slot to the next. While it stays below b^c0, ndig(e^k − a^k) ≤ c0, and since ndig never decreases, max(cap, ndig) and its clamp to the power's digit count stay at c0. It reaches b^c0 exactly when dm − step < 0, the subtraction's borrow; then b^c0 − 1 − dm (mod 2^(32·nl)) is the difference itself, and c0 and dm are formed as at a seed. For c0 below the power's digit count, b^c0 ≤ b^(s − 1) ≤ x < 2^(32·nl), so dm fits its words; at c0 = s the carry test is skipped, as before, and c0 cannot grow, so nothing is re-formed. (x mod b^c0) + d ≥ b^c0 ⟺ x mod b^c0 > b^c0 − 1 − d = dm.
- **Above the run.** The run ends only at a digit at or above c0, so after it every digit is above c0: the per-digit step then sets the digit's bit in both masks, cannot end the run, and adds nothing to x mod b^c0. The short path does exactly that.
- **Clipping.** P·w ≥ s for P > plo and P·w + w − 1 ≤ e − 1 for P < phi, so only plo and phi can be clipped; a step reuses the previous slot's state and needs neither endpoint.
- **Ballot.** The ballot's popcount and the popcount of its bits below a lane are the sum and the exclusive prefix sum of the 0/1 flags.
- **Early-exit carries.** A packed word plus the bias with no carry-in comes back unchanged: no byte reaches 256, every byte keeps bit 7, so the bias is taken back, and the carry-out is 0. In binary, x + 0xFFFFFFFF + 1 = x with carry 1. Skipping those words is the same as running them. The words above the comptime bounds are zero.
- **The plan.** Only the batches' survivor bound changes; the budget and largest-binding bounds are the same, so every layout still fits the device the way the plan says. On a 10 GB card (2,560 MiB budget): b62 1e17 9 partitions per launch at most and 2,457 MiB (was 5, 1,670), b60 1e16 8 and 2,431 MiB (was 4, 1,566). The slices are unchanged. A batch whose survivors overflow its list is re-run in smaller batches, as before; no run below re-ran a batch (dense b58 1e15 at 16 partitions per launch and dense b62 1e16 at 9: 0 re-runs).

## Measurements

**Card:** RTX 3080 10 GB (driver 580.178.04) on a rented box whose host caps it at **170 W** (default 320 W). Every timed run sat at the cap (167–170 W).

**Method:**
- #246 (`f3fb390`) and this PR, same box, two binaries, rounds interleaved with the order alternating (#246, PR; PR, #246; #246, PR), nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device wall time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds; "per round" is #246's time over the PR's in the same round. MHz is the mean SM clock per side; "cycles" is the ratio of device seconds × clock.

| field | #246 s/field (rounds) | this PR s/field (rounds) | speed-up | per round | MHz #246 / PR | cycles | partitions per launch, batches |
|---|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **107.90** (107.53, 108.08, 107.90) | **99.76** (99.92, 99.76, 99.35) | **×1.082** | 1.076, 1.083, 1.086 | 1316 / 1268 | ×1.111 | 5 → 9, 6,439 → 4,009 |
| b62 1e16, 2 fields | **9.046** (9.09, 9.05, 9.02) | **8.276** (8.34, 8.28, 8.27) | **×1.093** | 1.090, 1.093, 1.090 | 1405 / 1299 | ×1.197 | 13 → 16, 532 → 334 |
| **b60 1e16**, 2 fields | **21.315** (21.42, 21.27, 21.32) | **19.923** (20.06, 19.79, 19.92) | **×1.070** | 1.068, 1.075, 1.070 | 1259 / 1262 | ×1.054 | 4 → 8, 1,350 → 675 |
| b64 1e16, 2 fields | 30.696 (30.88, 30.54, 30.70) | 30.789 (31.00, 30.64, 30.79) | ×0.997 | 0.996, 0.997, 0.997 | 1308 / 1333 | ×0.980 | 6 → 7, 683 → 586 |
| b60 1e14, 3 fields | 0.663 (0.66, 0.67, 0.66) | 0.645 (0.65, 0.65, 0.64) | ×1.028 | 1.025, 1.031, 1.025 | | | 16 (both) |
| b62 1e14, 3 fields | 0.544 (0.55, 0.53, 0.54) | 0.526 (0.53, 0.52, 0.53) | ×1.034 | 1.036, 1.015, 1.028 | | | 16 (both) |
| b64 1e14, 3 fields | 0.786 (0.77, 0.80, 0.79) | 0.775 (0.79, 0.78, 0.77) | ×1.014 | 0.973, 1.030, 1.016 | | | 16 (both) |

- At b62 1e17 that is 8.1 s saved per field, at b60 1e16 1.4 s.
- At b62 the PR's side ran 50–100 MHz slower at the same cap (the cheaper slot does more work per cycle and draws more power), so in cycles the gain is larger (×1.11 at b62 1e17). At b60 the clocks matched.
- b64 is neutral, within its runs' 1.1–1.2 % spread: the FD kernel is off at powers of two, and only the plan moved (6 → 7 partitions per launch). The 1e14 fields are neutral to slightly faster (single runs scatter ±3 %).

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 6 rounds, alternating):

| | #246 | this PR | speed-up (per round) |
|---|---|---|---|
| **score** | median 6223.4 | median 6403.5 | **×1.029** (1.028, 1.032, 1.024, 1.039, 1.024, 1.030) |
| b58 MSD-weak (whole field) | 2.898e14 n/s | 2.949e14 | ×1.018 (1.015–1.022) |
| b58 MSD-strong (whole field) | 1.246e15 | 1.291e15 | ×1.036 (1.003–1.066) |
| b60 MSD-weak (sampled) | 5.947e14 | 6.149e14 | ×1.034 (1.026–1.037) |
| b62 MSD-weak (sampled) | 7.449e14 | 7.697e14 | ×1.033 (1.031–1.038) |

NiceMark samples partitions so that every top certificate is a seed; it gets the ballot, the cheaper carry test and the larger batches, not the stepped-slot work.

**The top stage alone** (`cubecl_cuda_top_fd_timing`: the first 40 batches of the first slice of each side's production plan, and 40 batches of every other partition where every slot seeds; ns per top prefix and partition, medians of 6 rounds per side; the stepped slot is (k·c − g)/(k − 1) for k partitions per launch, normalised by `top_kernel`'s time in the same round):

| field | #246: k, FD per slot, all-seed, stepped | this PR: k, FD per slot, all-seed, stepped |
|---|---|---|
| b62 1e17 | 5, 0.2424, 0.3913, 0.2066 | 9, **0.1678** (−30.8 %), 0.3433, **0.1403** (−32.1 %) |
| b60 1e16 | 4, 0.2447, 0.3859, 0.2003 | 8, **0.1644** (−32.8 %), 0.3292, **0.1380** (−31.1 %) |

With the FD kernel at about 25 % (b62 1e17) and 21 % (b60 1e16) of a field, that predicts ×1.08 and ×1.07, as measured.

**Parts** (the same fields, one binary with each part behind a switch, 2 interleaved rounds; the kernel alone, 6 rounds): carrying c0 and dm with the short path above the run and the endpoint skip take 24 % off a stepped slot (b62 1e17 0.2045 → 0.1554 ns per prefix and partition, b60 1e16 0.2021 → 0.1537) and gave ×1.041 / ×1.031 on the fields; the ballot another 5 points of the slot (0.1454 / 0.1444; ×1.047 / ×1.043 cumulative); the early-exit carries 3–4 % of the slot; the plan change ~2 points of the field.

## Exactness

All on the RTX 3080 (CUDA) unless marked lavapipe (llvmpipe, LLVM 20.1.2, Mesa 25.2.8, 8-lane subgroups).

- `cubecl_cuda_join_matches_the_cpu_reference`: ok. It covers b10's 69; windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions, tight and refused; sliced windows; and the production shape.
- `cubecl_cuda_top_fd_matches_the_top_kernel` (both top kernels on the same batches; per slot the same count, bucket counts and sorted entries, in one slot group and in several): ok, 26 fields, 279 batches (23 with a clipped block), 343,985,470 tops (the larger batches hold more than #246's 237,948,545).
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413 powers above c0, 69,824 with the carry.
- Dense fields, asserted equal to the CPU join: b58 1e15, 32 partitions: 254,938,965 survivors / 14,396,829 checked (16 partitions per launch, 0 re-runs); b62 1e16, 4 partitions: 120,013,475 / 7,355,827 (9 per launch, 0 re-runs).
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): ok. 417,789,835 join survivors, 16,879,877 checked, no hits; join = stride = CPU reference.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64): join = stride, found 0, counts identical to #246's: 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759.
- Every timed field above has #246's survivors and full checks in every round (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327; the 1e14 fields), no batch re-run; NiceMark's whole-field b58 scenarios: identical join survivors (33,590,315,220 and 4,027,773,430).
- `join_plan` unit tests (production layouts and slice cuts) and the non-ignored `cubecl_join` tests: ok.
- lavapipe, every wgpu test in `cubecl_join` (join parity, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler.
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's 13 `--require`s): 16 shaders, 0 flagged.
- `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean.

## Registers

From the driver's JIT of NVRTC's PTX (the runtime's own path) and from `nvcc -cubin -arch=sm_86 -O3` on CubeCL's CUDA, 1e14 fields at b62 and b60 (both give the same numbers):

| kernel | #246 | this PR |
|---|---|---|
| `top_fd_kernel` b62 | 110 registers, 3,888 SASS instructions | 108, 4,472 |
| `top_fd_kernel` b60 | 108, 3,696 | 107, 4,280 |

- No spills; still 2 blocks of 256 per SM.
- The static SASS grows by the rarely taken branch that re-forms c0 and dm (two `pw_minus1`s and an `ndig_fast` per power) and the early-exit branches; a stepped slot runs neither in the common case.
- In the append: 7 `SHFL` → 2, 0 `VOTE` → 2.
- CubeCL's direct SPIR-V compiler: TopFdKernel has 280–298 basic blocks at b57–b64 (#246: 298–310), below TopKernel's 368–386.

## Not in this PR

- **x mod b^c0 from only the words near c0** (leaving out the words that end four or more digits below c0, with an exact fallback when the remaining test is within b^p): measured 2–4 % *slower* per stepped slot; the left-out words are the cheap ones, and the extra test costs as much. Not taken.
- **Slices cut at one survivor per prefix too** (the same constant in `max_slice_prefixes`): similar whole-field gains (×1.074 at b62 1e17, ×1.057 at b60 1e16), but NiceMark's sampled b60 window went from 2 slices to 1 and lost 2.4 % (×0.972–0.980 in six rounds), so slices keep their size.
- **The append's destination** (the record stores, `top_b`, the bucket atomics) is unchanged.


🤖 Generated with [Claude Code](https://claude.com/claude-code)
