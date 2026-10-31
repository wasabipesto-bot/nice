# Stride prefilter: extract low digits without dividing a half-width shift

## What and why

Apple's GPU compiler (seen on an M4, macOS 26.3, through wgpu, naga's MSL and Metal) miscompiles an unsigned division or
remainder by a constant that is not a power of two when the dividend is a right shift by half its width:

- `naga_div(x >> 16u, K)`;
- `(x >> 16u) % K`;
- `uint(ulong p >> 32) / K`.

That is what made #225's finite-difference seed give wrong digits on the M4, and what #228 removes from the overlap
join's top kernel.

The stride kernel's low-digit prefilter (`candidate_check` in `common/src/cubecl_backend.rs`) has the same shape:

- It long-divides n by `pre_chunk_div` = b³ in split16 steps to peel off the low digit chunks.
- The loops are unrolled and every pass starts from a remainder of 0, so the first dividend of each pass is exactly
  `v[top] >> 16`.
- At two limbs (bases 33-40) `v[top]` is `u32(n_lo >> 32)`, so that dividend is `u32(n_lo >> 32) >> 16`.

This code already has a history on Apple GPUs. The comment above these lines records it: a multiply-subtract form of
them failed `cubecl_prefilter_survivors_match_the_host_mirror` there, and the current paired `/` and `%` replaced it
and passed. Nobody knows why the pairing avoids the bug.

The current code still passes on an M4 today: the probe test at b30, b34 and b40 passed twice, and
`cubecl_matches_cpu_niceonly`, `cubecl_cross_filter_survivors_match_the_host_mirror` and
`cubecl_niceonly_finds_69_in_base_10` passed too. So this PR is a precaution. It removes the pattern instead of relying
on a form that happens to compile correctly.

## The change

- **16-bit limbs.** n is held in 16-bit limbs, one to a u32, as #228 does for the join's powers.
- **Top pair first.** Each pass starts with the top two limbs, the value hi·2^16 + lo.
  - With 2^16 = Q·K + R (comptime constants), its quotient is hi·Q + (hi·R + lo) / K, and its remainder is
    (hi·R + lo) mod K.
  - So the dividend is the sum hi·R + lo, which is at most (2^16 - 1)·K < 2^32.
- **Why the pair is not divided as one u32, as #228 does.**
  - In #228 the pair is a u32 sum the schoolbook multiply produced.
  - Here, in the first pass at two limbs, the pair would be `u32(n_lo >> 32)` itself, the u64 form of the same fault.
  - A compiler can fold `((x >> 16) << 16) | (x & 0xFFFF)` back to `x`, so splitting it in halves first would not
    hide that.
- **The other steps.**
  - Later passes take the previous quotient as the pair.
  - Every other step divides `rem << 16 | limb`, with the remainder carried from the step before.
  - Remainders are computed by multiply-subtract, like the digit scan.
- **Same result.** The extracted chunks are the same, so the prefilter passes exactly the same candidates.
  - Each pass does one division fewer than before (2L - 1 instead of 2L), and no `%`.
- **Comment and CHANGELOG.** The comment now states the cause and the construction. The CHANGELOG gets one line.

## Exactness

Tests ran on an RTX 3060 in two ways:

- CubeCL's CUDA runtime;
- wgpu (WGSL through naga) on lavapipe (llvmpipe), the only Vulkan device present.

| test | CUDA | lavapipe |
|---|---|---|
| `cubecl_prefilter_survivors_match_the_host_mirror` (b30, b34, b40; every lane width) | pass (local copy*) | pass |
| `cubecl_cross_filter_survivors_match_the_host_mirror` (b40, b50) | pass (local copy*) | pass |
| `cubecl_matches_cpu_niceonly` | pass (`cubecl_cuda_matches_cpu_niceonly`) | pass |
| `cubecl_niceonly_finds_69_in_base_10` | not run | pass |
| prefilter survivors against the host mirror, 1e6 at the start, middle and end of every base 27-40 that has candidates (local*) | pass | pass |

\* The probe and cross-filter tests are wgpu-only, so I ran local copies of them against `CubeclContext::new_cuda(0)`.
These copies, and the start/middle/end sweep, are not part of this PR.

**Counts.**
- The survivor counts equal main's on both runtimes:
  - b30: 396 of 159,058 candidates;
  - b34: 2,099 of 350,205;
  - b40: 4,472 of 288,591.
- The CUDA cross-filter run passed 283 survivors at b40 and 30,449 at b50, in each of its three compact/plane
  variants.
- The sweep covered 27 windows at bases 28-30, 32-34, 37, 38 and 40; bases 27, 35 and 39 have no stride residues.
  - It reached one limb (b28-32, including b32's power-of-two K = 32768) and two limbs (b33-40), up to each range's
    end.
  - 9,675 of 1,475,822 candidates survive. That equals the mirror on both runtimes, and main's survivors in every
    window.

**Which tests cover this code.** The probe tests and the sweep exercise it; the parity tests mostly do not.
- `cubecl_matches_cpu_niceonly` has no prefilter at b10, b12 or b25.
- Its b40 window leaves no range after the MSD filter.
- b10 has no prefilter, so `cubecl_niceonly_finds_69_in_base_10` does not reach this code either.

**Integer model.** A model of the new division agrees with n mod K^p for every chunk divisor of bases 10-40, at one
to four limbs. It covered about 3 million values of n, with no u32 overflow.

**Lint and host suite.**
- `cargo fmt --all --check` and `cargo clippy -p nice_common --all-targets --features gpu -- -D warnings` are clean.
- The host suite (`cargo test --release -p nice_common --features gpu`) passes: 208 tests.
  - One parallel run failed `gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field`. That
    test uses a mock device and none of this code. It then passed alone three times and in two more full runs.

### WGSL before and after

The method:
- Dump the stride nice-only kernel's WGSL on lavapipe with `CUBECL_DEBUG_LOG`, using production flags (one
  `process_niceonly` field per base).
- Scan it for any division or remainder by a literal constant that is not a power of two, whose dividend is
  `x >> 16`, `u32(u64 >> 32)` or `u32(u64 >> 32) >> 16`.
- Literal zeros are folded first, and so is a word rebuilt from its own halves.

| base | limbs | main | this PR |
|---|---|---|---|
| 30 | 1 | 6 | 0 |
| 34 | 2 | 6 | 0 |
| 40 | 2 | 6 | 0 |

- **Main's sites.** They are the `/` and `%` of the first step of each of the three passes. At b34 and b40 the first
  pass divides `u32(n_lo >> 32) >> 16`.
- **This PR's divisions by K.** Each one in the prefilter now divides either the sum `hi·R + lo` or
  `rem << 16 | limb`, where `rem` is a run-time remainder.
- **Probe builds.** The kernels the tests compile at b30, b34 and b40 had 6 sites each on main and have none here.
- **Kernels without a prefilter.** The kernels the same tests compile at b10, b12, b25 and b50 are identical between
  main and this PR, apart from the order of their variable declarations.

## Not in this PR

Nothing else is in this PR.

- **Where it runs.** The prefilter runs only at bases 40 and below (`GPU_PREFILTER_MAX_BASE`) and is compiled out
  above, so the kernels for the live bases do not change.
- **Speed.** Speed at bases 40 and below was not measured, since no production work runs there.
- **Apple hardware.** This PR has not been run on Apple hardware. The current code already passes there, so an M4 run
  of the same four tests could only confirm that this does not regress.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
