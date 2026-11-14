## What

The GPU overlap join's FD top kernel appends its kept tops through `top_slot`, one atomic per plane (GPU subgroup). That append ran through lane 0: lane 0's group was tested, only lane 0 took the group counter's atomic, and its result was broadcast. This PR takes all three from the lanes that actually run the call, and lets the host check the stage.

- **Leader = the lowest kept lane** of the lanes running the call. If every kept lane is of its group `g0`, the leader alone does `fetch_add(n)` and the result reaches the others from it. Planes of at most 32 lanes (`ballot_append`, as before) use one ballot: count and rank are popcounts, the leader is the lowest set bit, and `g0` and the result come by `plane_shuffle` from that lane. Wider planes use sums and an exclusive scan over the active lanes, where only the leader's term is nonzero. A plane whose kept tops straddle groups still takes one atomic per kept lane. The number of plane operations is unchanged (4 with the ballot, 5 with the scans).
- **Account:** two new words in `ran`: the tops written minus the records reserved in `grp_cnt`, and the indices of the records written minus those reserved (mod 2^32), summed per cube in shared memory. After every batch (`run_pass`, `run_partition`) the host requires both to be zero (`top_complete`); otherwise the field fails and nothing is submitted.

## Why

Vulkan does not promise full subgroups, and wgpu does not ask for them. On a plane without lane 0, no lane took the atomic: the kept tops were written at offsets other planes also use, never counted, and never read by the join, a silent loss of candidates. No production device is known to launch such planes (256-thread groups are full on CUDA, Metal and RADV), so this is a robustness fix. #251 removed the same assumption from the check kernel.

## Soundness

Let P be the lanes that execute one call together. A ballot clears inactive lanes' bits on every backend, WGSL, SPIR-V and Metal define sums and scans over the active invocations, and the shuffles read the leader, which is in P. So P's kept lanes get ranks exactly 0..n-1 and there is one leader. If they share `g0`, one `fetch_add(n)` reserves `[a0, a0+n)` of that group and each writes `a0 + rank`; otherwise each reserves its own record. Every kept top thus gets a distinct record of its own group inside the counted range, for any population: full, partly filled, without lane 0, with holes, or split across calls.

Still assumed, as before and as in #251: the lanes that run the ballot (or scan) run the shuffle (or sum) after the leader's `if` together; `UNIT_POS_PLANE` is the lane's ballot bit (`CubeCL` lowers it on CUDA/HIP as `AbsolutePos % PLANE_DIM`, right for 256-unit cubes); CUDA/HIP's butterfly sums need full planes (CUDA never takes the scan form; HIP wave64 runs 256-unit cubes as full waves). If a device broke one of these, or misreported a 64-lane plane as 32, the account fails the field instead of losing tops.

## Exactness

| run | device | result |
|---|---|---|
| reproduction: main's append with every plane's lane 0 sitting out (test-only) | lavapipe, WGSL / SPIR-V | fails: 84 of 276 runs lose tops, 8.9 M of 13.0 M kept tops lost (both compilers) |
| main's append in the same harness, partly filled planes (cubes of 100/48/256) with lane 0 present | lavapipe, RTX 3080 | right: a partly filled plane there always has lane 0. On CUDA, a lane 0 that sits out makes the full-mask `_sync` intrinsics undefined (the run hangs) |
| `top_fd_appends_every_top_on_partly_filled_planes` (both forms, cubes 100/48/256, lane 0 out) | lavapipe WGSL / SPIR-V | ok, 552 runs each, 6.5 M tops |
| `cubecl_cuda_top_fd_appends_every_top_on_partly_filled_warps` (one cube for 100/48) | RTX 3080 | ok, 230 runs, 4.8 M tops |
| `check_lost_tops` (in `check_all`): two test-only faults fail a field and a partition's re-run with the account's error | RTX 3080, lavapipe | ok |
| every CUDA test of `cubecl_join` / every wgpu test (lavapipe, both compilers) | RTX 3080, lavapipe | ok |
| dense compares vs the CPU join: b60 1e16, b62 1e17, b64 1e17 (8 partitions) | RTX 3080 | ok, survivors and checked equal to the CPU join |
| host tests (`cargo test --release -p nice_common --features gpu --lib`), fmt, clippy `-D warnings` (default and gpu+spirv) | | ok, clean |

The generated CUDA and WGSL of every kernel other than `top_fd_kernel` are identical to main's (modulo `CubeCL`'s numbering of locals and its per-process shared-memory layout).

## Cost

COST

## Not in this PR

- The join kernel's survivor count (telemetry only), the niceonly stride kernels' plane queues, and `top_kernel` (one atomic per top, no plane operations) are unchanged.
- A device that runs planes without lane 0 has not been seen. The reproduction uses a test-only mode that makes lane 0 sit out.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
