# G2 brief: a second-generation join, designed from a clean slate for at least ×10 (2026-11-16)

You are a researcher on the nice research program (repo `~/projects/nice` on this machine,
ivory; upstream `wasabipesto/nice`). The maintainer's instruction of today: the point of this
program is "to delve deep into novel high-impact ideas", not incremental tuning. This brief is
one of two such lines; the other (`../BX/`) attacks the search's exponent, this one its
structure.

## Background you must read

- `common/src/overlap_join.rs` module docs on upstream main (the join as it is: top prefixes of
  t = L − 3 digits, bottom residues mod b^6, two partition digits, the remaining shared digits
  and the residue class mod b−1 as hash keys, one AND per matched pair, a middle-digit
  prefilter and a full check for survivors).
- `../../2026-11-fresh-eyes/NOTES.md` §3–§5: the pair-count model of the join's macro shape, its
  calibration to measured unit costs, and the **transversal join** (lead N1: work units keyed
  by the shared middle digits so that deep bottom lists are built once per key for the whole
  base instead of once per field).
- `../EXPERIMENTS.md` entries N1.C1 and N1.G1 and the directories `../N1/cpu`, `../N1/gpu-tile`:
  the CPU prototype and the GPU projection of that design: about ×3 per base at base 62 and ×2
  at base 64, limited by memory traffic on the deep bottom lists and by the top stage. The
  maintainer parked it: ×3 does not justify changing the server's work unit.
- `../BX/COMMON.md` for the accounting every method obeys (two output digits per fixed digit of
  n) and `../N22/RESULTS.md` (shares of a field on the main production card after this week's
  merges: top certificates 26 % at base 62 and 13 % at base 64, prefilter 24 / 26 %, AND 12 /
  15 %, check 7 / 11 %, walk 7 / 11 %).

## The task

Design the join you would build today if nothing were fixed: not the field as the work unit,
not the (t, k, p) shape, not one top list against one bottom list, not the order of the
stages, not "one AND per pair". The target is **at least ×10 per base at bases 62 and 64**
against today's main, in a model whose unit costs are calibrated to measurements (use the
measured costs per top test, per pair, per survivor and per check from the files above, and
state each), **or a clear demonstration of where the ceiling is and why**.

Directions to consider, and better ones of your own:

1. **Amdahl first.** Today's time splits roughly four ways (tops, pair tests, survivor
   handling, checks). ×10 needs every one of them cut by ten. Write the table: for each stage,
   the count it processes per candidate and the unit cost, and what structure determines the
   count. Which counts are forced by the accounting, and which are artefacts of the shape?
2. **Depth on both sides at once.** The transversal design deepens the bottoms. What deepens
   the tops as cheaply (the linear windows: for a fixed top, the digits of n² above position
   2u and of n³ above L + 2u are digits of arithmetic progressions in the bottom variable, so
   deeper top certificates can be stepped by additions, as the FD kernels already do across
   partitions)? Is there a shape in which both lists are deep and the pairing is over short
   lists (a join of two trees rather than two flat lists; a multi-way join through several
   overlapping keys; a sort-merge on the shared digits with early termination)?
3. **Order of pruning.** Survivors of the AND are 30 times more numerous than they need to be
   because the middle-digit prefilter runs after pairing. Can part of the middle be decided
   before pairing (per top with a class of bottoms, or per key), so that the pairing never
   forms those pairs?
4. **The memory problem that capped N1** (deep bottom lists do not fit the caches or the
   card): streaming or blocked formulations, implicit lists (bottoms generated in key order by
   a tree walk instead of stored), compressed representations.
5. **What the work unit would have to be**, stated last and plainly: if the best design needs
   a different server work unit, say exactly which, what it would cost to change, and what the
   best design *without* that change achieves.

Method: a model first (a script that computes every stage's count per candidate for a given
structure at bases 58–64, checked against the measured counts of today's shape), then a CPU
prototype of the most promising structure that reproduces the model's counts exactly on a real
base-62 sub-range and finds the same survivors as today's reference join there (exactness is
not negotiable: the join must be sound, every nice n must survive). No GPU work.

**Kill criterion:** if the best structure you can make sound models below ×5 per base at base
64 with honest unit costs, stop designing, write the ceiling argument (the Amdahl table with
the forced counts) so that nobody re-walks it, and say what assumption would have to break.

## Rules

CPU only on ivory (4 cores shared with three other investigators): one thread, `nice -n 19`,
single runs under fifteen minutes, keep 4 GB of disk free, `/tmp` is a small tmpfs. Python or
a small standalone Rust crate inside `G2/` (do not build the `nice` workspace in release; read
its sources freely; a worktree is not needed). Write only under
`~/projects/nice/scratchpad/2026-10-research-program/G2/`. No pushes, no pull requests, no
subagents, no rented machines, no contact with the production API or servers, nothing on any
other machine. Keep a living `G2/NOTES.md` (you may be resumed tomorrow with this conversation
intact). Deliver `G2/RESULTS.md` with the verdict against the kill criterion first. Hard stop
**20:45 UTC** today. Your final message is at most 300 words for the program's director.
