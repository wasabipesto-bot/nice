# Scope of a machine-checked proof that the middle-out join misses no candidate (brief, 2026-11-21 06:05 UTC)

You are a proof engineer who knows Lean 4 and Mathlib. Work alone (do not start subagents), on this machine
only (ivory), **reading only: no Lean build, no code changes, no pushes.** **Hard stop 08:30 UTC.** The
deliverable is a scope document, not a proof.

## Why

The "nice" project searches exhaustively for numbers n whose square and cube together use every digit of a base
exactly once ("nice numbers"); its results are statements of non-existence per base, so the search's soundness
(it never discards a nice number) is the whole value of a result. A redesigned GPU search join, the
**middle-out join**, has been built on a fork branch and is about to be read by the project's maintainer. Its
exactness today rests on tests: a CPU reference equal to brute force on whole small bases, the device equal to
the CPU reference on sampled slices, and a paper argument. Formal proofs of large results are now produced with
AI assistance routinely; the maintainer has been told a machine-checked exactness proof of this join "is well
within reach" and that it would first be scoped. That scope is your job.

## What exists

- **The join and its definition:** branch `dev/mo-clean`, head `10ddbf17`, worktree
  `~/projects/nice/.worktrees/midout-clean`. The mathematical object is `common/src/midout/coord.rs` (what a
  field is: a per-base renumbering of n; slices; coverage) and `common/src/midout/cpu.rs` (the exact CPU
  reference: the shape (f0, k), the residue classes, top certificates, bottom certificates through parents and
  children, the pairing test, the prefilter, the full check). The design in plain words:
  `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` (§1, §3, §4, §6.1, §6.8, §7).
- **Existing Lean work on the project's earlier join:** upstream draft pull request #160 ("Lean proofs: claims
  registry, END-1 with the affine stage, and the overlap join (END-2)"), parked by the maintainer as a draft.
  Find its branch (`gh pr view 160 -R wasabipesto/nice --json headRefName,headRepositoryOwner,files`; the fork
  is the remote `fork` of `~/projects/nice`) and read its Lean sources and its claims registry with `git show`
  / `git grep` on the fetched ref (do not check it out over anything; a `git worktree add` under
  `~/projects/nice/.worktrees/lean-read` is fine and must be removed at the end): namespace `NiceSearch`, 68
  claims proved by my records, including the residue filter, the top ("MSD") and bottom ("LSD") certificates
  and the overlap join's end-to-end statement. Note which Lean and Mathlib versions it pins and how it is built
  and checked in CI.
- Two outside repositories did related work (a Lean development with certified search by another author, noted
  in `~/projects/nice/scratchpad/2026-09-external-repos/` if that directory exists): read the notes there only
  if they help to avoid duplicating a definition; do not contact anyone and do not fetch those repositories.

## What the scope must settle

1. **The theorem, stated precisely** (in mathematical notation and as Lean signatures you would propose, not
   compiled): for a base b in the join's range, a coordinate (k0, k1, q0) and a field of that coordinate, every
   nice n whose renumbered value lies in the field is in the output of the reference algorithm. Break it into
   the lemmas it needs, each with its statement:
   coordinate bijection and coverage (fields partition the base's range; a field is a whole number of slices);
   the residue classes (necessity); the top certificate (the digits it certifies are the digits of n², n³ at
   those positions for every n under the top; what "certified" means with the carry); the bottom certificate
   through parents and children (the affine child digits); pairing (disjointness is necessary); class
   compatibility (each top meets exactly the classes it must); the prefilter (necessary for every nice n; note
   the exemption the code has and why); the final check (it is the definition). Say for each whether it is
   base-generic or specific to base 64, and where the code's edge cases are (the range's ends, tops clipped by
   the range, masks of more than 64 bits at bases above 64, the job split when a job has more probes than a
   window).
2. **Reuse:** for each lemma, what #160's library already proves (name the Lean declarations), what carries
   over with a change of parameters, and what is new. Be concrete about the mismatch between its overlap join
   (tops at f0 = 3, bottoms at k = 6, contiguous fields) and this one.
3. **The gap between the theorem and the running code**, honestly: the Lean statement is about a mathematical
   algorithm; the Rust CPU reference, the CubeCL kernels, the drivers and the hardware are not covered. Say
   what the strongest affordable link is (for example: the theorem about a Lean function that is extensionally
   the Rust reference, plus the existing device-against-reference sampled check), and what it would and would
   not let the project claim. Do not oversell.
4. **Size and plan:** an estimate of statements and lines (with the basis: the sizes of the corresponding
   proofs in #160), the order of work, what can be checked independently at each step, the build environment
   it needs (this machine cannot build Mathlib: 4.5 GB of disk free), and the main risks (definitions that do
   not match the code; arithmetic on 384-bit quantities; the wide-mask bases).
5. **Where it should live**, as options for the maintainer, since their own Lean pull request is parked: a
   separate directory or repository that depends on nothing in #160; an extension of #160's library on its own
   branch; nothing until they ask. State the trade-offs; I will choose or ask.

## Deliverable (by 08:30 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/SCOPE.md`, at most 250 lines, plain language, every
claim about existing code or proofs with its file and line or declaration name; then a report to me of at most
15 lines. Remove any worktree you added. If the tooling denies something, do not work around it: note it.
