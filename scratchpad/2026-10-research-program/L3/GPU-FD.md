# L3 GPU-FD: finite-difference detailed kernel on the GPU (RTX 3080, 2026-10-30)

**Verdict: PROCEED to a PR.** The exact finite-difference (FD) kernel, at its best variant (v3, run
length R = 128), beats the current CubeCL detailed kernel by:

| measure | b40 | b50 |
|---|---|---|
| benchmark harness, production host path | **2.60×** | **3.22×** |
| harness, both arms with the trimmed near-miss read (section 6) | 3.22× | 3.97× |
| 2e9-number window (kernel-dominated) | 3.28× | 3.97–4.03× |

The kill criterion was under 1.3× at b50. Every comparison is exact: whole `FieldResults` against
`process_range_detailed`, on all windows, for every variant and option set.

Branch `exp/gpu-detailed-fd` on `fork` (wasabipesto-bot/nice), head `e0c1b4c`. It is five commits on
origin/main `d1ff798`: `3c3ebcf` v1, `96cbe8d` v2, `6d0d2c7` v3, `aeb4d21` v4 plus the trimmed
near-miss read, and `e0c1b4c` clippy allows. Everything is in `common/src/cubecl_backend.rs`. Raw logs
are in `raw-fd/`.

## 1. Setup

- **Box.** Vast instance 58350503 `nice-research-l3-gpu-fd`: RTX 3080, driver 580.159.03, CUDA 12.8
  toolkit, Xeon E5-2630 v4 host, PCIe gen 3 ×16.
- **Power cap.** The board's power limit is **180 W** (default 340 W). Every timed run sat at 179 W, so
  clocks depend on the kernel (section 5).
  - This box is slower than L3's 260 W box: the old kernel runs b40 at 7.9e9 here, against 1.04e10 there.
  - Compare ratios between boxes, not rates.
- **Builds.** Built on the box from the branch.
  - The timed binary uses the release profile with `CARGO_PROFILE_RELEASE_LTO=false`, `CODEGEN_UNITS=16`
    and incremental builds, for iteration speed. The GPU kernels are JIT-compiled by NVRTC either way, so
    that profile changes only host code.
  - Check: an origin/main production-profile binary ("main") and this build's old path ("old") measured
    7.882e9 against 7.800e9 at b40, and 5.803e9 against 5.791e9 at b50 (`raw-fd/ab1`). That is within noise.
- **Isolation.** All runs set `NICE_API_BASE=http://127.0.0.1:9` and use non-interactive stdin. Nothing
  reached the API and nothing was uploaded.

## 2. Design

`detailed_fd_kernel` has one thread per run of R consecutive candidates; there are ceil(count/R)
threads in 256-wide cubes, with grid-stride over runs.

**State.** Five base-b digit arrays, **packed four digits per u32** (one byte lane each,
little-endian), in registers. Every index is comptime after unrolling.

| array | value | b40 digits / words | b50 digits / words |
|---|---|---|---|
| S | n² | 16 / 4 | 20 / 5 |
| C | n³ | 24 / 6 | 30 / 8 |
| dS | 2n+1 | 9 / 3 | 11 / 3 |
| dC | 3n²+3n+1 | 17 / 5 | 21 / 6 |
| ddC | 6n+6 | 9 / 3 | 11 / 3 |

That is 21 words at b40 and 25 at b50.

**Seed.** Once per run, the kernel computes the exact limbs of n, n², n³, 2n+1, 3n²+3n+1 and 6n+6, using
the existing schoolbook multiply. It then converts each to packed digits with the existing u64-by-b⁵
long division. That is about 100 u64 constant divisions per run at b50, roughly 1,500–2,000 instructions,
or about 5 % of the per-number work at R = 128 by count. The R sweep (section 4) is flat from 64 to 512,
so the seed is not what limits it.

**Step.** S += dS; dS += 2; C += dC; dC += ddC; ddC += 6.

**Digit add.** This is the biased-byte add from L2, on 32-bit words:
- `t = x + y + (256−b)·0x01010101 + cin`, one native add for four digits.
- For b ≤ 128, a lane that carried out holds a value below b (bit 7 clear). A lane that did not holds at
  least 256−b (bit 7 set).
- So `x = t − ((t >> 7) & 0x01010101)·(256−b)` and `cout = (t >> 31) ^ 1`.
- It is branch-free, with no compare-and-select. That avoids the data-dependent branch that cost L2 3×.

**Mask.** For each digit, `m |= 1u64 << d`, then two `popc` instructions, then one shared atomic per
number into the existing 4-copy workgroup histogram. The near-miss path is unchanged.

**Leading zeros.** The host runs the FD kernel only on the part of each batch where n² has exactly ls digits
and n³ exactly lc, both comptime. `fd_plan` computes that interval with malachite. At b40 and b50 it equals
the base's legal range, which the test asserts. So the mask covers exactly ls + lc comptime positions. Any
part of a batch outside the interval goes to the old per-number kernel (only seen in tests). The addend
widths are taken at the interval's top, so addends can grow digits inside a run.

**Variants.** These are comptime flags behind env knobs, all kept for A/B.

- **v1 (plain).** As above. Every word of S and C is masked every step, and each add takes its carry into
  the word above unconditionally, with a rare branch beyond that.
- **v2, static mask (`NICE_FD_STATIC`).** Words of S and C above the addend's width change only when a
  carry ripples through four digits of b−1, a rate of addend/b^(4k) per step:
  - S at b50: about 4e-4 per step;
  - C: about 1e-7.

  Their mask is cached per run and recomputed on that rare branch. This removes 14 of 50 masked digits at
  b50 (S words 3–4, C words 6–7) and 8 of 40 at b40. The carry-into-the-next-word becomes rare-only too.
- **v3, merged rare branch (`NICE_FD_MERGED`, default).** The five adds return their last word's raw sum.
  One AND of the five bit-31s guards a single branch that does all the ripples and the cached-mask
  refresh. That leaves one rare branch per step instead of five.
- **v4, low-digit table (`NICE_FD_TABLE=1`, off by default).** A b²-entry u64 table, in global memory and
  L1-resident, holds the mask of digits 0–1 of n² and n³ for each n mod b². It skips 4 masked digits.
- **Local histogram (`NICE_FD_HIST=1`, off).** Per-thread packed 8-bit counters for a 16-bin window
  around 0.59·b, in four registers, flushed every 255 numbers. Outliers go to the shared atomic.
- **Run length (`NICE_FD_RUN`, default 128).** Batch size via `NICE_FD_BATCH` (default 5e7, as today).
  `NICE_DETAILED_FD=0` selects the old kernel.

The FD kernel is used only where the chunk scan's wide (u64) flavour is: CUDA and HIP. The wgpu
(split16) path keeps the old kernel. Only the seed needs u64 division; the hot loop is pure 32-bit.

## 3. Registers and occupancy

To get these counts, I dumped CubeCL's generated CUDA (`CUBECL_DEBUG_LOG`) and compiled it offline with
nvcc 12.8, `-arch=sm_86 -Xptxas -v` (`raw-fd/scripts/regs.py`; `raw-fd/regs_v3.txt`,
`raw-fd/v1/regs.txt`). The runtime path is NVRTC → PTX → driver JIT, so these are close, not certain.
On sm_86, occupancy is 64K registers per SM and at most 1,536 threads (6 cubes of 256).

| kernel | b40 regs | b50 regs | spills | cubes/SM | occupancy |
|---|---|---|---|---|---|
| old `detailed_kernel` | 40 | 42 | 0 | 6 / 5 | 100 % / 83 % |
| FD v1 | 62 | **96** | 0 | 4 / **2** | 67 % / **33 %** |
| FD v2, v3 | 48 | 48 | 0 | 5 / 5 | 83 % / 83 % |

- **v1 at b50.** It held all 50 extracted digits live for the mask build, giving 96 registers and 33 %
  occupancy, yet still ran at about its instruction-count ratio. Occupancy is not what limits this kernel.
- **v2.** Caching the static part shortened the live ranges, which brought it to 48 registers at both bases.
- **Instruction mix.** The v3 b50 run loop is 449 static SASS instructions, including the rare blocks:
  SHF 177, LOP3 134, IADD3 43, IMAD 40, ISETP 12, one ATOMS. The old b50 kernel is IMAD-dominated: its
  outer loop is 336 instructions, with 123 IMAD, around inner division loops (`raw-fd/loops_v3.txt`,
  `raw-fd/v3_src/*.sass`).

## 4. R sweep

The source is `fd_timing`, an ignored test in the branch: each base's benchmark window (range start,
2e8 numbers), 25 windows per cell, 3 interleaved rounds, medians, ×old in the same session. Batch is 5e7
unless noted.

| R | v1 b40 | v1 b50 | v1 b40 (batch 2e8) | v1 b50 (batch 2e8) | v3 b40 | v3 b50 |
|---|---|---|---|---|---|---|
| 32 | 2.15 | 2.47 | 2.13 | 2.45 | 2.53 | 3.06 |
| 64 | 2.23 | 2.64 | 2.24 | 2.57 | 2.61 | 3.18 |
| 128 | 2.26 | 2.66 | 2.20 | 2.61 | **2.65** | **3.22** |
| 256 | 2.21 | 2.60 | 2.29 | 2.63 | 2.57 | 3.17 |
| 512 | 2.20 | 2.54 | 2.27 | 2.60 | 2.57 | 3.19 |
| 1024 | 2.20 | 2.53 | 2.22 | 2.50 | — | — |
| 2048 | 1.80 | 2.07 | 2.25 | 2.49 | — | — |

Sources: v1 from `v1/sweep1_batch*.log`, v3 from `sweep3.log`.

- **The curve is flat from R = 64 to R = 512**, within about 3 %.
- **R = 32** pays for the seed.
- **R = 2048 at batch 5e7** gives only 24k threads. That is under one wave: v1 holds 1,024 threads per
  SM at b40 and 512 at b50, across 68 SMs. So the GPU is under-filled.
- **Batch 2e8** (one launch per window) does not help.

Variants at R = 128, same protocol:

| variant | b40 | b50 | source |
|---|---|---|---|
| v1 plain | 2.24 | 2.60 | sweep2 |
| v2 static mask | 2.53 | 3.15 | sweep3 |
| **v3 static + merged** | **2.65** | **3.22** | sweep3 |
| v3 + local histogram | 2.45 | 3.01 | sweep3 |
| v4 = v3 + low-digit table | 2.64 | 3.25 | sweep4 |

The local histogram is consistently 5–7 % *slower*. Its 4-way select chain costs more integer issue than
one `ATOMS`, which sits off the integer pipe. The low-digit table is within ±2 % of v3 at every R, in both
the 2e8 and 2e9 windows. It is not worth its table and index.

**Kernel-dominated window.** This is 2e9 numbers, which amortises the per-call host cost tenfold:
3 windows per cell × 3 rounds (`sweep_bigwin.log`, `sweep4_bigwin.log`).

| | old n/s | v3 R=64 | v3 R=128 | v3 R=256 | v4 R=128 |
|---|---|---|---|---|---|
| b40 | 9.03e9 | 2.96e10 (3.28×) | 2.96e10 (3.28×) | 2.87e10 (3.18×) | 2.95e10 (3.26×) |
| b50 | 6.43e9 | 2.55e10 (3.96×) | 2.55e10 (3.97×); repeat 2.59e10 (4.03×) | 2.52e10 (3.92×) | 2.63e10 (4.09×) |

## 5. A/B against the current kernel (benchmark harness)

This is `nice_client detailed --gpu --benchmark --benchmark-secs 40`, about 18 s timed per scenario, on the
`b40_detailed`/`b50_detailed` GPU windows (2e8 numbers at the range start). It ran 3 interleaved rounds
with `nvidia-smi dmon` alongside, and the table gives medians. The source is `raw-fd/ab2`, the same
binary for all arms.

| arm | b40 n/s (rounds) | median | × | b50 n/s (rounds) | median | × | SM clock |
|---|---|---|---|---|---|---|---|
| old (`NICE_DETAILED_FD=0`) | 8.04e9 7.83e9 7.88e9 | 7.876e9 | 1.00 | 5.87e9 5.74e9 5.78e9 | 5.782e9 | 1.00 | 1410–1455 MHz |
| FD v1, R=256 | 1.760e10 1.743e10 1.741e10 | 1.743e10 | 2.21 | 1.496e10 1.491e10 1.495e10 | 1.495e10 | 2.59 | 1673–1695 |
| FD v2, R=128 | 1.980e10 1.971e10 1.956e10 | 1.971e10 | 2.50 | 1.673e10 1.832e10 1.802e10 | 1.802e10 | 3.12 | 1680–1710 |
| **FD v3, R=128** | 2.052e10 2.048e10 2.007e10 | **2.048e10** | **2.60** | 1.857e10 1.861e10 1.885e10 | **1.861e10** | **3.22** | 1680–1695 |

NiceMark, for reference: old 3,533–3,618, v1 8,495–8,554, v2 9,592–10,014, v3 10,250–10,289. With the
trimmed read of section 6 (`raw-fd/ab3`) it is old 3,764–3,893 and v3 13,471–13,562.

**Power cap caveat.** Every arm draws 179 W. Under that cap the old kernel, which is IMAD-heavy division,
clocks about 1,425 MHz. FD, which is SHF/LOP3/IADD3, clocks about 1,690 MHz. So about 1.18× of the gain on
this box is power, not instructions.

- Normalised per clock, v3 is about **2.2× at b40 and 2.7× at b50** on the harness. Kernel-only it is
  about 2.8× and 3.4×, assuming the 2e9-window runs had the harness's clock ratio; no dmon was taken
  there.
- With the trimmed read (section 6) the clock ratio is 1.16, giving about 2.8× and 3.4× per clock.
- Where neither kernel is power-limited, expect about the per-clock ratios. L3's 260 W board ran the old
  kernel near max boost: 1.04e10 at b40, about 1.88 GHz scaled from here. That needs confirming on an
  uncapped 3080/3090/4090 or an A100.

## 6. A host-side finding: the near-miss readback

The harness ran about 25 % below the 2e9-window rate for FD (b50: 1.86e10 against 2.55e10). That points to
a per-call cost of about 2.3 ms. The main part is in `detailed_impl`, which read back the whole near-miss
buffer on every call:

```rust
client.read_async(vec![miss_data_handle])   // NEAR_MISS_CAPACITY * 5 * 4 B = 20 MB
```

That is about 1.7 ms over PCIe 3 per call, whatever the miss count. The usual count is 0.

The branch now reads only `miss_total` records, and nothing when there are none.
`NICE_MISS_READ_ALL=1` restores the full read. Results are `raw-fd/ab3`, 3 interleaved rounds:

| arm | b40 median | b50 median |
|---|---|---|
| old, full read (today) | 7.835e9 | 5.793e9 |
| old, trimmed | 8.482e9 (+8 %) | 6.065e9 (+5 %) |
| FD v3, full read | 2.075e10 | 1.870e10 |
| FD v3, trimmed | **2.728e10** (+31 %) | **2.407e10** (+29 %) |

- With the trimmed read, FD v3 against the old kernel is **3.22× at b40 and 3.97× at b50**. Against
  today's production path (old, full read) it is 3.48× and 4.15×.
- With the copy gone, the FD arm is busier and drops to about 1,580 MHz under the cap; old drops to about
  1,365 MHz.
- **This fix is independent of FD** and worth a small PR of its own. It is +5–8 % on the current kernel's
  NiceMark windows.
- **Production impact is smaller.** Detailed fields are up to 1e9 numbers
  (`DETAILED_SEARCH_MAX_FIELD_SIZE`), five benchmark windows. At FD speed a whole 1e9 field takes about
  40 ms of GPU, so the claim/submit round trip may then dominate wall-clock per field. That is worth
  checking before expecting 3–4× field throughput.
- The niceonly readback (`read_niceonly_hits`) also reads its whole output buffer, but that is 1 MB per
  field, about 0.08 ms, which is negligible.

## 7. Exactness evidence

The test is `cubecl_cuda_fd_matches_cpu_detailed` (ignored, needs NVIDIA). It compares the whole
`FieldResults` (distribution and near-miss list) from `process_range_detailed_cubecl_with` against
`process_range_detailed`. The CPU side runs on scoped threads and is merged.

**b40 and b50.** It first asserts that the regular interval equals the legal range. It then runs 13
windows per base:
- range start (2e6);
- range end (the last 2e6);
- **a window straddling the range start**, where n³ gains a digit, so the batch splits between the FD and
  old kernels;
- 8 seeded random 1e6 windows;
- **1e6 windows centred on every point inside the range where an addend gains a digit**: dS at
  3,276,800,000,000 (b40) and 48,828,125,000,000,000 (b50), and dC at 3,783,722,724,161 and
  56,381,862,225,549,391. ddC gains no digit inside either range.

Each window is run under 7 option sets:
- v3 at R=128, with and without the table;
- v2 at R=256;
- v1 at R=256;
- v3 + local histogram + table at R=61 (partial runs);
- v2 + local histogram at R=1000 with batch 333,333 (many batches, a partial run at every batch end);
- v3 + table at R=1000 with batch 333,333.

**Benchmark windows.** The 2e8 windows at b40 and b50, whole: FD = old GPU kernel = CPU.

**Small bases, full range.** Every base 10–28 with a range (15 bases, 76 M numbers, **73 near-misses**),
all 7 option sets, identical. These are the only windows with near-misses; the b40/b50 windows have none.

**History.** It passed at every commit: v1 with 3 option sets (`v1/exact1.log`), v2 with 5
(`exact2.log`), v3 with 6 (`exact3.log`), v4 with 7 (`exact4.log`), with the trimmed read (`exact5.log`), and at the
final head `e0c1b4c`, together with the existing parity test (`exact_final.log`; the source md5 matches
the pushed file).

**Other checks.**
- The existing `cubecl_cuda_matches_cpu_detailed` passes with FD on by default (`parity_existing.log`):
  - b10 1e6 is 53 numbers FD and the rest old;
  - b40 2e6 runs on FD;
  - b62 2e5 runs on FD with 3-limb n;
  - b80 is old.
- The `nice_common` lib suite: 208 passed, 35 ignored (`libtests.log`).
- `fd_timing` checks each arm's `FieldResults` against the old kernel before timing, and every timed
  repetition's distribution.

## 8. What limits it

**The integer issue rate.**
- At 2.55e10 n/s and about 1.6–1.7 GHz, 68 SMs × 64 INT lanes allow about 270–290 integer instructions per
  number.
- That matches the estimated length of v3's hot path at b50: about 280, from 36 masked digits × 4.5,
  14 word-adds × 6.5 and about 25 more for popcount, atomic, loop and the rare test. This is an estimate
  from the SASS mix, not a dynamic count.
- Memory is idle apart from the histogram.
- There are no spills and occupancy is 83 %.
- Divergence is one rare branch per step plus the near-miss test, with warp-uniform digit lengths.
- So it is not latency, registers, divergence or launch shape. Profiler counters are still blocked on Vast
  (`ERR_NVGPUCTRPERM`, L3 notes), so the mix is from SASS, not counters.

**Mask build, about 55–60 % of the hot path.** Per digit:
- a byte extract: 1 op for lanes 0 and 3, 2 for lanes 1 and 2;
- the 64-bit one-hot `1u64 << d`, which is 2 SHF (`SHF.L.U32` + `SHF.L.U64.HI`);
- half a LOP3 per mask half for the OR.

That is about 4.5 ops per digit. v3 still masks 36 digits per number at b50 and 32 at b40, about 160 and
145 ops. Taking 4 more digits off with the b² table bought ≤ 2 %.

**Digit adds, about 30 %.** Each 4-digit word costs about 6–7 ops (IADD3 ×2, SHF ×2, LOP3 ×2, IMAD). There
are 14 word-adds per number at b50 and 13 at b40.

**Why b40 gains less than b50.** The old kernel's cost grows with limbs × chunks. n² and n³ span 3 and 5
u32 limbs at b40 but 4 and 6 at b50, so its long-division steps grow from about 20 to about 30 (L3 notes).
The FD cost grows only with digit count, 40 against 50. So the ratio is larger at b50 and should keep
growing with the base.

**Host per-call overhead.** See section 6: a fifth of a benchmark window at FD speed until the readback is
trimmed.

## 9. Next steps (PR outline, not done)

1. **PR 1 (small, independent).** The trimmed near-miss readback. It gives +5–8 % on the current kernel's
   detailed GPU scenarios and about +30 % once FD lands.
2. **PR 2.** The FD kernel as v3 only, with R = 128, the regular-interval split, `fd_plan`, and the
   exactness test.
   - Drop the v1/v2/local-histogram/table knobs, or keep them test-only, and drop `NICE_FD_BATCH`.
   - Run the 5 % protocol on `b40_detailed`/`b50_detailed` and re-pin the NiceMark detailed GPU references.
   - Keep the CHANGELOG entry short.
   - `cargo clippy -p nice_common --features gpu --release --all-targets` is clean at `e0c1b4c`. The
     kernel needs `collapsible_if` and the naming allows, like `candidate_check`.
3. **Validate on other silicon before merging.**
   - An uncapped 3080/3090/4090 and an A100 (Anvil) for the power-cap question and a different INT/FMA
     balance.
   - A 9070 XT via HIP (`wide_chunk` is on for HIP, so FD runs there unchanged).
4. **wgpu/Vulkan/Metal.** These need a split16 seed only: the hot loop is pure 32-bit. That is where u64
   division is slowest, so FD may gain the most there. It has not been tried.
5. **Further kernel ideas, each about ≤5 %, not tried.**
   - Biased storage of dS/dC, saving one IADD per word on the S and C adds.
   - Merging the 64-bit one-hot via the clamped 32-bit shift, but that relies on C++ UB for shifts ≥ 32,
     so no.
   - Unrolling the run loop by 2.

   The 2-SHF one-hot plus byte extraction is the floor of this mask design. A different uniqueness count
   would be needed to go much further.

## 10. Commands

```sh
# ivory
cd /home/claude/projects/nice && git fetch -q origin main
git worktree add .worktrees/exp-gpu-fd origin/main -b exp/gpu-detailed-fd
# box (fast-iteration build; see raw-fd/scripts/tbuild.sh)
export CARGO_TARGET_DIR=/root/tfast CARGO_PROFILE_RELEASE_LTO=false \
  CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 CARGO_PROFILE_RELEASE_INCREMENTAL=true
cargo test --release -p nice_common --features gpu --no-run
cargo build --release -p nice_client --features gpu
T=$CARGO_TARGET_DIR/release/deps/nice_common-<hash>
$T cubecl_cuda_fd_matches_cpu_detailed --ignored --nocapture --test-threads 1
FD_TIMING_VARIANTS=p,s,m,h,t FD_TIMING_RUNS=64,128,256 FD_TIMING_REPS=25 \
  $T fd_timing --ignored --nocapture --test-threads 1        # FD_TIMING_WINDOW=2000000000 for kernel-only
# harness A/B: raw-fd/scripts/run4.sh (ab2), run6.sh (ab3)
NICE_DETAILED_FD=0|1 NICE_FD_RUN=128 NICE_API_BASE=http://127.0.0.1:9 \
  nice_client detailed --gpu --benchmark --benchmark-secs 40 < /dev/null
# registers: CUBECL_DEBUG_LOG=<file> nice_client ... ; python3 raw-fd/scripts/regs.py
```
