Overlap join: check survivors in base-b² limbs from the top's record

Main (a7a59c1, with #250, #252, #253 and #254) is merged into this branch, so the diff shows this change alone; the files this change touches are as measured, apart from one doc comment that #254 reworded.

## What

The overlap join's last kernel, `check_kernel`, runs the full nice check on each survivor of the join's prefilter. Until now it rebuilt n = P·b^f0 + r0 as a binary number from the top's record and called the stride path's `candidate_check`: n² and n³ in 32-bit limbs, and each digit chunk out of a long division of the whole remaining number by b^5, through a shared-memory scratch, with a trim loop per pass.

This PR replaces the check kernel's body (`candidate_check` is untouched; the stride path still uses it):

- **n in base-b² limbs, from what the record already holds.** The record's word 6 is w6 = P mod b^(k2 − f0) (the prefilter's word). With r0 = n mod b^f0, n = H·b^k2 + w6·b^f0 + r0, where H = (P − w6) / b^(k2 − f0) is an exact division: a 64-bit subtract, a shift by the power of two in b^(k2 − f0), and a multiply by the inverse of its odd part. n's two-digit limbs come out of r0, w6 and H with a few quotients by b and b².
- **n² and n³ by schoolbook columns of u32 products.** Each column (at most 7 products of limbs below b² ≤ 4096, plus the carry) stays below 2^31. One quotient by b² per column normalises it into a limb; one quotient by b splits the limb into its two digits, which are OR-ed into a 64-bit digit mask.
- **Every quotient is a multiply-high and a shift**, `mul_hi(x, ⌈2^(32+s)/d⌉) >> s` with s = ⌊log2 d⌋, exact for every x < 2^31, which bounds every input the kernel gives it. No `/` or `%`, no 64-bit division, no shared memory: one code path on CUDA, HIP and wgpu instead of the wide and 16-bit-split pair.
- **A gate before the rest of n³.** n²'s digits and the low 10 digits of n³ (the low five limbs of the product, 15 products) must be distinct, by a popcount of the mask. Only planes with a lane that passes go on to the rest of n³. A nice number always passes it: the gate's digits are some of n² and n³'s, which are then all distinct.
- **Work distribution.** Each plane takes the next entries of the survivor list, one per lane, from a counter (one atomic by its first lane and a broadcast), asking for the next ones before it works on these. The counter is a fifth word of the batch's `ran` buffer, which the cube counts do not read. It relies on full planes: a cube's 256 threads are a multiple of every plane width (a power of two up to 128), so every plane starts full, and the plane ops run in plane-uniform control flow. The kernel launches 2048 cubes, more than a GPU holds at once at its ~40 registers (a 3080 holds 408, an H100 792); cubes that start after the list is exhausted exit at once. The old grid-stride loop over 1024 cubes left a tail on every device.

`common/src/join_check.rs` is new: the check's shape (b, the digit counts of n, n² and n³, f0, k2 and the gate's digits) with its bounds checked, which is also the kernel's comptime argument, and the quotient constants; its tests hold a host mirror of the kernel's arithmetic. CI's WGSL lint no longer requires a constant division in `CheckKernel@57`: it has none left to lint.

## Why

After the join's recent speed-ups the check had become a larger share of each field: with the device synchronised around each kernel group (an instrumented build), the old check kernel took 8.79 s of a b62 1e17 field's 77.5 s of device time (11 %) and 2.13 s of a b60 1e16 field's 15.6 s (14 %).

Its cost was the shape of the scan rather than the division instruction. Each pass divided the whole remaining number again (so the work grows with the square of its length), with a round trip through shared memory per limb and a trim loop and a branch per five digits. And the cube was built in most warps: any lane whose n² passed took its warp through it. By its SASS, a warp issued about 1,050 instructions per warp-iteration (32 survivors, one per lane), at about half an instruction per cycle.

## Soundness

The check computes the same base-b digits of n² and n³ by another route, and decides as before: n is nice iff the digits of n² and n³ (exactly s2 + s3 = b positions; the top limbs' digit counts are fixed per field, so no leading zero is ever counted) are all distinct.

- **n.** H·b^k2 + w6·b^f0 + r0 = n, with H = ⌊n / b^k2⌋: w6 = P mod b^(k2 − f0) is what both top kernels write to word 6 (the join's prefilter reads the same word), and r0 = n mod b^f0 is the list entry's. P − w6 is a multiple of b^(k2 − f0) = 2^z·o, so ((P − w6) >> z)·o⁻¹ mod 2^32 is H whenever H < 2^31, which holds on every field the join takes (H < b^5); the tests' smaller windows, where H reaches about 2^40, take it apart by 16-bit chunks instead. The probe mode rebuilds n from its limbs and the device test compares it with the list's n.
- **No overflow.** Every column of n² or n³ has at most ⌈L/2⌉ products of limbs below b², plus a carry below ⌈L/2⌉·b², so it is below ⌈L/2⌉·(b⁴ + b²) < 2^31 at every shape the join runs (`CheckShape::new` checks it per field: at most 7·(64⁴ + 64²) ≈ 1.2·10^8 here).
- **Exact quotients.** For d ≥ 3 not a power of two, m = ⌈2^(32+s)/d⌉ with s = ⌊log2 d⌋ is below 2^32, and e = m·d − 2^(32+s) lies in (0, d). Then x·m / 2^(32+s) = x/d + x·e / (d·2^(32+s)), and the second term is below 1/d whenever x·e < 2^(32+s), which holds for x < 2^31 because e < 2^(s+1). So `mul_hi(x, m) >> s` = ⌊x/d⌋ for every x < 2^31. Every quotient's input is below 2^31: columns and chunks below 2^28, limbs below b², and r0, w6 and a narrow H below 2^31 (checked per field). A power-of-two base uses shifts. A host test checks the bound for every divisor b and b² at bases 3–64. It also checks the worst element of every block of d across each input range the kernel uses (the quotient is monotone and never below the true one, so that element decides the block). An opt-in test (`NICE_TEST_CHECK_EXHAUSTIVE=1`) checks every x < 2^31 for every divisor.
- **The gate only drops non-nice n.** A repeated digit among n² and n³'s low digits is a repeated digit of n² and n³.
- **Every survivor is checked once.** The counter hands out disjoint, consecutive ranges of one entry per lane of the plane; a plane works on its range while the counter is below the list's length, and only on entries below it. Every cube still reaches the cube count, which the batch compares with the cubes launched as before; the counter's word is not compared.
- **What tests the check.** Every hit comparison in the suite but b10's [47, 100) is on a range with no nice number, so a check that rejected too much would pass all of them. The new device test therefore compares the kernel's own output with the CPU for every survivor, in three test-only modes. Count mode skips the gate and writes four words per list entry: the number of distinct digits of n² and n³ (against the client's `get_num_unique_digits`), whether the entry passes the gate (against its definition), and the 64-bit digit mask. Gated mode writes the same words with the gate applied as the hits mode applies it, so the divergent rest of n³ runs only in the lanes that pass, and it runs on a grid of one to three cubes, so every plane takes work from the counter many times. Probe mode writes every n rebuilt from its limbs. The test checks that every kernel of each batch ran before it reads the batch's list, so a dropped dispatch cannot pass as an empty list, and that the work counter ends exactly one take per plane past the list. No nice number is known above base 10, so the hits path meets a real hit only at b10's 69 (`check_all`); the gated mode covers that path's control flow on every survivor that passes the gate.

## Measurements

**Card:** RTX 3080 10 GB (driver 580.159.03) on a rented box whose host caps it at **180 W** (default 340 W).

**Where the check stood.** With the device synchronised around each kernel group of every batch (an instrumented build, not part of this PR), the old check kernel took 8.79 s of a b62 1e17 field and 2.13 s of a b60 1e16 field (two rounds each). A kernel that only loads what the check reads per survivor — the list entry and the record's words 0, 1 and 6 — took **3.36 s** and **0.76 s**. That is 2.5 TB in 3.36 s at b62 (8 bytes of list and one 32-byte record sector per survivor), 0.745 TB/s, 98 % of the card's DRAM bandwidth: a floor for any check that reads P per survivor. Launching 2048 cubes instead of 1024 saved 4 % of the old kernel, and exactly one wave (408 cubes) cost 1.6–2.8 % more.

**The new kernel alone** (same instrumentation, this kernel's form): **3.19 s** at b62 1e17 and **0.74 s** at b60 1e16, at the floor; ×2.8 and ×2.9 against the old kernel.

**Code** (the runtime's path: NVRTC's PTX through the driver's JIT, sm_86): 39 registers at b57, b60 and b62, 40 at b64; no spills, no local or shared memory. At b62 a warp issues 330 instructions per warp-iteration (32 survivors, one per lane) on the common path (140 multiply-adds, 170 ALU, 6 loads and atomics, 14 branch and sync), plus 249 for the rest of n³ when one of its lanes passes the gate. One entry per lane per take beat four and eight (−7 % of the check at b62 1e16): the JIT gives it 39 registers instead of 47, which fits 6 cubes per SM instead of 5. The gate's width (8, 10 or 12 digits of n³) made no measurable difference (±2 %), since the kernel waits on memory either way.

**Method:**
- The base branch (`d813aea`) and this PR, same box, two binaries. Rounds were interleaved with the order alternating (base, PR; PR, base; base, PR), with nothing else running.
- Harness: `cubecl_cuda_join_throughput_fixed_fields` after one 1e14 warm-up field per process, at the starts b57 28151599893042801193, b60 1366406074057412100454, b62 7997740455941656911841 and b64 41242006262957161709568.
- s/field is the mean device time per field (`device=`; two fields in flight at 1e16). Figures are medians of 3 rounds. "Per round" is the base's time over the PR's in the same round. MHz is the mean SM clock per side (nvidia-smi every 5 s); "cycles" is the ratio of device seconds × clock.

| field | base s/field (rounds) | this PR s/field (rounds) | speed-up | per round | MHz base / PR | cycles |
|---|---|---|---|---|---|---|
| **b62 1e17**, 1 field | **74.65** (73.28, 74.65, 75.97) | **68.64** (68.05, 68.75, 68.64) | **×1.088** | 1.077, 1.086, 1.107 | 1478 / 1461 | ×1.099 |
| b62 1e16, 2 fields | **6.249** (6.26, 6.24, 6.25) | **5.762** (5.79, 5.75, 5.76) | **×1.085** | 1.082, 1.086, 1.085 | 1442 / 1477 | ×1.080 |
| **b60 1e16**, 2 fields | **15.201** (15.36, 14.94, 15.20) | **13.521** (13.51, 13.52, 13.53) | **×1.124** | 1.137, 1.105, 1.124 | 1457 / 1449 | ×1.140 |
| b64 1e16, 2 fields | **22.267** (22.31, 21.80, 22.27) | **20.818** (20.82, 20.78, 20.83) | **×1.070** | 1.072, 1.049, 1.069 | 1447 / 1444 | ×1.070 |
| b57 1e14, 3 fields | 0.579 (0.56, 0.58, 0.58) | 0.537 (0.56, 0.53, 0.54) | ×1.078 | 1.005, 1.090, 1.078 | | |
| b60 1e14, 3 fields | 0.564 (0.56, 0.56, 0.57) | 0.539 (0.54, 0.54, 0.54) | ×1.046 | 1.054, 1.046, 1.052 | | |
| b62 1e14, 3 fields | 0.488 (0.49, 0.50, 0.48) | 0.481 (0.46, 0.48, 0.49) | ×1.015 | 1.063, 1.037, 0.984 | | |
| b64 1e14, 3 fields | 0.683 (0.70, 0.68, 0.67) | 0.681 (0.68, 0.68, 0.69) | ×1.003 | 1.022, 1.010, 0.983 | | |

- At b62 1e17 that is 6.0 s saved per field; the instrumented check went from 8.79 to 3.19 s.
- b64 gains least, probably because the old kernel's quotients by 64^5 and 64 were shifts there, which made its check the cheapest of the four (its check time alone was not measured).
- It is not clock. At b62 1e17 both sides sat at the cap (median 179.6 W) at the same median clock, 1440 MHz; the means in the table carry single 5-second samples that catch idle bursts (1,920 MHz) and dips, so the cycle ratios are rougher than the time ratios, more so at 1e16 with a few samples per run.
- The PR's runs at 1e16–1e17 are also steadier: 0.2–1.0 % spread against 0.4–3.6 %.
- The 1e14 fields (0.5–0.7 s each) gain or are neutral, within their rounds' spread at b62 and b64. The b57 1e14 gain (×1.078) came with the PR's side at a mean 1905 MHz against the base's 1635 (few samples per short run), so it is not evidence on its own.

NiceMark nice-only (`nice_client niceonly --gpu --benchmark --benchmark-secs 150`, 6 rounds, alternating):

| | base | this PR | speed-up |
|---|---|---|---|
| **score** | median 7889.7 (7801.7–7930.8) | median 8327.8 (8261.3–8413.0) | **×1.056** (per round 1.059, 1.066, 1.051, 1.057, 1.050, 1.064) |
| b58 MSD-weak (whole field) | 3.715e14 n/s | 4.000e14 | ×1.077 |
| b58 MSD-strong (whole field) | 1.440e15 | 1.497e15 | ×1.039 |
| b60 MSD-weak (sampled) | 7.969e14 | 8.444e14 | ×1.060 |
| b62 MSD-weak (sampled) | 9.658e14 | 1.024e15 | ×1.060 |

## Exactness

All on an RTX 3080 (CUDA) unless marked lavapipe (llvmpipe, Mesa, 8-lane subgroups). The timings and most items below are from the code as timed; since then the tests were strengthened after a review, the kernel was given its shape as one comptime argument and a test-only gated mode, and rustfmt, clippy and comments changed. This head was rebuilt and the items marked "(this head)" re-run on it; the kernel's arithmetic and loop are as timed.

- **New (this head): `cubecl_cuda_check_counts_match_the_cpu`**, count, gated and probe modes against the CPU, entry by entry: ok on 1,168,717 survivors of real lists from 24 fields in 64 batches (b10's window, the 17 windows, and the production fields of `PLAN_FIELDS` at 1e14 with the b57 frontier partitions 0/1000/3248) and 84,652 synthetic n over the 22 distinct field shapes, 3,047 entries past the gate. The synthetic lists hold, per shape, 4,000 random n of its digit counts and the adversarial and edge n that fall in its band: all digits b − 1, the smallest n, 0 and b − 1 alternating, the record parts at their extremes, the band's ends, the last n whose square or cube stays below a power of b, and the ends with low digits all 0 or all b − 1 (32–51 such n at each production shape). Every batch is checked to have run in full first; the work counter's end is checked on every run.
- `NICE_TEST_JOIN_COMPARE=1` at 1e14 (b57/60/62/64; b62 again on this head): join = stride (which still runs `candidate_check`), found 0; 4,850,227,888 / 268,123,373; 2,694,700,282 / 180,517,288; 1,439,469,648 / 88,159,810; 5,702,041,796 / 346,647,759, as before.
- `cubecl_cuda_join_matches_the_cpu_reference` (also this head): ok. It covers b10's 69 through the new check; the windows b20–b64, including b50 and b54 after refused layouts; the b57 frontier partitions 0/1000/3248, tight and refused; sliced windows; and the production shape.
- `cubecl_cuda_top_fd_matches_the_top_kernel` (with the sentinel records): ok, 26 fields, 279 batches (23 with a clipped block), 375,887,645 tops.
- `cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu`: ok, 102,365 intervals, 33,582 kept, 203,413 above c0, 69,824 with the carry.
- Dense fields equal to the CPU join: b58 1e15, 32 partitions, 254,938,965 / 14,396,829; b62 1e16, 4 partitions, 120,013,475 / 7,355,827.
- Whole b42 field (`NICE_TEST_JOIN_FULL_FIELD=1`): join = stride = CPU reference, 417,789,835 join survivors, 16,879,877 checked, no hits.
- Every timed field above has the base's join survivors and prefilter survivors in every round (at 1e16, the two fields' totals). These counts are the join's, written before the check runs, so they show the join unchanged, not the check; the check's evidence is the device test above and the hit comparisons (b10's 69, the whole b42 field, the 1e14 COMPARE):
  - b62 1e17: 1,020,844,021,499 / 62,584,252,554.
  - b62 1e16: 163,513,599,082 / 10,027,698,695.
  - b60 1e16: 460,847,952,346 / 30,871,838,404.
  - b64 1e16: 787,584,956,227 / 47,900,853,327.
  - NiceMark's whole-field scenarios: identical in all 12 runs (b58 MSD-weak 33,590,315,220 join survivors, MSD-strong 4,027,773,430).
- Host tests of `join_check` (release, 1.2 s), and with `NICE_TEST_CHECK_EXHAUSTIVE=1` every x < 2^31 for all 114 divisors (b and b² at bases 3–64, not powers of two): exact, 131 s on 9.6 CPUs. `join_plan` and `cubecl_join` host tests: ok.
- lavapipe (llvmpipe, LLVM 20.1.2, 8-lane subgroups), every wgpu test of `cubecl_join` (the new test with the same totals as on CUDA, CPU-reference parity incl. b10's 69, the FD-vs-top-kernel test on 21 fields / 142 batches / 1,018,088 tops, the certificate test, the production-field sample, the ticket test): ok with the naga (WGSL) compiler and with CubeCL's direct SPIR-V compiler (9 passed each). On this head the new test again, with both compilers: ok, the same totals as CUDA (159 s with naga, 304 s with SPIR-V, side by side on 5 CPUs).
- CI's WGSL lint (`wgsl_dump_for_lint` on lavapipe + `scripts/wgsl-lint.py` with the workflow's requires, less `CheckKernel@57`): 14 shaders, 0 flagged; `CheckKernel` b57 has no constant division left.
- This head: `cargo fmt --all --check`; `cargo clippy -p "*" --all-targets -- -D warnings`, default, with `--features nice_client/gpu` and with `--features nice_client/gpu,nice_client/cubecl-spirv` (rustc 1.99.1): clean. The `join_check` host tests and the exhaustive quotient test: ok.

## Registers

From the driver's JIT of the PTX each process compiled at run time (NVRTC, as CubeCL runs it), over all 24 processes of the A/B: the check kernel has 39 registers (18 images) or 40 (6, at b64), and no spills or local memory in any. The old kernel (38 registers in an offline nvcc build) also used a 9 KiB shared-memory scratch per cube; the new one uses none.

## Not in this PR

- **The gather.** The check now runs at the speed of its loads: per survivor one 8-byte list entry and one 32-byte record sector, of which it uses 12 bytes (P and w6). Going below that means not reading the record per survivor, for instance carrying P in the survivor list, which would cost the join kernel shared memory per staged survivor. Not tried here.
- **The top's certificate.** The record's certified digits could sharpen the gate further. That needs each top's certified positions in the record, written by the FD kernel, for a gate that already sends about one plane in twenty on to the rest of n³ (in a simulation of b62 1e17's survivors). Not done.
- **One counter on HBM GPUs (unmeasured).** The kernel makes one same-address atomic per 32 survivors, 1.96·10^9 per b62 1e17 field: about 0.6·10^9/s on the 3080, where it does not limit (one entry per lane beat four). At an A100's or H100's gather speed it would need about 1.2·10^9/s or 2.6·10^9/s, near the one-per-clock rate reported for same-address L2 atomics, so the counter could co-limit the check there. Not measured; two entries per lane per take would halve the atomics.
- **Two entries per lane per take** measured 4 % faster than one in a single round at b62 1e17 (1.6 % in cycles, it ran 42 MHz higher), about 0.1 s of a 75 s field; one entry per lane needs no inner loop, so the kernel keeps it.
- **Other GPUs.** On wgpu the old check kept its chunks below 2^16 (for RADV, which does not strength-reduce a 64-bit constant division), so it made two to three times as many passes as on CUDA. The new kernel is the same on every runtime, so devices on that path may gain more than the 3080 does; none was measured.
- **Backends not run:** HIP (no AMD device), Metal (Apple GPUs; the kernel has no `/` or `%`, so none of the half-width-shift division patterns the WGSL lint looks for; CI's macOS job will be its first Metal run, on a paravirtual GPU that does not reproduce the M4 compiler bug), DX12. Run: CUDA on an RTX 3080, and lavapipe (llvmpipe) through naga and through CubeCL's direct SPIR-V compiler.

🤖 Generated with [Claude Code](https://claude.com/claude-code)



