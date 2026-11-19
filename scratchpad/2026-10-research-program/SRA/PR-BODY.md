## Stride walk: fail a field whose kernel launches did not all run

### The defect

On the CubeCL CUDA runtime (CubeCL 0.10), a buffer allocation that fails leaves the client holding a handle to memory that does not exist. Every later launch that binds it panics inside CubeCL's device thread, is logged as `WARN … Task failed: Any { .. }` and dropped, and `client.sync()` still returns `Ok`. Reads of the buffers that did allocate succeed and return them unchanged: zeros.

The overlap join catches this: each kernel counts the cubes that finished and the host compares them with the cubes it launched (`JoinDevice::ensure_ran`). The nice-only stride path (`niceonly_kernel` in `common/src/cubecl_backend.rs`) had no such count. Its survivor-queue account balances at zero when nothing ran and its hit count is zero, so the field was submitted as searched and empty. Production routes nice-only fields below the join's minimum size, and bases outside the join's range, to this path.

### Reproduction (RTX 3080 20 GB, CUDA 12.8, `gpu,cubecl-cuda`)

A small CUDA program holds all but a few hundred MiB of the card before the client starts; the client talks to a local stand-in for the API.

| field | memory left | v3.4.8 | this branch |
|---|---|---|---|
| b62 5e12, normal routing | 290 MiB | every launch dropped (`Task failed` ×45), submitted `[]` | `stride walk b62: the device did not run every launch: its kernels finished 0 of 200319 cubes`, exit 1, nothing submitted |
| b64 1e13, `NICE_JOIN_ROUTE=stride` | 400 MiB | ×71, device wait 0.13 s (2.6 s normally), submitted `[]` | `… finished 0 of 277280 cubes`, exit 1, nothing submitted |
| b64 1e13, `NICE_JOIN_ROUTE=stride` | 520 MiB | ×92, submitted `[]` | `… finished 0 of 282373 cubes`, exit 1, nothing submitted |

### The fix

The join's rule, applied to the stride kernel:

- **Kernel:** at the end of `niceonly_kernel`, after all three of its paths (plain, cube-scoped queue, plane-scoped queue), each cube waits for its units (`sync_cube`) and unit 0 adds 1 to a fourth word of the field's count buffer. Per cube, by unit 0, which every cube has, so partly filled planes change nothing; an atomic add, not a store.
- **Host:** `CubeclNiceonlyRun` adds up the cubes it launches, and `read_niceonly_hits` (the only reader of a stride field's result) requires the kernel's count to equal it before it reads the queue account and the hits; a mismatch fails the field with the message above. The comparison is mod 2^32; a field launches far fewer cubes than that.

No retry, no new flag or environment variable.

**Detailed mode** already has the equivalent check and is unchanged: every candidate adds 1 to one histogram bin, and the host requires the total to equal the range size.

### Tests

- `cubecl_dropped_launches_fail_the_field` (wgpu; runs in the lavapipe jobs with WGSL and SPIR-V) and `cubecl_cuda_dropped_launches_fail_the_field`: a test-only switch counts a launch without running it. On each stride path, a b50 field in two launches of 9 cubes each must fail when both are dropped ("0 of 18 cubes") and when the second is ("9 of 18"), and must return exactly the host mirror's survivors when none is. It fails with the host check removed, and with a kernel that counts once per launch instead of once per cube.
- `ran_complete_wants_every_launched_cube`: the check itself, without a device.
- `just lint` and the whole suite pass. Every stride and detailed device test passes on CUDA and on lavapipe with both compilers (one overlap-join CUDA test, untouched here, runs out of memory on a 20 GB card when run after the others, on main too).

On the card, healthy fields give identical results to v3.4.8; launch counts vary from run to run in both builds. Time, three interleaved rounds of three fields:

| | v3.4.8 | this branch |
|---|---|---|
| b62 5e12, 3 fields, median | 2.05 s | 2.14 s (round spread 0.44 s) |
| b64 1e13 forced stride, 3 fields, median | 7.80 s | 7.77 s |
| device wait, first field b62 / b64 | 0.71 / 2.60 s | 0.70 / 2.60 s |

### Vulkan and Metal: what has and has not run

- **Vulkan GPUs** with the SPIR-V compiler take the plane-scoped queue path by default. With the new count, that path has run on CUDA (passes) and on no real Vulkan GPU. Lavapipe cannot stand in: its plane-scoped path already loses survivors on main, independently of this change, which is why production keeps that path off on software rasterizers. If the count were wrong there, stride-path fields on such clients would stop with an error instead of being submitted. Before merging, someone with a Vulkan card should run:

  ```
  cargo test --release --features cubecl-spirv -p nice_common -- --ignored --nocapture cubecl_dropped_launches_fail_the_field cubecl_queues_check_every_survivor_on_partly_filled_planes
  ```

- **Metal:** not run on Apple hardware. This pull request's macOS CI job runs the new test and every stride device test through Metal (wgpu to Metal, and the direct MSL compiler); that is the only Metal evidence.

### Follow-ups (not included)

- Not included: a CUDA context that fails to initialise for lack of memory falls back to wgpu on the CPU rasterizer without an error.
- Not included: some allocation failures end in a host panic (`CallError` unwrapped, exit 101) rather than an error.
- Not included: the hand-written CUDA backend was not examined for the same gap.
- Not included: CUDA device tests share one client's memory pools per process, so a large join test can run out of memory after the others.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
