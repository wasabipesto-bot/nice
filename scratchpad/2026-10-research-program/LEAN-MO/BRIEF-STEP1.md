# The middle-out join in Lean, step 1: a Lean model of the reference that agrees with the Rust on fixtures (brief, 2026-11-22 05:55 UTC)

You are a proof engineer who knows Lean 4 and Mathlib. Work alone (do not start subagents). **Hard stop
11:15 UTC; the box destroys itself at about 11:45 UTC. Push to the fork after every piece that builds.**

## Why, and what step 1 is

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a base
exactly once. Its redesigned GPU search join (the "middle-out join") is defined by an exact CPU reference in
Rust. Yesterday's scope, **`~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/SCOPE.md`: read it in
full first, it is your specification** (the theorem, eleven lemmas L1–L11 with signatures, what the earlier Lean
library already proves, the plan in §6, the risks in §7), names as the main risk that a Lean model does not
match the code, and as the cure: **model first, compared against tables from the Rust before any proof.** That
is step 1, and it is useful by itself: a second, independent definition of the search.

Chosen by me among the scope's options: a separate Lean project on a fork branch that **imports the earlier
library pinned at its commit** (`lean-proofs`, `4cdaa47f`, the head of the maintainer's parked draft pull
request #160, which nobody touches), no pull request.

## What to build

A new branch **`lean/midout`** on the fork, created from `dev/mo-clean` (head `10ddbf17`, worktree
`~/projects/nice/.worktrees/midout-clean`: do not commit there; make your own worktree
`~/projects/nice/.worktrees/lean-midout`), containing:

1. **A Lake project in a new directory `lean-midout/`** that depends on the earlier library by git revision
   (the repository `https://github.com/wasabipesto-bot/nice`, revision `4cdaa47f…`, its Lean subdirectory; if
   Lake cannot take a subdirectory of a git dependency in the pinned Lean version, say what you did instead:
   for example a git subtree copy of that directory at that commit, clearly marked as a verbatim copy, with a
   script that checks it is byte-identical). Same Lean and Mathlib pins as the earlier library.
2. **The model**: Lean functions that mirror `common/src/midout/coord.rs` and `cpu.rs` (the coordinate v and
   its inverse, quanta and slices, the shape, the residue classes and roots, the top certificate, parents and
   children with their masks, the pairing test, the prefilter with its exemption, the final check,
   `slice_join`, `search_field`), written to be extensionally the Rust (same lists in the same order where that
   is cheap), reusing the earlier library's definitions wherever the scope says they fit (name each reuse).
   Executable, base-generic. These must be the definitions the later theorems will be about; if a second,
   faster form is needed for running, say so and state the refinement that will have to be proved.
3. **Fixtures from the Rust**: a small Rust program on the branch (an example or script in the style of the
   earlier library's fixture generator, which the scope cites) that writes tables from the real code: every
   survivor, in order, with the counters, of every slice of the small bases the Rust tests already run; and
   base-64 pieces: v of sampled n and the slice lists of sampled fields; top certificates on sampled prefixes;
   parents and child masks under sampled slices; prefilter verdicts on random n; the residue classes for
   every base 3–128. Deterministic (fixed seeds), small enough to commit (a few MB at most), with a checksum.
4. **A conformance executable** (`lake exe …`) that recomputes each table with the Lean model and compares it
   entry for entry, exiting non-zero on the first difference with the place it differs.
5. **A workflow for the fork's own CI**, triggered on pushes to `lean/**` only, that builds with warnings as
   errors and runs the conformance executable (the fork has Actions enabled; earlier work used temporary
   push-triggered workflows there). Name it clearly as temporary.

**If the model and the Rust disagree** and you become convinced the Rust is the one that is wrong, stop and
report it to me at once with the smallest reproducing input: that would be a finding about the search itself.

**If time remains** after conformance passes: L1 of the scope (the coordinate is a bijection onto its image, a
field is a whole number of slices, fields partition the range), proved with no `sorry` and no new axioms; then
stop. Do not start the join lemmas today.

## Rules

- **ivory** (this machine): reading, git and notes only; it cannot hold Mathlib (4.5 GB of disk free): no
  `lake` here. All building on the box, and as the final check on the fork's CI.
- **One rented box, which I rented and logged in to for you:** `ssh -p 26300 root@ssh6.vast.ai` (Vast
  61919150: 96 threads visible with a CPU quota of about 23, 125 GB of memory, 50 GB of disk, a fresh Ubuntu
  image; its GPU is not needed). Install elan, the pinned toolchain, the Mathlib cache (`lake exe cache get`),
  and the Rust toolchain the repository pins for the fixture generator. Never contact the production API;
  nothing here needs a client binary. Never create or destroy instances; never use another machine. Leave the
  box idle.
- Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; commit messages in plain words with no reference
  to notes, steps, agents or models. `git push -u fork lean/midout` from ivory (bundle from the box). **No pull
  request; nothing to the upstream remote `origin`; no comment on any pull request; the branches `lean-proofs`
  and `dev/mo-clean` are read-only for you.**
- Nothing is called proved that has a `sorry`, an added axiom, or `native_decide`; say exactly what is model,
  what is tested against fixtures, and what is proved.
- If the tooling denies something, do not work around it: note it and report it.
- Long commands under `nohup` with logs, polled; foreground `sleep` on ivory is blocked (wait with a background
  `until …; do sleep N; done` loop).

## Deliverables (by 11:15 UTC)

1. Branch `lean/midout` on the fork, building on the box and green in the fork's CI (give the run's URL).
2. `LEAN-MO/STEP1-NOTES.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): what the model
   covers, definition by definition against the Rust (file and line), what was reused from the earlier library,
   the fixtures (what, how many entries, how generated), the conformance result, every place where the model
   and the Rust differed on the way and how it was resolved, what is proved (if anything), build times, and
   what step 2 should start with.
3. A final report to me of at most 20 lines.
