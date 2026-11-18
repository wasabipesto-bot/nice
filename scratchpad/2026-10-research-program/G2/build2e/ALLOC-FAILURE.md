# Can production submit a false "empty" after a CUDA allocation failure? (2026-11-18, 22:52–23:30 UTC)

**Yes, on the stride route.** Production's v3.4.8 client (`8c267de5`, features `gpu,cubecl-cuda`, md5
`ff8a5d2c…`, CubeCL CUDA runtime) submitted fields as searched and empty after every launch had silently done
nothing. This happens on the stride path, which production takes on its own for nice-only fields below the
join's minimum size (1e13) and for bases outside 40–64. The overlap join catches the same failure every time:
it retries with smaller layouts and either gets the right counts or exits with an error.

Setup: Vast 61303619 (RTX 3080, 20 GB). The production hosts were mapped to 127.0.0.1 and ::1, and the block
was proved again first (`raw/alloc/proof_hosts_block.txt`). The client talked only to the local stub
(`build1/box/stub_api.py`). `raw/alloc/hog.cu` is a CUDA program that takes all but LEAVE MiB of the card's
free memory before the client starts, or DELAY s after it starts. `raw/alloc/arun.sh` runs one experiment;
each one has a directory `raw/alloc/runs/<tag>/` (client log, stub output, memory trace at 200 ms). Code was
not changed on any branch.

## (a) What the client does (fields are known to be non-empty; base runs had no hog)

| route, field | memory condition | client | submitted |
|---|---|---|---|
| join, b64 1e16 (`base64`) | none | ok | checked 14,702,398,417 |
| join, b64 | LEAVE 2000 / 6000 / 7800 / 800 MiB (`e2`, `e3`, `e4`, `e9_join_800`; 5.26 GB and 1.31 GB allocations fail) | warns "the device did not run a batch … kernels finished [0,0,0,0] of [9215,1008,64512,2048] cubes", shrinks the layout 1–3 times | **correct**: checked 14,702,398,417 |
| join, b64 | LEAVE 330 / 450 (`e9_join_330`, `_450`) | no layout runs: `ERROR GPU processing error: overlap join: the device did not run a batch …`, exit 1 | nothing |
| join, b62 1e16 (`base62`, `e6_mid62`, LEAVE 3000) | | shrinks twice | **correct**: 7,181,002,897 |
| join, hog after the field's buffers exist (`e5_after64`) | | nothing fails (pools reused) | correct, both fields |
| **stride, b64 1e13 forced** (`NICE_JOIN_ROUTE=stride`; `base_stride`, `e8_stride_400`, `_520`) | LEAVE 400 / 520: one 328 MB allocation fails, then 78 / 89 launches panic "couldn't find resource … Memory page 0 doesn't exist" | **no error**; device wait 0.13 s (normally 2.63) | **`nice_numbers: []`**, launches 78, num_ranges 5,198,135 (normally 7,854,163) |
| **stride, b62 5e12, routed by production itself** (below `JOIN_MIN_FIELD_SIZE`; `nat_base_qn62`, `nat_hog290_qn62`) | LEAVE 290: 2 allocations fail, 50 launches panic | **no error**; device wait 0.09 s (0.64 in a normal run) | **`nice_numbers: []`, launches 50, valid 808,129,000,000** |
| stride | LEAVE 340 (b62), 260 (b65), 640 (b64): an unwrap of `CallError` on the host | panic, exit 101 | nothing |
| any | LEAVE 150–230: `CUDA_ERROR_OUT_OF_MEMORY` when the context is created | **switches without an error to wgpu on llvmpipe** (CPU Vulkan), `WARN CubeCL CUDA unavailable, falling back` | correct but slow (b65 1e12 correct; b64 1e16 had not finished after 240 s) |

The false empty cannot be told apart in the submission. No nice number is known in these fields, so in every
row "found nothing" was the honest answer as well; what the false runs have is that their kernels never ran
(log and device time). Telemetry shows only small changes (fewer launches, other `num_ranges`/`valid_numbers`),
and those also vary between normal runs. The server has nothing to reject.

## (b) The mechanism in CubeCL 0.10.0

1. An allocation (`client.empty`/`create`) reaches `cubecl-cuda-0.10.0/src/compute/server.rs:124`,
   `command.reserve(size).unwrap()` in `initialize_memory`, and panics: "can't allocate buffer of size: N".
   The handle was already returned to the caller and now names memory that does not exist.
2. The panic happens inside a device-runner task. `cubecl-common-0.10.0/src/device/handle/channel.rs:466`
   and `:480` catch it with `catch_unwind`, log `WARN … Task failed: Any { .. }`, and drop the task.
3. Every later launch or read that binds that handle panics in
   `cubecl-runtime-0.10.0/src/stream/event.rs:268` → `cubecl-cuda-0.10.0/src/compute/stream.rs:101`
   (`get_cursor(…).unwrap()`): "couldn't find resource for that handle: Memory page 0 doesn't exist".
   That panic is caught and dropped in the same way, so the kernel never runs.
4. On CUDA the panic is not recorded as a stream error. Only `Err` returns from `launch_checked` are pushed
   (`server.rs:157–163`), and `is_healthy` (`stream.rs`, `errors.is_empty()`) stays true. So `client.sync()`
   and production's launch fences return `Ok`. Reads of buffers that did allocate succeed and return whatever
   the dropped kernels would have changed, unchanged: zeros.

## (c) What catches it in production today, and the smallest guard that would

- **Overlap join: caught.** `JoinDevice::ensure_ran` (`common/src/cubecl_join.rs:4400` at v3.4.8) compares
  every kernel's finished-cube count (`cube_done`, `:246`) with the cubes launched. A dropped launch reads
  [0, 0, 0, 0] and becomes `NotRun`, so the layout is refused and retried smaller (`:4877–4910`); at the
  smallest layout the field errors and the client exits 1 (`client/src/main.rs`, "GPU processing error").
  `ensure_checked`/`check_complete` (`:4422`, `:4532`) would not catch it by themselves: 0 entries checked of
  0 listed passes.
- **Stride path (cubecl): not caught.** `queue_complete` (`common/src/cubecl_backend.rs:3202`) requires
  queued − checked = 0, which holds trivially when nothing ran. `CubeclPendingField::wait` (`:3301`) reads only
  the hit count and hits. The launch fences (`launch_fence`, `:2766`; awaited at `:2816–2830`) return `Ok` on
  CUDA (b.4). No account counts cubes.
- **Smallest guard:** the join's own rule applied to the stride kernel. Each cube adds 1 to a spare word of
  `nice_count` at its end; `wait` requires the field's sum to equal the cubes launched for it, and fails the
  field otherwise (the day's wide path does the same with `C_JOBS`). One atomic per cube, one comparison per
  field.
- **A guard at the client level:** treat a CUDA context that fails to initialise on a `--gpu` box as an error,
  not a silent move to llvmpipe. That fallback is correct but runs on the CPU at a small fraction of the speed.

## (d) lavapipe / wgpu

Same panic at allocation (`cubecl-wgpu-0.10.0/src/compute/server.rs:270`, `stream.empty(size).unwrap()`). But
a launch whose binding cannot be prepared returns `Err` and is pushed onto the stream's errors
(`server.rs:364`, `:379`), so the next sync fails with `ServerUnhealthy`. That is what the wide path's tests hit
on lavapipe today (`build2e/raw/lvp/small.log`). Production's fences propagate a failed sync (`launch_fence`
maps it to an error), so on wgpu the field should fail rather than submit. **I did not measure this for
production's client on wgpu** (llvmpipe cannot be pushed out of memory by a GPU hog); it rests on the code and
on the wide path's observation.

Not done (time): the trunk's narrow middle-out path (piece 4 of the request; it has no `C_JOBS` account, and day
one's b64 run under the accidental failure reported `survivors 0 = checked 0`, `raw/m2_oom_failed/`); a hog
grabbing memory between two stride fields (the stride path creates buffers for every launch, so that should
behave like the LEAVE rows); the hand-CUDA backend (`GpuHandle::Cuda`, not selected on this build).
