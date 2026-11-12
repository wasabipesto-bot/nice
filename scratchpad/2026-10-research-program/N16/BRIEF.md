# N16 brief: a harness that splits the join's fixed per-batch cost, ready for a window on the RX 9070 XT (2026-11-12)

You are an engineer on the nice research program (repo `~/projects/nice`, upstream
`wasabipesto/nice`, fork `wasabipesto-bot/nice`). Read first, in this order:
`../N13/RESULTS.md` (yesterday's measurements on the user's RX 9070 XT, wgpu on Vulkan through
CubeCL's SPIR-V compiler: all of it), `../N13/BRIEF.md` (the machine's rules and the workspace
recipe), `../N13/raw/scripts/` (the build, chain and analysis scripts that ran there),
`../L51/RESULTS.md` (how the profile and the ablation modes work), the module docs at the top of
`common/src/cubecl_join.rs` and the body of `join_kernel` on tree E (below).

## Why

That one card (demoux) does about 81 % of the nice-only search; NVIDIA through CUDA does 13 %.
Yesterday's window found that on it **the join's "base" is about a third of a field
(~1.0 ps per pair, against 0.26 ps and 11 % on an RTX 3080)**. "Base" is what is left of the join
phase with the AND, the walk, the prefilter and the stage/check switched off (ablation mode `z`):
the work-item headers and their barriers, the batch loads of the top records into shared memory,
the transposed copy, the entry waves' loads and loops, and whatever each launch costs on the host
and in the driver. Nobody has split it. If it fell to NVIDIA's cost per pair the card would gain
about ×1.3. Two tunings measured there point the same way and are unexplained: `TOP_CAP` 128
(which also makes the work group 128 threads, `JOIN_WG == TOP_CAP`) wins 4–5 % there and loses
4 % on NVIDIA; CUDA's denser plan (`NICE_EXP_VRAM=1`, 44 % fewer launches) wins 4 %.

Hypotheses to separate (add your own after reading the kernel):
- H1 **per-launch fixed cost** (encode, submit, wait, readbacks in wgpu/RADV): 7,959 launches for
  a 75 s field; the denser plan saved 2.8 s with 3,501 fewer launches (0.8 ms each, if all of the
  saving is launches and none is fewer FD seeds).
- H2 **work groups of several waves**: RADV compute runs 64-lane waves, so a 256-thread group is
  four waves and every `sync_cube` is a real barrier across them (as far as I know ACO emits no
  barrier at all when the work group fits one wave); the kernel has three barriers per work
  item, two per batch, more per entry wave.
- H3 **shared-memory traffic** (the batch loads write 6–8 words per top; the transposed copy
  reads 64 words per thread; atomics on `s_cw`).
- H4 **code generation** of CubeCL's SPIR-V through ACO (bounds clamps on shared-memory indices,
  unrolled loops that do not pipeline, 64-bit emulation, spills).
- H5 **entry waves** (two entries per thread, 67–70 % of the lanes in use, divergence).

The card can only be measured in a window the user grants on their desktop, and each hour of it
stops the search's main engine. **Your job is to make that window short and decisive: a tested
harness, tested scripts and a run plan of at most 90 minutes, plus everything that can be
learned without the card.** You do not touch demoux.

## The box

Instance **60315324** (`nice-research-n16-prep`, RTX 3080, 7 h TTL from ~06:10 UTC). From
`~/projects/nice/scratchpad/2026-10-research-program`: `python3 vast.py ssh 60315324` prints the
ssh command; wait for `/root/READY`. `/root/nice` is a clone of the fork with remote `upstream`
fetched. All builds and runs happen there (ivory has 7.6 GB free: no builds on ivory). lavapipe
(`mesa-vulkan-drivers`) gives the wgpu path on the box, as earlier work did ("lavapipe with both
compilers"); CUDA gives the NVIDIA column. Record the card's power cap and clock and each
process's join-kernel register variant where you time on CUDA, as L51 did.

## Trees

- **E** = fork `exp/b64-profile` (44eee52: main c0c357a's join kernels + #250's FD top kernel,
  L51's profile timers, ablation modes `NICE_EXP_JOIN_ABL` and knobs `NICE_EXP_JOIN_*`) plus
  yesterday's three patches from `../N13/raw/scripts/` (`patch_harness.py`, `patchC.py`,
  `patch_dense_wgpu.py`). Start a new fork branch **`exp/n16-join-base`** from 44eee52, commit the
  three patches' result as the first commit, and build on that. Keep E's join kernels as they
  are (comparability with yesterday's numbers); everything new is behind `NICE_EXP_*` switches
  that default to today's behaviour.
- Current upstream main is `5b1d627` (#250 merged). Task D's branch starts there.

## Task A: what yesterday's logs already say (ivory only, first 30 minutes)

From `../N13/raw/demoux/` and `analysis.txt`: re-derive the base on that card from the whole-field
totals per mode (check the 36 % / 33 %), the seconds per launch at each plan, and bound H1 from
the sparse-plan against denser-plan runs (state how much of that saving could instead be FD
seeds, from the top phase's own numbers). Say what the existing data cannot separate.

## Task B: the split harness (the must-have)

On `exp/n16-join-base`, all selectable per process by environment variable, each documented in
the code and in your results with exactly what it executes:

1. **Base-split modes** below mode `z` (timing only; counts need not be preserved, say so in the
   output line): dispatch only (the kernel returns after its first barrier); + the work-item
   headers and their three barriers; + the batch loads of the top records into shared memory;
   + the transposed copy; + the entry waves' loads and loops without the AND (= today's `z`).
   If a finer or different cut is more natural in the code, use it and say why.
2. **Host-side launch accounting** on the wgpu path and on CUDA: launches, syncs and readbacks
   per field, and wall time split into encode/submit, wait and readback, summed per field (cheap
   timers; check that they do not move the total by more than 0.5 %). A knob that forces the
   partitions per launch (1, 2, 4, the plan's own, the denser plan's) so that seconds against
   launches gives a slope and an intercept.
3. **Work-group geometry.** Variants that test H2: the work group at one wave (64 threads), two
   (128) and four (256), with `TOP_CAP`, `TRANSPOSE_MIN` and `AND_GROUP` set to whatever the
   kernel's constraints allow at each size; decouple `JOIN_WG` from `TOP_CAP` if that is a small
   change (then 256 tops per batch can run on smaller groups and the two effects separate).
   Counts must stay exact for these.
4. **Barrier and shared-memory ablations** that are cheap to add (for example the headers kept in
   registers at a small work group; the clipped-chunk atomics replaced by a plane OR; anything
   your reading of the kernel suggests). Mark each as exact or timing-only.
5. The **b64** fields of yesterday's list in every chain that matters (the denser plan,
   `TOP_CAP` 128, the two together were only measured at b62 and b60).

Validate on the box: every mode builds and runs on CUDA and on lavapipe with the SPIR-V compiler
(`--features gpu,cubecl-spirv`, production's build on that card); the exact variants give the
CPU join's counts on a dense field (`NICE_TEST_JOIN_DENSE*`, `wgpu_join_matches_the_cpu_join_on_a_dense_field`);
the timing-only modes say so. Then **measure the split on the RTX 3080** (b62 1e17 at 0.45,
b60 1e16 at 0.55, b64 1e17 at 0.55: the fields of `../N13/RESULTS.md`), so the window's numbers
have an NVIDIA column to stand next to: seconds per mode, ps per pair per part, and the
launch-accounting line. lavapipe timings mean nothing; use it for correctness only.

## Task C (time-boxed to 60 minutes, drop it if it does not come together): what ACO generates

RADV can compile pipelines without the hardware: build Mesa's RADV on the box (a release that
knows the RX 9070 XT, GFX12 / "navi48": Mesa 25.1 or later; ACO only, `-Dllvm=disabled`,
`-Dvulkan-drivers=amd`, no gallium drivers), run the wgpu harness for one tiny field with
`RADV_FORCE_FAMILY=<the family name for that card in that Mesa>` and `RADV_DEBUG=shaders` (the
null winsys executes nothing, so the run itself fails or hangs: use a timeout; the dump happens at
pipeline creation). From the join kernel's ACO IR: the wave size, the number of barriers
(`s_barrier`) and where they sit, shared-memory (LDS) loads and stores per section, anything that
looks poor (clamps on every index, emulated 64-bit, long scalar sequences in the unrolled copy),
and the same for a 128-thread and a 64-thread work group. Instruction counts per section next to
what L51 and B64 report for NVIDIA's SASS where they exist. This is evidence for the window's
decision table, not a result on its own.

## Task D: a candidate branch for the denser plan on wgpu devices (small; after B)

Branch **`exp/n14-wgpu-dense-plan`** on the fork from upstream main `5b1d627`: let a wgpu device
that can hold it use the denser batch plan that CUDA uses (`JoinLimits::vram_budget`, the gate
in `limits_of`; read the docs on `SURV_PER_PREFIX_VRAM` and `JoinLimits` for why the gate exists:
the budget must be a safe share of the device's memory). Find out what the runtime can know on
wgpu (adapter type, limits, anything CubeCL exposes; the 9070 XT reports a 2 GiB largest buffer on
a 16 GB card) and propose the narrowest rule that includes a discrete desktop card and excludes
software rasterizers, integrated and unified-memory devices (the Apple M4 must keep today's
plan); say plainly if no sound rule exists. One commit, unit tests for the rule, `cargo fmt`,
clippy clean on `nice_common` with the features CI uses, lavapipe device tests pass. No changelog
line and no PR: the window measures this binary against main first.

## Deliver

- `N16/RESULTS.md`: Task A's re-derivation; every switch with what it executes; the RTX 3080's
  split table; Task C's findings or why it was dropped; Task D's rule and its tests. Mark every
  number measured, derived or assumed.
- **`N16/WINDOW-PLAN.md`**: the window, minute by minute, for someone who has only that file and
  `../N13/BRIEF.md`'s machine rules: workspace setup, which binaries to build (and how long builds
  took yesterday on that machine: see the build logs in `../N13/raw/demoux/`), the chain scripts in
  run order with seconds per run, **the must-haves inside the first 45 minutes and the whole plan
  inside 90**, and a decision table: for each outcome of the split (launch cost, barriers, loads,
  copy, entry waves, spread evenly) what it means, which variant run confirms it, and what the
  fix would be with its estimated gain on that card.
- `N16/raw/scripts/` (everything the window runs, exercised end to end on the box with CUDA and
  lavapipe so that only the paths change) and `N16/raw/box/` (logs). Copy results to ivory as you
  go.

## Rules

Vast only through the instance above: never `vast.py create` or `destroy` (the director destroys
the box). ivory writes only under `N16/` and, if you need one, a worktree
`~/projects/nice/.worktrees/n16-join-base`; no builds on ivory. Push only to the fork, only as
new branch names or new commits on your own two branches; **never force-push, never delete a
branch, and if a push is refused do not ask anyone to do it for you: report it**. Never push to
`wasabipesto/nice`; no PRs; no subagents. Never touch the fleet, the server, `~/fleet-run`,
demoux or mayalaran. Hard stop **12:15 UTC**: write up
what you have; an unfinished Task C or D is fine, an untested window script is not.
