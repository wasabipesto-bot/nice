**Title:** GPU detailed mode: the finite-difference seed in one u32 function, shared with the coming browser kernel

---

The browser's WebGPU path has no 64-bit integers, so a browser version of the finite-difference detailed kernel (#225) cannot call `fd_seed`, which takes n as two u64 halves. The seed's wgpu flavour already does all its arithmetic in u32: it is the split16 form that keeps it exact on Apple GPUs. This PR moves that body into its own `pub(crate) fn fd_seed_split16`, which takes n as 32-bit words, the form the browser kernel already holds n in. `fd_seed` keeps its signature. On wgpu it splits n into words and calls the new function, and the CUDA/HIP branch is untouched. Results and speed are unchanged. One commit on `main`.

## The change

All of it is in `common/src/cubecl_detailed_fd.rs`, plus one CHANGELOG line.

- **`fd_seed_split16(nw, sd, cd, ds, dc, ddc, base, limbs, chunk_digits, chunk_div, ls, lc, lds, ldc, lddc)`.**
  - This is the split16 body, moved unchanged.
  - It reads n's 32-bit words from `nw[0..limbs]`, little-endian, instead of shifting them out of two u64 values.
  - It zeroes its five outputs itself, so a caller needs nothing else. Before, `fd_seed` zeroed them ahead of the branch.
- **`fd_seed`.**
  - The wide (CUDA/HIP) branch zeroes its outputs through a small `fd_clear` helper and is otherwise as before.
  - The split16 branch writes n's `limbs` words into a local array and calls `fd_seed_split16`.
- **Visibility.** `fd_add_top`, `fd_add_const_top`, `fd_ripple`, `fd_to_digits` and `NO_CARRY` become `pub(crate)`, for the browser kernel's step loop. No signatures or behaviour change.
- **The Apple fix is untouched.** `fd_to_digits` is unchanged, so every chunk's division still starts from the top two limbs, and no dividend is a bare half-width shift. The PR adds no division.
- The module docs say which items are shared and why.

## Exactness

- **Apple M4** (macOS 26.3, 25D125; Metal through wgpu and naga):
  - `cubecl_fd_seed_matches_cpu`: **132 of 132 windows exact.** That is 44 bases × (range start, middle and end) × 1,024 n, checking every digit of all five arrays.
  - `cubecl_fd_matches_cpu_detailed` and `cubecl_reads_back_every_near_miss` pass.
  - As a control, `metal_half_shift_div_repro` (with `NICE_METAL_DIV_REPRO=1`) still fails on the same machine: variants 0–2 are wrong and the controls are exact. The compiler fault the seed avoids is still present, and the seed test would catch it.
- **CUDA** (RTX 3080, driver 580.159.03):
  - `cubecl_cuda_fd_matches_cpu_detailed`, `cubecl_cuda_matches_cpu_detailed` and `cubecl_cuda_reads_back_every_near_miss` pass.
  - CUDA normally uses the wide seed, which this PR does not change. With `NICE_CUBECL_WIDE=0`, the CUDA runtime takes the split16 seed instead. `cubecl_cuda_fd_matches_cpu_detailed` also passes that way, including both 2e8-number benchmark windows against the CPU and the per-number kernel, and bases 10–28 in full. That runs the shared function on a real NVIDIA GPU.
- **lavapipe** (naga WGSL): `cubecl_fd_seed_matches_cpu` (132 of 132), `cubecl_fd_matches_cpu_detailed`, `cubecl_reads_back_every_near_miss` and `cubecl_matches_cpu_detailed` pass.
- **Lint and unit tests.**
  - `cargo fmt --all --check` is clean.
  - `clippy -D warnings` is clean on `nice_common --all-targets` with the default features, with `gpu`, and with `gpu,cubecl-spirv`.
  - The `nice_common` lib suite passes: 220 passed.

## Generated code

The kernels were dumped with `CUBECL_DEBUG_LOG` on `main` (7362e18) and on this branch, then compared up to renaming of `CubeCL`'s generated names. The two sources are aligned line by line with the names erased. Across every aligned line, a single consistent renaming maps `main` onto the branch, with 0 conflicts.

- **WGSL.** This covers the finite-difference kernel at bases 40 and 50 (and 10–24, the test's other bases), and the seed test's kernel at all 44 bases 10–64. The only difference is where n's words are extracted.
  - On `main`, `u32(n >> 0)` and `u32(n >> 32)` are computed where the 16-bit split uses them.
  - On the branch, the same expressions are computed first and stored in a `limbs`-word array (`array<u32, 2>` at bases 40 and 50). They are read back at the same place.
  - Per word, that is 3 lines added and 2 lines replaced by 1, plus the array's declaration.
  - No division, no new shift and no other u64 operation. Every other line maps one to one.
- **CUDA C++.**
  - The wide seed, the production CUDA path, is identical at bases 40 and 50.
  - The split16 source (`NICE_CUBECL_WIDE=0`) differs exactly as the WGSL does.
- **Control.** The per-number kernel's WGSL is identical.

## Speed

Speed is unchanged. Measured on an RTX 3080 with `nice_client detailed --gpu --benchmark --benchmark-secs 60`, `main` and the branch interleaved twice, for each seed flavour:

| seed | run | b40 (numbers/s) | b50 (numbers/s) | score |
|---|---|---|---|---|
| wide (CUDA default) | main | 2.793e10 | 2.455e10 | 13,804 |
| | branch | 2.722e10 | 2.463e10 | 13,647 |
| | main | 2.752e10 | 2.422e10 | 13,605 |
| | branch | 2.726e10 | 2.399e10 | 13,480 |
| split16 (`NICE_CUBECL_WIDE=0`) | main | 2.686e10 | 2.382e10 | 13,330 |
| | branch | 2.685e10 | 2.391e10 | 13,353 |
| | main | 2.653e10 | 2.396e10 | 13,288 |
| | branch | 2.682e10 | 2.354e10 | 13,242 |

- **Split16, the path this PR changes:** within 0.4 % of the `main` run before it (+0.2 %, −0.3 %).
- **Wide:** the generated code is identical, so the 1 % between pairs is this card's run-to-run drift. The SM clock median fell from 1,725 to 1,665 MHz over the eight runs.

## Not in this PR

- The browser kernel: a u32-only variant of the finite-difference kernel for WebGPU that calls `fd_seed_split16`, behind the browser runner's existing GPU entry point.
- The browser parity step that checks it, and today's browser kernel, against the CPU in a headless browser.

Both will be follow-up PRs. This one changes no behaviour on its own.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
