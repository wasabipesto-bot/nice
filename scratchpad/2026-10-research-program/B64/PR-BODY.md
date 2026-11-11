Stacked on #250: this branch is #250's commit plus one, so until #250 merges the diff here shows both.

## What

The FD top kernel (#240, #250) has run at every base the join takes except the power-of-two one: `top_fd_runs` excluded
b64 behind `TOP_FD_AT_POW2_BASES = false`, on the grounds that `top_kernel`'s divisions are shifts and masks there and
that FD had measured slower. With #250's FD kernel that is no longer true, so this PR removes the gate:

- `top_fd_runs(fs)` is now `top_fd_fits(fs)`: FD certifies the tops wherever its state fits, b64 included. The constant
  and the `is_power_of_two` exclusion are gone, and the comments that said FD does not run at power-of-two bases (the
  constant's, `top_fd_runs`', the `top_fd` field's, `SURV_PER_PREFIX_VRAM`'s and the planner test's) are updated.
- Everything keyed on `top_fd_runs` follows at b64: the FD launch with `top_kernel` beside it for the clipped blocks
  (`clip_vs`), and on CUDA #250's denser batch plan (`SURV_PER_PREFIX_VRAM`), which gives b64 batches 11–13 partitions
  per launch instead of 5–7.
- Tests:
  - the planner test `vram_budgets_get_larger_batches_in_the_same_slices` takes b64 1e16 and 1e17 into its loop
    instead of asserting that b64's plan is unchanged;
  - a new host test, `top_fd_runs_at_base_64`, pins `top_fd_runs` true for production-shaped b64 fields (1e16 and 1e17,
    the first and last slice of each);
  - the join parity test (`check_all`) now reports for every window whether its tops went through FD, and asserts it
    for the b64 window.

No kernel changes. Nothing changes at any other base.

## Why

b64 is the base after b62 and most of the search cost that is left. On a b64 field the top certificates were the
second-largest phase after the join: 16.7–17.8 % of the field, profiled on an RTX 3080 (b64 1e16 and 1e17 fields at
several positions of the base), at 0.230 ns per top test against 0.158 ns for FD at b62. With FD on, the same field's
top phase costs 0.104 ns per test and 8.4 % of the field.

## Soundness

FD's arithmetic is base-generic, and nothing in it assumes b is not a power of two:

- **The packed-digit adds.** Digits sit one to a byte, four to a u32, with a bias of 256 − b per byte.
  - Without a carry a byte is 256 − b + s with s ≤ b − 1, so it lies in [256 − b, 255] and keeps bit 7 when b ≤ 128.
  - With a carry it wraps to s − b < b ≤ 128, so it loses bit 7.
  - `top_fd_fits` requires b ≤ 128 for this and b ≤ 64 for the u64 digit masks. At b = 64 the bias is 192: a byte
    without a carry is in [192, 255], a byte with one is in [0, 63].
  - The early exits ("a word plus the bias and no carry comes back unchanged") hold for the same reason.
- **The divisions.** The seeds' `fd_digits_trim` and the certificate's digit scan divide by `chunk_div` = b^cd and by b
  at comptime. At b64 these are 2^30 and 2^6, so shifts and masks.
  - The split16 long division is exact for any constant divisor.
  - The limb trim relies on "x < b^m needs at most `pow_limbs16(b, m)` limbs". That holds for b^m = 2^(6m): `pow_limbs16`
    counts 2^(6m)'s own limbs, at least as many as any smaller value needs.
- **The digit count.** `ndig_fast`'s constants come from `ndig_magic(64, …)`; a test checks them for every base 10–64.
- **The state fits.** At b64, n has 13 digits, n² has 26 and n³ has 38, and `top_fd_fits` holds for production-shaped
  1e16 and 1e17 fields and their slices (the new host test).
- **The same code runs at b64 on the device in CI.** `top_fd_matches_the_top_kernel` already compared FD with
  `top_kernel` at b64: a b64 window and a b64 1e14 field (plus a b64 1e16 field in the CUDA variant). It forces the FD
  path itself, independent of `top_fd_runs`, and passes on this branch (CUDA and lavapipe).
- **Clipped blocks** go to `top_kernel` beside FD as at the other bases; 23 of the comparison's 279 batches had one.

## Measurements

**Card:** an RTX 3080 10 GB at 300 W (driver 610.57.04, CUDA 12.8).

**Method:**
- #250 (`ee30303`) and this PR, same box, two binaries.
- Rounds interleaved, the order alternating between rounds, nothing else on the GPU.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, given a list of b64
  production fields: 58557331862957161709568 at 1e17, and 51001531862957161709568 + 58557331862957161709568 at 1e16.
  These are 0.35 and 0.55 of the b64 range; both are heavier than the base's mean field.
- Each process's `join_kernel` was replayed through the driver's JIT: 46–48 registers, no spill, in every run.
- Seconds are each process's wall time for its fields.

| field | #250 (s) | this PR (s) | per round (#250 ÷ PR) | median |
|---|---|---|---|---|
| b64 1e17 (0.55 of the range), 3 rounds | 141.31, 142.03, 144.67 | 130.00, 130.27, 130.56 | ×1.087, ×1.090, ×1.108 | **×1.090** |
| b64 1e16 × 2 (0.35, 0.55), 3 rounds | 34.65, 34.74, 34.69 | 32.79, 32.78, 32.80 | ×1.057, ×1.060, ×1.058 | **×1.058** |
| b62 1e17 (7997740455941656911841), 2 rounds | 58.26, 58.13 | 58.98 (*), 58.16 | ×0.988 (*), ×0.999 | unchanged |

(*) That process's driver JIT compiled the known 40-register spill variant of `join_kernel` (40 registers + 24 B),
which costs about 3 % on its own. The spill-free re-run is ×0.999, as expected: nothing at b62 changes.

**Without #250 (main `c0c357a` with only the gate removed; one binary, the gate as a switch):** b64 1e17 ×1.061
(144.97 → 136.63 s, 1 round), b64 1e16 ×1.021, ×1.041 (2 rounds). Main has neither #250's faster FD step nor its denser CUDA
plan (its b64 batches keep 5–6 partitions per launch with FD on), so the gain is smaller there; this PR is stacked on
#250.

**On top of #251 as well** (#250 + #251, the same switch, the same card, an earlier session): b64 1e17 ×1.141 (0.55
field), then ×1.129 and ×1.125 (0.05 + 0.55 fields); b64 1e16 ×1.039, ×1.067, ×1.065. That is the same absolute saving
or a little more, on a field whose check costs less.

**Where the gain comes from** (the 1e17 field, profiled: #250's kernels with per-phase timers, the gate as a switch, one
process each): with FD on, the top phase falls from 24.10 s to 10.84 s
(0.230 → 0.104 ns per test), launches halve (5,846 → 3,061) and inputs/bucket fall by ~0.5 s; the join and the check do
not move (±2 %). The profiled field falls from 144.0 to 129.7 s (×1.110), and ~93 % of that saving is the top
phase itself.

**What other GPUs should expect:** the denser plan (more partitions per launch) is CUDA-only, and on CUDA it is part of
the top phase's gain too, since FD re-seeds each prefix once per launch. On wgpu (Vulkan, Metal, DX12) the plan keeps
5–7 partitions per launch, so one FD slot in 5–7 is a seed instead of one in 11–13. Using the ~2.4× seed cost measured
for #250, that puts FD at about 0.116 ns per test instead of 0.104, still about half of `top_kernel`'s: roughly
×1.07–1.09 at 1e17 where the top phase is a similar share (an estimate; not run on a wgpu GPU).

**NiceMark** is not affected by construction: its nice-only scenarios are b58, b60 and b62, where `top_fd_runs` returns
what it returned before.

## Exactness

- **CUDA (RTX 3080):** all pass.
  - `cubecl_cuda_join_matches_the_cpu_reference`: every window, b50 and b54 included; all 17 report FD tops, and the
    b64 window asserts it.
  - `cubecl_cuda_top_fd_matches_the_top_kernel`: 26 fields, 279 batches, 23 with a clipped block, 423,166,282 tops;
    b64 window, 1e14 and 1e16 fields included.
  - `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`.
  - The dense compare against the CPU join (`cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`, hits and both
    survivor counts) on a b64 1e16 field (48 partitions; 2,836,249,711 / 172,308,464) and on 32 partitions of slice 0
    of a b64 1e17 field (2,803,067,823 / 173,796,394).
  - Every timed run gave the same counts on both sides: b64 1e17 3,092,989,872,066 / 191,683,594,021; 1e16
    687,610,801,525 / 42,436,400,204.
- **Host:** the `join_plan`, `cubecl_join` and `overlap_join` unit tests, the two new or changed ones included.
- **lavapipe (Mesa 25.2):** every wgpu test of `cubecl_join` passes with naga and with CubeCL's SPIR-V compiler (8
  each); the b64 window reports FD tops on both.
- **WGSL lint:** CI's `wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with the workflow's `--require` list: clean.
  - The list names no FD kernel per base, and this PR adds none.
  - As an extra check, the WGSL of every lavapipe join test was linted the same way. It includes `TopFdKernel` at b64
    (282 and 244 constant divisions): 75 shaders, 0 flagged.
- `cargo fmt --all --check` and `just lint`'s two clippy runs (default; `nice_client/gpu,nice_client/cubecl-spirv`):
  clean.

## Not in this PR

- FD-specific tuning at b64 (the FD kernel's cube size, `TOP_FD_MIN_UNITS`): not measured.
- A wgpu or Metal timing of b64.
