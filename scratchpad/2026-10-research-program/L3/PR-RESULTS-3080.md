# GPU detailed PRs on an RTX 3080 (2026-10-30): readback and finite-difference kernel

Raw logs: `L3/pr-raw/3080/` (`logs/proto` = protocol, `logs/post` = clock-reason samples,
lavapipe/SPIR-V runs and WGSL dumps, `logs/*.log` = builds and tests, `scripts/` = every script
run, `summary.txt` = output of `scripts/summarize.py logs/proto`).

## Branches

| tree on box | commit | what |
|---|---|---|
| `/root/main` | `46e4dc4` | upstream main |
| `/root/rb` | `6a1e396` | `pr/gpu-detailed-readback` (fork): trimmed near-miss readback |
| `/root/fd` | `f3a33cf` | `pr/gpu-detailed-fd` (fork), stacked on `6a1e396`: FD kernel |

`/root/fd` was the readback commit plus the FD files copied over by tar; md5 of
`cubecl_detailed_fd.rs` (`fbb98fd6…`) and `cubecl_backend.rs` (`6d773ee3…`) on the box equal the
committed `f3a33cf` files (`logs/tests_fd.log` first lines; local `md5sum` after the commit).

## Box

- Vast 58401551 `nice-research-fd-3080`, created 12:26 UTC, TTL 5 h.
- **RTX 3080, 20 GB variant** (20480 MiB, VBIOS 94.02.27.00.14), driver 580.126.18 (CUDA 13.0
  driver), CUDA toolkit 12.8 (NVRTC 12.8.93). PCIe 3.0 ×16 (host max gen 3). Host Xeon E5-2673 v4,
  80 threads, 251 GB.
- **Power: default = enforced = max = 320 W** (`box_initial.txt`, `logs/proto/smi_before.txt`).
  Not capped below default, unlike yesterday's card (180 W of a 340 W default).
- **But every kernel runs into it.** Sustained b50 1e10-number windows, 40 in a row per tree
  (`logs/post/perf_*.txt`, sampled 8 s in; `perf_dmon_*.txt`):

  | tree | clock-event reason | power (dmon median) | SM clock (median) |
  |---|---|---|---|
  | main (division) | SW Power Cap: Active | 318 W | 1770 MHz |
  | rb (division) | SW Power Cap: Active | 318 W | 1755 MHz |
  | fd (FD) | SW Power Cap: Active | 317 W | 1860 MHz |

  HW slowdown and thermal slowdown not active. P1 dmon by scenario (median W / MHz per round):
  main b40 318/1875 318/1815 318/1815, b50 316/1785 313/1785 313/1785; rb b40 314/1770 316/1785
  313/1770, b50 316/1755 318/1755 318/1755; fd b40 308/1890 310/1890 309/1890, b50 315/1890
  310/1875 315/1875. So FD clocks about 1.07× higher than division (rb) at the same power;
  per clock FD/rb is the ratio ÷ 1.07. The max SM clock is 2100 MHz; neither reaches it.
- Rust 1.99.1 (repo pin), release profile (LTO, 1 codegen unit), `--features gpu`. Builds:
  `cargo build --release -p nice_client --features gpu`, `cargo test --release -p nice_common
  --features gpu --no-run`, and the harness `cargo build --release -p nice_common --features gpu
  --example fdbench` (`scripts/fdbench.rs` dropped untracked into each tree's `common/examples/`).
- Isolation: `NICE_API_BASE=http://127.0.0.1:9`, stdin `/dev/null`; benchmark logs say "API latency:
  unavailable" and "Not uploading". Nothing reached the API.

## P1: NiceMark detailed GPU, interleaved main rb fd × 3

`nice_client detailed --gpu --benchmark --benchmark-secs 150 < /dev/null` (`scripts/protocol.sh`),
67.5 s timed per scenario, 2e8-number windows at the range start. `auto` picked **CubeCL CUDA device
0** in every run ("GPU initialized: CubeCL CUDA device 0, batch size 50000000").

| scenario | main rounds | main median (spread) | rb rounds | rb median (spread) | fd rounds | fd median (spread) | rb/main | fd/rb | fd/main |
|---|---|---|---|---|---|---|---|---|---|
| b40_detailed | 1.039e10 1.018e10 1.013e10 | 1.018e10 (−0.5/+2.1 %) | 1.108e10 1.106e10 1.114e10 | 1.108e10 (−0.2/+0.5 %) | 3.337e10 3.352e10 3.358e10 | 3.352e10 (−0.4/+0.2 %) | 1.088 | 3.025 | 3.293 |
| b50_detailed | 7.521e9 7.512e9 7.483e9 | 7.512e9 (−0.4/+0.1 %) | 7.980e9 8.093e9 8.052e9 | 8.052e9 (−0.9/+0.5 %) | 2.978e10 2.968e10 2.984e10 | 2.978e10 (−0.3/+0.2 %) | 1.072 | 3.698 | 3.964 |
| NiceMark detailed GPU | 4660 4609 4590 | 4609 (−0.4/+1.1 %) | 4956 4986 4991 | 4986 (−0.6/+0.1 %) | 16615 16624 16682 | 16624 (−0.1/+0.3 %) | 1.082 | 3.334 | 3.607 |

No scenario regresses. Per clock (÷ 1.068 at both bases from the dmon split): fd/rb ≈ 2.83× (b40),
3.46× (b50).

## P2: fixed 2e9-number windows (range start), interleaved, 3 rounds × 5 reps

`fdbench <base> 2e9 5` (`process_range_detailed_cubecl` on `CubeclContext::new_cuda(0)`, the
client's detailed GPU call; JIT warm-up on a 1e6 window first). Per round: median of the 5 reps.

| base | main rounds | main median | rb rounds | rb median | fd rounds | fd median (spread) | fd/rb | fd/main |
|---|---|---|---|---|---|---|---|---|
| 40 | 1.111e10 1.131e10 1.126e10 | 1.126e10 (−1.3/+0.5 %) | 1.121e10 1.139e10 1.142e10 | 1.139e10 (−1.6/+0.3 %) | 3.278e10 3.520e10 3.523e10 | 3.520e10 (−6.9/+0.1 %) | 3.09 | 3.13 |
| 50 | 8.200e9 8.272e9 8.252e9 | 8.252e9 (−0.6/+0.3 %) | 8.238e9 8.301e9 8.321e9 | 8.301e9 (−0.8/+0.2 %) | 2.942e10 2.988e10 3.142e10 | 2.988e10 (−1.5/+5.1 %) | 3.60 | 3.62 |

A window takes 57–63 ms on FD, so these are sensitive to the boost ramp: fd b40 round 1 reps were
3.17e10 3.18e10 3.28e10 3.52e10 3.51e10 (the first three before the clock settled). Every
tree's FNV fingerprint of the full results (distribution + near-miss list) is identical per window:
b40 `3fe3045d83ae3d56` (1 near-miss in this window), b50 `c9458b7bb055f708` (0).

## P4: one production-size field, 1e10 numbers (the server's detailed cap), interleaved, 3 rounds × 2 reps

`fdbench <base> 1e10 2`, range start. Seconds per field (all six reps):

| base | main | rb | fd | fd/main |
|---|---|---|---|---|
| 50 | 1.2228 1.2131 1.2213 1.2144 1.2242 1.2138 | 1.2132 1.2062 1.2239 1.2147 1.2185 1.2102 | 0.3349 0.3172 0.3316 0.3173 0.3325 0.3171 | 3.75× (rate medians 8.211e9 / 3.081e10) |
| 52 | 1.2941 1.2821 1.2964 1.2864 1.2889 1.2854 | 1.2778 1.2699 1.2961 1.2865 1.2925 1.2872 | 0.3445 0.3241 0.3414 0.3227 0.3460 0.3241 | 3.86× (7.764e9 / 2.994e10) |

Fingerprints identical across trees: b50 `3619ae5882d74d25`, b52 `2da21dc1a25c64ba` (0 near-misses
each). Base 52 is not in any test; this is the cross-tree check there. The readback fix is within
noise on a 1e10 field (it saves one ~1.7 ms copy per field). The sustained 40-field runs gave 1.223 s
(main), 1.242 s (rb, run after main, hotter card, 1755 MHz), 0.322 s (fd); those were sequential,
for the clock-reason samples only.

## P3: exactness on the box

- rb, CUDA (`logs/tests_rb.log`): `cubecl_cuda_reads_back_every_near_miss` (bases 10–28 in full, 73
  near-misses), `cubecl_cuda_matches_cpu_detailed`, `gpu_reads_back_every_near_miss` (hand-CUDA,
  10–24), `gpu_matches_cpu_detailed_small`: 4 passed.
- rb, lavapipe (llvmpipe LLVM 20.1.2, naga WGSL): `cubecl_reads_back_every_near_miss` (27
  near-misses), `cubecl_matches_cpu_detailed`, then `lvp.sh rb` (with `cubecl_finds_69_in_base_10`,
  task-cap test (skips itself on llvmpipe), `web_kernel_near_miss_matches_cpu_at_base_49`): all pass.
- fd, lib suite (`logs/tests_fd.log`): 209 passed, 38 ignored (includes
  `plan_covers_exactly_the_legal_range`).
- fd, CUDA: `cubecl_cuda_fd_matches_cpu_detailed` (b40/b50: 13 windows × 4 run shapes, the 2e8
  benchmark windows FD = division = CPU, bases 10–28 full × 4 shapes, 73 near-misses),
  `cubecl_cuda_matches_cpu_detailed`, `cubecl_cuda_reads_back_every_near_miss`: 3 passed, 148 s.
- main, lavapipe (`logs/lvp_main.log`): `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10`,
  task-cap, `web_kernel_near_miss_matches_cpu_at_base_49`: 4 passed, 3.6 s.
- fd, lavapipe naga WGSL (`logs/lvp_fd.log`): the same four plus `cubecl_fd_matches_cpu_detailed`
  and `cubecl_reads_back_every_near_miss`: 6 passed, 15.1 s. On wgpu the seed is split16
  (`wide_chunk: false` in the compile log).
- Near-misses in the existing parity-test windows (`logs/parity_window_misses.txt`, rb tree, fdbench
  1 rep): b10 1e6 from 47: 556,846 (so the trimmed read is exercised at more than half the
  2^20-record buffer); b40 2e6, b62 2e5, b80 1e5: 0.
- main vs fd, every base 10-64 (`scripts/fdcheck.rs`, `logs/fdcheck_{main,fd}.txt`): start, middle
  and end of each range, min(1e8, range) numbers each, through `process_range_detailed_cubecl` on
  CUDA; 132 lines (100 distinct windows, 8.56e9 numbers, 261 near-misses at b10-b35), identical
  hashes line for line (`diff` empty). Whole run 9 s (main) vs 15 s (fd): the difference is NVRTC
  compile time, 44 FD kernels (larger, fully unrolled) against 44 division kernels, about 0.14 s
  more per base, once per process.
- fd, WGSL check (`logs/post/wgsl_*.wgsl`, dumped with `CUBECL_DEBUG_LOG` from
  `cubecl_matches_cpu_detailed` on lavapipe): the FD kernels at b10/b40/b62 declare 8 u64 locals
  (start, count, n, the mask, the near-miss n) and divide only by u32 constants (`/ u32(...)`: 57,
  315, 905 lines; `/ u64`: 0), like the division kernel (4 u64 locals, u32 divisions only).
- fd, CubeCL SPIR-V compiler on lavapipe (`logs/post/lvp_spirv_fd.txt`; binary from
  `cargo test --release -p nice_common --features cubecl-spirv --lib --no-run`, device
  `llvmpipe ... (Vulkan, wgpu<spirv>)`): `cubecl_fd_matches_cpu_detailed`,
  `cubecl_reads_back_every_near_miss`, `cubecl_matches_cpu_detailed`, `cubecl_finds_69_in_base_10`,
  `web_kernel_near_miss_matches_cpu_at_base_49`: 5 passed, 19.7 s. Again with `NICE_CUBECL_WIDE=1`
  (u64 seed division; `wide_chunk: true` in `logs/post/spirv_wide_compile.log`): FD test and
  `cubecl_matches_cpu_detailed` 2 passed, 13.8 s. (The first SPIR-V build attempt in `post.sh`
  failed only because `--no-run` without `--lib` also built the untracked CUDA-only example;
  `spirv.sh` reran it with `--lib`.)
- fd, every ignored test the lavapipe CI job runs, from the gpu binary minus CUDA, hand-CUDA and
  timing tests (`logs/post/lvp_full_fd.txt`): 19 passed, 118.7 s (nice-only, join, web included).
- 4-core lavapipe timing (`taskset -c 0-3`, `LP_NUM_THREADS=4`; `logs/post/lvp_4core_timing.txt`):
  fd `cubecl_fd_matches_cpu_detailed` 7.37 s, `cubecl_reads_back_every_near_miss` 3.22 s,
  `cubecl_matches_cpu_detailed` 4.06 s; rb `cubecl_reads_back_every_near_miss` 3.89 s.
- naga-cli 29.0.4 (the lockfile's naga/wgpu version; `scripts/naga.sh`, `logs/post/naga.txt`):
  the dumped WGSL of the FD kernels (b10, b40, b62) and the division kernel (b10, b80) all validate
  and translate to MSL (default `metal1.0` header and `--metal-version 2.4`) and to SPIR-V, exit 0;
  `logs/post/wgsl_*.metal`. No Apple compiler was run: Metal is covered only by the macOS CI job.

## Incidents

- 14:18–14:24 UTC the box's ssh port refused, then timed out; it came back with the box still
  running (uptime unchanged). Nothing was running on it at the time.
- The rustup install raced between the first two parallel builds (`main` failed on a component
  download rename; rerun). `cargo clippy` was unusable on the box afterwards ("not applicable to the
  toolchain"), so clippy ran on ivory.

## Commands

```sh
# ivory
cd /home/claude/projects/nice && git fetch -q origin main && git fetch -q fork
git worktree add .worktrees/pr-readback origin/main -b pr/gpu-detailed-readback
git worktree add .worktrees/pr-gpu-fd pr/gpu-detailed-readback -b pr/gpu-detailed-fd
cargo fmt --all --check
cargo clippy --all-targets --features gpu -- -D warnings          # both branches, clean
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings  # fd, clean
# box
git worktree add /root/main 46e4dc4; git worktree add /root/rb origin/pr/gpu-detailed-readback
git worktree add /root/fd origin/pr/gpu-detailed-readback   # + FD files by tar (md5 above)
/root/build.sh <tree>        # client release + nice_common test --no-run (scripts/ on ivory)
/root/build_ex.sh <tree>     # fdbench example
/root/tests_rb.sh; /root/tests_fd.sh; /root/lvp.sh <tree> <test bin> [filters]
/root/protocol.sh            # P1, P2, P4 interleaved, dmon alongside
/root/post.sh                # clock reasons, lavapipe, WGSL dump, cubecl-spirv
/root/spirv.sh               # cubecl-spirv lib test binary + lavapipe runs
/root/naga.sh                # naga-cli 29.0.4 WGSL -> MSL
/root/lvp_full.sh            # every CI lavapipe test (fd)
/root/fdcheck.sh             # cross-tree fingerprints, bases 10-64 (scripts/fdcheck.rs)
python3 scripts/summarize.py logs/proto > summary.txt
```
