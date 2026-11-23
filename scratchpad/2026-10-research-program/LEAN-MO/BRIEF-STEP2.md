# The middle-out join in Lean, step 2: the join's lemmas, in two halves (brief, 2026-11-23 05:55 UTC)

You are a proof engineer who knows Lean 4 and Mathlib. Work alone (do not start subagents). **Hard stop
11:15 UTC; the box destroys itself at about 11:45 UTC. Push to the fork after every lemma that builds.**

## Where things stand

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a base
exactly once. Its redesigned search join (the "middle-out join") has an exact CPU reference in Rust. On the
fork branch **`lean/midout`** (head `4934b0ca`; directory `lean-midout/`; worktree
`~/projects/nice/.worktrees/lean-midout` on ivory, this machine) there is a Lean model of that reference which
agrees with the Rust on 81,484 fixture comparisons, and 83 theorems: the coordinate lemmas (L1), the computable
range equal to the library's, and the run form of the join a permutation of the definitional form
`sliceSurvivors`. **Read first, in full,** under `~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/`:
`SCOPE.md` (the theorem, the lemmas L1–L11 with statements, what the earlier library proves and where: your
specification) and `STEP1-NOTES.md` (what the model is, definition by definition; what is proved; the lesson
"before each lemma, add the fixture that would catch its mutant"). Then the model: `lean-midout/NiceMidOut/*.lean`.

Today the join's lemmas are proved **in two halves by two engineers working at the same time on the same box**.
Which half is yours is in the message that gave you this brief. Neither half includes L10 (the end-to-end
composition): it is done after both halves are merged.

- **Half T (tops and the generic lemmas):** L2 (range and digit lengths), L3 (residue classes; reuse), L4 (the
  top certificate: the scan equals the library's `cert`; `mhi`; `unitTops` lists every nice n's top with its
  clipped interval), L6 (class compatibility: the probe-set identity), L9 (the final check is the definition).
  Your branch: **`lean/midout-tops`**; new files only, named `NiceMidOut/Tops*.lean`, `Classes*.lean`,
  `Check*.lean`, `Range*.lean` as needed.
- **Half B (bottoms, pairing, prefilter):** L5 (parents and children: a slice's parents are exactly the
  residues with the slice's digits whose low output digits are distinct, every nice n's residue is one, and the
  child's two new digits are the affine expressions), L7 (pairing: a nice n's top mask and child mask are
  disjoint; the chunk skip loses nothing is already proved, use it), L8 (the prefilter: every nice n passes,
  with the exemption stated and proved). Your branch: **`lean/midout-bottoms`**; new files only, named
  `NiceMidOut/Bottoms*.lean`, `Pairing*.lean`, `Prefilter*.lean` as needed.

Each lemma is stated about the model's own definitions (`sliceSurvivors` and what it is built from), in the
form L10 will need: "for every nice n of the slice, [the object] of n is in [the model's list] with [the mask
the model computes]". If a statement in the scope does not fit the model as it now is, state what you proved
instead and why. If a model definition must change to make a lemma true or provable, **do not change it on your
branch**: write the proposed change in your notes (the other engineer depends on the same definitions) and
prove what can be proved without it.

## Rules

- **Shared files are frozen today:** `NiceMidOut/Coord.lean`, `Join.lean`, `CoordProofs.lean`,
  `RangeProofs.lean`, `RunProofs.lean`, `Conformance.lean`, the fixtures, the lakefile. Add files; touch
  `NiceMidOut.lean` only to add your own import lines. New fixtures go in a new table file of your own with
  its own generator addition, only if a lemma's mutant would otherwise pass (say which).
- Nothing is called proved that has a `sorry`, an added axiom or `native_decide`; the tree you push has no
  `sorry` (keep unfinished work out of the build and describe it in the notes). `lake build --wfail`, the
  conformance executable and the axiom check must pass at every push; the fork's CI (it runs on pushes to
  `lean/**`) must be green on your branch at the end: give the run's URL.
- **ivory**: reading, git and notes only (it cannot hold Mathlib). **The box, shared by the two of you:**
  `ssh -p 24564 root@ssh7.vast.ai` (Vast 62104162: 24 cores, **31 GB of memory**, 60 GB of disk, a fresh Ubuntu
  image). Each engineer works under its own directory `/work/tops` or `/work/bottoms` with its own clone and its
  own `.lake`; the Mathlib cache may be fetched twice. Build with at most 10 jobs each and watch `free -g`: two
  builds share 31 GB. Do not touch the other directory. Never contact the production API; no client binary is
  needed. Never create or destroy instances; never use another machine. Leave the box idle.
- Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; plain commit messages with no reference to notes,
  steps, agents or models. `git push -u fork <your branch>` from ivory (bundle from the box). **No pull request;
  nothing to the upstream remote `origin`; no comment on any pull request; `lean/midout`, `lean-proofs` and
  `dev/mo-clean` are read-only for you** (I merge the two halves afterwards).
- If the model and the Rust reference turn out to disagree on something a lemma exposes, or a lemma is false
  for the model as written, stop that lemma and tell me at once with the smallest example: that is a finding.
- If the tooling denies something, do not work around it: note it and report it. Long commands under `nohup`
  with logs, polled; foreground `sleep` on ivory is blocked.

## Deliverables (by 11:15 UTC)

1. Your branch on the fork, green in its CI.
2. `LEAN-MO/STEP2-NOTES-T.md` or `STEP2-NOTES-B.md`: each lemma with its Lean name and exact statement in
   words, what was reused from the earlier library (declaration names), what is not proved and why, any change
   you propose to a shared definition, what L10 will need from your half, build times.
3. A final report to me of at most 15 lines.
