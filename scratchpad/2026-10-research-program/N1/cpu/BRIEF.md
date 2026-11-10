# N1 CPU brief: the join at the transversal shape on the CPU, exact counts and a measured ratio (2026-11-10)

You are an engineer on the nice research program (repo `~/projects/nice`, upstream
`wasabipesto/nice`, fork `wasabipesto-bot/nice`). Read first:
`~/projects/nice/scratchpad/2026-11-fresh-eyes/NOTES.md` (§3) and `mc_counts.py` next to it, the
module docs of `common/src/overlap_join.rs` and `common/src/cpu_join.rs` on upstream main
(c0c357a), and `../../L50/ROADMAP.md` (where the CPU join's time goes today).

## The idea being tested

The join runs at one shape: t = L − 3 top digits (blocks of b^3 numbers, f0 = 3), k = 6 bottom
digits, p = 2 partition digits, on fields that are ranges of 1e16–1e17 numbers. A contiguous
field has to rebuild every k-digit bottom, which is why k is stuck at 6. If the "field" is a
base's **whole range** and the work unit is **one partition value** (all n of the base whose
digits at positions f0 .. f0+p−1 equal it), every list entry is built once per base and deeper
bottoms become affordable. The target shape is **(t, k, p) = (L − 4, 9, 5)**: f0 = 4, overlap
o = t + k − L = 5 = p (no key level), 62^5 partition values at b62, per value ≈ 7e5 top-layer
prefixes and 62^4 bottom candidates. The reference `overlap_join::join_range` takes any
(t, k, p), so soundness is inherited: this is the same join with other parameters and a
non-contiguous unit of work. What is unknown is what it costs.

My Monte Carlo (`mc_counts.py`, simplified certificate) predicts per admissible n at b62
(admissible = n in a root class of the residue filter; 3.13e20 per base): today (f0 3, k 6):
P_T 0.070, P_B 0.305, AND survivors 2.0e-4; new (f0 4, k 9): P_T 0.127, P_B 0.061, pairs 8.0e-3
with no field prune, AND survivors 2.7e-5 (noisy: 8 events). b60 and b64 are in `mc_b60.txt`,
`mc_b64.txt`.

## Tasks

Worktree `~/projects/nice/.worktrees/n1-transversal-cpu`, branch `exp/n1-transversal-cpu` from
`origin/main` (c0c357a), pushed to the fork only.

1. **Make the CPU side run the shape.** `overlap_join` (FieldSetup, the reference `join_range`)
   and `cpu_join::CpuJoin` at (L − 4, 9, 5) with the range = the base's whole valid range
   (`base_range`), for chosen partition values. Known obstacles: `JoinParams::for_length` is
   fixed (add an explicit constructor or an env override, experiment-only); a 9-digit residue's
   cube is past u128 (use the 256-bit `W4`, or arithmetic mod b^(k+mid)); u32 casts of
   `b^(k+2−f0)` terms in the prefilter (`pc`, `pk`, `dm`); the key-level code path assumes
   o − p = 1 in places; `TopFdSetup` step sizes; `CPU_SLICE_PREFIXES` (7e5 prefixes is under it).
   Keep today's shape bit-for-bit unchanged (its tests must still pass).
2. **Exactness.** (a) The existing test windows and `check_partitions` still pass. (b) New: at
   small bases where brute force over the whole base is cheap (b ≤ 30, and b 35/40 through the
   reference), run *whole-base* units at an analogous shape (largest k and p that the digit
   length allows, f0 ≥ 2) for every partition value and compare the union of hits and the
   per-unit AND-survivor and prefilter-survivor sets with (i) the reference `join_range` at the
   same shape and (ii) the reference at today's kind of shape over the same n, and at b10 find
   69. (c) At b50 or b54, for 20 random partition values of the new shape, the fast CPU join's
   survivors and prefilter survivors equal the reference's lists exactly.
3. **Counts** at b60, b62, b64 for ≥ 24 random partition values of the new shape and ≥ 24
   partitions of a mid-base production field (1e16 at b60/b64, 1e17 at b62) at today's shape:
   top tests and certified tops, bottom candidates and valid bottoms, AND pairs, AND survivors,
   prefilter survivors, full checks, each per admissible n. Compare with the Monte Carlo above
   and flag anything more than 30 % off (the Monte Carlo has no closure rule, no d/d+1 domain,
   and no field prune).
4. **Timing** on ivory (4 shared cores; `nice -n 19`; one thread; interleave the two shapes,
   ≥ 3 rounds, report medians and spread): CPU seconds per admissible n at today's shape
   (production field partitions) and at the new shape (partition values), with a phase breakdown
   (tops, bottoms, scan/AND, prefilter, check) for each. Also (f0 3, k 9, p 6) and (f0 4, k 8,
   p 4) if they come cheaply. The headline is the ratio new/today per admissible n at b62 and b60.
5. If time remains: what the bottom build costs per partition value and how much of it a
   two-level build (valid low-f0-digit residues once per base, extended by the partition digits
   with affine updates) removes.

## Deliver

`N1/cpu/RESULTS.md` in this directory: what had to change (with the diff's size), exactness
evidence, the counts table against the Monte Carlo, the timing table with the ratio and its
spread, and what you think the model in NOTES §3 gets wrong. Raw output under `N1/cpu/raw/`.
State each number's provenance. The decision the director takes from it: the redesign needs
≥ ×3 per base on GPUs; your CPU ratio is supporting evidence and the counts are the inputs to
the GPU projection.

## Rules

ivory is shared and nearly full: `df -h /` before building (9.5 GB free), build only what you
need (`-p nice_common`, no GPU features), keep your target dir under 3 GB and `cargo clean` it
when you are done; `/tmp` is a 3.8 GB tmpfs. CPU work under `nice -n 19`. Same-version worktrees
can share cargo artifact slots: `cargo clean -p nice_common` before a build whose result you
compare, and check binaries by a label string. Writes only under `N1/cpu/` and your worktree.
Never push to `wasabipesto/nice`; no PRs; no subagents; no Vast; never touch the fleet, the
server, `~/fleet-run`, demoux or mayalaran. Hard stop 11:30 UTC: write up what you have.
