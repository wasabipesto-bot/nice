# L3 notes: detailed mode on the GPU (RTX 3080, 2026-10-28)

The box is the same Vast RTX 3080 as L1 (`../L1/GPU-RESULTS.md`), host Xeon E5-2658A v3. The code is
upstream `85b5b4e`. The binary is `cargo build --release -p nice_client --features gpu`, from the L1
working tree; the detailed path is untouched by the L1 instrumentation. All runs set
`NICE_API_BASE=http://127.0.0.1:9` and use non-interactive stdin, so nothing reached the real API and
nothing was uploaded. The driver script is `run_detailed.sh`; the raw logs are in `raw/`.

## 1. Rates

| run | backend | b40_detailed n/s | b50_detailed n/s | b50_detailed_1t n/s | NiceMark |
|---|---|---|---|---|---|
| GPU, `--benchmark-secs 120` | CubeCL CUDA | **1.040e10** | **7.802e9** | — | 4747 |
| GPU, `--benchmark-secs 300` (with dmon) | CubeCL CUDA | 1.040e10 | 7.758e9 | — | 4735 |
| CPU, `--benchmark-secs 120 --threads 16` | — | 4.403e7 | 2.864e7 | 1.865e6 | 1056 |

- **Backend.** `auto` picked the **CubeCL CUDA runtime**: `GPU initialized: CubeCL CUDA device 0, batch size 50000000` (RUST_LOG=info). That matches `client/src/main.rs:550`: detailed auto leads with `CubeclContext::new_cuda`, and hand-CUDA is only the third stop.
- **GPU against CPU.** The GPU is 236× (b40) and 273× (b50) the 16-thread CPU. The CPU scales 15.4× over one thread at b50.
- **CPU caveat.** The box has 48 logical CPUs visible and no cgroup quota, so the 16-thread CPU number may be affected by neighbours.

## 2. Utilisation (`nvidia-smi dmon -s um -d 2` during the 300 s run)

There are 137 samples at 2 s, 05:36:12–05:40:44, in `raw/dmon300.log`:

- **SM:** 98 % in 101 samples and 99 % in 34; the other 2 samples are the idle start and end.
- **Memory controller:** 0 % in every sample.
- **Framebuffer:** 433 MB in use.

dmon's `sm` is the fraction of time a kernel is resident, not ALU utilisation. The 1–2 % gap is the host
side: launch boundaries and the histogram drain every few batches. So the device is never starved, and
DRAM is idle. The 300 s rates equal the 120 s ones (b40 1.040e10 both times; b50 7.758e9 against 7.802e9,
−0.6 %), so there is no thermal or power drift. The board runs at a 260 W power limit (default 320 W).

## 3. The kernel (`detailed_kernel`, common/src/cubecl_backend.rs:80–350)

**Launch.** One thread per candidate, grid-stride:

- each dispatch covers `CUBECL_BATCH_SIZE` = 5e7 numbers;
- it runs `min(ceil(count/256), MAX_CUBES = 4096)` cubes of 256 threads (1,048,576 threads);
- so each thread checks about 48 consecutive-stride numbers per dispatch.

**Kernel specialisation.** `base`, `limbs`, `chunk_digits`, `chunk_div`, `cutoff` and `wide_chunk` are comptime parameters, so every limb loop unrolls and every division is by a constant.

**Powers.** n is split into u32 limbs: 2 at both b40 and b50, since n < 2^43 and n < 2^57. Then:

- n² (4 limbs) and n³ (6 limbs) come from fully unrolled schoolbook u32×u32→u64 multiply-adds;
- that is 4 + 8 products; this part is cheap.

**Digit extraction**, for each of n² and n³:

- the limbs are copied into a per-thread scratch row in **shared memory**, `sv_s`, padded to an odd stride against bank conflicts;
- the value is reduced by repeated long division by `chunk_div = b^5`, which is below 2^31 at b40 and b50;
- on CUDA, `wide_chunk` is set, so each step divides a 64-bit `rem<<32 | limb` by the constant; nvcc lowers that to a multiply-high sequence, with the remainder by multiply-subtract;
- one pass over the remaining limbs yields one 5-digit chunk;
- each chunk is split into digits with 32-bit divisions by the constant `b`.

Per number that is roughly:

- 20 (b40) to 30 (b50) 64-bit constant divisions;
- 40 or 50 32-bit constant divisions;
- a shared-memory load and store per limb step.

Most of this is IMAD/IMAD.HI work.

**Uniqueness.** Each digit ORs `1 << d` into a u64 mask (two masks above base 64). At the end, `u = popcount`.

There is no per-digit histogram and no early exit. Every digit of both powers is extracted even when a duplicate has already been seen. That is required, since detailed mode counts uniques rather than testing niceness.

**Histogram.** One shared-memory atomic per number into one of 4 copies of a (b+1)-bin workgroup histogram:

- the copy is chosen per warp, so all 32 lanes of a warp hit the same copy;
- same-bin lanes serialise in the atomic;
- the copies are reduced to the global histogram once per cube;
- near-misses (`u > cutoff`) take a global atomic and a 5-word store, which is rare.

**Divergence.** The digit loops are data-dependent (`while top >= 0`, the most-significant chunk's `while chunk != 0`). Consecutive n have equal digit lengths, so a warp stays converged.

## 4. Compute- or latency-bound?

It looks compute-bound on the integer pipe. Memory is ruled out. Latency is argued against by the
instruction count, not excluded: I could not confirm it with counters (see section 5).

- **Not memory.** The memory controller reads 0 %. The per-number working set is registers plus a 7-word shared row, and the only global traffic is one histogram reduction per cube.
- **Residency.** The kernel is resident 98–99 % of the time. dmon cannot tell a stalled resident kernel from a busy one, so this is no evidence either way on latency.
- **Issue budget.** The 3080 has 68 SMs × 64 INT32 lanes/clk × about 1.8 GHz ≈ 7.8e12 integer ops/s, so the measured rates allow about **750 integer ops per number at b40** and about **1,000 at b50**.
- **Instruction count.** Counting from the source:
  - b40: about 20 64-bit constant divisions at about 12–16 IMAD/IMAD.HI/shift each, plus 40 digit splits at about 4–5, plus 40 mask ORs;
  - b50: about 30 divisions and 50 digits.

  That comes to roughly 750–850 at b40 and 1,000–1,100 at b50, close to the issue budget. A latency-bound kernel would fall well short of it.
- **Scaling.** The b40:b50 rate ratio is 1.33. That lies between the digit-count ratio (1.25) and the long-division ratio (about 1.5), as an ALU-bound mix of the two would.
- **Smaller costs.** The shared atomic, the shared scratch traffic (about 50 LDS/STS per number) and the multiply are second-order next to the constant divisions.
- **Where the levers are.** The levers that would move this kernel are fewer divisions per digit: larger chunks, or a divide-and-conquer split of n³. Memory or launch tuning would not move it.

## 5. Cheap probes, if L3 goes further

None of these were run here.

- **Profiler.** `ncu` exists in the image (`/usr/local/cuda/bin/ncu`), but Vast blocks the counters: `ERR_NVGPUCTRPERM`. Instruction mix and stall reasons need a host with profiling enabled, such as an Anvil node or a rental that allows it.
- **Histogram atomic.** Warp-aggregate it (`plane` match or ballot per bin before one atomic) and count how much the 4 copies actually help.
- **Shared scratch.** `sv_s` costs a shared load and store per limb step, about 50 per number. With 2-limb n and comptime bounds, the n² scan could stay in registers if the limb index were made comptime. That needs a fixed-trip unrolled division instead of the `while top >= 0` loop.
- **Fewer long divisions.** Use a divide-and-conquer split of n³: one division by `b^k` into two halves, then scan each half with 64-bit arithmetic. That replaces the O(limbs × chunks) long-division sweep.
