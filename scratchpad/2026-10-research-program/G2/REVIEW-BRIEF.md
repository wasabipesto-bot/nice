# G2 review brief: try to break the ×10 claim before anyone builds on it (2026-11-16)

You are an independent, adversarial reviewer. Program directory:
`~/projects/nice/scratchpad/2026-10-research-program/` on this machine (ivory); repository
`~/projects/nice` (upstream `wasabipesto/nice`). You were not involved in the work under
review; take none of its claims on trust.

## What is under review

`G2/RESULTS.md`, `G2/NOTES.md`, `G2/model.py`, `G2/model2.py`, the prototype crate `G2/proto/`
(binary `G2/g2proto.bin`) and `G2/raw/`: a clean-slate design for the project's "overlap join"
(read `common/src/overlap_join.rs` module docs on upstream main for today's join, and
`../2026-11-fresh-eyes/NOTES.md` §3–§5 plus `N1/cpu/RESULTS.md`, `N1/gpu-tile/RESULTS.md` for the
earlier transversal design that reached ×3 and was parked). The claim: with transversal work
units (slices of the shared middle digits across the whole base), shape (f0 4, k 10), bottoms
generated from shared depth-9 parents with the deepest digit in registers, and top-driven
pairing over sorted 64-chunks with a common-mask skip, a base costs **×10.1 less at base 62
(range ×4.7–17.6) and ×8.3 less at base 64 (×5.1–13.2)** than today's main on a GPU. Counts are
said to be measured exactly by a CPU prototype on real base-62 and base-64 units; GPU unit
costs are derived, not measured. If it holds, it is the largest lever the project has; it also
needs the server's work unit to change, which the maintainer will only consider on strong
evidence. Your review decides whether a GPU benchmark is worth building tomorrow, and what
exactly it must measure.

## Attack these, in order of how much damage a flaw would do

1. **Soundness and coverage.** Does every candidate n of a base belong to exactly one
   (super-unit, unit, top, bottom) pair that the structure tests, including the ends of the
   base's range, tops clipped by the range, the residue classes, and the "mid-base switch"
   (dropping tops whose interval lies in fields already searched)? Is the chunk common-mask skip
   sound (a skipped chunk can contain no bottom disjoint from the top)? Is the affine
   generation of the deepest bottom digit exact, carries included? Re-run the prototype's
   exactness runs yourself (small whole bases against brute force), then write your own
   independent check on at least one base it did not use and on one real base-62 unit against
   a from-scratch enumeration of that unit's candidates (not against the prototype's own
   reimplementation of today's shape).
2. **The counts.** Re-derive pairs, kept chunk incidences, bottoms, children, tops and
   survivors per admissible n from first principles for b62 and b64 and compare with the
   measured ones; re-run at least two units per base; check the sampled units are
   representative of the base (they sit at particular leading digits: how do the counts vary
   across the range, and does the base mean follow from the samples as claimed?).
3. **The baseline.** Is "today's main" priced fairly and consistently with what the model
   prices for G2 (base mean against field measurements; the field-to-base-mean ratios 1.34 and
   1.62; which build: main now includes #251, #256, #259, measured at 49.8 s per real base-62
   field on an RTX 3080 at 300 W, `MU260/RELEASE-NUMBERS.md`; instant fields, which cost
   nothing today, are 11–35 % of base 62)? Would a fair baseline move the ratio by more than
   10 %?
4. **The unit costs.** Each GPU unit cost in `RESULTS.md` §3 and §6 against what today's
   kernels actually cost per comparable operation (EXPERIMENTS entries N1.G1, N17.1, N22.1,
   L30.x; `N1/gpu-tile/RESULTS.md` measured a floor of 0.13–0.15 ps per pair for a dense AND and
   found that deep lists die on memory traffic): where is the design optimistic? In
   particular: shared-memory capacity and occupancy for the chunk slices or four-Russians
   tables on an RDNA4 card (LDS-bound at 18.9 KiB per workgroup before this week) and on an RTX
   3080; the cost of sorting and cutting 2.7e16 generated bottoms into chunks on a GPU; the
   host or device cost of the depth-9 parent tree and of streaming tops; anything the model
   leaves out (launch overheads per super-unit at 0.43 ms each; survivor write-out;
   verification). Give your own low / central / high for each cost with reasons, and
   recompute the ratios.
5. **What the server change really is.** `RESULTS.md` §7: is the unit as described
   verifiable, resumable and assignable (claims, partial progress, a second implementation's
   check, clients of different speeds), and is the mid-base switch really exact? What breaks?
6. **The benchmark.** Specify the smallest GPU experiment that would confirm or kill the
   claim: what to build (kernels, inputs from the prototype), what to measure, on which cards
   (an RTX 3080 can be rented; the production card is an AMD RX 9070 XT reachable only in
   short windows), and the numbers at which the project should stop (the author proposes: a
   64-pair word above 20 ps or a bottom above 10 ps).

## Method and limits

CPU only on ivory: two threads at most, `nice -n 19`, single runs under fifteen minutes, keep
4 GB of disk free. Build the prototype in your own copy (`G2/review/`), never in place; write
only under `G2/review/`. No pushes, no pull requests, no subagents, no rented machines, no
contact with the production API or servers.

## Deliver

`G2/REVIEW.md`: the verdict first (the claim stands / stands with a corrected range / does not
stand), then findings by severity with evidence, then your recomputed table, then the
benchmark specification. Hard stop **20:40 UTC** today. Your final message is at most 300 words
for the program's director.
