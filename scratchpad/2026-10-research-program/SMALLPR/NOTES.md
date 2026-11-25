# Two small PRs, 2026-11-25 (ivory)

Both branch from `origin/main` fdbe07d3, one commit each, pushed to `fork` only; no PR opened, nothing to
`origin`. Changelog lines carry `#NNN`. Descriptions: `BODY-1.md`, `BODY-2.md`. Logs and binaries used below:
`SMALLPR/logs/`; the stand-in libcuda: `SMALLPR/fakecuda/`.

| | branch | worktree | commit |
|---|---|---|---|
| 1 | `pr/gpu-software-renderer-error` | `~/projects/nice/.worktrees/gpu-sw-error` | 5781393a |
| 2 | `pr/ci-spirv-atomic-stores` | `~/projects/nice/.worktrees/ci-atomic` | 68194bf1 |

## 1. `--gpu` refuses a software renderer

### What main does (fdbe07d3, `client/src/main.rs`)

`init_gpu` (line 600) walks, for `--gpu-backend auto`: CubeCL CUDA (636–658) → CubeCL wgpu (744–768) → hand-CUDA
(770–790) → final error (792–801). A named backend that fails is fatal. The wgpu branch returns the first adapter
`CubeclContext::new_default` gives (`WgpuDevice::default()`, i.e. wgpu's `request_adapter(HighPerformance)`, which
prefers discrete, then integrated, then CPU adapters) with an info line, whatever it is.

- (a) CUDA runtime present, context creation fails: `cubecl-cuda`/`cuda` named → exit 1. `auto` →
  `log_cuda_fallthrough` (400) warns "driver loaded but failed to initialize", then wgpu: NVIDIA's Vulkan ICD if
  installed (hardware, used, no further warning), else Mesa's llvmpipe if installed (used, **info only**), else no
  adapter → hand-CUDA (fails the same way) → final error. Reproduced on lavapipe with a stand-in libcuda whose
  `cuInit` returns `CUDA_ERROR_OUT_OF_MEMORY` (`logs/fake_client_main_auto.log`): WARN about CUDA, then
  "GPU initialized: CubeCL wgpu device (llvmpipe ...)" — the case seen on the rented box.
- (b) No CUDA, hardware Vulkan/Metal: `auto` → CubeCL CUDA fails at info (no libcuda) → wgpu hardware, used.
  `cubecl` → same device. `cuda`/`cubecl-cuda` → exit 1.
- (c) Only a software renderer: `auto` and `cubecl` run on llvmpipe with an info line
  (`logs/run_client_main_{auto,cubecl}.log`); `cuda`/`cubecl-cuda` exit 1. (`cubecl-hip`: explicit only, HIP
  device, not affected.)

Nothing the project runs on purpose uses the client on a software renderer: no workflow runs `nice_client --gpu`
(`.github/workflows/*`: only builds and `--version` smoke tests in docker); the justfile's `client-gpu*` and
`benchmark-sweep --gpu` are for a developer's own GPU machine; the README documents no such use; the fleet runs
`--gpu` on NVIDIA boxes, where an exiting client is already the designed failure ("a broken GPU crashes the repeat
below anyway and gets reaped", `fleet/controller.py`). The browser e2e uses SwiftShader inside Chrome, not the
native client. The library's device tests on lavapipe call `CubeclContext::new_default` directly, which is
unchanged.

### What changed and why that, not more

- `common/src/cubecl_backend.rs`: `CubeclContext::is_software_rasterizer()`, wgpu only, using the existing
  name test `is_software_rasterizer(&str)` (llvmpipe, lavapipe, swiftshader, "software rasterizer") that the
  kernels' own choices already use, so "software" has one definition in the code.
- `client/src/main.rs`: `judge_wgpu_adapter(device, software, cuda_failure)` → `Err(reason)` for a software
  renderer; `Ok(Some(warning))` for a hardware adapter used after CubeCL CUDA failed on a machine with an NVIDIA
  driver (the two existing classifiers `cuda_toolkit_missing` / `cuda_driver_rejected`, i.e. exactly the cases
  `log_cuda_fallthrough` already warns on); `Ok(None)` otherwise. In `init_gpu` the wgpu attempt is passed through
  it: a refusal goes into the existing error arms (named `cubecl` → `error!` + exit 1; `auto` → into `tried`, chain
  continues to hand-CUDA, final `error!` lists every reason). Docs: `init_gpu` comment, one README sentence,
  changelog line.
- Not done: no flag, no environment switch, no change to adapter selection (`--gpu-wgpu-device` still pins one;
  pinning `Cpu` now errors), no `DeviceType::Cpu` check (would need another field in the `WGPU_DEFAULT` cache; the
  name test is what the kernels use), no change to the CUDA paths. Hand-CUDA's "third stop" is now reachable when
  wgpu offered only a software renderer, which on main it was not; that only matters on a box with a working
  NVRTC/driver but failed CubeCL CUDA, and is strictly faster than llvmpipe.

### Tests and runs

- Unit test `a_software_renderer_is_refused_and_a_gpu_after_cuda_warns` (client, host-only): software refused
  with and without a CUDA failure and the message says "without --gpu"; hardware without a CUDA failure → no
  message; hardware after a CUDA failure → a warning naming the device and the CUDA error. ivory, debug,
  `--features gpu`: client suite 26 passed. Fork CI (run 45544909480): `Format and clippy` (= `just lint`) pass,
  `Test workspace` pass, `Test GPU host code` pass, the build matrix (see the run for the final state).
- Real binary on lavapipe (container `lvp26`, Mesa 26.0.8, `LP_NUM_THREADS=2`), main's and this branch's
  `nice_client --features gpu` (debug), `niceonly --gpu --gpu-backend X --api-base http://127.0.0.1:9` (a closed
  port; neither run reached the network: main's run panicked building its HTTP client in the container, which has
  no CA store, after GPU init; that is the container, not the change):

  | backend | main | this branch |
  |---|---|---|
  | auto | "GPU initialized: CubeCL wgpu device (llvmpipe ...)" | exit 1, final ERROR lists cubecl-cuda, cubecl ("llvmpipe ... is a software renderer ... Run without --gpu"), cuda |
  | cubecl | llvmpipe, info | exit 1, ERROR with the reason |
  | cuda, cubecl-cuda | exit 1 (no libcuda) | same |
  | auto + stand-in libcuda failing `CUDA_ERROR_OUT_OF_MEMORY` | WARN (CUDA), then llvmpipe | WARN (CubeCL CUDA), WARN (hand-CUDA), exit 1 with all three reasons at ERROR |

  Logs: `logs/run_client_{main,pr1}_*.log`, `logs/fake_client_{main,pr1}_*.log`.
- Fork CI GPU Device Parity on this branch (run 45545836683): lavapipe and Metal device tests (library only,
  unaffected by design).

### Could not be tested

- A real CUDA context failure (no NVIDIA GPU here): exercised through the stand-in libcuda above, which drives
  the same `DriverError(CUDA_ERROR_OUT_OF_MEMORY)` text through both CUDA backends' real init code.
- The new warning (hardware wgpu after a CUDA failure) on a device: no hardware wgpu adapter on ivory. Covered
  only by the unit test of `judge_wgpu_adapter`; the wiring (`cuda_failure` set in the CubeCL CUDA arm, read in
  the wgpu arm) is by reading. On the maintainer's AMD and M4 machines CubeCL CUDA fails with "no libcuda",
  which neither classifier matches, so `cuda_failure` stays `None` and nothing changes there.

### Reviewer, look hardest at

1. False positives of the name test on real hardware: a hardware adapter whose name contains "llvmpipe",
   "lavapipe", "swiftshader" or "softwarerasterizer" would now be refused. None known; the same test already
   turns kernel features off. Windows WARP ("Microsoft Basic Render Driver") is *not* caught (unchanged).
2. Whether `--gpu-wgpu-device Cpu` should stay allowed as an explicit request (the help text names `Cpu` as a
   spelling). Here it errors like any other software renderer; it was never faster than the CPU path.
3. Under `auto`, the software renderer's reason is at debug until the final error; if hand-CUDA then succeeds
   the client runs on hand-CUDA with only the existing info lines.

## 2. CI check: SPIR-V keeps every atomic operation

### What main does

`gpu-parity.yml`'s lavapipe job (lines 64–90) runs `cubecl_backend::tests::wgsl_dump_for_lint` under
`--features cubecl` with `CUBECL_DEBUG_LOG`, then `scripts/wgsl-lint.py` with `--require` per kernel, and uploads
the log on failure; the next step runs the `cubecl_` device tests under `cubecl-spirv`. Nothing compares the
SPIR-V the second build produces with anything.

### What changed

- `common/src/cubecl_backend.rs` (test module only): `atomic_store_trap_kernel` (unit 0 stores 7 into two
  shared atomic words in one block, barrier, reads them out) and its launch at the end of
  `wgsl_dump_for_lint`; doc comments.
- `scripts/spirv-atomic-check.py WGSL_LOG SPIRV_LOG [--require K]... [--expect-dropped K]...`: pairs kernel
  variants by name + the `KernelId` block (minus `pf_count`, which the join sets from the compiler and which
  only selects a register-only prefilter test; listed in `COMPILER_CHOSEN` with that reason), counts
  `OpAtomicStore/IAdd/ISub/Or/And/Xor/[US]Max/[US]Min/Exchange/CompareExchange` against the WGSL builtins, flags a
  variant with fewer of any kind in SPIR-V. Exit 0/1/2 as `wgsl-lint.py`. Same shape and conventions as
  `wgsl-lint.py` (a log reader, `--require`, a header that says what it cannot see).
- `gpu-parity.yml`: one step after the SPIR-V parity step (reuses its test binary): the dump again under
  `cubecl-spirv` with `CUBECL_DEBUG_LOG=$RUNNER_TEMP/spirv.log`, then the script with
  `--expect-dropped AtomicStoreTrapKernel` and `--require` for the ten production kernels that have atomics; and
  an upload of `spirv.log` on failure. No new job; the extra cost is one ~15 s test run in the existing job.
- Why this and not a Rust test: the repository already checks kernels this way (dump test + Python script in the
  lavapipe job), both outputs come from that job, and compiling every kernel both ways in one Rust test would need
  both compilers in one build, which the feature layout does not allow (`cubecl-spirv` switches the wgpu
  runtime's compiler for the whole build).

### Tests and runs

- ivory, release test binaries `--features cubecl` and `--features cubecl-spirv`, dump test on lavapipe (lvp26,
  Mesa 26.0.8): WGSL 15 variants, SPIR-V 15, all 15 paired (11 kernels); production kernels match
  (`logs/check_pass.txt`); `AtomicStoreTrapKernel: lost in SPIR-V: store 2 in WGSL, 1 in SPIR-V`; exit 0 with
  the expectation, exit 1 without it (`logs/check_noexpect.txt`); exit 2 for swapped or unreadable dumps.
  `wgsl-lint.py` with CI's `--require` list on the new WGSL dump: 0 flagged (the trap kernel has no division).
- Against the 2026-11-14 dumps of #263's first version (`T26B/raw/ci/dump/wgsl_hw.log` vs `spv_hs.log`): all 16
  `NiceonlyKernel` variants flagged, store 5 against 2 — the real defect, found by the script unchanged.
- Coverage: every launchable production kernel for wgpu is in the dump (detailed, detailed FD, browser u32
  kernels, nice-only, bucket, top, top FD, join, check); not in it: `smoke_kernel` (CUDA/HIP only) and test-only
  kernels. Full suites with dumps: see "Full-suite comparison" below.
- Fork CI: GPU Device Parity run 45545815302 and Build/Test run 45545819469 (`just lint` passed there).

### Could not be tested / limits

- Counts per kernel: a dropped store masked by an extra store of the same kind elsewhere in the kernel is not
  seen. Only the variants the dump compiles are compared (one or a few per kernel), not every comptime variant.
- If CubeCL fixes the pass (e.g. on an upgrade), the expectation fails with a message saying to remove the trap
  kernel; that is deliberate, and a reviewer may prefer it to warn instead.

### Reviewer, look hardest at

1. The pairing key: whole `KernelId` block minus `pf_count`. A future comptime argument set per compiler makes
   that kernel unpaired, and `--require` then fails (good, loud), but the fix is to add it to `COMPILER_CHOSEN`
   only if it does not change atomics.
2. Whether "fewer in SPIR-V" is the right rule (more in SPIR-V, e.g. after unrolling, passes).
3. The trap kernel lives in the test module and is compiled by the dump test only; `wgsl-lint.py` sees it too
   (harmless: no divisions).
