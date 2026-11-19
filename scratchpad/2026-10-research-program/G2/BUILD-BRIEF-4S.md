# The middle-out join, step 4S: the library path made ready for the RX 9070 XT, offline (brief, 2026-11-19 06:00 UTC)

You are an engineer on the fourth step of a build. Work alone (do not start subagents), on this machine only
(ivory: 4 cores, 7 GB of memory, about 6 GB of free disk). **Hard stop 11:30 UTC.**

## Why

The middle-out join (trunk `dev/middle-out-join`, head `4abfab5c`, worktree
`~/projects/nice/.worktrees/midout`, code in `common/src/midout/`) runs base-64 fields end to end at ×3.9
against production on an RTX 3080. **The card that does 86 % of the project's search is an RX 9070 XT** (RDNA4,
Mesa RADV, the SPIR-V compiler, planes of 64 lanes), and the library path has never run there: not at 64
lanes, not on Vulkan hardware at all. The owner's card is available only in short windows. Yesterday, the same
situation for the join's prototype kernel was handled offline with Mesa's ACO compiler on this machine:
instruction counts per loop for that card, a model, eleven tuning commits, and then a window in which the
tuned kernel measured ×1.36 faster than the untuned one and ran exactly at 64 lanes on first contact.

Since then the library path gained kernels nobody has looked at for that card: tops built on the device (a
hierarchy), the preparation with its accounts, the main kernel with accounts, the record expansion with the
prefilter inside, and production's check kernel behind it.

Read first, under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's
decision and the rules: all apply), `BUILD-NOTES.md` (the trunk: §1, §9, §10, §11), `TUNE-RESULTS.md` and
`PORT-NOTES.md` sections "RDNA4 pricing", "Worktree, branch, build" and the CubeCL pitfalls (the method and the
tools: the `g2mesa` container with a RADV-only Mesa build and drm-shim, `aco/aco.sh`, `aco/loops.py`,
`port/model_rdna4.py`, how SPIR-V is dumped for a plane width the local device does not have),
`WINDOW-RESULTS.md` (what the card showed: its operating point under this kernel is 2.85 GHz at the 304 W cap;
synchronised launches cost 0.12 ms, queued ones microseconds; uploads through the compute queue cost 7 %).

## Your job

1. **A static pre-flight of every kernel of the library path at 64 lanes**: make the library's kernels
   compile for plane width 64 without a device (as the port's `--force-w` did) and dump their SPIR-V; run
   `spirv-val`; compile each with ACO for GFX1201; record per kernel: registers, shared memory, waves per SIMD,
   instructions, and per loop the instruction mix per wave-iteration. Read every kernel for a plane-width or
   lane-0 assumption that 8 and 32 lanes would not have exposed. This alone decides whether a window would be
   wasted.
2. **A model of the whole slice on the card**, stage by stage, by the method of `TUNE-RESULTS.md`, anchored on
   what the card measured for the prototype kernel (its end-to-end 0.77 fs pipelined) and on the RTX 3080's
   measured stage times for the library path (`BUILD-NOTES.md` §9–§10). State the predicted ms per slice per
   stage, the predicted ratio against the card's main (4.707 fs per admissible n) with its band, and which
   stage is predicted to bind.
3. **Tune what the listings show is costly on that card** in the kernels added since the prototype (tops,
   preparation accounts, expansion with prefilter, the account code in the main kernel): 64-bit operations
   that ACO emits as pairs, shared-memory budgets just over a waves-per-SIMD threshold, address arithmetic,
   serial loops. One ordinary commit per change, each **exact first**: the parity tests on lavapipe at 8 lanes
   through SPIR-V (container `localhost/lvp26`), the fault tests, production's suite, fmt and clippy. A change
   that cannot be proven exact here is not kept.
4. **A window plan for the library path**, `G2/WINDOW-PLAN-2.md`, for at most 45 minutes on the card: what is
   built beforehand, exactness at 64 lanes first (device against the CPU reference on a set of slices whose
   reference results are computed in advance or on that machine's 12 threads; the fault tests; the wide path
   at base 65 on one slice), then whole fields against main's fields in the same session by the pipelined
   protocol, what each outcome means, and a stop line. Reuse `WINDOW-PLAN.md` and `port/window/*`; dry-run the
   driver on lavapipe.

**Stop rule:** if by 08:30 UTC the 64-lane SPIR-V of the library path cannot be produced and compiled by ACO,
write what blocks it and spend the rest of the time on item 1's code reading and item 4.

## Rules

- ivory only: no rented machines, no ssh elsewhere, no production API. Builds under `nice -n 19` with `-j 2`,
  one target directory inside the worktree; **check `df -h /` before every build and stop under 3.5 GB free**
  (another job is using a little disk and CPU for counting); never build in `/tmp`. If `g2mesa` is stopped,
  start it as the notes say; remove no container, image or volume.
- You are the only writer of `common/src/midout/gpu.rs` and `gpu_wide.rs` on the trunk today. Another engineer
  is adding a client route on branch `dev/mo-client` (files under `client/` and a thin layer over
  `search_field`): do not change `search_field`'s signature or `FieldOutcome` without writing the change at
  the top of `BUILD-NOTES.md` §1 at once.
- Ordinary commits (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; `git push fork dev/middle-out-join`. No pull
  request, nothing to upstream.
- Every time is labelled predicted; nothing here is a measurement of the card.

## Deliverables (by 11:30 UTC)

1. Commits on the trunk and the fork, everything passing at the head.
2. `G2/BUILD-NOTES.md` §1 updated and a new section "Step 4S" (the pre-flight table, findings from the code
   reading, the model, each tuning change with counts before and after, what was dropped); `G2/WINDOW-PLAN-2.md`;
   raw listings under `G2/build4s/`.
3. A final report to me of at most 30 lines: can the library path run at 64 lanes as far as can be told
   offline; the predicted ratio on the card and what binds; what changed; the window plan in three lines.
