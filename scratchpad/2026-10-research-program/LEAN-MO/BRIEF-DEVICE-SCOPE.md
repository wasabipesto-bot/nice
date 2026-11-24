# Scope: a Lean model of what the GPU path does differently from the reference, and a proof that it returns the same (brief, 2026-11-24 05:55 UTC)

You are a proof engineer who knows Lean 4 and Mathlib and can read GPU kernel code. Work alone (do not start
subagents), on this machine only (ivory), **reading only: no builds, no code changes, no pushes.** **Hard stop
08:30 UTC.** The deliverable is a scope document, not a proof.

## What exists

The "nice" project's redesigned search join (the "middle-out join") has: an exact CPU reference in Rust
(`common/src/midout/cpu.rs`, `coord.rs`; fork branch `dev/mo-clean`, head `eb9ef776`, worktree
`~/projects/nice/.worktrees/midout-clean`); a GPU path (`common/src/midout/gpu.rs` for base 64, `gpu_wide.rs`
for bases 65–70) that does the same search differently; and, on the fork branch `lean/midout` (directory
`lean-midout/`, worktree `~/projects/nice/.worktrees/lean-midout`), a Lean model of the **reference** with 208
theorems ending in "if every field of a covering set returns nothing, the base has no nice number", audited
(`~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/REVIEW.md`). Read `lean-midout/README.md` and that
audit first, then `~/projects/nice/scratchpad/2026-11-midout-design/DESIGN.md` §2 (the pipeline), §4 (the
execution checks), §5 (data between stages), §6.3–6.8, then the module documentation at the top of `gpu.rs`
and the host driver (`GpuJoin`, `search_field`, `check_slice`, `finish_group`).

The proof says nothing about the GPU path. Between the reference and what a card computes there are two kinds
of difference: **algorithmic** (the GPU path computes the same sets by another route) and **implementation**
(limb arithmetic, bit layouts, lane and plane mechanics, memory). Only the first kind can be modelled at a
reasonable price. The algorithmic differences I know of: tops certified in a hierarchy (a coarse level once per
64 slices, then per slice); parents taken from lists shared by the 64 slices that differ only in digit 8;
children appended per parent and scattered into (class, key) buckets with a per-bucket sort; jobs (class, unit)
with more probes than a window split into instances; the pairing as records of non-zero words with child-list
positions, expanded afterwards into survivors; the prefilter applied in the expansion with the top's
certificate above position 11; survivors checked by production's check kernel; a field as groups of 16 slices
with per-slice accounts and two conservation laws; one slice per field recomputed on the CPU.

## What the scope must settle

1. **The list of algorithmic differences, complete and exact**, each with the code (file and line), what set
   or list it computes, and the statement that it equals the reference's object (as a Lean signature you would
   propose against the existing model's definitions, not compiled). Mark each: already implied by an existing
   theorem; new but short; new and substantial; not expressible without modelling implementation detail.
2. **Which of them, if wrong, would lose a nice number silently** (not caught by the execution accounts, the
   conservation laws or the sampled CPU slice), and with what probability the sampled check would see it. That
   ranking decides what is worth proving: a difference whose error is always loud is worth less than one whose
   error is silent.
3. **What a "device model" would be**: one more Lean function per stage, composed into a `deviceSearchField`
   with the same outcome type, and a theorem `deviceSearchField = searchField` (as sets or as lists: say
   which); how it would be tied to the Rust (fixtures from the GPU path's host-side reference points: the
   project already compares device and CPU slice by slice; which intermediate tables can the Rust emit without
   a card: the shared lists, the bucket layout, the job split?) and what stays untested without a card.
4. **Size, order, risks**, with the basis (the sizes of the corresponding proofs already in `lean-midout/`),
   and the lessons of the audit built in: whole-object statements, vacuity checks at the real parameters, a
   mutant for every lemma, tested function = proved function.
5. **Your recommendation:** which two or three differences to prove first if only a few sessions are spent,
   and which to leave to tests, with reasons.

## Deliverable (by 08:30 UTC)

`~/projects/nice/scratchpad/2026-10-research-program/LEAN-MO/DEVICE-SCOPE.md`, at most 250 lines, plain language,
every claim about code with file and line; then a report to me of at most 15 lines. If the tooling denies
something, do not work around it: note it.
