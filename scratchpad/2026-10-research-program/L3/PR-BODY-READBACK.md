# GPU detailed mode: read back only the near-misses that were written

After every detailed field, the `CubeCL` path (`detailed_impl`, which `--gpu-backend auto` runs on NVIDIA, AMD and Apple GPUs) copied the whole near-miss buffer back to the host: `NEAR_MISS_CAPACITY` = 2^20 records of five u32, 20 MB, whatever the count. The count is almost always zero at the live bases: the `b40_detailed` and `b50_detailed` benchmark windows have none, and neither did the 1e10-number fields at the start of bases 50 and 52 timed below. On the RTX 3080 below (PCIe 3.0 ×16) that copy costs about 1.7 ms per field, close to a tenth of a 2e8-number benchmark window. This PR reads the count first, as before, then only the `count` records the kernel wrote (`Handle::offset_end` trims the read to that prefix), and nothing at all when the count is zero. The hand-CUDA backend already skipped the read at zero; when there are near-misses it now copies only the written records too (`CudaSlice::slice`) instead of both 2^20-entry buffers.

Why nothing can be lost: the kernel takes a slot with an atomic `fetch_add` on the count for every near-miss and writes the record only if the slot is below the capacity, and the host already refuses a count above the capacity. So a count within the capacity means slots `0..count` hold exactly the records written and nothing at or above `count` was. The host now also checks that the read returned exactly `count` × 5 words. Record order on the device was never deterministic; the host sorts the list as before.

## Measured

RTX 3080 (20 GB board), driver 580.126.18, CUDA 12.8, PCIe 3.0 ×16, Xeon E5-2673 v4 host. The board's power limit is its default, 320 W, and the detailed kernel runs into it: `nvidia-smi` reports "SW Power Cap: Active" at about 318 W, with the SM clock at 1.75–1.88 GHz (max 2.1 GHz). Rust 1.99.1, release profile, `--features gpu`; `--gpu-backend auto` picked `CubeCL` CUDA. A is `main` (46e4dc4), B is this branch, same box, interleaved A B A B A B (the stacked finite-difference branch ran in between, as a third arm). `nice_client detailed --gpu --benchmark --benchmark-secs 150`; rates in numbers per second; spread is the lowest and highest round relative to the median.

| scenario | A rounds | A median (spread) | B rounds | B median (spread) | B / A |
|---|---|---|---|---|---|
| b40_detailed | 1.039e10 1.018e10 1.013e10 | 1.018e10 (−0.5/+2.1 %) | 1.108e10 1.106e10 1.114e10 | 1.108e10 (−0.2/+0.5 %) | **1.088×** |
| b50_detailed | 7.521e9 7.512e9 7.483e9 | 7.512e9 (−0.4/+0.1 %) | 7.980e9 8.093e9 8.052e9 | 8.052e9 (−0.9/+0.5 %) | **1.072×** |
| detailed GPU score | 4660 4609 4590 | 4609 (−0.4/+1.1 %) | 4956 4986 4991 | 4986 (−0.6/+0.1 %) | **1.082×** |

Per window that is 19.6 → 18.0 ms at base 40 and 26.6 → 24.8 ms at base 50: the copy is a fixed cost per field, so it matters in proportion to how short the field is. Through `process_range_detailed_cubecl` directly, same interleaving (median of five windows per round, three rounds):

| window | A | B | B / A |
|---|---|---|---|
| b40, 2e9 numbers from the range start | 1.126e10 (−1.3/+0.5 %) | 1.139e10 (−1.6/+0.3 %) | 1.012× |
| b50, 2e9 numbers from the range start | 8.252e9 (−0.6/+0.3 %) | 8.301e9 (−0.8/+0.2 %) | 1.006× |
| b50, one 1e10-number field (the server's cap), median of 6 | 1.218 s | 1.214 s | 1.003× |
| b52, one 1e10-number field, median of 6 | 1.288 s | 1.287 s | 1.001× |

So a production field gains nothing measurable today; the benchmark windows gain most, and so does any faster kernel, since the copy does not shrink with it (the finite-difference kernel proposed on top of this branch runs a 1e10 field in 0.32 s). Results were identical on every window (the same hash of distribution and near-miss list across both trees). No scenario regresses.

## Exactness

- `cubecl_reads_back_every_near_miss` (wgpu) and `cubecl_cuda_reads_back_every_near_miss` (CUDA runtime): the whole range of every base from 10 to 24 (2.24 million numbers, 27 near-misses), and to 28 under CUDA (76 million numbers, 73 near-misses), against `process_range_detailed`: distribution and near-miss list identical. These are the windows with near-misses inside the legal range. Of the existing parity tests' windows, base 10's (1e6 numbers from 47, almost all past the range end) has 556,846 near-misses, so it reads back more than half the buffer, and the base 40, 62 and 80 windows have none, the zero-count path.
- `gpu_reads_back_every_near_miss` (hand-CUDA): bases 10 to 24 in full, identical.
- Run on the RTX 3080 above: both CUDA tests, the hand-CUDA test, and the existing `cubecl_cuda_matches_cpu_detailed` and `gpu_matches_cpu_detailed_small` pass. On lavapipe (llvmpipe, LLVM 20.1.2): `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` pass; pinned to 4 cores like a hosted runner (`taskset`, `LP_NUM_THREADS=4`), the new test takes 3.9 s.

## Not in this PR

- The browser kernel (`cubecl_web.rs`) reads its near-miss buffer in the same round trip as the histogram, on purpose (one queue drain per field in a browser); it is 160 KB there.
- The nice-only path's hit buffer (1 MB per field, about 0.1 ms).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
