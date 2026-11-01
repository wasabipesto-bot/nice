# Retire the hand-CUDA detailed kernel?

*Line numbers cite `origin/main`; the checkout this was researched from was
48 commits behind and had to be read via `git show origin/main:<path>`.*

## What's true today

- `detailed_kernel` (`common/src/cuda/nice_kernels.cu:682-729`) is unchanged
  since Oct 8 and still divides per number via `num_unique_digits`
  (`nice_kernels.cu:314`) and `scan_digits` (`nice_kernels.cu:216`). CubeCL's
  detailed path moved to finite differences in #225 (`dd08a98`, Oct 31),
  3.3x/4.0x faster than the old division kernel at b40/b50 on an RTX 3080
  (PR-BODY-FD.md:13). The PR body says explicitly: "The hand-CUDA backend
  (`--gpu-backend cuda`) ... still divide[s] per number" (L3/PR-BODY-FD.md:89).
  CubeCL keeps a per-number fallback only for bases above 64 (#225 commit
  message), so hand-CUDA isn't even faster there.
- `auto`'s chain, both modes (`client/src/main.rs:538-696`): CubeCL CUDA →
  CubeCL wgpu → hand-CUDA → exit(1). No Vulkan stop exists any more — the
  hand-written Vulkan backend was removed outright in #193 (`54ae755`,
  Oct 28), "CubeCL's wgpu path now covers every device it served, faster,
  with the join." Hand-CUDA is auto's *third* stop, reached only when both
  CubeCL runtimes fail to start (`main.rs:677-680`: "the corner where both
  CubeCL runtimes failed but NVRTC works"). There's no CPU fallback once
  `--gpu` is requested and every backend fails.
- The one documented real failure (`scratchpad/2026-10-gpu-fail/FINDINGS.md`)
  was a CUDA compat-library/driver mismatch on fleet hosts. It broke CubeCL
  CUDA and would break hand-CUDA identically — both sit on the same
  NVRTC/driver stack — and wgpu couldn't help either way because the image
  has no Vulkan ICD. The fix was correcting the library path, not routing
  around it. **Not verified**: whether the narrow corner hand-CUDA's
  fallback is supposed to cover (CubeCL-CUDA *and* CubeCL-wgpu both fail,
  NVRTC alone works) has ever actually happened on the fleet.
- Niceonly: hand-CUDA's own backend "has no overlap join"
  (`client_process_cuda.rs:347-349`) and serves the stride path for bases
  outside 40-64 or fields under 1e13 (`overlap_join.rs:51-59`:
  `JOIN_MIN_BASE=40`, `JOIN_MAX_BASE=64`, `JOIN_MIN_FIELD_SIZE=1e13`). But
  `CubeclContext` already implements `NiceonlyGpu` fully — `begin_stride`,
  `begin_join`, `join_limits` (`cubecl_backend.rs:2273-2396`) — so
  `--gpu-backend cubecl-cuda` alone covers stride *and* join on NVIDIA.
  Since #207 (`81cfa5e`), `auto` no longer pairs hand-CUDA with the join at
  all (`cuda_pairs_join`, `main.rs:474-479`); only an explicit `cuda` does.
  **Not verified**: whether hand-CUDA's stride kernel beats CubeCL-CUDA's
  own stride kernel outside the join's range — #207 only measured parity on
  join-eligible production fields.

## (1) What gets removed

- **Detailed kernel only**: delete `detailed_kernel`/`num_unique_digits` from
  `nice_kernels.cu` (~90 lines) and the detailed-mode code in
  `client_process_cuda.rs` — `detailed_kernel()` (`:209`), `detailed_defines`
  (`:256`), `process_range_detailed_cuda` (`:666-770`) — plus its tests
  (`gpu_matches_cpu_detailed_small:1666`, `gpu_reads_back_every_near_miss:1696`,
  mirror tests `mirror_num_unique_digits`/`mirror_digit_extraction_*`). The
  niceonly stride kernel, `NiceonlyGpu` impl, and `--gpu-backend cuda` stay.
  Roughly 350-450 lines.
- **Whole backend**: also drop `nice_kernels.cu`'s niceonly kernel, the `cuda`
  feature (`common/Cargo.toml:15,19`), and `--gpu-backend cuda`/`cubecl` →
  `cuda` pairing. Loses the join-less stride path at bases <40/>64 and
  fields <1e13 on NVIDIA specifically through hand-CUDA — but per above,
  CubeCL-CUDA's own stride kernel is unverified-but-plausibly a full
  substitute there.

## (2) What `auto` becomes, what a broken-CubeCL user gets

Detailed-only removal: `auto` becomes CubeCL CUDA → CubeCL wgpu → exit(1).
A user whose CubeCL CUDA runtime is broken already gets CubeCL **wgpu**
today (needs only a graphics driver) before ever reaching hand-CUDA —
losing hand-CUDA only removes the third stop, which per the fleet note
above may never have fired for a real user. No CPU fallback exists in
either case once `--gpu` is requested.

## (3) Risk / tests / CI

Low risk for detailed-only removal: CI's `test-gpu-host` job
(`.github/workflows/rust-build-test.yml:52-69`) only NVRTC-*compiles*
kernels without executing them (`nvrtc_compiles_kernels_for_all_supported_bases`),
so no GPU-execution coverage is lost from CI either way — the `#[ignore]`d
tests already don't run there. README's `cuda` backend row/description
(`README.md:216,239-240`) needs updating either way, as CHANGELOG did for #193.

## (4) Savings

Detailed-only: ~350-450 lines + one less kernel to keep correct under future
digit-extraction changes (3 recent PRs, #228/#229/#230, already needed
parallel fixes across kernels). Whole backend: ~2,600 lines
(`nice_kernels.cu` 729 + `client_process_cuda.rs` 1,850) plus feature wiring;
no dependency drops since `cudarc` is already pulled in by `cubecl-cuda`.

## (5) Recommendation

Remove the detailed kernel now — it's strictly dominated (slower on every
base, on the one path that's actually reachable before it in `auto`, and no
longer CI-exercised for execution), mirroring the Vulkan precedent at much
lower risk since nothing else loses coverage. Hold off on the whole backend
until someone measures CubeCL-CUDA's stride kernel against hand-CUDA's
outside the join's base/size range — that comparison doesn't exist yet, and
the Vulkan removal had it before acting. **Smallest safe step**: detailed
kernel only, as above.
