# Overlap join: run the prefilter in the walk, before staging survivors

## What and why

`join_kernel` ANDs each bottom entry's digit mask against 32 tops at a time, and each lane then walks the set bits of its pass mask. Until now every pair in range (a join survivor) was staged in shared memory, and when the stage was half full the whole cube ran the middle-digit prefilter on it (`mid_pass`), compacted the ~6 % that passed per plane and wrote them to the list.

That survivor handling turned out to be most of the join kernel. Removing it piece by piece (runtime variants of the same kernel, b62 1e16 field, RTX 3080) gives, per join survivor:

| piece | ps per survivor | share |
|---|---|---|
| `mid_pass` arithmetic: all 8 digit columns of n² and n³ (72 products, 24 divisions by b), per survivor | 35.5 | 44 % |
| staging and flushing: shared stores and reads, plane scans, two `sync_cube` per 256 staged survivors | 17.7 | 22 % |
| the set-bit walk itself | 14.9 | 18 % |
| list writes and the global atomic per flush round | 11.9 | 15 % |
| **total** | **81** | 73 % of the join kernel, 35 % of the field |

`mid_pass` rebuilt every column although positions `0..k` are the bottom's own mask (already distinct, and already ANDed against the top's certificate) and the top's digits are the same for every survivor of that top. Only positions `k` and `k + 1` can fail.

The CPU join already avoids all of that (`cpu_join::CpuJoin::prefilter`). With `n = R + D·b^k` (`R` the bottom's `k` digits, `D` the top's next `mid = k2 − k`), the digits the prefilter tests are those of

    x2 = (⌊R²/b^k⌋ + 2R·D) mod b^mid,    x3 = (⌊R³/b^k⌋ + 3R²·D) mod b^mid

so the test splits into a per-entry part, a per-top part and about 50 instructions per pair (`mid_pass` was about 290). That is cheap enough to run in the walk, on every survivor, before anything is staged.

### What the kernels do now

- **Bucket kernel.** The digit columns run to `k2` instead of `k`, and per extended entry it writes two words (`ext_q`, replacing the one-word `ext_pk`): `⌊R'²/b^(k−1)⌋` and `⌊R'³/b^(k−1)⌋` mod `M = b^(mid+1)` with `3R'² mod M` split over their top bits (`R'` the entry with key digit 0). For a shape without a key level it writes the carries and `2R`, `3R²` directly.
- **Join kernel, wave load** (once per entry per 256 tops): for the bucket's key digit `d`, `t = q + d·c mod M` gives the key digit's output digits (the low digit, which replaces `ext_pk`'s stepping) and the prefilter's two carries; with `2R`, `3R² mod b^mid` that is two packed registers per entry (`ac`, `pc`).
- **Top chunk load:** `t_dm = D | seed << 16`, one more 1 KiB shared array.
- **Walk:** after the range test, the pair is counted as a join survivor and `walk_pf` runs the affine test against the entry's mask (in registers) and, when the seed flag says so, the top's certificate (already in shared memory). Only pairs that pass are staged.
- **Flush:** every staged pair is a prefilter survivor, so it is one atomic for the whole stage and a straight copy; the plane compaction and its barriers are gone, and so are `mid_pass` and `plane_tot`.
- **Join survivors** are counted per thread in the walk, with one atomic per plane at the end.
- **Every shape the host accepts takes this path,** not only the production one (`f0 = 3, k = 6, k2 = 8`, key level). The terms that vanish at `k ≥ mid + 2` (the key digit's `d²` and `d³` terms, `R mod b^mid`'s key part, and the `D²·b^k` terms when `k < mid`) are added under `comptime` exactly as `cpu_join`'s `advance` and `prefilter_any` add them, and `R' mod M` takes the slot's partition digits when `f0 < mid + 1`. So the small test windows (bases 10-40, `k` from 1 to 5, with and without a key level) exercise the same code as production fields, and nothing of the old flush-time prefilter is left.

Registers (ptxas 12.8, sm_86, on the CUDA CubeCL emits for b62): join kernel **62 → 39** (SASS 1,672 → 784 instructions), so 6 cubes of 256 fit an SM instead of 4; bucket kernel 34 → 39.

## Soundness

- **The same test.** The two digits at positions `k` and `k + 1` of n² and n³ are the same numbers as `mid_pass` computed (the identity above, which needs `k ≥ mid`; the extra terms cover `k < mid`). They are tested the same way: distinct from each other, from the bottom's mask, and from the certificate when the top's seed flag is set.
- **What `mid_pass` tested and the walk no longer does:** positions `0..k`. Those are the bottom's mask. The bucket kernel lists an entry only if its digits there are distinct and miss the field's certificate, and the AND has just tested them against the top's certificate. So those tests could never fail.
- **The same survivors.** At 1e14 at bases 57, 60, 62 and 64 the join survivors, the prefilter survivors (= full checks) and the hits are identical to main's (table below). The CPU reference agrees on every test shape (bases 10-64, CUDA and both lavapipe compilers).
- **The stage overrun.** A chunk can still add more than the stage's free half; that overflow is written to the list directly, as before. Before, it skipped the prefilter (more full checks) and was missing from the survivor count, so main's counts drifted on dense fields (1.1e-4 of survivors at b62 1e17, 3.9e-3 at b60 1e16). Now the overflowing pairs have passed the prefilter and been counted in the walk, so the list holds exactly the prefilter survivors either way, and both counts are exact. The dense-field test now asserts equality with the CPU join instead of a tolerance. The overflow also became rare: the stage fills about 16 times more slowly.
- **Apple's Metal compiler.** Every new division or remainder by a constant divides a sum, a loaded word or a remainder, never a bare half-width shift or a u64 high word. `scripts/wgsl-lint.py` with CI's require list: 0 flagged, `JoinKernel@57` (34 constant divisions) and `BucketKernel@57` (46) found.

## Memory

`ext_q` is 8 B per entry and slot where `ext_pk` was 4 B; `join_plan::Footprint` counts it. The production plans at bases 57-64 grow by 8-11 MiB (0.6-0.8 %); partitions per launch are unchanged (16 on a 10 GB card). The host refuses a shape whose prefilter terms would not fit 18 bits (`b^(mid+1) > 2^18`); no base up to 64 has one.

## Measured

TBD

## Exactness

On the RTX 3080, through CubeCL's CUDA runtime:

- `cubecl_cuda_join_matches_the_cpu_reference`: every test window (bases 10-64; `k` from 1 to 6, with and without a key level; the b50 and b54 windows included), the b57 frontier field's partitions, tight layouts with re-runs and top-layer splits, slices and refused layouts. Join survivors, prefilter survivors and hits equal the CPU reference, batch by batch.
- `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`, which now asserts equality:
  - b58 1e15 (the dense default), 32 partitions: 254,938,965 join survivors and 14,396,829 checked, equal to the CPU join's.
  - b62 1e16, 4 partitions (`NICE_TEST_JOIN_DENSE_FIELD`): 120,013,475 and 7,355,827, equal to the CPU join's. Main's kernel on the same partitions: 120,011,463 and 7,357,700, with 2,012 survivors overrunning its stage.
- `cubecl_cuda_join_matches_the_reference_on_a_whole_field` (`NICE_TEST_JOIN_FULL_FIELD=1`): the whole b42 1e13 field, 1,764 partitions, 417,789,835 join survivors and 16,879,877 checked, no hits, equal to the threaded reference. The stride pipeline agrees.
- The throughput harness with `NICE_TEST_JOIN_COMPARE=1` on 1e14 fields at bases 57, 60, 62 and 64: the counts in the table above, identical to main's, and the stride pipeline finds the same numbers (none).

On lavapipe (llvmpipe, Mesa 25.2.8), the `cubecl_join::` ignored tests (the CPU-reference test above, the production-field sample, join and stride kept apart by ticket) pass through naga's WGSL and through CubeCL's direct SPIR-V compiler (`--features cubecl-spirv`). The SPIR-V build compiles every join kernel variant without `RUST_MIN_STACK`. The WGSL lint with CI's command and require list reports 15 shaders and 0 flagged sites.

Host: `cargo fmt --check`; `cargo clippy -p "*" --all-targets -- -D warnings` with default features, with `nice_client/gpu`, and with `nice_client/gpu,nice_client/cubecl-spirv`; `cargo test --release -p nice_common -p nice_client` with default features and with the `gpu` umbrella.

## Not in this PR

- **Plane-compacting the survivors before the prefilter.** The walk runs `walk_pf` at about 23 % lane use (7.5 survivors per 32-lane round). Gathering a plane's survivors first (prefix sums, shuffles of the entry terms) could run it at near-full lanes, worth an estimated 5-10 % more; not done here.
- **A third prefilter digit (`k + 2`).** It would cut the full checks by about 80 %, but the check kernel is now only a few percent of a field, and testing it on every survivor in the walk costs more than it saves. Run only on the ~6 % that pass, the net is about 1-1.5 %.
- **#235** (top certification from one endpoint) is independent: it changes `top_kernel` and `cert_power`, this changes the bucket and join kernels. The two merge cleanly in `cubecl_join.rs`; the CHANGELOG lines will need the usual one-line resolution.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
