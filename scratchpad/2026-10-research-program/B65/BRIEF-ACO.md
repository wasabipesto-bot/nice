# The wide main kernel's inner loop as the RX 9070 XT's compiler sees it: where its instructions go, and what can go (brief, 2026-11-28 06:05 UTC)

You are a GPU performance engineer who reads compiler output (Rust, CubeCL kernels, SPIR-V, AMD's ACO backend).
Work alone (do not start subagents), on this machine (ivory) only, **offline: no card, no other machine.**
**Hard stop 11:30 UTC; report by 12:00 UTC** (check `date -u`).

## Why

The "nice" project's redesigned search join (the middle-out join; fork branch `dev/mo-mode`, head `f503a13c`,
worktree `~/projects/nice/.worktrees/mo-mode`) runs bases 65–70 on a wide device path
(`common/src/midout/gpu_wide.rs`; the narrow base-64 path it mirrors is `gpu.rs`). **Base 65 is about 73 % of the
machine time the search still has ahead of it, its main (pairing) kernel `wide_kernel` is 58 % of a base-65
field, and the card that does most of the project's work is an AMD RX 9070 XT (RDNA4, Mesa's RADV driver with
the ACO compiler, 64-lane subgroups, SPIR-V straight from CubeCL)**: so that one kernel's inner loop on that one
compiler is roughly 40 % of everything that remains. It has been tuned for that card once, offline, for
occupancy (registers and shared memory: `G2/WIDE2-NOTES.md` §C, §D), and never for instruction count. The
narrow kernel's loop was counted at 171–173 VALU cycles and 39 shared-memory (LDS) operations per wave-iteration
(`CW/RESULTS.md`, `G2/PORT-NOTES.md` "RDNA4 pricing", `G2/BUILD-NOTES.md` §12). Yesterday both main kernels gained a
per-lane survivor count and fault-emulation hooks in the slab loop (`B65/FIXES-NOTES.md`; the hooks are being
compiled out by another engineer today on a branch `dev/mo-hooks`: do not touch that work, but do count what the
hooks and the count cost in this compiler's output).

Paths are relative to `~/projects/nice/scratchpad/2026-10-research-program/` unless they start with `~`.

## The tools (all exist; read how they were used before writing anything)

- `G2/PORT-NOTES.md` (sections "RDNA4 pricing", "Worktree, branch, build", the CubeCL pitfalls, and lines around
  "RADV for GFX1201 offline"): how SPIR-V is dumped (`CUBECL_DEBUG_SPIRV=dir` with the `cubecl/spirv-dump`
  feature; `cubecl.toml` logger for sources), how a plane width the local device does not have is forced
  (`MIDOUT_FORCE_W=64`, the compile-only path of the slice tests), the container **`g2mesa`** (`podman start
  g2mesa`; a RADV-only Mesa 26.0.8 with the amdgpu drm-shim: it reports "AMD Radeon RX 9070 XT (RADV GFX1201)"
  and compiles, it runs nothing), `G2/aco/aco.sh DIR…` (every `.spv` → `<kernel>.aco.txt`), `G2/aco/loops.py`
  (instructions and cycles per loop iteration), `G2/port/model_rdna4.py`.
- `G2/WIDE2-NOTES.md` §C–§D and `G2/BUILD-NOTES.md` §12: the last offline session on the wide kernel (occupancy:
  120 registers, 21.4 KB of shared memory, 12 waves per SIMD) and how its numbers were produced.
- This machine has 4 slow cores: one cargo build at a time, `nice -n 19`, `-j 2`, a target directory of its own
  under the worktree you create (`~/projects/nice/.worktrees/mo-aco`, branch `exp/mo-wide-aco` cut from
  `f503a13c`), never in `/tmp`; check `df -h /` first and stop if under 6 GB free. Lavapipe for compile-only
  runs is the container `lvp26` (see `G2/CLEAN-NOTES.md` for how tests are run in it).

## The job

1. **Reproduce the pipeline at today's head:** `wide_kernel` at base 65 (the variant the RX 9070 XT would run:
   64 lanes, `maxpop` 18, the default batch shape) and `g2_kernel` at base 64, through ACO for GFX1201. Report
   for each: registers, shared memory, waves per SIMD (must match the earlier notes or say why not), and **the
   word loop's instruction mix per wave-iteration** (VALU, SALU, LDS loads and stores, branches; cycles by
   `loops.py`'s model), with the loop's ACO listing kept in your output directory.
2. **Explain the difference between the two loops instruction by instruction**: what the wide loop does per slot
   that the narrow one does not (18 against 17 slice loads; 7-bit digit fields in five words against 6-bit in
   four; two-word masks; digits 64..b through ballots; the pad row), and **what yesterday's per-lane survivor
   count and the fault hooks add** (count the loop at `73bc0065`, the commit before them, for both kernels).
3. **Find instructions that can go, and show it in the compiler's output.** On the scratch branch, try source
   changes to `wide_kernel`'s inner loop (and to `g2_kernel`'s where the same idea applies) that keep the
   result identical by construction (say why for each), compile-only, and count again. Candidates to start from,
   none of them checked: digit extraction with fewer shifts and masks per slot (fields pre-shifted on the host);
   the probe's digits kept as byte offsets ready for the shared-memory address; loads of two slice words as one
   64-bit load where the layout allows; hoisting anything the loop recomputes per slot; whatever the listing
   shows the compiler failing to combine. The earlier studies found that sharing loads between probes and wider
   words are slower in practice (`PS/RESULTS.md`, `CW/RESULTS.md`): do not repeat those.
   **Kill: if after three distinct ideas no variant removes at least 8 % of the word loop's cycles per slot in
   the model with occupancy unchanged (12 waves), stop and report the table.**
4. For the best variant(s): the exact diff, the before/after instruction table, occupancy, and what could not be
   checked offline. **Exactness is not claimed by you**: the variants will be run on a card through Vulkan by
   someone else; you may run the ordinary device tests on lavapipe (`lvp26`) to catch a broken variant early if
   time allows (they execute at lavapipe's own plane width, not 64).

## Rules

- Nothing leaves this machine: no pushes except the scratch branch `exp/mo-wide-aco` to the remote `fork` at the
  end (never `origin`; never force-push; commit trailer exactly `Co-Authored-By: Claude Fable 5.2
  <noreply@anthropic.com>`; no mention of assistants, agents or a research program in commits or comments); no
  pull request; never contact the production API.
- Stop the `g2mesa` container when you are done (`podman stop g2mesa`); remove your target directory if it is
  over 3 GB.
- A number from a model is a model's number: label measured compiler output (instruction counts) and modelled
  time (cycles, predicted gain) separately, and do not turn a cycle count into a promised speed-up.
- If the tooling denies something, do not work around it: note it and report it.

## Deliverables (by 12:00 UTC)

`B65/ACO-RESULTS.md` (the two loops' tables, the explained difference, what the count and hooks cost, each
variant tried with its diff and table, the kill line met or not, what a card run must check), listings under
`B65/aco/`, the scratch branch on the fork, and a final report to me of at most 15 lines.
