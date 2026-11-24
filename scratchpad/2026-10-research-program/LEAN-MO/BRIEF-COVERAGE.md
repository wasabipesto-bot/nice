# A checked coverage certificate for a searched base (brief, 2026-11-24 05:55 UTC)

You are a proof engineer who knows Lean 4 and Mathlib. Work alone (do not start subagents). **No rented machine
today: this machine (ivory) cannot build Mathlib, so you build only through the fork's CI** (pushes to
`lean/**` on `wasabipesto-bot/nice` run "Lean middle-out (temporary)": `lake build --wfail`, the conformance
program, the axiom check; 8–11 minutes a run; read results with `gh run list/view -R wasabipesto-bot/nice`,
logs with `gh run view --log-failed`). Write carefully, push small, wait with a background
`until …; do sleep N; done` loop (foreground `sleep` is blocked). **Hard stop 10:30 UTC.**

## Where things stand

Fork branch **`lean/midout`** (head `05747baa`, directory `lean-midout/`, worktree
`~/projects/nice/.worktrees/lean-midout`): a Lean model of the "nice" project's middle-out search and 208
theorems, ending in `no_nice_of_searched_withDigits` (`NiceMidOut/WholeBase.lean`): if
`Coord.withDigits b k0 k1 q0 = some c`, a list of fields `fs` satisfies `c.Covers fs`, and every field's
`searchField` returns an outcome with no nice number, then no n is nice in base b. Read `lean-midout/README.md`,
`WholeBase.lean`, `Coord.lean`, and under `~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/`:
`REVIEW.md` (the independent audit: note what it says the proof does not cover) and the "After the audit"
section of `STEP2-NOTES-B.md`.

**The link this task closes.** In a real search, the fields are handed out and recorded by a coordinator
(`scripts/midout_coordinator.py` on the fork branch `dev/mo-clean`: state in `claims.jsonl` and
`submissions.jsonl`; a work list of fields made by `common/examples/midout_fields.rs`). The theorem's
hypothesis `c.Covers fs` is about a list of fields; today nothing connects "the coordinator's record" to it.

## What to build, on `lean/midout`

1. **A decision procedure:** a computable `coversB : Coord → List (ℕ × ℕ) → Bool` (sort the fields, check each
   is whole quanta, check they leave no gap in `[lo, vEnd)`; overlaps allowed or refused, say which and why)
   with the theorem `coversB c fs = true → c.Covers fs` (and the converse if it is cheap). For 262,144 fields
   it must run in seconds when compiled.
2. **A certificate checker executable** (`lake exe coverage`): arguments: base, coordinate digits, and a file
   of searched fields, one per line (`range_start range_size nice_count`, the form a small script can produce
   from a coordinator's `submissions.jsonl`; write that script too, standard-library Python, beside the Lean
   project, and say exactly which submissions it takes: accepted ones only). It prints whether the coordinate
   is accepted, whether the fields cover the range, how many report a nice number, and exits 0 only if the
   range is covered and every field reports none. State in its output, in one honest sentence, what a "yes"
   means: "if each listed field's search really returned what is recorded, then by
   `no_nice_of_searched_withDigits` base b has no nice number", and what it does not check (that the searches
   ran, or ran correctly).
3. **The theorem that makes the executable's "yes" mean that:** from `coversB c fs = true` and "for every
   field of fs, `searchField` returns an outcome with an empty nice list" conclude `∀ n, ¬ IsNice b n`
   (a corollary of the existing theorem, stated on the checker's own inputs).
4. **Tests in the conformance program or beside it:** small-base work lists that cover, that leave a gap at
   the start, in the middle, at the end, that contain a field not of whole quanta, an empty list, duplicates,
   unsorted input; base 64 with the 262,144 single-quantum fields (generated in the test, not stored) to show
   the run time. A mutant check you run through CI on a scratch branch `lean/scratch-cov` (not merged): a
   `coversB` that forgets the last gap must fail its proof.
5. **If time remains:** "each nice number appears exactly once in a field's outcome" is still unproved (the
   audit's note C1); do not start it today unless everything above is green before 09:00.

## Rules

- Nothing is called proved that has a `sorry`, an added axiom or `native_decide`; the tree you push to
  `lean/midout` has no `sorry`. Experiments that may not build go to `lean/scratch-cov` first.
- Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; plain messages with no reference to notes, agents
  or models. `git push -u fork lean/midout`. **No pull request; nothing to the upstream remote `origin`;
  `lean-proofs` and `dev/mo-clean` are read-only for you** (another engineer is changing
  `scripts/midout_coordinator.py` on `dev/mo-clean` today: read its submission format from the head as you
  find it and say which commit you read).
- ivory: no `lake`, no Rust builds. Never contact the production API. If the tooling denies something, do not
  work around it: note it and report it.

## Deliverables (by 10:30 UTC)

1. `lean/midout` on the fork, green in its CI (run URL).
2. `LEAN-MO/COVERAGE-NOTES.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): the definitions
   and theorems with exact statements, the executable's usage and output, the tests, the run time at base 64,
   what a "yes" does and does not mean.
3. A final report to me of at most 15 lines.
