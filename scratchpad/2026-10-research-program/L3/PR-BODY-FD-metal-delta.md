# PR #225 body: the Metal delta (2026-10-30)

These are the edits to the live PR body, which is identical to `PR-BODY-FD.md` before this change, for the Metal gate
(commit d8038d6, now the head of `pr/gpu-detailed-fd`). `PR-BODY-FD.md` already has them. Five places:

1. **"Where it runs"** bullet: one clause, "…so production fields run entirely on the new kernel**, except on Metal
   adapters (see Portability)**."
2. **Exactness**: a new bullet after the lavapipe bullet, "With the Metal gate (the second commit)…", giving the CUDA
   and lavapipe tests and the speed A/B.
3. **Portability**: the "Metal: not run" bullet is replaced by "**Metal: off.**…".
4. **Portability**: the speed bullet now says AMD only, and gives the M4 speed-up a fix would recover.
5. **Not in this PR**: "Measurements on AMD or Apple GPUs" becomes an Apple GPUs bullet (with the likely fix) and
   "Measurements on AMD GPUs".

**Also stale, not edited:** the opening line still says the PR is stacked on the readback branch and is "the one commit
on top of it".
- The readback branch is merged as #224 (946ec15), and the PR is now two commits on `main`.
- The measurements' "B" tree is the readback branch, which is what `main` now is.

Suggested opening: "Two commits on `main`: the finite-difference kernel, and a gate that keeps Apple GPUs on the
per-number kernel (see Portability). The measurements below compare against `main` (46e4dc4) and the readback branch,
since merged as #224."

## The new text, as it stands in PR-BODY-FD.md

- **With the Metal gate (the second commit).**
  - **CUDA** (RTX 3080, driver 595.91.07): `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and `cubecl_cuda_reads_back_every_near_miss` pass, and the client's debug log shows the new kernel serving every benchmark window.
  - **lavapipe:** `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` pass, and the client's production path still takes the new kernel.
  - **Lib suite:** 210 passed, including the new `detailed_kernel_by_device`.
  - **Speed is unchanged.** 60 s benchmarks, interleaved without the gate and with it:

    | | without the gate | with the gate |
    |---|---|---|
    | b40 | 3.331e10 to 3.467e10 | 3.339e10 |
    | b50 | 2.968e10 to 3.044e10 | 2.968e10 to 2.976e10 |
    | score | 16,571 to 17,121 | 16,591 to 16,614 |

    The highest run without the gate was the first, on a cold card.

...

## Portability

The kernel needs nothing the per-number kernel does not already need on every backend: u32 arithmetic in the hot loop; u64 add, multiply and shift for the start, the seed's limb products and the digit mask (`shader-int64` on wgpu, which the native per-number kernel already requires; the browser keeps its u32-only kernel); and a u64 division only in the seed, only on CUDA and HIP. On wgpu the seed uses the split16 division, so no u64 division reaches WGSL, SPIR-V or MSL unless `NICE_CUBECL_WIDE=1` asks for it, exactly as with the per-number kernel. In the WGSL `CubeCL` generates for it (dumped on lavapipe at bases 10, 40 and 62), every division is by a u32 constant; naga 29.0.4, the version wgpu uses here, validates that WGSL and translates it to MSL (default and `--metal-version 2.4`) and to SPIR-V, as it does the per-number kernel's.

- CUDA: run on the RTX 3080 (NVRTC 12.8).
- Vulkan: run on lavapipe through both compilers, as above.
- **Metal: off.** The new kernel gives wrong results on an Apple M4, so detailed fields on any Metal adapter keep the per-number kernel, exactly as on `main`.
  - **Device.** Apple M4, macOS 26.3, through wgpu with naga's MSL.
  - **Failures.** `cubecl_fd_matches_cpu_detailed` fails at the base 50 range start, and `cubecl_reads_back_every_near_miss` fails at base 23.
  - **Sweep.** 1e5 numbers at the start and middle of every base from 10 to 64. The new kernel is wrong at bases 23, 27–30, 49 (mid-range), 50, 52 (mid-range) and 53–55, with most unique counts off by 1 to 4; the per-number kernel is exact in every window.
  - **The fault is in the seed or the mask build.** The kernel fails even at one number per run, so the stepping is not to blame.
  - **Elsewhere it is exact.** The same code passes on CUDA, on lavapipe, and on the macOS CI runner's paravirtual Metal device (macOS 26.6.2), through naga's MSL and through `CubeCL`'s own MSL compiler.
  - **Suspected cause (not yet shown on the device).** In the seed's digit conversion, the division `(x >> 16) / K` of the top word x of n² and n³ is computed from the low 16 bits of x. Modelling that reproduces the M4's histograms exactly in every window except base 23's. It is the 16-bit form of a Metal miscompilation seen before on the same machine, where `hi(a·b) / K` divides the low word.
  - **The gate.** `DetailedKernel::for_device` checks the adapter's wgpu backend. CUDA, HIP and the other wgpu backends keep the new kernel.
  - **Before lifting it,** `cubecl_fd_matches_cpu_detailed` (which runs the new kernel on any wgpu device) has to pass on Apple hardware.
- HIP: the same code path as CUDA (`wide_chunk_for` picks the u64 seed there); not built or run (no ROCm here).
- Speed is not measured on AMD GPUs. Through wgpu they take the split16 seed: by count about 530 u32 divisions per run at base 50, about 4 per number at 128 per run, against about 200 per number in the per-number kernel's split16 scan. On the M4, before the gate, the new kernel ran 3.0× (base 40) and 4.5× (base 50) faster than `main` on the benchmark windows. That is the speed a fix would recover; the base 50 figure came from wrong results.

## Not in this PR

- The hand-CUDA backend (`--gpu-backend cuda`) and the browser kernel (`cubecl_web.rs`, u32 only): both still divide per number.
- Bases above 64: the per-number kernel, as before.
- **Apple GPUs.** The new kernel stays off on Metal until the miscompilation is understood and worked around.
  - The likely fix is to convert the seed to digits the way the per-number kernel does: through shared memory, in a runtime loop. That code is exact on the M4 in every window.
  - The seed is about 5 % of a run, so a slower conversion costs little.
- Measurements on AMD GPUs.

## Unified diff against the live body

```diff
--- PR-BODY-FD.md (live PR body)	2026-10-30 16:18:54.750698023 +0000
+++ PR-BODY-FD.md	2026-10-30 16:31:49.194147612 +0000
@@ -8,7 +8,7 @@
 - **Digit arrays.** The five values live in registers as base-b digits, four per u32 (one byte lane each, little-endian). An addition is biased, as on the CPU: adding 256 − b to every byte makes a lane overflow into the next exactly when its digit sum reaches b, so one native add carries four digits, and `t − ((t >> 7) & 0x01010101) · (256 − b)` takes the bias back from the lanes that did not carry (bit 7 of a lane is clear exactly when it carried, for b ≤ 128). No compare or select per digit.
 - **Cached high words.** Words of S and C above the addend's width change only when a carry ripples through four digits of b − 1. Their part of the digit mask is computed once per run, and each step's five additions return the raw sum of their last fast word; one AND of those sums guards a single, rare branch that does every ripple and refreshes the cached mask. The hot loop masks 36 digits per number at base 50 instead of 50, with one branch per step.
 - **Mask, histogram, near-misses.** Unchanged from the per-number kernel: `m |= 1u64 << d` per digit, two `count_ones`, one shared-memory atomic into the 4-copy workgroup histogram, and the same near-miss records.
-- **Where it runs.** `fd_plan(base)` computes, with exact integer roots, the interval where n² has exactly `ls` digits and n³ exactly `lc`, and the widths of the three addends at the interval's top. `detailed_impl` sends the part of each batch inside that interval to the new kernel and anything outside it to the per-number kernel. The interval is exactly the legal range at every base from 10 to 64 (the two digit counts sum to the base and neither can fall, so neither can rise), so production fields run entirely on the new kernel. The per-number kernel stays for bases above 64, whose mask needs two words, for candidates outside a base's range (tests only), and as the reference in the tests (`DetailedKernel::Division`).
+- **Where it runs.** `fd_plan(base)` computes, with exact integer roots, the interval where n² has exactly `ls` digits and n³ exactly `lc`, and the widths of the three addends at the interval's top. `detailed_impl` sends the part of each batch inside that interval to the new kernel and anything outside it to the per-number kernel. The interval is exactly the legal range at every base from 10 to 64 (the two digit counts sum to the base and neither can fall, so neither can rise), so production fields run entirely on the new kernel, except on Metal adapters (see Portability). The per-number kernel stays for bases above 64, whose mask needs two words, for candidates outside a base's range (tests only), and as the reference in the tests (`DetailedKernel::Division`).
 
 Measured on an RTX 3080 at its default 320 W power limit, the new kernel is 3.0× (base 40) and 3.7× (base 50) faster than the readback branch on the benchmark's detailed GPU windows (3.3× and 4.0× faster than `main`), and a production field of 1e10 numbers at base 50 takes 0.32 s instead of 1.22 s.
 
@@ -68,6 +68,19 @@
 - `plan_covers_exactly_the_legal_range` (normal suite, no GPU): the plan's interval equals the legal range at all 44 bases from 10 to 64 that have one, and there is no plan above 64.
 - The existing parity tests pass through the new default: `cubecl_cuda_matches_cpu_detailed` (base 10 1e6 from the range start, which runs 53 numbers on the new kernel and the rest, past the range end, on the per-number kernel, with 556,846 near-misses; b40 2e6; b62 2e5 with a three-limb n; b80 on the per-number kernel), `cubecl_cuda_reads_back_every_near_miss`, and the whole `nice_common` lib suite (209 passed).
 - On lavapipe (llvmpipe, LLVM 20.1.2): `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` (which compares the browser kernel with the native path, now this kernel, at base 49) pass through naga's WGSL path (wgpu's default compiler, as in a `--features cubecl` build; 15 s) and through `CubeCL`'s SPIR-V compiler (`--features cubecl-spirv`, 20 s; the device reports `wgpu<spirv>`). The first two pass again under SPIR-V with `NICE_CUBECL_WIDE=1`, which makes the seed divide in u64 (`wide_chunk: true` in the compile log). Every ignored test the lavapipe CI job runs (19, from the `--features gpu` test binary minus the CUDA, hand-CUDA and timing ones; the nice-only and join tests included) passes on this branch. Pinned to 4 cores (`taskset`, `LP_NUM_THREADS=4`, like a hosted runner) `cubecl_fd_matches_cpu_detailed` takes 7.4 s and `cubecl_reads_back_every_near_miss` 3.2 s.
+- **With the Metal gate (the second commit).**
+  - **CUDA** (RTX 3080, driver 595.91.07): `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and `cubecl_cuda_reads_back_every_near_miss` pass, and the client's debug log shows the new kernel serving every benchmark window.
+  - **lavapipe:** `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10` and `web_kernel_near_miss_matches_cpu_at_base_49` pass, and the client's production path still takes the new kernel.
+  - **Lib suite:** 210 passed, including the new `detailed_kernel_by_device`.
+  - **Speed is unchanged.** 60 s benchmarks, interleaved without the gate and with it:
+
+    | | without the gate | with the gate |
+    |---|---|---|
+    | b40 | 3.331e10 to 3.467e10 | 3.339e10 |
+    | b50 | 2.968e10 to 3.044e10 | 2.968e10 to 2.976e10 |
+    | score | 16,571 to 17,121 | 16,591 to 16,614 |
+
+    The highest run without the gate was the first, on a cold card.
 
 ## Portability
 
@@ -75,14 +88,25 @@
 
 - CUDA: run on the RTX 3080 (NVRTC 12.8).
 - Vulkan: run on lavapipe through both compilers, as above.
-- Metal: not run (no Mac here). The macOS job of the GPU parity workflow runs the new wgpu tests through naga's MSL backend (`--features cubecl`) and `CubeCL`'s MSL compiler (`--features cubecl-metal`); the naga translation above is the only Metal check made before that.
+- **Metal: off.** The new kernel gives wrong results on an Apple M4, so detailed fields on any Metal adapter keep the per-number kernel, exactly as on `main`.
+  - **Device.** Apple M4, macOS 26.3, through wgpu with naga's MSL.
+  - **Failures.** `cubecl_fd_matches_cpu_detailed` fails at the base 50 range start, and `cubecl_reads_back_every_near_miss` fails at base 23.
+  - **Sweep.** 1e5 numbers at the start and middle of every base from 10 to 64. The new kernel is wrong at bases 23, 27–30, 49 (mid-range), 50, 52 (mid-range) and 53–55, with most unique counts off by 1 to 4; the per-number kernel is exact in every window.
+  - **The fault is in the seed or the mask build.** The kernel fails even at one number per run, so the stepping is not to blame.
+  - **Elsewhere it is exact.** The same code passes on CUDA, on lavapipe, and on the macOS CI runner's paravirtual Metal device (macOS 26.6.2), through naga's MSL and through `CubeCL`'s own MSL compiler.
+  - **Suspected cause (not yet shown on the device).** In the seed's digit conversion, the division `(x >> 16) / K` of the top word x of n² and n³ is computed from the low 16 bits of x. Modelling that reproduces the M4's histograms exactly in every window except base 23's. It is the 16-bit form of a Metal miscompilation seen before on the same machine, where `hi(a·b) / K` divides the low word.
+  - **The gate.** `DetailedKernel::for_device` checks the adapter's wgpu backend. CUDA, HIP and the other wgpu backends keep the new kernel.
+  - **Before lifting it,** `cubecl_fd_matches_cpu_detailed` (which runs the new kernel on any wgpu device) has to pass on Apple hardware.
 - HIP: the same code path as CUDA (`wide_chunk_for` picks the u64 seed there); not built or run (no ROCm here).
-- Speed is not measured on AMD or Apple GPUs. Through wgpu (Vulkan, Metal) they take the split16 seed: by count about 530 u32 divisions per run at base 50, about 4 per number at 128 per run, against about 200 per number in the per-number kernel's split16 scan.
+- Speed is not measured on AMD GPUs. Through wgpu they take the split16 seed: by count about 530 u32 divisions per run at base 50, about 4 per number at 128 per run, against about 200 per number in the per-number kernel's split16 scan. On the M4, before the gate, the new kernel ran 3.0× (base 40) and 4.5× (base 50) faster than `main` on the benchmark windows. That is the speed a fix would recover; the base 50 figure came from wrong results.
 
 ## Not in this PR
 
 - The hand-CUDA backend (`--gpu-backend cuda`) and the browser kernel (`cubecl_web.rs`, u32 only): both still divide per number.
 - Bases above 64: the per-number kernel, as before.
-- Measurements on AMD or Apple GPUs.
+- **Apple GPUs.** The new kernel stays off on Metal until the miscompilation is understood and worked around.
+  - The likely fix is to convert the seed to digits the way the per-number kernel does: through shared memory, in a runtime loop. That code is exact on the M4 in every window.
+  - The seed is about 5 % of a run, so a slower conversion costs little.
+- Measurements on AMD GPUs.
 
 🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
