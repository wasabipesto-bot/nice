# Independent review of the first two middle-out pull requests before they are opened (2026-11-19 16:10 UTC)

You are an independent reviewer. You did not write this code. Work alone (do not start subagents).
**Hard stop 17:40 UTC; the box destroys itself at about 18:05 UTC.**

## What you review

Two stacked branches on the fork of the "nice" project (an exhaustive search for numbers n whose square and
cube together use every digit of a base exactly once), cut for a busy maintainer who has seen none of the
development:

1. `pr/midout-coordinate` (head `cf27bc89`, on upstream main `974d7194`; worktree
   `~/projects/nice/.worktrees/pr-midout-coord`; 520 lines): the *field coordinate* of a redesigned search
   join: what a field of the new kind is (all n sharing digits 5–7; a range of a per-base renumbering of n),
   the maps between n and the coordinate, slices, coverage. Description: `G2/PR1-BODY.md`.
2. `pr/midout-cpu-reference` (head `06d55495`, on top of 1; worktree `~/projects/nice/.worktrees/pr-midout-cpu`;
   1,157 lines): the exact CPU reference of the join for a field, tested against brute force on whole small
   bases. Description: `G2/PR2-BODY.md`.

(Paths under `~/projects/nice/scratchpad/2026-10-research-program/`.) The author's notes are
`G2/PR12-NOTES.md`; the plan the cut follows is `G2/PR-PLAN.md`; why a field is defined this way:
`G2/fs/REVIEW.md` §1. Nothing in the repository uses this code yet; later pull requests add the GPU path.

The maintainer's rules: one discrete change per pull request; tests with it; `just lint` clean; a description
in plain words that assumes the reader has seen nothing; **no reference to any research program, notes,
scratchpad path, agent, assistant or model name, and no private host names**; no new feature, flag or job
without their yes (these add none).

## Decide, for each: merge, merge with fixes (list them), or hold

Read each diff as the maintainer will, top to bottom, cold, and try to break it:

1. **The coordinate (PR 1).** Is the map a bijection on the base's range, do the fields cover the range exactly
   once including both ends, is "a field is 4,096 whole slices" true and tested without circularity, are the
   overflow margins real (n near 2^76, 128-bit arithmetic)? Does the code say precisely what a field commits a
   server to and what it leaves free, and is every such sentence true? Is anything left that refers to the
   older definition (digits 6–8)?
2. **The CPU reference (PR 2).** Is it a correct definition of the search: for a field, the set of n it reports
   as survivors, as checked, and as nice numbers? Test it yourself beyond the author's tests: (a) against
   production's own CPU search on whole small bases (the repository's existing nice-only functions: the nice
   numbers found must be the same; base 10 must give 69); (b) by mutation: break one rule at a time in a scratch
   copy (a top certificate off by one digit, a bottom digit test dropped, the residue classes, the prefilter,
   the range ends) and see whether the tests fail; report every mutant that survives. The author found and
   fixed one such gap (the prefilter was checked against itself): check the fix and look for the next.
3. **Tests.** Fast enough (the author measured 13 s in release, 67 s in debug for `just test`: say whether the
   debug time is acceptable for this repository's habits or which case to trim); ordinary, not ignored; no
   dependence on anything outside the repository.
4. **Standing alone.** Each branch compiles, lints (`just lint`) and passes the whole suite by itself: run all
   of it yourself on the box in your own clones and target directories. No dead code kept alive by
   allowances; no production behaviour changed (a `mod` line is expected).
5. **Readability.** What would a maintainer have to ask in a comment thread? Names, the word "slice", "shape
   (f0, k)", "quantum", "padded form": is each defined where it is first used?
6. **The two descriptions** against the code and against the rules above. Accurate? Plain? Too long? Do they
   say what the reader can verify alone and what comes next? Any forbidden reference?

Do not review speed. Do not rewrite; list.

## Machines and rules

- **ivory**: reading and notes only; do not build here.
- **One rented box, handed to you for this task:** `ssh -p 35082 root@ssh2.vast.ai` (Vast 61441981; 16
  threads visible with a CPU quota of about 5; the toolchain and `just` are on it; the author's clones are
  under the paths `G2/PR12-NOTES.md` names: use your own clones and target directories, fetched from
  `https://github.com/wasabipesto-bot/nice.git`). Nothing ever contacts the production API. Never create or
  destroy instances; never use another machine. Leave it running and idle.
- **You change nothing on the two branches.** Mutants and experiments live in scratch clones on the box. No
  pushes, no pull request.

## Deliverable (by 17:40 UTC)

`G2/PR12-REVIEW.md`: for each pull request the verdict in the first line, then findings ranked (must fix
before opening; should; note) with file and line and the evidence; the mutants tried and which survived; what
you ran yourself and its result; corrections to each description. Then a report to me of at most 25 lines.
