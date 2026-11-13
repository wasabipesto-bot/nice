# N6 brief: can the join test fewer top certificates? A counting study (2026-11-13)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork = remote `fork`). The project searches
for "nice numbers": n whose square and cube together use every base-b digit exactly once. Read
first: `../README.md` (rails), the module docs of `common/src/overlap_join.rs` (the method:
tops, bottoms, partitions, the field certificate, `Base::cert`), `common/src/cpu_join.rs` and
`common/src/cpu_top_fd.rs` (the CPU join and its stepped top certificates), the docs of
`top_kernel` and `top_fd_kernel` in `common/src/cubecl_join.rs`, `../../2026-11-fresh-eyes/NOTES.md`
section 3 (an operation model of the join) and `../N1/cpu/RESULTS.md` section 3 (measured counts
per field). No GPU is needed for this task and none is provided.

## Why

Certifying tops is about a fifth of a field on every card measured (RTX 3080: 23 % at b62 1e17,
18 % at b60 1e16; RX 9070 XT: 22 % and 19 %), the same on AMD and NVIDIA per test (0.15 ns with
the finite-difference kernel). A b62 1e17 field tests about 9e10 (top prefix, partition) pairs
and about two thirds of them fail. Every (prefix, partition) pair is tested on its own, one
finite-difference step from its neighbour. Nobody has asked whether the tests could be
organised so that most failing pairs are never visited: a certificate for a whole group of
pairs at once (all partitions of a prefix that share leading digits of the partition value, all
prefixes that share a parent, an interval of n whose squares and cubes share more leading digits
than the pair's own), a cheap first-stage test on fewer digits, or an order of enumeration in
which a failure skips ahead. Halving this phase would be about ×1.1 on every device at every
base; a factor of five would be ×1.2.

## Task

1. **Describe exactly what a top test is today** and what it costs: what interval of n a
   (prefix, partition) pair stands for, which digits of n² and n³ the certificate fixes, what
   makes a pair fail (a repeated digit among the certified ones, which powers and positions),
   how the finite-difference step moves between pairs and what it must recompute, and what the
   field certificate already removes before any top is tested.
2. **Count on real fields with the CPU code** (ivory, `nice -n 19`, at most two threads;
   production-shaped fields at b60 1e16, b62 1e17 and b64 1e17, a sample of slices and
   partitions large enough that the counts are stable to a few percent: say how you sampled):
   tests done, tests passed, and for the failures, **where they fail**: at how many certified
   digits, in which power, and how failures cluster along each axis (consecutive partitions of
   one prefix, sibling prefixes of one partition, the partition value's leading digits).
3. **Evaluate grouping schemes by counting, not by argument:** for each candidate (yours and the
   ones named above), the number of tests it would do in total (group tests plus the remaining
   individual ones), exactly, on the same sample, and a cost estimate that prices a group test
   honestly (what it has to compute). A scheme must be exact: it may never reject a pair that
   today's test passes. Say how each scheme interacts with the stepped kernel (does it keep the
   one-add step, does it need a second kernel pass, what it does to the order in which passing
   tops reach the join).
4. **Recommend:** a GPU prototype (which scheme, what gain on a field, what it would take), or
   a closed question with the counts that close it.

## Deliver

`N6/RESULTS.md` (the description, the count tables per base, each scheme's totals and cost
estimate, the recommendation), scripts and raw outputs under `N6/raw/`. If you need
instrumentation in the Rust code, put it on a local branch in a worktree
`~/projects/nice/.worktrees/n6-top-counts` (experiment-only; push it to the fork as
`exp/n6-top-counts` if it is worth keeping; never force-push). Mark every number measured,
derived or assumed.

**Kill criterion:** if no exact scheme removes at least 40 % of the top-test work net of its own
cost at b62 and at b64, say so and stop.

## Rules

ivory only: CPU builds without GPU features (`cargo build --release -p nice_common` style; check
`df -h /` first, about 7 GB free; set `CARGO_TARGET_DIR=~/projects/nice/target` so builds are
incremental; `/tmp` is a small tmpfs); keep CPU use to two threads under `nice -n 19`. No Vast
machine, no `vast.py`. Never touch the fleet, the server, `~/fleet-run`, demoux or mayalaran. No
PRs, no subagents, no pushes to `wasabipesto/nice`. Hard stop **12:00 UTC**; your final message
is a short report for the program's director.
