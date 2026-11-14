# CPU2 brief: fewer top tests in the CPU join by skipping failing runs (2026-11-14)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork = remote `fork`). The project searches
for "nice numbers": n whose square and cube together use every base-b digit exactly once. Read
first: `../README.md` (rails, PR rules); `../N6/RESULTS.md` (yesterday's counting study of the top
certificates: what a top test is, where failures cluster, and the scheme table) with its code on
fork branch `exp/n6-top-counts`; on upstream main (`41b4b405`): the module docs of
`common/src/overlap_join.rs`, `common/src/cpu_join.rs` and `common/src/cpu_top_fd.rs` (the CPU
join and its stepped top certificates); the two most recent CPU PRs the maintainer merged, for
the level of evidence expected: `../L52/PR-RESULTS.md`, `../L56/PR-RESULTS.md` and their bodies.
No GPU and no rented machine is involved.

## Why

In the join, every (top prefix, partition) pair is certified on its own and about two thirds
fail. Yesterday's exact counts show the failures come in long runs along the partition axis
(P(fail | previous fails) ≈ 0.95; 64–70 % of failing pairs sit in runs of 128 or more), and that
a walk which tests a pair, and on a failure skips to the first partition where the failing
digit can change, needs only **0.40–0.43 of today's tests when each prefix is walked on its
own** (the floor for any exact order is 0.36). A GPU cannot run that walk (its lanes are in
lockstep and it loses), but the CPU join walks each prefix on its own already. The CPU join is
what CPU-only clients and CPU allocations run; nobody has measured what its top phase costs
today or what the skip walk would save.

## Task

1. **Where the CPU join's time goes today** at production shapes: b60 1e16, b62 1e17 and b64 1e17
   fields (a sample of slices and partitions large enough that shares are stable to a point or
   two; say how you sampled): the top phase's share, and within it seeding, stepping and
   appending. If the top phase is under 8 % of a field at b62 and b64, stop here and say so.
2. **The skip walk, exactly.** When a pair fails, the certificate knows which certified digit
   repeated. Derive, and prove, the first later partition at which that digit (or the pair of
   digits that collide) can differ, so that every skipped pair is one today's test would also
   fail. `exp/n6-top-counts` has a counting model of several such rules; the production version
   must be exact for every base and field shape the join accepts, must leave the set and order
   of passing tops unchanged (the join's results and its counters must be bit-identical), and
   must work with the finite-difference stepping (a skip is a jump of the state: by a multiply,
   by a re-seed, or by stepping without testing; measure which is cheapest).
3. **Implement it** behind nothing (if it is exact it replaces the loop) on a branch
   `exp/cpu-top-skip` in a worktree `~/projects/nice/.worktrees/cpu-top-skip`; tests: the existing
   CPU join tests and reference comparisons, plus a test that the list of passing tops is
   identical to the unskipped walk's on real fields at b57–b64 and on small bases exhaustively.
4. **Measure** on ivory, one thread, `nice -n 19`, the old binary against the new, interleaved,
   at least five alternations per field (ivory is a shared VM: report the spread, use the
   minimum and the median, and say if the machine was too noisy to conclude): seconds for the
   sampled work at the three shapes, counts identical. The maintainer's bar for a PR is a
   measured ×1.05 for a simple change and up to ×1.10 for a large one, at production shapes.

**Kill criterion:** the top phase is under 8 % of a CPU field (task 1), or the skip walk gains
less than ×1.05 on the whole field at b62 and at b64. Then write up the numbers and stop.

## Deliver

`CPU2/RESULTS.md` (the profile, the skip rule and its proof, the tests, the timing tables with
every alternation, the verdict), scripts and raw outputs under `CPU2/raw/`. If the gain clears
the bar: the branch pushed to the fork as `exp/cpu-top-skip` (plain push of a new branch; never
force-push; no PR), in a state a reviewer could read: one commit on `41b4b405`, formatted,
`cargo clippy -p nice_common --all-targets -- -D warnings` clean under the pinned toolchain
(Rust 1.100.0), no changelog line yet. Mark every number measured, derived or assumed.

## Rules

ivory only: CPU builds without GPU features, `CARGO_TARGET_DIR=~/projects/nice/target`, check
`df -h /` first (about 10 GB free), at most two threads in total under `nice -n 19`, `/tmp` is a
small tmpfs. No Vast machine, no `vast.py`. Never touch the fleet, the server, `~/fleet-run`,
demoux or mayalaran. No PRs, no subagents, no pushes to `wasabipesto/nice`. **Commit locally and
write your results file early and often: an outage yesterday cut agents off mid-run.** Hard stop
**11:00 UTC**; your final message is a short report for the program's director.
