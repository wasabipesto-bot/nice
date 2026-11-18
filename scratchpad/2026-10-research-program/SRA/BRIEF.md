# SRA: the stride path must prove its kernels ran (brief for a fix, 2026-11-18 23:30 UTC)

You are an engineer preparing one small, careful fix for production code. Work alone (do not start
subagents). **Hard stop 02:30 UTC** (tonight, after midnight).

## The defect

Read `~/projects/nice/scratchpad/2026-10-research-program/G2/build2e/ALLOC-FAILURE.md` first (measured an hour
ago on the box you are getting; raw logs and the harness in `G2/build2e/raw/alloc/`).

In short: "nice" is an exhaustive search whose normal result is "nothing found". On the CubeCL CUDA runtime, a
failed buffer allocation leaves the client holding a handle to memory that does not exist; every later launch
that binds it panics inside CubeCL's device thread, is logged as "Task failed" and dropped, and `sync()` still
returns Ok. The **overlap join** notices: it compares the cubes each kernel finished with the cubes launched
(`ensure_ran` in `common/src/cubecl_join.rs`) and retries or errors. The **stride path**
(`common/src/cubecl_backend.rs`) does not: its accounts balance at zero, so production's v3.4.8 client
submitted unsearched nice-only fields as searched and empty, with no error (three reproductions in the
write-up: a base-62 field of 5e12 that production routes to the stride path by itself, and forced-stride
base-64 fields).

## The fix wanted

**Positive evidence of execution on the stride path, checked by the host**, the same rule the join already
has: every cube that runs adds to a count, and the host requires the count to equal the cubes it launched
before it accepts a field's result; a mismatch is an error (the field fails and nothing is submitted), with a
message in the style of the join's. Nothing else: no retry logic, no new flag, no behaviour change on a
healthy device.

Things to get right:

- **Every stride kernel and every consumer of its result**: nice-only and detailed. For the detailed path,
  first find out whether it has the same gap (can a launch that did nothing produce a result the host
  accepts? is there already an account, such as the distribution's total against the range size?) and say
  what you found; fix it in the same change only if it is the same small account, otherwise report it as a
  separate item.
- **Every runtime the kernels compile for**: CUDA, wgpu through WGSL and through SPIR-V, Metal (compile only;
  you cannot run it). Known traps in this codebase, all real: planes (subgroups) that run partly filled and
  code that assumes lane 0 exists or that a plane is full (count per cube or per lane that actually runs, never
  per assumed plane); on the SPIR-V compiler, several atomic *stores of the same value* in one basic block are
  merged into one (an atomic add is safe; do not add stores); a `loop` with two `break`s and a read after it
  compiles to invalid SPIR-V. `G2/PORT-NOTES.md` ("CubeCL 0.10 pitfalls") and
  `T26B/CUBECL-ISSUE-DRAFT.md` have the details.
- **A regression test that fails without the fix**: a test-only way to make launches do nothing (or to make
  the host believe it launched more cubes than ran), asserting the field errors; in the style of the join's
  `ensure_ran` tests. It must run in CI's lavapipe jobs, not only on CUDA.
- **Proof on the card**: with the memory-hog harness of `G2/build2e/raw/alloc/`, the three cases that
  submitted a false empty now end in an error and submit nothing; healthy runs give identical results and
  counts as before; the stride path's speed is unchanged within noise (time one small base-62 field and one
  forced-stride base-64 field before and after, three rounds).

## Machines, branch, rules

- **ivory** (this machine): reading, git and notes only; do not build here (disk nearly full).
- **One rented box, handed to you for this task:**

      ssh -p 28120 root@ssh6.vast.ai

  Vast instance 61303619: RTX 3080 20 GB at a 320 W limit, 64 threads, 251 GB memory. It has the toolchain,
  lavapipe, a build of the v3.4.8 client, the local stub and the memory-hog harness from tonight's
  measurement. Production hosts are mapped to 127.0.0.1 and ::1 there: prove the block again before any client
  binary runs. **Nothing ever claims from or submits to the production API**; the client talks to the local
  stub only. It destroys itself about 06:00 UTC. Leave it running and idle at the end. Never create or destroy
  instances; never use another machine; if the box misbehaves, stop and report.
- **Branch `pr/stride-ran-account` from upstream main** (`origin/main`, be9cc923 or later), own worktree
  `~/projects/nice/.worktrees/stride-ran` on ivory; one target directory per worktree on the box. Ordinary
  commits (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle from the box to ivory;
  `git push -u fork pr/stride-ran-account` from ivory. **Do not open a pull request**: an independent review
  comes first, and I open it.
- The repo's standard before review is **`just lint`** (it runs the pinned toolchain's fmt and clippy with the
  feature sets CI uses): it must pass. The whole test suite must pass on the box, and the device tests on CUDA
  and on lavapipe with both compilers.
- One discrete change. No drive-by edits, no renames, no new flags or environment variables in production
  paths. Do not touch `common/src/midout/` (it does not exist on main) or the join.
- A CHANGELOG entry of **one short sentence** under Unreleased, user-facing, with a placeholder `(#NNN)` for
  the pull request number.

## Deliverables (by 02:30 UTC)

1. The branch on ivory and on the fork.
2. `SRA/RESULTS.md` (in `~/projects/nice/scratchpad/2026-10-research-program/SRA/`): what the gap was per
   kernel and consumer, what the fix adds, the detailed path's situation, the regression test, the before and
   after of the three reproductions, the healthy-run comparison and timings, what was not tested (Metal), and
   anything else you saw that deserves its own fix (list, do not fix).
3. `SRA/PR-BODY.md`: a pull request description for the maintainer. Rules for it: it describes the defect,
   the reproduction, the fix, the tests and what a wgpu device should expect, in plain words; it contains **no
   reference to any research program, scratchpad path, agent, assistant or model name, and no private host
   names**; follow-ups are one brief line each, marked "not included"; it ends with the line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
4. Raw logs under `SRA/raw/`.
5. A final report to me of at most 25 lines: what changed (files, lines), the detailed path's answer, test and
   lint results, before and after on the card, timings, what you would want a reviewer to look at hardest.
