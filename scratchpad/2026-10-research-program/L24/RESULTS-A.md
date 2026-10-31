# L24 (a) results: the split16 seed as one u32 function (2026-10-31)

**Branch** `pr/fd-seed-split16` on the fork, head **215952d**, one commit on upstream main 7362e18. Not opened
as a PR; the body is `L24/PR-BODY-A.md`.

**Verdict:** exact everywhere it was run, the generated code differs only in the word extraction, and speed is unchanged.
- **M4:** seed 132/132, the FD suite and the near-miss test pass.
- **RTX 3080:** the CUDA suite passes with both seeds.
- **lavapipe:** the seed test (132/132) and the FD suite pass.
- **WGSL/CUDA:** alpha-equivalent to main apart from the word extraction.
- **Speed:** the split16 A/B is within 0.35 %.

## The change (common/src/cubecl_detailed_fd.rs, CHANGELOG.md)

- **`pub(crate) fn fd_seed_split16(nw: &Array<u32>, sd, cd, ds, dc, ddc, base, limbs, chunk_digits, chunk_div, ls, lc, lds, ldc, lddc)`.**
  - n arrives as 32-bit words `nw[0..limbs]`, little-endian. This is the shape `detailed_kernel_u32` already builds (`nw`, four words).
  - The function zeroes its own outputs.
  - The body is the old split16 branch, unchanged except that `w = nw[i]` replaces `w = u32(n_lo/n_hi >> shift)`.
- **`fd_seed`.** The signature is unchanged.
  - The wide branch zeroes its outputs through `fd_clear` (the same loops, moved into the branch). Its generated CUDA source is identical; see below.
  - The split16 branch builds `nw` from `n_lo`/`n_hi` and calls the new function.
- **`pub(crate)`:** `fd_add_top`, `fd_add_const_top`, `fd_ripple`, `fd_to_digits` and `NO_CARRY`, per PROPOSAL §1 (a).
- **Module doc:** one new paragraph saying what is shared and why.
- **CHANGELOG:** one sentence, saying plainly that this is an internal change.
- **No test hook.** The `#[doc(hidden)]` test-only hook did not fall out naturally: the existing seed probe already reaches `fd_seed_split16` through `fd_seed` on wgpu. No wasm code was added.

## RTX 3080 box (Vast 58551941, `nice-research-l24a-seed`, driver 580.159.03, Rust 1.99.1)

Scripts are `raw-a/scripts/p1.sh` and `p2.sh`, and the logs are in `raw-a/box/`. main and the branch were built in separate checkouts with
separate target dirs (`/root/nice` at 7362e18, `/root/pr` at 215952d). Their binaries differ (sha256 in `p1.log`), and each tree's
identity shows in its kernel dumps.

| step | command | result |
|---|---|---|
| fmt | `cargo fmt --all --check` | rc 0 |
| clippy | `cargo clippy -p nice_common --all-targets [--features gpu \| gpu,cubecl-spirv] -- -D warnings` | rc 0 for all three (40.7 s, 55 s, 24 s: real checks) |
| host | `cargo test --release -p nice_common --features gpu` | lib: 220 passed, 41 ignored; integration binaries 0 tests |
| CUDA | `test_pr cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed --ignored --exact` | ok (132 s); b40/b50 2e8 windows "finite differences = division = CPU"; bases 10-28: 73 near-misses |
| CUDA | `… cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed` | ok (4 s) |
| CUDA | `… cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss` | ok (59 s); 73 near-misses match |
| CUDA split16 | `NICE_CUBECL_WIDE=0 … cubecl_cuda_fd_matches_cpu_detailed` | ok (142 s): the shared function on a real GPU, same windows |
| lavapipe | `VK_ICD_FILENAMES=lvp_icd.json … cubecl_fd_seed_matches_cpu` | ok, **132 of 132 windows exact** (23.5 s) |
| lavapipe | `… cubecl_fd_matches_cpu_detailed` | ok (8.4 s); bases 10-24: 27 near-misses |
| lavapipe | `… cubecl_reads_back_every_near_miss`, `… cubecl_matches_cpu_detailed` | ok, ok |

### Kernel dumps and diff

- **Dumps** (`raw-a/box/dumps/*.log.gz`, `CUBECL_DEBUG_LOG`), for both main and the branch:
  - WGSL on lavapipe, from the `cubecl_fd_matches_cpu_detailed` run: the FD kernel at b10-24, b40 and b50, plus the per-number kernel at b40 and b50.
  - WGSL on lavapipe, from the `cubecl_fd_seed_matches_cpu` run: the seed probe kernel at all 44 bases.
  - CUDA C++ from a 4 s `nice_client detailed --gpu --benchmark` run, with the default seed (wide) and with `NICE_CUBECL_WIDE=0`.
- **Tools.** `raw-a/scripts/kdump.py extract` splits a log into kernels.
- **The first diff was useless.** A plain alpha-renamed diff came out huge for two reasons:
  - The compilers list the `var l_mut_*` declarations grouped by type, in an order that varies from run to run. The unchanged per-number kernel differed this way too.
  - One extra generated name shifts every later name.
- **`raw-a/scripts/kalign.py` therefore checks alpha-equivalence instead.** It aligns the two sources with the names erased, then requires one consistent renaming across every aligned line, and compares the declarations as sets under that renaming. The full output is `raw-a/box/kernel-diff-full.txt`.

| kernels | conflicts | differences |
|---|---|---|
| WGSL FD kernel, 14 bases (b10-24, b40, b50) | 0 | the word extraction only (below) |
| WGSL seed probe, 44 bases | 0 | the word extraction only |
| CUDA split16 FD, b40, b50 | 0 | the word extraction only |
| CUDA wide FD, b40, b50 (production CUDA) | 0 | **none** |
| WGSL per-number kernel, b40, b50 (control) | 0 | none |

Every differing line in all 60 changed kernels is one of these:
- a new declaration `var a_X: array<u32, limbs>` (`uint32 l_arr_X[limbs]` in CUDA);
- one blank line;
- per word: `let t = n >> k; let w = u32(t); a_X[i] = w;` added before the output zeroing, with main's `let t = n >> k; let l = u32(t);` becoming `let l = a_X[i];`.

No `/` or `%` and no other u64 operation appears in any differing line. b40 (limbs = 2), with branch-only names primed:

```
  + let l_45' = l_36 >> u32(bitcast<u64>(u64(0)));
  + let l_46' = u32(bitcast<u64>(l_45'));
  + a_44'[u32(0)] = l_46';
  + let l_47' = l_36 >> u32(bitcast<u64>(u64(32)));
  + let l_48' = u32(bitcast<u64>(l_47'));
  + a_44'[u32(1)] = l_48';
  ... (output zeroing, aligned) ...
  - let l_45?main = l_36 >> u32(bitcast<u64>(u64(0)));
  - let l_50 = u32(bitcast<u64>(l_45?main));
  + let l_50 = a_44'[u32(0)];
  (and the same for word 1)
```

### Speed (60 s benchmarks, interleaved; `raw-a/box/bench-*.log`, dmon in `bench-dmon-*`)

| # | seed | tree | b40 | b50 | NiceMark | pwr / pclk median |
|---|---|---|---|---|---|---|
| 1 | wide | main | 2.793e10 | 2.455e10 | 13804 | 177 W / 1725 |
| 2 | wide | branch | 2.722e10 | 2.463e10 | 13647 | 178 / 1695 |
| 3 | wide | main | 2.752e10 | 2.422e10 | 13605 | 178 / 1680 |
| 4 | wide | branch | 2.726e10 | 2.399e10 | 13480 | 178 / 1680 |
| 5 | split16 | main | 2.686e10 | 2.382e10 | 13330 | 178 / 1680 |
| 6 | split16 | branch | 2.685e10 | 2.391e10 | 13353 | 178 / 1680 |
| 7 | split16 | main | 2.653e10 | 2.396e10 | 13288 | 178 / 1665 |
| 8 | split16 | branch | 2.682e10 | 2.354e10 | 13242 | 178 / 1665 |

- **Split16 (the changed path):** +0.17 % and −0.35 % against the main run before it.
- **Wide:** −1.1 % and −0.9 %, on byte-equivalent generated code and identical host code, so about 1 % is this card's drift (power-capped at 180 W, clock falling).
- **On this card,** split16 costs about 2 % against wide.

## Apple M4 (mayalaran, macOS 26.3 25D125, "Apple M4", 10-core GPU, Metal 4)

- **Setup.**
  - Work dir `~/claude-exp-2026-10-31-seed`, with source from `git archive 215952d`.
  - `CARGO_HOME` was an APFS clone of `~/.cargo/registry`, plus 177 lockfile crates missing there and the index, both from ivory.
  - 90-minute watchdog (`raw-a/m4/scripts/`).
- **Build.** `cargo test --release --offline -p nice_common --features cubecl --no-run -j 4`: 103 s, rc 0.
- **Logs** are in `raw-a/m4/logs/`.

| test | result |
|---|---|
| `cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu` | ok, **132 of 132 windows exact**, 44 bases (6.9 s; rerun 3.5 s, 132/132 again) |
| `cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed` | ok (4.3 s): b40/b50 windows exact, bases 10-24 in full |
| `cubecl_backend::tests::cubecl_reads_back_every_near_miss` | ok (1.0 s) |
| control: `NICE_METAL_DIV_REPRO=1 … metal_half_shift_div_repro` | **fails as expected**: variants 0-2 wrong at every k but 32768, variants 3-5 exact. The compiler fault is still present, so the seed test is a live check. |

- **The test binary does not log the adapter.** The device record is from `system_profiler`: one GPU, "Apple M4", Metal 4. wgpu on macOS has only the Metal backend.
- **Machine time:**
  - wall 15:54:35 to 16:29:00 UTC, 34 min (2,065 s), from directory creation to removal;
  - active compute about 2 min: build 103 s at `-j 4`, tests 13 s + 3.5 s, control 1 s.
- **Cleanup.** The watchdog was killed by PID, the directory removed and `/tmp` left clean.

## Notes

- **PLAN.md has no "Correction to the brief" section.** Nothing by that name exists in `L24/` or anywhere in the program directory. I worked from PROPOSAL §1/§2.1/§7 and PLAN §2.
- **Box p1, first attempt:** crates.io stalled ("transfer too slow"). It passed after a `cargo fetch` with retries (`p1-attempt1.log`).
- **NVIDIA Vulkan is unusable on this Vast container** (`NVIDIA_DRIVER_CAPABILITIES=compute,utility`; the ICD fails in `vk_icdGetInstanceProcAddr` even after `libxext6`). `NICE_CUBECL_WIDE=0` on CUDA stood in as the real-GPU split16 path.
- **M4 neighbour:** `~/claude-exp-2026-10-31-browser` (the other agent's) was present at 15:53 and absent at 16:29. My commands and watchdog only ever addressed `~/claude-exp-2026-10-31-seed`.
- **The box is still running, idle,** at $0.113/h. Its self-destroy timer fires about 19:47 UTC (created 15:46:48). I did not destroy it (vastai commands are not mine to run).
