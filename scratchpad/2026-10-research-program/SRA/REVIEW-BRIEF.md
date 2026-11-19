# SRA: independent review of the stride-path fix before it becomes a pull request (2026-11-19 01:30 UTC)

You are an independent reviewer. You did not write this change. Work alone (do not start subagents).
**Hard stop 03:15 UTC.**

## What you review

Branch `pr/stride-ran-account` (2 commits on upstream main, head `3940f8a9`; worktree
`~/projects/nice/.worktrees/stride-ran` on ivory; also on the fork): `common/src/cubecl_backend.rs` and
`CHANGELOG.md`, about +170 lines. It is a soundness fix for production code that will be offered to the
project's maintainer as a pull request.

Background, in this order, under `~/projects/nice/scratchpad/2026-10-research-program/`:
`G2/build2e/ALLOC-FAILURE.md` (the defect, measured: after a CUDA allocation failure CubeCL 0.10 silently drops
every later launch, and production's v3.4.8 client submitted unsearched stride-path fields as empty),
`SRA/BRIEF.md` (what the fix was asked to do and its constraints), `SRA/RESULTS.md` (what the author says they
did and measured), `SRA/PR-BODY.md` (the description the maintainer will read).

## What to decide

**Merge, merge with fixes (list them), or hold.** Try to break it:

1. **Can a stride field still be accepted when not every launch ran?** Every consumer of a stride field's
   result (the threaded pipeline, the one-field form, benchmarks, device tests, the browser runner if it shares
   the kernel) must pass through the new check; the count of launched cubes must be right on every path
   (partial last launch, re-launches, several fields in flight, a field with zero launches); the comparison
   mod 2^32 must not let a real loss through.
2. **Can a healthy device now fail?** The new end-of-kernel step on every path of `niceonly_kernel` (plain,
   cube-scoped queue, plane-scoped queue): is it reached by every cube and every unit, including early
   exits; is the barrier legal where it stands; partly filled planes and cubes without a full plane; lane 0
   absent. On every runtime: CUDA, wgpu through WGSL and through SPIR-V (known compiler traps: several atomic
   stores of one value in a basic block are merged, see `T26B/CUBECL-ISSUE-DRAFT.md`; a loop with two breaks
   and a read after it compiles to invalid SPIR-V, see `G2/port/CUBECL-LOOP-BREAK-ISSUE-DRAFT.md`), Metal
   (never run by the author: read the kernel for anything Metal could object to, and say plainly that it is
   unverified).
3. **The count buffer grew from 3 to 4 words:** every reader, writer, zeroing and size assumption, in every
   backend that shares it.
4. **The regression test:** does it fail without the fix (remove the host check and run it on lavapipe with
   both compilers and on CUDA: do this yourself), and does it test the kernel's count or only the host's
   arithmetic? What is the smallest additional test that would close the gap, if any?
5. **Is the detailed path really covered** by its existing histogram-total check, in every consumer?
6. **Is it one discrete change?** No drive-by edits, no new flags or environment variables in production
   paths, the test-only switch unreachable in release builds.
7. **`just lint`** and the whole test suite: run them yourself on the box.
8. **The pull request description** against its rules: accurate against the code and the logs (spot-check
   three numbers against `SRA/raw/`); plain words; says what a wgpu device should expect; follow-ups one brief
   line each and marked not included; **no reference to any research program, scratchpad path, agent,
   assistant or model name, no private host names**; ends with the Claude Code line. And the CHANGELOG line:
   one short user-facing sentence.

## Machines and rules

- **ivory**: reading and notes only; do not build here.
- **One rented box, handed to you for this task:** `ssh -p 28120 root@ssh6.vast.ai` (Vast 61303619, RTX 3080
  20 GB, 64 threads; the author's trees, toolchain, lavapipe, the local stub and the memory-hog harness are on
  it: `SRA/RESULTS.md` says where). Production hosts are mapped to 127.0.0.1 and ::1 there: prove it before any
  client binary runs; nothing ever claims from or submits to the production API. It destroys itself about
  06:00 UTC. Leave it running and idle. Never create or destroy instances; never use another machine.
- **You change nothing on the branch.** If you want to demonstrate a defect, do it in a scratch worktree on the
  box with its own target directory. No pushes, no pull request.

## Deliverable (by 03:15 UTC)

`SRA/REVIEW.md`: the verdict in the first line; findings ranked (must fix before the pull request; should
fix; note), each with file and line and the evidence; what you ran yourself and its result; corrections to the
description. Then a report to me of at most 20 lines: the verdict, the must-fix list, what you verified
yourself.
