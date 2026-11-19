# The middle-out join, step 5L: fields that fix digits 5–7, parents shared across digit 8, and the wide prefilter (brief, 2026-11-19 08:40 UTC)

You are an engineer on the fifth step of a build. Work alone (do not start subagents). **Hard stop
12:10 UTC, and it is hard: the box destroys itself at about 12:45 UTC. Bundle commits to ivory after every
piece.**

## Where things stand

Read first, under `~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's
decision and the rules: all apply), `BUILD-NOTES.md` (§1, §2, §9–§12), `BUILD-NOTES-CLIENT.md`, and then
**`fs/REVIEW.md` in full: it is the specification of your first piece.**

The trunk `dev/middle-out-join` is at `cc0a9e04` (worktree `~/projects/nice/.worktrees/midout`): the join for
base 64 and for wide masks (65–70), execution accounts, a client route against a local coordinator whose
claims name their coordinate as `midout:K0,K1,Q0`. End to end ×3.94 against production on this box's card.

An independent review of the field structure this morning proved that any field fixing digits within 4–8 is
a union of whole slices, and recommended one change: **a field should fix digits 5–7 of n, not 6–8**
(coordinate `(4, 8, 5)` instead of `(4, 9, 6)`; the same 262,144 fields of 2^57 at base 64; still a bit
permutation). That leaves digits 4 and 8 free inside a field: tops keep sharing across digit 4 (built), and
**parents can share their preparation across digit 8** (the per-slice root pass falls to about 22 % of its
size by exact counts; the review prices it at about 3 % of a slice, derived, never measured on a card).

## Your job, in this order

1. **The coordinate `(4, 8, 5)`**: `Shape::for_coord` returns the (4, 10) shape for it explicitly; the
   coordinate tests (bijection, coverage, range ends) pass for it at base 64 and in padded form at base 65; the
   device path searches a field of it exactly: parity against the CPU reference on slices, whole-field counts
   equal to the same n-sets searched under `(4, 9, 6)` (a field of one coordinate is a different set of slices:
   compare slice by slice). Both coordinates stay supported; the default stays as it is until you have shown
   the new one exact; then make `(4, 8, 5)` the default and say so at the top of the notes. The client route
   and the coordinator accept `midout:4,8,5` (they refuse it today, with a test: update the test).
2. **Parent preparation shared across digit 8 inside a field** (the review's §4 and its `G2_ANCKEY`
   prototype): the depth-8 ancestors computed once per group of slices that differ only in digit 8, the
   per-slice pass reduced to what depends on digit 8. Exact first (the accounts and the fault tests must hold:
   children counted two ways, probes = 8 × tops), then its cost per slice by cumulative stops and the ten-field
   number against the trunk before your change, same session. If it does not pay on this card, say so with the
   numbers and leave it behind a switch that is off.
3. **The wide prefilter's arithmetic** (`BUILD-NOTES.md` §11.4: it adds 2.6 ms to the base-65 expansion): reuse
   each record's fixed high part or use limbs as the narrow path does; exact at base 65 against the CPU
   reference and with the wide path forced at base 64 and small bases; base 65 again as a multiple of base 64
   in one session (last night ×2.08).

Order of sacrifice: 1 completely, with its tests, before anything else; then 2; then 3. If a piece is
unfinished at 11:40 UTC, park it on a side branch pushed to the fork and leave the trunk at the last state
where everything passes.

Kernel traps (all real here): on the SPIR-V compiler several atomic stores of one value in a basic block are
merged into one; a `loop` with two `break`s and a read after it compiles to invalid SPIR-V; planes may run
partly filled; lane 0 may not exist. Every kernel change is checked on lavapipe at 8 lanes through SPIR-V as
well as on CUDA.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, handed to you for this task** (the client-route engineer just left it idle):

      ssh -p 38876 root@ssh2.vast.ai

  Vast instance 61386517: RTX 3080 (10 GB) capped at 240 W, 16 threads visible with a CPU quota of about 5,
  31 GB memory; toolchain, lavapipe, trees at `cc0a9e04` and scripts are on it (`G2/build4f/box/` and the notes
  say where). Production hosts are mapped to 127.0.0.1 and ::1: check before any client binary runs; nothing
  ever claims from or submits to the production API. Never create or destroy instances; never use another
  machine. Leave it running and idle.
- You are the trunk's only writer. Ordinary commits (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory after every piece;
  `git push fork dev/middle-out-join` from ivory. No pull request, nothing to upstream. No server code. One
  target directory per worktree. fmt and clippy clean; production's suite passes.

## Deliverables (by 12:10 UTC)

1. Commits on ivory and the fork, everything passing at the trunk's head.
2. `G2/BUILD-NOTES.md` §1 updated and a new section "Step 5L" (what a field is now and why; the exactness
   evidence for the new coordinate; the parent sharing's counts and its measured worth; the wide prefilter;
   numbers); `BUILD-NOTES-CLIENT.md` updated for the coordinate id. Raw logs under `G2/build5l/`.
3. A final report to me of at most 25 lines.
