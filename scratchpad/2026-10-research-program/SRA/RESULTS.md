# SRA: the stride path must prove its kernels ran — results (2026-11-18/19, 23:25–02:30 UTC)

Branch `pr/stride-ran-account` from upstream main 71eb5fcd (same `common/` and `client/` as v3.4.8 `8c267de5`),
worktree `~/projects/nice/.worktrees/stride-ran`, pushed to the fork. Commits: `7cf0c40d` (the fix, its tests,
CHANGELOG), `3940f8a2` (test-only: the regression test without a `Debug` bound on the result, and `cargo fmt`).
Production code is identical in both; the client binary measured on the card was built at `7cf0c40d`.
PR description: `SRA/PR-BODY.md`. Box: Vast 61303619 (RTX 3080 20 GB): worktree `/root/sra/nice` with target dir
`/root/sra/target`, and upstream main at `/root/sra/base` with `/root/sra/t-base` (comparison run only);
`libpq-dev` and `just` installed there; left running and idle (0 % GPU, no processes) at 01:25 UTC.
Harness and scripts: `raw/harness/`; box logs: `raw/box/logs/`, runs: `raw/box/runs/` (run.log, hog.log, and
client.log of the six hog runs) with everything in `raw/box/runs.tgz`.

## 1. The gap, kernel by kernel and consumer by consumer

| kernel | consumer of its result | account before | dropped launch accepted? |
|---|---|---|---|
| `niceonly_kernel` (stride walk), plain path (no queue: no-MSD dispatches, devices without plane ops) | `read_niceonly_hits` ← `CubeclPendingField::wait` (the pipeline) / `CubeclNiceonlyRun::finish` (tests) | none: hit count only | **yes**: 0 hits, read as "searched, empty" |
| `niceonly_kernel`, cube-scoped queue | same | queue account `nice_count[1..3]` = queued − checked | **yes**: 0 − 0 = 0 passes |
| `niceonly_kernel`, plane-scoped queue (production default on CUDA and SPIR-V) | same | same | **yes** |
| `detailed_kernel`, `detailed_fd_kernel` (detailed mode, native) | `detailed_impl` | histogram total == range size | no (see 3) |
| `detailed_kernel_u32`, `detailed_fd_kernel_u32` (browser) | `cubecl_web` detailed | histogram total == range size | no |
| join kernels | `JoinDevice` | `ensure_ran` (cubes finished per kernel) | no (unchanged, not touched) |

There is one stride-walk kernel and one host reader (`read_niceonly_hits`); every route into it
(`CubeclContext::begin_stride` → `CubeclNiceonlySink` → `CubeclNiceonlyRun` → `CubeclPendingField::wait`) goes
through that reader, on every runtime (wgpu/WGSL, wgpu/SPIR-V, Metal, CUDA, HIP: the code is generic over `R`).

## 2. What the fix adds (`common/src/cubecl_backend.rs` +78/−5 outside tests, of which ~20 are `cfg(test)` plumbing; tests +84; CHANGELOG +4)

- Kernel: `cube_ran(nice_count)` at the very end of `niceonly_kernel`, after the comptime branch over its three
  paths: `sync_cube(); if UNIT_POS_X == 0 { nice_count[3].fetch_add(1) }` — the join's `cube_done`. Per cube,
  by unit 0 (every cube has a unit 0; nothing assumes a plane is full or that a plane has lane 0); an atomic
  add, not a store (the SPIR-V store-merge trap cannot apply); no new loop or `break`. The barrier is in
  uniform control flow (the branch is comptime, every path's loops exit before it). Cost: one barrier and
  at most one atomic per cube (≤ 4096 per launch).
- Count buffer: `NICEONLY_COUNT_WORDS` 3 → 4.
- Host: `CubeclNiceonlyRun.cubes` adds the cubes of every launch (after clamping to `MAX_CUBES`, i.e. exactly
  the grid launched); `CubeclPendingField` carries it; `read_niceonly_hits(…, cubes)` calls the new
  `ran_complete(base, counts, cubes)` before `queue_complete` and before reading hits. Mismatch →
  `stride walk b{base}: the device did not run every launch: its kernels finished {ran} of {cubes} cubes`
  (the join's wording). Comparison mod 2^32 (as the queue account's low-word sum); a single launch is at most
  4096 cubes so a dropped launch cannot wrap it away.
- Test hook (`cfg(test)` only, like `test_bits`): `skip_launches` makes `launch` count a launch without
  running it. No flag, no environment variable, no retry, nothing on a healthy device.
- CHANGELOG: one sentence under a new `## Unreleased`, `(#NNN)` placeholder.

## 3. The detailed path

Already has the account; no change. Every candidate of a launch adds 1 to exactly one histogram bin
(`detailed_kernel` and `detailed_fd_kernel` share the histogram), and `detailed_impl` ends with
`ensure!(counted == range.size(), "GPU histogram counted {counted} of {} candidates; the device dropped work …")`.
A dropped launch leaves its candidates unbinned, so the total falls short and the field errors; a drain whose
histogram buffer failed to allocate fails its read (or, if it read zeros, falls short the same way). The
near-miss buffers are read only after that check. The browser runner (`cubecl_web.rs:1007`) has the same
check. Not measured under the hog tonight (the brief's three reproductions are all nice-only).

## 4. Regression tests

- `cubecl_dropped_launches_fail_the_field` (wgpu; CI's lavapipe jobs run it with WGSL and with SPIR-V, both
  commands match the `cubecl_` filter / `--ignored`) and `cubecl_cuda_dropped_launches_fail_the_field`:
  generic `dropped_launches` — b50 window of `queue_cases()` with a firing certificate, split into two
  launches, on each path (plain; cube-scoped queue; plane-scoped where `plane_queue_runs`, i.e. CUDA and real
  Vulkan, not llvmpipe), for no launch dropped / both / the second only, through `end_field` +
  `PendingField::wait` (the pipeline's consumer). Clean: must equal the host mirror's survivors (probe mode);
  dropped: must error with "did not run every launch".
- `ran_complete_wants_every_launched_cube` (no device, in the ordinary suite).
- Without the fix (host check deleted, kernel count left in): see 5 — the dropped cases come back `Ok` and the
  tests fail.

## 5. Tests and lint (box, toolchain 1.100.0 pinned, all at 3940f8a2; logs `raw/box/logs/`)

| check | command | result |
|---|---|---|
| `just lint` | `just lint` (fmt --check; clippy `-p "*" --all-targets`, and with `nice_client/gpu,nice_client/cubecl-spirv`, `-D warnings`) | **pass** (`checks/just_lint.log`; the first attempt at 7cf0c40d failed on `cargo fmt` of one test line and on a `Debug` bound in the CUDA-only test — fixed in 3940f8a2) |
| clippy with CUDA | `cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings` (the CUDA-only test is outside `just lint`'s features) | pass |
| suite, CI form | `cargo test --locked --release --no-fail-fast` | pass (client 24, common 207) |
| suite, `just test` form | `cargo test --release -p "*" --no-fail-fast` (needed `libpq-dev` on the box to link `-lpq`) | pass (common 247, api 4, client 24, integration 3) |
| CI's GPU-feature unit tests | `NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib` | pass, 261 (incl. `ran_complete_wants_every_launched_cube`) |
| lavapipe, WGSL | `cargo test --release --features cubecl -p nice_common -- --ignored` (CI's command) | pass, 41 |
| WGSL Apple-division lint | CI's `wgsl_dump_for_lint` + `scripts/wgsl-lint.py` with CI's `--require` list | pass |
| lavapipe, SPIR-V | `cargo test --release --features cubecl-spirv -p nice_common -- --ignored cubecl_` (CI's command) | pass, 32 |
| CUDA (RTX 3080) | `cargo test --release --features cubecl-cuda -p nice_common -- --ignored cubecl_cuda_` | every stride and detailed test passes (incl. the new one on all three paths, partly-filled warps, queue faults, parity with the CPU). Two **join** tests failed in the parallel run and one in a `--test-threads=1` run, each on a CubeCL allocation failure (`can't allocate buffer of size: 1314320384` / `5257281536`) after the one test process had filled the card (19,976 MiB parallel; 16.5 GB serial); the join's own `ran` check caught them (`NotRun`, "top cubes run"). The serial failure, `cubecl_cuda_top_fd_matches_the_top_kernel`, passes alone (`phase6/topfd_alone.log`). Upstream main (71eb5fc, its own worktree `/root/sra/base` and target dir `/root/sra/t-base`), same serial command: **the same test fails the same way** (16 passed, 1 failed, `can't allocate buffer of size: 5257281536`, "top cubes run", peak 16,471 MiB; `phase6/base_cuda_serial.log`). So this is pre-existing test-process memory pressure, not this change. |
| Metal | `cargo check -p nice_common --all-targets --features cubecl-metal` | Rust compiles; the kernel's MSL is generated at run time, so the MSL was not produced or compiled here |

The regression test without the fix (`phase2/nofix_*.log`: the `ran_complete(...)?` line deleted, nothing else):
**fails on CUDA, lavapipe WGSL and lavapipe SPIR-V** — `compact=false plane=false skip_from=Some(0): a dropped
launch must fail the field`. With the fix it passes on all three, printing for every path
`skip_from=None: 30449 of 30449 survivors`, `Some(0): … finished 0 of 2 cubes`, `Some(1): … finished 1 of 2
cubes` (plane-scoped path on CUDA only; llvmpipe skips it by design).

## 6. On the card (memory-hog harness of G2/build2e/raw/alloc, `SRA/raw/harness/srun.sh`)

Hosts block proved again before any client ran (`raw/box/proof_hosts_block.txt`; `srun.sh` also aborts if a
production host answers or resolves off loopback). Client: `nice-fix` (md5 8ae52693…, `gpu,cubecl-cuda`,
release, 7cf0c40d) against `nice-v348` (ff8a5d2c…), local stub only.

| case | v3.4.8 (rerun tonight, same session) | this branch |
|---|---|---|
| b64 1e13 forced stride, LEAVE 400 | Task failed ×71, **submitted `[]`**, launches 70, device wait 0.13 s | `ERROR GPU processing error: stride walk b64: the device did not run every launch: its kernels finished 0 of 277280 cubes`, rc=1, **0 submissions** |
| b64 1e13 forced stride, LEAVE 520 | Task failed ×92, **submitted `[]`**, launches 91, wait 0.16 s | `… finished 0 of 282373 cubes`, rc=1, **0 submissions** |
| b62 5e12, production routing (no override), LEAVE 290 | Task failed ×45, **submitted `[]`**, launches 43, wait 0.08 s | `… stride walk b62: … finished 0 of 200319 cubes`, rc=1, **0 submissions** |

The original write-up's runs of v3.4.8 (`e8_stride_400`, `e8_stride_520`, `nat_hog290_qn62`) showed the same.
Note "0 of N": the first allocation failure (at the first field's buffers) poisons every later launch.

Healthy runs (no hog): same results and counts as v3.4.8 — `nice_numbers: []` on every field; launches b62
44–46 both, b64 116–119 / 278–283 / 341 by field position both (the floor controller's spread, same in both);
`valid_numbers` per field position identical (729,957,500,000 b62 fields 2–3; 1,458,006,375,000 b64 fields 2–3)
with field 1 varying run to run in both. In the base runs the stub's filler field (base 10, 47..100) went
through the stride path ~5,900 times on CUDA with the fix, each submitting `69` with the account satisfied.

## 7. Timings (3 rounds, each a queue of 3 copies of the field, binaries interleaved, alternate order)

`processing_secs` per field (client telemetry), medians over rounds; `raw/box/logs/timings.txt`.

| field | v3.4.8 | this branch |
|---|---|---|
| b62 5e12 (production routing), sum of 3 fields per round | 2.490 / 2.050 / 2.051 s, median 2.051 | 2.137 / 2.099 / 2.453 s, median 2.137 |
| b62, device wait per field (median, fields 1/2/3) | 0.709 / 0.332 / 0.314 s | 0.696 / 0.327 / 0.312 s |
| b64 1e13 forced stride, sum of 3 fields per round | 7.799 / 7.838 / 7.714 s, median 7.799 | 7.825 / 7.730 / 7.765 s, median 7.765 |
| b64, device wait per field (median, fields 1/2/3) | 2.600 / 2.319 / 2.362 s | 2.597 / 2.319 / 2.356 s |

Unchanged within noise: the b62 totals' spread between rounds (0.44 s) is larger than the difference of medians
(+0.09 s, +4 %), and the device wait, which is the kernel's share, agrees to 1 %. Results and launch counts per
field position are the same in both (6).

## 8. Not tested

- Metal: not run (no Apple device); `cargo check --features cubecl-metal` passes, but the MSL is generated at
  run time, so it was never produced or compiled. The added code (a cube barrier and one atomic add) is the
  same construct the queue account already runs on Metal.
- HIP: same generic code, not built (no ROCm).
- wgpu on real hardware under allocation failure: not measured (llvmpipe cannot be pushed out of memory by a
  GPU hog). Per the original write-up's reading of cubecl-wgpu 0.10, a launch whose binding fails is pushed as
  a stream error and the launch fences fail the field already; the account is a second check there.
- Detailed mode under the hog (see 3).

## 9. Seen, deserves its own fix (not fixed)

1. CUDA context creation failing with `CUDA_ERROR_OUT_OF_MEMORY` (LEAVE 150–230 in the write-up) falls back
   to wgpu on llvmpipe with only a WARN: correct but a small fraction of the speed on a `--gpu` box.
2. Some allocation failures end in a host panic, `called Result::unwrap() on an Err value: CallError`, exit 101
   (write-up LEAVE 340/260/640); not an error path, site not traced.
3. After one failed allocation the CubeCL CUDA client is poisoned for the process (every later launch is
   dropped); with this fix the client now exits 1 on the first stride field, as the join does at its smallest
   layout. A supervisor that restarts the client will loop if memory stays short; nothing is submitted.
4. The hand-CUDA backend (`GpuHandle::Cuda`) and the middle-out paths (not on main) were not examined.
5. CUDA device tests share one CubeCL client per test process, and its pools keep what earlier tests
   allocated: the join's `cubecl_cuda_top_fd_matches_the_top_kernel` fails on a 20 GB card when run after the
   others (upstream main too; passes alone), and in parallel two more join tests do. A test-isolation fix
   (one process per heavy test, or dropping the pools) is its own item.
6. The plan cache (`cached_plan`) keeps a base's residue table handle for the process; if its allocation
   failed, every later field of that base fails (now loudly).
