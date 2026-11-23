# Independent audit of a Lean proof before anything is claimed from it (brief, 2026-11-23 07:25 UTC)

You are an independent reviewer who knows Lean 4 and Mathlib. You did not write this proof. Work alone (do not
start subagents). **Hard stop 10:45 UTC; the box destroys itself at about 11:45 UTC.**

## What you audit

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a
base exactly once ("nice numbers"); its results are statements that none exists in a base, so what matters is
that the search never discards one. A redesigned search join (the "middle-out join") has an exact CPU
reference in Rust (`common/src/midout/cpu.rs`, `coord.rs` on the fork branch `dev/mo-clean`, worktree
`~/projects/nice/.worktrees/midout-clean` on ivory, this machine). Over three sessions a Lean project was
written on the fork branch **`lean/midout`** (head `5eb715f3`, directory `lean-midout/`, worktree
`~/projects/nice/.worktrees/lean-midout`): a Lean model of that reference, fixture tables generated from the
Rust with a conformance program (81,484 comparisons), and 191 theorems ending in

    searchField_complete, searchField_sound      (lean-midout/NiceMidOut/EndToEnd.lean)

said to mean: "for every base with a range, every valid coordinate, every shape that fits and every
whole-quanta field, the model's search returns every nice number whose renumbered value lies in the field, and
only nice numbers of the field". The authors' accounts: `lean-midout/README.md` on the branch, and under
`~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/`: `SCOPE.md` (what was to be proved and what a
proof would and would not let the project claim), `STEP1-NOTES.md`, `STEP2-NOTES-T.md`, `STEP2-NOTES-B.md`.
The proof imports an earlier library at a pinned commit (the `proofs` directory of the fork branch
`lean-proofs`, `4cdaa47f`), which defines `IsNice`, digits and the base range.

**A proof is only as good as its statements and its definitions. Your job is to find out whether these two
theorems say what the project would claim from them, and what exactly they do not say.** Assume nothing from
the authors' notes.

## Decide: the claim in the README is (a) accurate, (b) accurate with stated corrections, or (c) not supported

1. **The definitions the statements rest on.** Read `IsNice`, the digit functions and the base range in the
   earlier library, and `Coord`, `Coord.Valid`, `vOfN`, `fieldDigits`, `Shape`, `Shape.Fits`, `searchField`,
   `FieldOutcome` in this project. Is `IsNice b n` the property the project means (the digits of n² and n³
   together are each digit 0 … b − 1 exactly once)? Check it against the Rust's definition and against known
   values: by evaluation in Lean on the box, the nice numbers of whole small bases (base 10 must give exactly
   69) by the Lean definition, by brute force over the base's range.
2. **Vacuity.** Are the hypotheses satisfiable where the project needs them? Produce Lean terms or evaluations
   on the box showing that for base 64 with coordinate (4, 8, 5) and shape (4, 10), and for base 65 with its
   coordinate and shape, `Coord.withDigits` returns a coordinate, `Shape.Fits` holds, and `fieldDigits`
   returns `some` for a real field (take one from the fixtures), so that both theorems apply to them. Is
   `Coord.Valid` or `Fits` accidentally so strong that no real instance satisfies it, or so weak that the
   theorem's conclusion is about an empty search? Is `∃ o, searchField … = some o` ever `none` for a field the
   Rust would search?
3. **Is the function in the theorems the function that was tested?** Trace `searchField` in the statements to
   the code the conformance executable runs against the Rust tables: the same constants, or a second form
   joined by a proved lemma (the notes say `sliceRun` is proved a permutation of `sliceSurvivors`): check that
   chain yourself, including what `o.nice` is in each form.
4. **Do the proofs depend on the details that matter?** On the box, in a scratch copy, mutate the *model*
   one definition at a time (at least: the top certificate asked for one position too high; a residue class
   dropped from the roots; the prefilter's exemption threshold changed; the child's affine digit using the
   wrong coefficient; a top's interval made strict at one end; the field's digit test off by one) and record
   for each: does the proof still build (then the theorem did not depend on it: explain), and does the
   conformance program catch it. A mutant that neither the proofs nor the conformance catch is a finding.
5. **Axioms and trust.** `#print axioms` for both theorems yourself; no `sorry`, no `native_decide`, no
   `implemented_by`/`extern`/`unsafe` anywhere on the path from the theorems to the definitions; `partial`
   definitions or `decreasing_by sorry`; the pinned dependency really is the commit it claims; rerun
   `leanchecker` on the two end-to-end modules.
6. **The gap to the running code, stated honestly.** What do the theorems *not* cover: the Rust itself, the
   384-bit arithmetic, the bit-sliced word, mask widths above 64, the GPU kernels, the drivers, the
   coordinator's bookkeeping, "each number is reported once". Is each of these said plainly in the README, and
   is any sentence there stronger than the theorems? Propose the exact wording the project may use in public
   for what is proved, in two sentences.

Do not rewrite the proof; list findings ranked (wrong or overstated; should fix; note) with file and line.

## Machines and rules

- **ivory**: reading and notes only (it cannot hold Mathlib).
- **One rented box, handed to you for this task:** `ssh -p 24564 root@ssh7.vast.ai` (24 cores, 31 GB of
  memory, 60 GB of disk; the toolchain and built trees of the authors are under `/work/tops`, `/work/bottoms`,
  `/work/merged`: use your own clone and build directory `/work/review`, fetched from
  `https://github.com/wasabipesto-bot/nice.git`, branch `lean/midout` at `5eb715f3`; you may copy the Mathlib
  cache). Never contact the production API. Never create or destroy instances; never use another machine.
  Leave the box idle.
- **You change nothing on any branch.** Mutants and experiments live in your scratch copy on the box. No
  pushes, no pull request, no comment on any pull request.
- If the tooling denies something, do not work around it: note it and report it. Long commands under `nohup`
  with logs, polled; foreground `sleep` on ivory is blocked.

## Deliverable (by 10:45 UTC)

`LEAN-MO/REVIEW.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): the verdict (a, b or c) in
the first line; findings ranked with file, line and evidence; the mutant table; what you ran yourself and its
output; the two-sentence public wording you would sign. Then a report to me of at most 15 lines.
