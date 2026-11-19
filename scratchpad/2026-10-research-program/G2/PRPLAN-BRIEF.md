# The middle-out join: a read for maintainability and a plan for reviewable pull requests (brief, 2026-11-19 12:05 UTC)

You are an independent reviewer and release planner. You did not write this code. Work alone (do not start
subagents), on this machine only (ivory), **reading only: you change no code and build nothing**.
**Hard stop 15:00 UTC.**

## The situation

In two days, seven engineers wrote a new GPU search join ("the middle-out join") for the "nice" project on
branch `dev/middle-out-join` (head `66259bb0`, worktree `~/projects/nice/.worktrees/midout`; upstream main is
`origin/main`). `git diff --stat origin/main...HEAD` is about 7,000 lines: `common/src/midout/` (coordinate,
CPU reference, narrow and wide device paths, accounts, wire, route), examples, a client mode, a coordinator
script, and small additive edits to two production files. It is exact, audited for silent loss, and ×4.09
faster end to end than production's join at base 64 on an RTX 3080.

The project's maintainer (one person, little time) approved the build and said: *"My expectation is that you
would spend a day on the basic implementations then a few more days optimizing it before review and merge."*
Their standing rules for pull requests, which the plan must satisfy:

- one discrete change per pull request, never several combined (separate stacked pull requests are fine);
- every pull request carries its tests; new device tests must run on CI's Mesa (lavapipe) jobs;
- an independent review before each is opened; `just lint` clean;
- descriptions in plain words, saying what a wgpu (Vulkan, Metal) device should expect when a measurement is
  CUDA-only; the changelog line is one short sentence;
- new features, flags and jobs need the maintainer's explicit yes (the build itself has it; a client flag and a
  coordinator script are new surface they have not seen);
- **no server, schema or API change until the join has settled**; the maintainer also asked that the field
  structure not tie the project to one search implementation.

Read first, under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-NOTES.md` (all of it: the
state, the interface, the accounts, each step), `BUILD-NOTES-CLIENT.md`, `AUDIT-MO.md` (the audit and what
remained), `fs/REVIEW.md` §1 (the field-structure review). Then the code and its history
(`git log --stat origin/main..HEAD`).

## What to deliver

1. **A maintainability read** of the branch as it stands, for someone who must own it for years:
   - what a new reader cannot follow (file by file: where the structure, names or comments fail; functions
     that are too long to review; kernels whose invariants are not written down);
   - leftovers of the two days: superseded code still in the tree, experiment switches and environment
     variables, diagnostics, examples that are really benchmarks, duplicated logic between the narrow and the
     wide path (how much is duplicated, and whether one generic path is realistic or a trap in CubeCL 0.10),
     test-only features and whether any can leak into a release build;
   - what in production files changed and whether each edit is really additive;
   - tests: which are fast enough for CI, which need a GPU, which run on lavapipe, what CI would actually
     exercise today, and what is covered only by box runs recorded in notes;
   - documentation the repository would need (module docs, a design note, how to run the coordinator).
   Rank the findings: must be fixed before any pull request; should; later.
2. **A pull-request plan**: the smallest series of stacked, individually reviewable pull requests that lands
   this, in order, each with: its one-sentence purpose; the files and roughly how many lines; what it lets the
   maintainer verify by itself (tests that run in CI); what is deliberately left for a later one; its risk if
   merged alone (nothing may change the default client's behaviour until the maintainer opts in); and the one
   thing a reviewer should look at hardest. Say where the series can stop and still be useful (for example:
   coordinate and CPU reference only). Say which pieces need the maintainer's explicit yes as new surface, and
   which parts should NOT be proposed yet (anything that fixes the field structure on the server).
   Propose how the branch's history should be turned into that series (fresh commits per pull request from
   the final tree; the present history has superseded steps).
3. **What you would cut**: anything in the branch that does not earn its place in a first series (for example
   a second coordinate kept only for comparison, benchmark examples, the wide path if base 65 is a year away),
   with what each cut saves the reviewer and what it costs.
4. **Open questions for the maintainer**, at most seven, each answerable in a line (names, flags, where the
   coordinator script lives, whether the wide path is in the first series, the default coordinate).

Do not review correctness of the kernels (the audit did) or speed. Do not rewrite anything.

## Rules

- ivory only, read-only on the repository (no commits, no builds, no pushes, no pull requests); write only
  `G2/PR-PLAN.md` and `G2/MAINTAINABILITY.md` in the scratchpad.
- The plan and the review must not assume the maintainer has read any of the notes: the pull requests will
  not be able to refer to them.

## Deliverables (by 15:00 UTC)

`G2/MAINTAINABILITY.md` (ranked findings with file and line), `G2/PR-PLAN.md` (the series as a table plus a
paragraph per pull request, the cuts, the open questions), and a report to me of at most 30 lines.
