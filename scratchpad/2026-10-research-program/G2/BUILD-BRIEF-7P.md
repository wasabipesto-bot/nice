# The middle-out join, step 7P: cut the first two pull requests from the cleaned tree (brief, 2026-11-19 15:05 UTC)

You are an engineer preparing two small pull requests for a busy maintainer. Work alone (do not start
subagents). **Hard stop 17:30 UTC; the box destroys itself at about 18:05 UTC. Bundle to ivory as you go.**

## Where things stand

The middle-out join (a redesigned GPU search join for the "nice" project) lives on a development branch on a
fork. Today it measured ×4.79 against production's join on the card that does most of the search, exact at 64
lanes, and was cleaned for review: branch **`dev/mo-clean`**, head `5a048669` (worktree
`~/projects/nice/.worktrees/midout-clean` on ivory). It is 13,000 lines and will reach the maintainer as a
series of stacked pull requests. **You cut the first two**, which contain no GPU code:

1. **the field coordinate**: what a field of the new kind is (all n sharing digits 5–7; a range of a per-base
   renumbering of n), the maps between n and the coordinate, slices, coverage of a base's range;
2. **the exact CPU reference of the join for a field**, tested against brute force on whole small bases.

Read first, under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's
decision and the rules: all apply), **`PR-PLAN.md` in full (the series, and what PRs 1 and 2 contain: your
specification)**, `MAINTAINABILITY.md` (what a reader could not follow), `CLEAN-NOTES.md` (the state of the
cleaned tree, the test tiers), `fs/REVIEW.md` §1 (why the field is defined this way: the pull request must be
able to say it in its own words). Then the code on `dev/mo-clean`, and the repository's own conventions
(`CHANGELOG.md`, recent merged pull requests with `gh pr list -R wasabipesto/nice --state merged --limit 8` and
`gh pr view`, the justfile, CI workflows).

The maintainer's rules for pull requests: one discrete change each; its tests with it; `just lint` clean; a
description in plain words that assumes the reader has seen none of the development; no reference to any
research program, notes, scratchpad path, agent, assistant or model name, and no private host names; the
changelog line, if the repository's convention wants one for a change no user can reach yet, is one short
sentence with a placeholder `(#NNN)`; new features, flags and jobs need the maintainer's explicit yes (these
two pull requests add none: library code and tests only, reachable from nothing).

## Your job

- **Branch `pr/midout-coordinate`** from upstream main (`origin/main`): fresh commits (not the development
  history) taken from the cleaned tree: only what pull request 1 needs. Then **branch
  `pr/midout-cpu-reference`** on top of it: only what pull request 2 adds. The development tree stays the
  archive; if you find something in it that must change to make the cut clean, change it in your branches and
  list it, so it can be carried back.
- Per the defaults the maintainer has been told about: **only the coordinate that fixes digits 5–7** (the older
  one is not in these pull requests); the names `midout` and "middle-out join"; base 64, plus the padded form
  for a base that is not a power of two only if `PR-PLAN.md` puts it in pull request 1 (follow the plan; say
  what you did).
- Each branch must stand alone: it compiles, `just lint` passes (no dead-code allowances papering over a bad
  cut), the whole test suite passes in CI's form, its own tests are fast (seconds, CPU only) and are ordinary
  tests, not ignored ones; nothing in production code paths changes (one `mod` line is expected); module docs
  say what the thing is and why, for a reader who has only this pull request.
- **Read each diff as the maintainer will**: top to bottom, cold. Anything you would have to explain in a
  comment thread, explain in the code or the description, or cut.
- Draft each description: what it adds; why a field is defined this way, in five lines (what it commits the
  project to and what it leaves free: the review's two proven statements, said plainly); what the reader can
  verify with this pull request alone and how long the tests take; what comes next in the series, in two
  lines; "nothing uses this yet". End with the line
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

Do **not** open pull requests: an independent review comes first, and I open them.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, handed to you for this task** (the cleanup engineer just left it idle):

      ssh -p 35082 root@ssh2.vast.ai

  Vast instance 61441981: RTX 3080 (not needed for these two), 16 threads visible with a CPU quota of about
  5, 31 GB memory; the toolchain, `just`, lavapipe and trees are on it (`G2/build6c/box/` and `CLEAN-NOTES.md`
  say where). Production hosts are mapped to 127.0.0.1 and ::1: nothing ever claims from or submits to the
  production API. Never create or destroy instances; never use another machine. Leave it running and idle.
- Own worktrees on ivory (`~/projects/nice/.worktrees/pr-midout-coord`, `…/pr-midout-cpu`); one target
  directory per worktree on the box. Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory;
  `git push -u fork <branch>` from ivory for both. No pull request, nothing to upstream.

## Deliverables (by 17:30 UTC)

1. The two branches on ivory and the fork.
2. `G2/PR1-BODY.md`, `G2/PR2-BODY.md` (the descriptions), and `G2/PR12-NOTES.md`: what each branch contains
   (files, lines, tests and their run time), the lint and suite results per branch, what you changed against
   the cleaned tree and why, what you would ask a reviewer to look at hardest, anything in `PR-PLAN.md` that
   turned out wrong.
3. Raw logs under `G2/build7p/`.
4. A final report to me of at most 25 lines.
