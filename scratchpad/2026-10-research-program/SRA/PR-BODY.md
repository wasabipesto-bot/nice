## Stride walk: fail a field whose kernel launches did not all run

### The defect

On the CubeCL CUDA runtime (CubeCL 0.10), a buffer allocation that fails leaves the client holding a handle to memory that does not exist. Every later launch that binds that handle panics inside CubeCL's device thread, is logged as `WARN … Task failed: Any { .. }` and dropped, and `client.sync()` still returns `Ok`, because on CUDA the panic is not recorded as a stream error. Reads of the buffers that did allocate succeed and return what the dropped kernels would have changed: zeros.

The overlap join already catches this: every join kernel counts the cubes that finished, and the host compares that with the cubes it launched before it accepts a batch (`JoinDevice::ensure_ran`). The nice-only **stride path** (`niceonly_kernel` in `common/src/cubecl_backend.rs`) had no such account. Its only device-side account, the survivor queues' (`queue_complete`), balances at zero when nothing ran, and its hit count is zero too, so a field whose launches were all dropped was submitted as searched and empty, with no error. The stride path is what production uses for nice-only fields below the join's minimum size and for bases outside the join's range, so a client could submit such a field with no override set.

### Reproduction (RTX 3080 20 GB, CUDA 12.8, client built with `gpu,cubecl-cuda`)

A small CUDA program holds all but a few hundred MiB of the card's memory before the client starts; the client talks to a local stand-in for the API.

| field | memory left | v3.4.8 | this branch |
|---|---|---|---|
| b62, 5e12 (stride by routing, no override) | 290 MiB | every launch dropped (`Task failed` ×45, device wait 0.08 s), submitted `nice_numbers: []` | `GPU processing error: stride walk b62: the device did not run every launch: its kernels finished 0 of 200319 cubes`, exit 1, nothing submitted |
| b64, 1e13, `NICE_JOIN_ROUTE=stride` | 400 MiB | every launch dropped (`Task failed` ×71, device wait 0.13 s against 2.6 s normally), submitted `[]` | `… stride walk b64: … finished 0 of 277280 cubes`, exit 1, nothing submitted |
| b64, 1e13, `NICE_JOIN_ROUTE=stride` | 520 MiB | every launch dropped (`Task failed` ×92), submitted `[]` | `… finished 0 of 282373 cubes`, exit 1, nothing submitted |

### The fix

The rule the join already uses, applied to the stride kernel:

- **Kernel:** at its end, each cube of `niceonly_kernel` waits for all its units (`sync_cube`) and unit 0 adds 1 to a fourth word of the field's count buffer (`nice_count[3]`). This runs after all three of the kernel's paths (plain, cube-scoped queue, plane-scoped queue). It counts per cube, by unit 0, which every cube has, so a partly filled plane or a cube without a full warp changes nothing. It is an atomic add, not a store, so the SPIR-V compiler's merging of identical atomic stores cannot touch it. One atomic per cube (at most 4096 per launch).
- **Host:** `CubeclNiceonlyRun` adds up the cubes it launches for the field, and `read_niceonly_hits`, which every consumer of a stride field's result goes through (the pipeline's `CubeclPendingField::wait` and the device tests), requires the kernel's count to equal it (mod 2^32; one launch is at most 4096 cubes, so a dropped launch cannot wrap it) before it reads the queue account and the hits. A mismatch is an error in the style of the join's: `stride walk b{base}: the device did not run every launch: its kernels finished {ran} of {launched} cubes`. The field fails and nothing is submitted.

No retry, no new flag or environment variable, nothing changes on a healthy device.

**Detailed mode** already has the equivalent account and is unchanged: every candidate adds 1 to exactly one histogram bin, and the host fails the field unless the histogram's total equals the range size (`GPU histogram counted … of … candidates; the device dropped work`). A dropped launch leaves its candidates out of the histogram, so it cannot be accepted. The browser runner's detailed path has the same check.

### Tests

- `cubecl_dropped_launches_fail_the_field` (wgpu, runs in the lavapipe jobs with both the WGSL and the SPIR-V compiler) and `cubecl_cuda_dropped_launches_fail_the_field`: a test-only switch makes `launch` count a launch without running it, as the device does when it drops one. On each path of the stride kernel (plain, cube-scoped queue, and the plane-scoped queue where the device runs it), a b50 field split into two launches must fail through the pipeline's own `wait` when both launches are dropped and when only the second is, and must return exactly the host mirror's survivors when none is. With the host's check removed, both tests fail (the field comes back `Ok`).
- `ran_complete_wants_every_launched_cube`: the check itself, without a device.
- Every existing stride-path device test now also passes through the account, including the partly-filled-plane tests (cubes of 100, 48 and 36 units; ballot and scan forms on lavapipe, ballot on CUDA).
- `just lint` passes; the whole suite passes (`cargo test -p "*"`, and the `gpu`-feature unit tests); the device tests pass on lavapipe with both compilers and, for the stride and detailed paths, on CUDA (RTX 3080). On a 20 GB card one overlap-join device test (`cubecl_cuda_top_fd_matches_the_top_kernel`) fails on a 5 GB allocation when it runs after the others in the same process, on main as well; it passes alone.

On the card, healthy fields are unchanged against v3.4.8 (b62 5e12 by routing and forced-stride b64 1e13, three rounds of three fields each, interleaved): the same results and launch counts per field, and the same time within noise:

| field | v3.4.8 | this branch |
|---|---|---|
| b62 5e12, 3 fields per round, median of 3 rounds | 2.05 s | 2.14 s (rounds 2.10–2.45; v3.4.8's 2.05–2.49) |
| b64 1e13 forced stride, 3 fields, median | 7.80 s | 7.77 s |
| device wait per field, b62 / b64 (first field) | 0.71 / 2.60 s | 0.70 / 2.60 s |

About 5,900 small base-10 fields also went through the stride path on CUDA, each finding 69 with the account satisfied.

### What a wgpu device should expect

Nothing new on a healthy device: one cube barrier and at most one atomic add per cube, at the end of the kernel, and one comparison per field. On wgpu, CubeCL's server records a launch whose buffers cannot be bound as a stream error, so the launch fences should already fail such a field (read from the code; a software rasterizer cannot be pushed out of GPU memory to measure it); the new count is a second check there. Metal: the crate builds with `cubecl-metal`, but the kernel's MSL is generated at run time and was not run on an Apple device; the added code is the same barrier-and-atomic the survivor queues' account already runs there.

### Follow-ups (not included)

- Not included: a CUDA context that fails to initialise for lack of memory falls back to wgpu on the CPU rasterizer without an error, which is correct but very slow.
- Not included: some allocation failures end in a host panic (`CallError` unwrapped, exit 101) rather than an error.
- Not included: the hand-written CUDA backend was not examined for the same gap.
- Not included: the CUDA device tests share one client's memory pools per process, so a large join test can run out of memory after the others on a 20 GB card.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
