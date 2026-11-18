# The middle-out join: an independent soundness audit of the first day's code (brief, 2026-11-18 22:05 UTC)

You are an independent auditor. You did not write this code and you are not here to like it. Work alone (do
not start subagents). **Hard stop 01:45 UTC** (tonight, after midnight).

## Why

"nice" is an exhaustive search whose expected result is *nothing found*. Its whole value is that a base
declared empty really is empty. Today two engineers wrote about 4,500 lines of a new GPU search join ("the
middle-out join") in seven hours: `common/src/midout/` on branch `dev/middle-out-join`, head `91ac0761`,
worktree `~/projects/nice/.worktrees/midout` on ivory. It is 4 times faster than production's join and is
meant to search base 64 and the bases after it. Its exactness evidence so far: a CPU reference equal to brute
force on whole small bases, and the device equal to the CPU reference **on 5 real slices** and 2 on the
software renderer. The prototype it came from was thought exact until day one found a table that overflows on
about 1 slice in 1,000.

**Your question: can this code lose a candidate, or report a wrong count, without the host noticing? Find the
ways before a base depends on it.** A finding with a reproduction is worth more than ten suspicions; a
suspicion with a file and line is still worth writing down.

Read first, on ivory under `~/projects/nice/scratchpad/2026-10-research-program/`: `G2/BUILD-NOTES.md` in full
(the state, the interface, the design decisions, the limits the authors already know about), `G2/PORT-NOTES.md`
(the CubeCL 0.10 pitfalls hit so far), `T2/SOUNDNESS.md` (an earlier audit of production's join: the classes
of defect that were real there), `T26B/CUBECL-ISSUE-DRAFT.md` and `G2/port/CUBECL-LOOP-BREAK-ISSUE-DRAFT.md`
(two compiler defects of the SPIR-V path: several atomic stores of one value in a basic block are merged into
one; a loop with two breaks and a read after it compiles to invalid SPIR-V). Then the code.

## What to do, in this order

1. **A broad parity sweep on the card.** Device against the CPU reference on as many real base-64 slices as
   the night allows (at least 300 chosen by a recorded seed across the whole base, plus the first and last
   fields of the base, plus slices you pick for extremes: the most probes per job, the widest tops, the
   largest classes and buckets, slices with no tops at all). Survivor sets, prefiltered lists, every count.
   The CPU reference costs about 20 s per slice per thread and the box has about 5 CPUs' worth of quota: plan
   the sweep so it runs in the background while you read code.
2. **Every limit.** List every fixed capacity, table size, field width and counter width in the device path
   and its driver (probe table, popcount limit, slab and list capacities, 16-bit and 32-bit fields, per-field
   totals). For each: the largest value seen in your sweep, the margin, and what happens past it: **a loud
   error, or a silent wrap or truncation?** Prove the behaviour by fault injection where you can (shrink the
   limit in a test build and watch the run fail or not).
3. **What the host's account can and cannot see.** The driver verifies "every account" per 16 slices. Work
   out exactly which kernel failures those accounts would catch and which they would not: a slice skipped, a
   launch dropped, a plane that ran partly filled, a chunk not probed, a record lost between the kernel and
   the expansion, a candidate dropped by the prefilter in error, a check never run. Fault-inject the ones you
   doubt.
4. **Read for the known classes of defect:** assumptions about the plane (subgroup) width or that lane 0
   exists (the code has run at 8 and 32 lanes only; the card that will do 86 % of the work runs 64, and
   Vulkan may run partly filled planes); atomics and barriers (and the two compiler defects above: look for
   their shapes in the kernels); shared memory read before it is written; anything racing between phases;
   arithmetic that can overflow at the ends of a base's range.
5. **The coordinate layer** (`coord.rs`): that every n of a base's range lies in exactly one field and one
   slice, including the ends of the range and the padded form for a base that is not a power of two.

Do not review style, speed or naming. Do not review the wide-mask work (another engineer is writing it on
another branch tonight).

## Machines, branch, rules

- **ivory**: reading, git and notes only; do not build here (disk nearly full).
- **One rented box, handed to you for this task** (the two build engineers used it today; it is idle now):

      ssh -p 14628 root@ssh3.vast.ai

  Vast instance 61286074: RTX 3080 capped at 240 W, 16 threads visible with a 5.12-CPU quota, 31 GB memory.
  The build tree at `91ac0761`, the toolchain, lavapipe, staged slices and scripts are on it (`BUILD-NOTES.md`,
  `G2/build1/box/`, `G2/build2a/box/` say where). Production hosts are mapped to 127.0.0.1 and ::1 there: check
  that still holds before any client binary runs. Nothing ever claims from or submits to the production API.
  It destroys itself about 06:40 UTC. Leave it running and idle at the end. Never create or destroy instances;
  never use another machine; if the box misbehaves, stop and report.
- **You change no code on `dev/middle-out-join`.** Tests and fault-injection switches you write go on a new
  branch `dev/mo-audit` from `91ac0761` (own worktree `~/projects/nice/.worktrees/midout-audit` on ivory;
  ordinary commits, never amend, rebase or force; trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle from the box to ivory;
  `git push -u fork dev/mo-audit` from ivory). No pull request, nothing to upstream. You propose fixes; you do
  not apply them to the trunk.
- One target directory per worktree on the box (two worktrees sharing one have handed back the wrong binary
  twice today).

## Deliverables (by 01:45 UTC)

1. `G2/AUDIT-MO.md`: findings ranked in four classes (a candidate or count can be lost silently; lost but
   detected; robustness; gaps in the tests), each with file and line, the evidence (reproduction, fault
   injection or reasoning), and a proposed fix; the sweep's result (how many slices, which, all equal or not);
   the table of limits; what the accounts catch; what you did not get to.
2. The tests and switches on `dev/mo-audit`; raw logs under `G2/audit1/`.
3. A final report to me of at most 30 lines: the verdict in one sentence; the findings by class; the sweep;
   the three things you would fix first.
