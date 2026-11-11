# B64 follow-up: PR-ready branch for the FD top kernel at power-of-two bases (2026-11-11)

Same box as RESULTS.md (Vast 60171046, RTX 3080 at 300 W, Ryzen 9 3900X). Raw logs: `raw/pr/tests/` (test runs,
streams, lints) and `raw/pr/ab/` (A/B harness runs: `.log`, `.smi`, `_jit.txt`; build logs); scripts `raw/pr/scripts/`
(`pr_build.sh`, `pr_tests.sh`, `pr_ab.sh`, `after_build.sh`, `after_prt.sh`; they use `run.sh`, `jit.sh`, `exact.sh`,
`build.sh`, `patch_harness.py` and `patchF.py` from `raw/scripts/`).

## Branch

- **Final head: fork `pr/top-fd-pow2-final` = `5e10c9c`**, one commit on `ee303030` (#250's commit on c0c357a).
  3 files, +57 / −32 (CHANGELOG +1; `cubecl_join.rs` 31 lines; `join_plan.rs` 57 lines, of which ~20 are a rewrapped
  doc paragraph).
- **Fork `pr/top-fd-pow2` = `f96a068`**: my first push, the same change before `cargo fmt` and two long doc lines
  rewrapped. I could not update it: the force-push was refused by this session's permission classifier ("Git
  Destructive"). `pr/top-fd-pow2-v2` (`9062cbf`) and `-v3` (`37632bc`) are intermediate pushes of the same commit.
  `git diff f96a068 5e10c9c` is rustfmt line breaks in two test assertions and doc-comment rewrapping only; no code
  change. **The coordinator needs to point `pr/top-fd-pow2` at `5e10c9c` (force) or use `pr/top-fd-pow2-final`, and
  may delete `-v2`/`-v3`.**
- The change: `TOP_FD_AT_POW2_BASES` and the `is_power_of_two` exclusion removed (`top_fd_runs` = `top_fd_fits`); docs
  updated (the constant, `top_fd_runs`, the `top_fd` field, `SURV_PER_PREFIX_VRAM`, the planner test). Tests: b64
  1e16/1e17 in `vram_budgets_get_larger_batches_in_the_same_slices` (was: b64 plan unchanged); new host test
  `top_fd_runs_at_base_64`; `check_window` returns whether FD ran and `check_all` asserts it for the b64 window and
  prints it for all. CHANGELOG line with #254.
- Checked what was conditional on the gate: `batch_surv_per_prefix` (CUDA's denser plan) follows `top_fd_runs`, so b64
  now gets it on CUDA (7 → 13 partitions per launch at 1e16, 5–6 → 11–13 at 1e17; main without #250 keeps 5–6 with FD on); `clip_vs` handling is FD's usual
  path (23 of the FD-vs-top test's 279 batches had a clipped block); the only test that assumed FD off at b64 was the
  planner test (changed). `top_fd_matches_the_top_kernel` already included b64 (window, 1e14, and 1e16 in the CUDA
  variant) and forces FD itself.

## Soundness review (nothing found that assumes b is not a power of two)

Packed-digit bias 256 − b (b ≤ 128 keeps bit 7 semantics; b64: no-carry bytes in [192, 255], carry bytes in [0, 63]);
early exits hold for the same reason; `fd_digits_trim` and the scan divide by comptime b^cd = 2^30 and b = 2^6 (shifts;
split16 exact for any constant); the limb trim via `pow_limbs16` is conservative at exact powers of two; `ndig_magic`
constants tested 10–64; `top_fd_fits` at b64: s2 = 26, s3 = 38, holds for production 1e16/1e17 and their slices (new
test). Details in PR-BODY.md §Soundness.

## Tests run (binaries built from `f96a068`; the final head differs only in formatting/comments)

| test | result | log |
|---|---|---|
| host `join_plan::` (incl. `top_fd_runs_at_base_64`, the changed VRAM test) | ok, 9 passed | `tests/host_join_plan.log` |
| host `cubecl_join::` (incl. #249's `sorted_layer_and_segments_match_the_cpu_buckets`) | ok, 7 passed | `tests/host_cubecl_join.log` |
| host `overlap_join::` | ok, 16 passed | `tests/host_overlap_join.log` |
| CUDA `cubecl_cuda_join_matches_the_cpu_reference` (windows incl. b50, b54, b64: all 17 "FD tops: true") | ok, 65 s | `tests/cuda_*cpu_reference.log` |
| CUDA `cubecl_cuda_top_fd_matches_the_top_kernel` (26 fields, 279 batches, 23 clipped, 423,166,282 tops; b64 window, 1e14, 1e16) | ok, 281 s | `tests/cuda_*top_fd*.log` |
| CUDA `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu` | ok | |
| CUDA `cubecl_cuda_join_matches_the_reference_on_a_whole_field` | **skipped by itself** (opt-in `NICE_TEST_JOIN_FULL_FIELD`; it is a b42 field, untouched by this change); not run | |
| dense compare vs CPU join, b64 1e16 at 39667831862957161709568, 48 partitions | ok, 2,836,249,711 / 172,308,464 | `tests/pr_x_e16.log` |
| dense compare vs CPU join, b64 1e17 at 58557331862957161709568, 32 partitions of slice 0 | ok, 2,803,067,823 / 173,796,394 | `tests/pr_x_e17.log` |
| lavapipe (Mesa 25.2.8), naga: every wgpu `cubecl_join` test | ok, 8 passed (b64 window FD tops: true) | `tests/lvp_naga.log` |
| lavapipe, CubeCL SPIR-V compiler: the same | ok, 8 passed (b64 window FD tops: true) | `tests/lvp_spv.log` |
| CI WGSL lint: `wgsl_dump_for_lint` + `wgsl-lint.py` with the workflow's 13 `--require` | rc 0, 14 shaders, 0 flagged | `tests/wgsl_lint_ci.log`, `wgsl_ci.log.gz` |
| extra: the same lint over the WGSL of all lavapipe join tests (incl. `TopFdKernel` b64: 282 / 244 constant divisions) | rc 0, 75 shaders, 0 flagged | `tests/wgsl_lint_join.log` |
| `cargo fmt --all --check` | f96a068: **failed** (3 hunks), fixed; final head: ok | `tests/fmt.log`, `fmt_final.log` |
| clippy `-p "*" --all-targets -D warnings` (default; and `--features nice_client/gpu,nice_client/cubecl-spirv`) | ok on f96a068, 9062cbf and the final head | `tests/clippy_*` |

The workflow's `--require` list names no FD kernel per base, so nothing was added to it.

## A/B (unprofiled, interleaved, alternating order; `raw/pr/ab/`)

R = ee303030 + harness list, N = this branch + harness list; MF = main c0c357a + harness + the gate as an env switch.
Every process's `join_kernel` was 46–48 registers, no spill, except `ab_N_b62_r1` (40 + 24 B, re-run).

| | R (#250) | N (PR) | R/N per round | median |
|---|---|---|---|---|
| b64 1e17 at 0.55 | 141.31, 142.03, 144.67 | 130.00, 130.27, 130.56 | 1.087, 1.090, 1.108 | **×1.090** |
| b64 1e16 at 0.35 + 0.55 | 34.65, 34.74, 34.69 | 32.79, 32.78, 32.80 | 1.057, 1.060, 1.058 | **×1.058** |
| b62 1e17 (L30's field) | 58.26, 58.13 | 58.98 (spill variant), 58.16 | 0.988, 0.999 | unchanged |
| main only (MF off → on): b64 1e17 at 0.55 | 144.97 | 136.63 | 1.061 (1 round) | |
| main only: b64 1e16 at 0.35 + 0.55 | 34.66, 34.74 | 33.94, 33.38 | 1.021, 1.041 | |
| earlier, on the stack (#250 + #251, SF switch): b64 1e17 | 135.02; 236.67, 236.44 (2 fields) | 118.32; 209.59, 210.13 | 1.141, 1.129, 1.125 | ×1.13 |

- `ab_R_e17_r1` (10:52:35–10:54:59) overlapped a niced `cargo clippy -j 4` for about a minute; its ratio (1.087) is the
  lowest of the three, so if anything it understates.
- **Top phase against denser plan** (profiled, tree EF = #250's kernels + profile, gate switch, b64 1e17 at 0.55; from
  the main session, `raw/box/pf_*`): top phase 24.10 → 10.84 s, rest of the field −1.0 s (inputs, bucket); profiled field
  144.0 → 129.7 s. So ~93 % of the saving is the top phase. The denser plan (CUDA-only) matters inside that: FD seeds each
  prefix once per launch, and launches went 5,846 → 3,061. Expected on wgpu, where the plan keeps 5–7 partitions [E,
  from #250's ~2.4× seed cost]: FD ~0.116 ns per test instead of 0.104, i.e. roughly ×1.07–1.09 at 1e17 instead of ×1.09.
  Main-only (no #250 at all: older FD step and no denser plan) measured ×1.02–1.06.
- NiceMark not run: its nice-only scenarios are b58/b60/b62 (`bench_defs.rs`), where `top_fd_runs` is unchanged.

## Worries

- The branch-name situation above (force-push refused).
- The gain on the PR's own base (#250) is ×1.09 at 1e17 and ×1.06 at 1e16, smaller than the ×1.13 I reported on the
  stack (#250 + #251); both clear the ×1.05 simple-change bar, but the 1e16 one only narrowly (and b64 should be
  inserted at 1e17).
- Only two b64 fields were timed (both heavier than the mean); the profile split is from one 1e17 field.
- No non-CUDA timing at b64; the wgpu expectation is an estimate.
