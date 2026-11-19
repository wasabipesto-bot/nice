# The middle-out join, step 3W: one trunk, and the wide kernels brought level (brief, 2026-11-19 03:15 UTC)

You are an engineer on the third step of a build. Work alone (do not start subagents). **Hard stop
06:00 UTC, and it is hard: the box you work on destroys itself at about 06:40 UTC. Bundle your commits to
ivory after every piece, not only at the end.**

## Where things stand

Read first, on ivory under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the
owner's decision and the rules: all apply to you), `BUILD-NOTES.md` (the trunk: read sections 1, 9 and 10
closely), `BUILD-NOTES-WIDE.md` (the wide-mask branch), `AUDIT-MO.md` §1 and §4 (why the accounts exist).

Two branches hold the middle-out join tonight:

- **The trunk, `dev/middle-out-join` at `c0ad3f4a`**: base 64 with 64-bit masks (`common/src/midout/gpu.rs`).
  Since the wide branch forked it gained a cheaper record expansion, production's prefilter before the check,
  a top hierarchy (step 2A), and, three hours ago, accounts that prove every stage ran, two conservation laws,
  guards, and a sampled CPU check per field (step 3A), with an auditor's fault-injection switches as tests.
- **`dev/mo-wide` at `a8a76315`**, forked from the trunk at `7ba982c7`: bases 65–70 with two-word masks in a
  separate file (`gpu_wide.rs`), exact at base 65 and on two slices of base 68, with its own full check and one
  account of its own (job instances that ran). It has none of the trunk's later work.

## Your job, in this order

1. **Merge `dev/mo-wide` into the trunk** (an ordinary merge commit; the files are separate, conflicts should
   be few). Everything that passed on each branch passes on the merge: the trunk's tests and fault tests, the
   wide branch's tests, production's suite, fmt and clippy.
2. **The trunk's accounts and guards, ported to the wide kernels**: positive evidence that every stage ran,
   compared by the host with what it queued; probes run = 8 × tops; children counted two ways; the slice-done
   count; the guards on index widths; the sampled CPU check hook (the CPU reference already runs with wide
   masks). Acceptance as on the trunk: the fault switches that apply (dropped main kernel, dropped tops,
   dropped probe, dropped parent, a failed device allocation) are loud on the wide path too, each asserted by
   a test, at base 65 and with the wide path forced at base 64.
3. **The trunk's speed work, ported to the wide kernels**: the prefilter before the check (it needs a second
   mask word above base 64; mirrored in the CPU reference), the top hierarchy, the cheaper expansion. Exact
   first: device = CPU reference at base 65 on the wide branch's test slices, and with the wide path forced at
   base 64 and at small bases against brute force.
4. **The number again**: base 65 end to end on whole fields after the port, against the wide branch's 3.484 fs
   (taken on another card, uncapped; this box is capped at 240 W, so also run base 64 through the narrow path
   in the same session and report base 65 as a multiple of it: last night's multiple was ×2.04).

Order of sacrifice if time runs out: 1 and 2 with their tests first; then 3; then 4. If 3 is unfinished at
05:30 UTC, stop it, leave it on a side branch (`dev/mo-wide-speed`, pushed to the fork), and keep the trunk
at the last state where everything passes.

Kernel traps to respect (all real here): on the SPIR-V compiler several atomic stores of one value in a basic
block are merged into one (use adds or distinct values); a `loop` with two `break`s and a read after it
compiles to invalid SPIR-V; planes may run partly filled and lane 0 may not exist. `PORT-NOTES.md` has them.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, handed to you for this task:**

      ssh -p 14628 root@ssh3.vast.ai

  Vast instance 61286074: RTX 3080 (10 GB) capped at 240 W, 16 threads visible with a 5.12-CPU quota, 31 GB
  memory; the trunk's trees, toolchain, lavapipe, staged slices and scripts are on it (`G2/build3a/box/` and the
  notes say where); the wide branch's box is gone, so stage what its tests need from ivory
  (`G2/build2e/box/`, `G2/bases/`). Base 68 does not fit this card's memory: do not attempt it. Production hosts
  are mapped to 127.0.0.1 and ::1: check before any client binary runs; nothing ever claims from or submits to
  the production API. Two old wait loops of an earlier engineer are sleeping on the box; leave them. Never
  create or destroy instances; never use another machine.
- You are the trunk's only writer. Ordinary commits and merge commits only (never amend, rebase or force);
  trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory after every
  piece; `git push fork dev/middle-out-join` from ivory. No pull request, nothing to upstream. One target
  directory per worktree.

## Deliverables (by 06:00 UTC)

1. The commits on ivory and the fork, with everything passing at the trunk's head.
2. `G2/BUILD-NOTES.md` section 1 rewritten for one trunk, and a new section "Step 3W" (what merged, what was
   ported and how it was proven, the wide path's fault table, the base-65 number, what is left for the wide
   path); `BUILD-NOTES-WIDE.md` marked as merged with a pointer.
3. Raw logs under `G2/build3w/`.
4. A final report to me of at most 25 lines: the state of the trunk's head; which wide faults are loud; the
   base-65 number as a multiple of base 64; what was left on a side branch; what the next piece should be.
