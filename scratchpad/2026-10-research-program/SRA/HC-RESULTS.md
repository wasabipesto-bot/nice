**No.** I found no way for the hand-written CUDA backend to report a nice-only field as searched and empty after an allocation failure, at v3.4.5 or on upstream main. Every device call returns a `Result` that reaches the client, and the client exits 1 without submitting. On the card, 88 runs never produced a false empty: no wrong b54 result, and 0 wrong out of about 228,000 base-10 control fields (each should return `[69]`, and each did). Two cases are not covered. (1) Failures that are not allocations (a kernel launch error, a fault inside a kernel, an Xid) were not reached; the code handles them the same way. (2) Under `--gpu-backend auto`, v3.4.5 moves without an error to another backend when CUDA context creation itself runs out of memory. That is no longer hand-CUDA (see "Not covered").

SRA follow-up HC, 2026-11-19 05:47–07:00 UTC. Vast 61386568 (RTX 3080, 20,480 MiB, power limit 220 W, driver 580.126.09, CUDA 12.8 image). No code was changed on any branch. Raw logs are in `raw/hc/`.

## Setup

- **Hosts block** (`raw/hc/proof_hosts_block.txt`, 05:48 UTC, before any build; checked again before the first client run at 06:01 in `proof_hosts_block_prerun.txt`). `api`, `data`, `www` and the bare `nicenumbers.net` map to 127.0.0.1 and ::1, and curl exits 7 for all four. The harness also checks this before every run. Every client ran with `--api-base http://127.0.0.1:8410` against `stub_api.py`.
- **Binaries.** Both were built with `--features gpu` (cuda + cubecl + cubecl-cuda) on Rust 1.100.0 with `--locked`.
  - v3.4.5: commit `0e75257a`, binary md5 `366d75c0…`.
  - Upstream main: `71eb5fcd`, md5 `e001f98a…` (`raw/hc/bin_md5.txt`, `build_*.log`).
- **How each version ran.**
  - v3.4.5 ran with the default `--gpu-backend auto`. In nice-only mode that is hand-CUDA (`GPU initialized: CUDA device 0`).
  - Main ran with `--gpu-backend cuda`. Main pairs hand-CUDA with CubeCL's join, and b54 1e13 fields go to the join (`main_base_natural`: route `join`). So the main runs forced the stride path with `NICE_JOIN_ROUTE=stride`; every main row below reads `route stride`.
- **Fields.** Four base-54 fields of 1e13 from the census, chosen for their high survivor share (0.78–0.79; `msd_check.json`). Each does about 90–110 launches over about 6–7e6 ranges.
- **The base-10 control.** After the queue runs out, the stub hands out base 10, `[47, 100)` (claim id 1). That field contains the nice number 69. Hand-CUDA runs it on the GPU (1 launch, 1 range), so every one of these fields must return `[69]`; an empty answer there is a detected false empty. Each run submitted 2,000–25,000 of them while the card was squeezed. Fields with ids 900011–13 are the same field placed in the queue.
- **The hogs.**
  - `hog.cu`: the original harness. It holds all but LEAVE MiB, once.
  - `hog2.cu`: new. It does the same, then keeps grabbing (in pieces down to 1 MiB, every 0.5 ms) any memory that becomes free, so that memory the client releases cannot come back to it.
  - `hog3`: hog2 polling in a tight loop.
- **The harness.** `arun_hc.sh` adds two hog modes to the original:
  - `between`: the hog starts the moment the first queued field has been submitted.
  - `after D`: the hog starts D seconds after the client.

## The code path

v3.4.5 lines are from the tag. Main's lines are in brackets, at `71eb5fc`.

1. **Initialisation.**
   - v3.4.5, nice-only `auto` and `cuda`: `client/src/main.rs:504–543` → `try_init_cuda` (`:370`) → `CudaContext::new` (`common/src/client_process_cuda.rs:172–206`). That creates the context and runs the NVRTC smoke test; both use `?`.
   - **If this fails under `auto`, v3.4.5 continues at info level** (`main.rs:542`) to CubeCL wgpu (`:571–592`, "CubeCL unavailable" at `:590`). With no adapter it exits 1 with "No usable GPU backend" (`:635–639`).
   - Main with an explicit `cuda`: initialisation errors exit 1 (`main.rs:707–719`). If CubeCL's join runtime fails to start, that only gives a warning, and every field stays on hand-CUDA (`:684–700`).
2. **Per-base plan.** `niceonly_plan` (`:101–138`, the same on main) runs NVRTC, `load_module`, `load_function`, then `clone_htod` of the residue table and the low masks. Every step uses `?`.
3. **Field open.** `RangeSink::begin_field` (`:548–569` [530–551]) allocates the field's output with `alloc_zeros` (1 MiB `d_nice_out`, 4 B `d_nice_count`), both with `?`.
4. **Launches.** `launch` (`:574–647` [556–629]) does, each with `?`:
   - waits on the backpressure event (`synchronize`);
   - uploads the descriptors with `clone_htod` (three uploads);
   - records timing events;
   - calls `launch_args.launch(cfg)`, which in cudarc is `cuLaunchKernel(...).result()?`;
   - records the ring event.
5. **Errors reach the field.** In the dispatcher (`common/src/gpu_niceonly.rs`), errors from `begin_field` and `launch` go into `first_error` (`:964–998` [914–948]). The next `End` takes it and the field becomes `Err` (`:1036–1044` [992–995]).
6. **Readback.** `CudaPendingField::wait` (`:492–542` [474–525]) runs, in order:
   - `end.synchronize()?`, which also returns any sticky error from a kernel;
   - `clone_dtoh(d_nice_count)?`;
   - a bail if the count is over capacity;
   - `clone_dtoh(d_nice_out)?`.

   Event-timing errors only give a warning, but they come after `synchronize` has succeeded.
7. **The client.** An `Err` from begin or finish makes the client log `GPU processing error` and **exit 1** (`client/src/main.rs:805`, `:847` [`:1081`, `:1110`]).
8. **No way to tell "nothing ran" from "nothing found".** The kernel's only output is `atomicAdd(nice_count)` on a find (`common/src/cuda/nice_kernels.cu:499`, `:543`, `:575`), and `d_nice_count` starts at zero. Hand-CUDA's only protection is that CUDA reports every launch, allocation and fault, and that cudarc and nice propagate it.
9. **Errors cudarc swallows.** cudarc 0.19 keeps errors raised in `Drop` and in `stream.wait` inside `device_ptr` in `ctx.record_err`. Those are only read by `check_err`, which nice never calls. All of them are waits or frees on the one stream nice uses; a broken context would also fail the next launch or sync.

**Why this differs from CubeCL.** CubeCL catches the panic from a failed allocation and drops the task, and its stream stays "healthy". Hand-CUDA does neither: cudarc returns `DriverError(CUDA_ERROR_OUT_OF_MEMORY)` from the allocation, and nice uses `?` on it.

## Cases measured

Unless a row says otherwise:
- "4/4" means the four b54 fields were submitted, each with `nice []`, about 90–110 launches and about 2.8–3.0e12 valid numbers. These match the healthy runs, and the variation is the floor controller's.
- "ctl" is the base-10 control: how many were submitted, and how many of those were `[69]`.

| # | runs (`raw/hc/runs/…`) | backend | memory condition | what the client did | submitted |
|---|---|---|---|---|---|
| 1 | `v345_base`, `v345_mix_base`, `v345_s54_base` | v3.4.5 auto → hand-CUDA | none (peak 257 MiB) | normal | 4/4 b54; mix b62 `[]` (26 launches), b64 1e12 `[]` (0 launches: the MSD filter removes the whole field, same in every run); ctl 2,357/3,342/3,767, all `[69]` |
| 2 | `v345_before_100/180/220` | v3.4.5 | hog before start, LEAVE 100–220: the CUDA context cannot be created | "CUDA unavailable; trying the next backend" (info) → "CubeCL unavailable" → `ERROR No usable GPU backend`, **exit 1** | nothing |
| 3 | `v345_before_200_vk` (Vulkan loader + mesa installed for this one) | v3.4.5 | LEAVE 200 | **moves to CubeCL wgpu on llvmpipe without an error** (info only) | 3 base-10 fields `[69]` (correct); the b54 field had not finished after 150 s |
| 4 | `v345_before_225…255`, `v345_bt_before_255`, `v345_s54_before_236…254` | v3.4.5 | LEAVE 225–255: the context starts, the first nice-only device allocation fails | `GPU processing error: DriverError(CUDA_ERROR_OUT_OF_MEMORY)`, **exit 1** (rc 139, a segfault at exit, in 3 of the 4 `s54` runs, after the error) | nothing (also none of the base-10 fields queued first) |
| 5 | `v345_before_256…600`, `v345_bt_before_256…259`, `v345_mix_before_258…276` | v3.4.5 | LEAVE ≥ 256 | normal; the threshold is sharp (255 fails, 256 works) | 4/4; mix b54+b62+b64 correct; ctl 3,500–3,750 each, all `[69]` |
| 6 | `v345_after_{1.5,3,5}_{0,30}` | v3.4.5 | hog 1.5/3/5 s after start (fields in progress), LEAVE 0/30 | normal | 4/4; ctl all `[69]` |
| 7 | `v345_g_after_*`, `v345_g3_after_long` (hog3, 30 s of base-10 fields) | v3.4.5 | greedy hog after start, LEAVE 0 | normal; the hog never gains memory (81 grabs, 2 MiB free, the whole run) | 4/4; ctl 25,225, all `[69]` |
| 8 | `v345_g_after_sweep_0.3…0.6` | v3.4.5 | greedy hog 0.3–0.6 s in (context up, no plan yet) | OOM at the first allocation, **exit 1** | nothing |
| 9 | `v345_g_after_sweep_0.62…1.4` | v3.4.5 | greedy hog 0.62–1.4 s in (plan built, fields starting) | normal | 4/4; ctl all `[69]` |
| 10 | `v345_g_between_{0,50}`, `v345_g_s54_between_{0,4,8}`, `v345_g_mix_between_fif{1,2}`, `v345_g_between_smallbig_{0,4}` | v3.4.5 | greedy hog between fields; plans for new bases (b62, b64, b54 after base-10) built after the squeeze | normal; plans fit in what the client already holds | all correct: base-10 `[69]`, b54/b62 `[]` with normal launches |
| 11 | `v345_deep_base_*` (`NICE_GPU_MSD_FLOOR` 2e7/2e8, 100k batches in flight) | v3.4.5 | none; an attempt to make the client's memory grow | memory stays at 257 MiB: the descriptor uploads are pageable, so each one is ordered after the kernels before it | correct (154 launches, all 1e13 valid) |
| 12 | `main_base_stride`, `main_base_natural` | main `cuda` (+ join) | none | normal | stride 4/4; natural route = join (3.2 GB, not hand-CUDA); ctl all `[69]` |
| 13 | `main_stride_before_100/200` | main `cuda` | LEAVE 100/200 | `Failed to initialize CUDA … OUT_OF_MEMORY`, **exit 1** | nothing |
| 14 | `main_stride_before_230` | main | LEAVE 230 | CubeCL join start-up panics on an allocation, caught: "overlap join unavailable, every field stays on hand-CUDA"; then hand-CUDA OOM, **exit 1** | nothing |
| 15 | `main_stride_before_245/252/255` | main | LEAVE 245–255 | join starts; hand-CUDA's first allocation fails, **exit 1** | nothing |
| 16 | `main_stride_before_256/260/300`, `main_stride_g_after_*`, `main_stride_g3_after_long`, `main_stride_g_between_q4`, `…_qsmall_then54` | main | LEAVE ≥ 256; greedy hog after or between | normal | 4/4 (or 5/5); ctl up to 24,661 per run, all `[69]` |
| 17 | `main_stride_g_between_qmix{,_2,_6,_10,_16,_24}` | main | greedy hog after the first b54 submission (LEAVE 0–24); later fields are b62, then b64 | **mid-run failure**: the b64 plan upload (5.8 MB residues, 11.5 MB masks) hits `OUT_OF_MEMORY` in the dispatch thread. The error goes into `first_error`, the next `End` (the b62 field, still open) takes it, and the client logs `GPU processing error` and **exits 1** | the 2 b54 fields that ran before the squeeze (correct); **b62 and b64 not submitted** |

Row 17 is a real mid-run allocation failure on the hand-CUDA stride path. The field that had already run was failed too and not submitted, which is safe in the conservative direction.

Across all 88 runs: no b54 field came back with fewer launches or a lower `valid_numbers` than the healthy runs' spread, and no base-10 field came back without 69.

## Why the squeeze could only reach start-up and new plans

After hand-CUDA's first nice-only allocation, the process holds about 256 MiB. That is the CUDA context, the modules, and cudarc's stream-ordered pool (`cuMemAllocAsync`). From then on, the per-field buffers come from that pool: the 1 MiB output buffer and the roughly 1.3 MB descriptor batches.
- A competing process cannot take that memory. hog2 and hog3 polled for freed memory for 30 s and never gained a byte.
- The working set does not grow with load (row 11).

So allocations fail at three points only:
1. context creation;
2. the first nice-only allocation;
3. a plan for a new base that does not fit the pool (row 17, seen on main; v3.4.5's plans fitted).

All three were reached, and all three exit 1.

## Not covered

- **Allocation failures after a field's buffers exist.** Failures in `begin_field`'s `alloc_zeros` or in a descriptor `clone_htod`, once the pool is up, could not be provoked. The code propagates them with `?` (points 3–5 above), but I did not observe them.
- **Failures that are not allocations.**
  - `cuLaunchKernel` returning an error (out of resources, invalid configuration);
  - a fault inside a kernel (illegal address, a sticky context error);
  - an Xid, a GPU reset, an ECC error.

  None of these can be produced from outside the process without changing code. In the code they come back from `launch(cfg)?` or from `end.synchronize()?` in `wait`, and fail the field.
- **`auto` falling through on a context-creation failure** (rows 2–3; v3.4.5 only, main's explicit `cuda` exits).
  - With a usable Vulkan driver, v3.4.5 continues on CubeCL wgpu: llvmpipe here, or the real GPU on a box whose container exposes NVIDIA's Vulkan.
  - That is CubeCL's stride path, not hand-CUDA. Its submissions would carry backend `cubecl`, not `cuda`, so the 15,046 `cuda` rows in the census were hand-CUDA runs.
  - CubeCL wgpu on a real GPU under memory pressure was not measured, here or two nights ago (ALLOC-FAILURE.md (d)). This container's NVIDIA Vulkan ICD cannot be loaded (no graphics capability).
- **Other cards, drivers and pool behaviour.** Only one card, driver 580, cudarc 0.19.9/0.19.10. Older drivers without `cuMemAllocAsync` use cudarc's synchronous `cuMemAlloc`/`cuMemFree` path. That path frees memory back to the device, so a hog could take it between fields. The errors would still be returned (`malloc_sync(...)?`), but this path was not run.

## Fix

None is needed for soundness. Two small improvements, described only:
- v3.4.5-style `auto` should log a CUDA context failure on an NVIDIA box as a warning, not info.
- Hand-CUDA could adopt the cube-count account proposed for CubeCL (one atomic per block, checked in `wait`). That would also protect against a dropped launch that CUDA does not report, which is not known to happen.
