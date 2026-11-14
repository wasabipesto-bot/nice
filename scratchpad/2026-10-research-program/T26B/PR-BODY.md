## What

The GPU stride walk (`niceonly_kernel`) queues its cross filter's survivors in shared memory and checks them in dense
waves. Both queues assumed every plane is full and laid out along `UNIT_POS_X`:

- **plane-scoped queue** (default on CUDA and `cubecl-spirv`): each wave drained `PLANE_DIM` entries through lanes
  `UNIT_POS_X % PLANE_DIM`, and a plane's queue sat at `PLANE_POS * 2 * PLANE_DIM`;
- **cube-scoped queue** (default on WGSL): lane 0 published its plane's total at `UNIT_POS_X / PLANE_DIM`, and every
  lane summed `CUBE_DIM_X / PLANE_DIM` of them.

On a partly filled plane, survivors were dropped unchecked, silently. This PR makes both queues take everything from
the lanes that actually run, and fails the field if a queue checks fewer survivors than it queued.

## Why

Vulkan does not promise full subgroups, and the subgroup layout is up to the driver. No device in use is known to
split a 256-wide workgroup unevenly, so this is a robustness fix, but a missed survivor is a missed candidate.
Reproduced on main with a test-only cube size (one cube):

| survivors lost (b50 window, 30,449 survivors) | cube 256 | cube 100 | cube 48 | cube 36 |
|---|---|---|---|---|
| RTX 3080 (CUDA), plane-scoped | 0 | 1,064 | 5,072 | 2,958 |
| RTX 3080 (CUDA), cube-scoped | 0 | 1,217 | 10,152 | 3,382 |
| lavapipe (WGSL and SPIR-V), cube-scoped | 0 | 1,217 | 0 (8-lane subgroups) | 3,382 |

## How

- **Ranks and counts from the running lanes:** `plane_ballot` (planes of at most 32 lanes, as `top_slot`) or one
  `plane_exclusive_sum` and one `plane_sum` of a packed word. A wave takes one entry per running lane.
- **Plane-scoped queue:** each plane's lowest running lane reserves two slots per running lane once from a shared
  counter, so the queues are disjoint and fit however the cube is cut.
- **Cube-scoped queue:** each plane's lowest running lane adds its survivors and its lanes with ranges left to a shared
  word with one atomic, and broadcasts the old value. Two words alternate between iterations, so the loop keeps its two
  barriers; the serial walk over plane totals is gone.
- **Account:** each lane counts survivors queued minus checked, and the same for their low words; a cube writes its
  sums to two new count words only if not zero. The host fails the field unless both are zero, as for an output
  overflow.

## Soundness

For any population, running lanes get distinct ranks `0..n` and survivors distinct positions; the plane-scoped queue
holds fewer than `n` entries between waves and a wave checks the newest `min(n, qn)`; the cube-scoped planes' atomics
cut each iteration's survivors into disjoint ranges. So every queued survivor is checked once, without `PLANE_DIM`, a
lane 0, or a linear layout. Remaining assumptions, as in `top_slot`: lanes that run a ballot or scan also run the
following shuffle or sum, and `UNIT_POS_PLANE` is the ballot bit (true for CUDA cubes of whole warps).

## Exactness

| run | result |
|---|---|
| new partly-filled-plane test, RTX 3080 (one cube of 256/100/48/36 units, both queues; ballot form, and the scan form forced by a test knob) | 64 runs exact (main: 24 of 32 lose survivors) |
| the same with nine more one-cube sizes (255 down to 9 units), RTX 3080, ballot form | every run exact |
| same, lavapipe WGSL and SPIR-V (cube-scoped queue, both forms) | 32 runs exact each (main: 8 of 16 lose) |
| fault tests (skip one entry; check one twice) | the field fails with the account's message (CUDA, lavapipe) |
| every `cubecl_backend` device test, CUDA and lavapipe (WGSL, SPIR-V) | pass |
| 120 b54 fields of 1e13 and 6 NiceMark sweeps through the client's path | account zero, same hits as main |
| host tests, fmt, clippy `-D warnings` (also `nice_client/gpu,cubecl-spirv`) | clean |

CUDA always takes the ballot form. The scan form can only be forced there by the test knob, and CubeCL's CUDA scans read
every lane of a warp, so on partly filled warps it is undefined: it is exact at the test's sizes (last warps of 4 and 16
lanes) and wrong in 24 of 60 plane-scoped runs at 255, 63, 31, 17 and 9 units. The account failed the field in every one
of those runs. WGSL, SPIR-V and Metal define their scans over the running lanes.

The other kernels' sources are untouched; their generated CUDA (join kernels) and WGSL (all lint shaders) compare
identical to main's.

## Cost

RTX 3080 at the host's 130 W power cap, interleaved with main, card cooled before each run. Every run forces the stride
walk (`NICE_JOIN_ROUTE=stride`), which production uses only for the fields the overlap join does not take, so none of
this is a client-wide speed-up:

| | main | this PR | |
|---|---|---|---|
| 40 b54 fields of 1e13, plane-scoped queue (median of 3) | 83.86 s | 73.58 s | ×1.14 |
| same, cube-scoped queue (`NICE_CUBECL_PLANE_COMPACT=0`) | 93.08 s | 73.91 s | ×1.26 |
| plane-scoped, scan form forced (test-only knob; median of 5) | 83.91 s | 84.41 s | +0.6 % |
| cube-scoped, scan form forced | 93.08 s | 91.36 s | −1.8 % |
| NiceMark nice-only, stride forced (median of 6) | 95.1 | 117.4 | ×1.23 |

The gain is the ballot form: two ballots replace CubeCL's exclusive scan and sum (chains of warp shuffles) in every
iteration. Not measured at the card's default power limit: under the cap main ran at 1,120–1,160 MHz and this PR at
1,380–1,415 MHz, so part of the gain here is clock. The scan form, forced on the RTX 3080, costs about 0.6 % on the
plane-scoped queue, within main's run-to-run spread.
NiceMark per scenario: b58 msd-weak ×1.46, b60 ×1.13, b62 ×1.39, b58 msd-strong ×1.02 (CPU rejection; rounds spread
8 % on both sides, one of six at ×0.94).

## What a wgpu device should expect

Not measured (no AMD or Apple GPU here). Devices with 32-lane planes (Apple M4, cube-scoped queue) take the ballot
form; 64-lane devices (an RX 9070 XT, if CubeCL reports 64 lanes) take the scan form: about +0.6 % on the plane-scoped
queue and −1.8 % on the cube-scoped one, as measured on CUDA. The direction should carry; the size will not.

## Not in this PR

- The plane-scoped queue still cannot run on llvmpipe (it loses the same survivors on main and here with full
  subgroups, and none with one subgroup per workgroup), so it stays off on software rasterizers. The account does not
  catch that loss there either: its report relies on the final workgroup barrier, which llvmpipe mishandles after
  subgroup barriers.
- CubeCL's CUDA lane id (`AbsolutePos % PLANE_DIM`) is wrong past the first cube when cubes are not whole warps.
- A rank helper shared with `take_entries` (#251) and `top_slot` (#260) once those land.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
