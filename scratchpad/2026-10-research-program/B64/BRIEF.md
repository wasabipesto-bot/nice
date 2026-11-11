# B64 brief: the first profile of a base-64 field, and the walk's per-pair floor (2026-11-11)

You are an engineer on the nice research program (repo `~/projects/nice`, upstream
`wasabipesto/nice`, fork `wasabipesto-bot/nice`). Read first: the module docs at the top of
`common/src/overlap_join.rs` and `common/src/cubecl_join.rs`; `../L51/RESULTS.md` (the last
full-stack profile, at b62 and b60, and how it was taken: profile timers, ablations, the
register-variant caveat); `../N1/gpu-tile/RESULTS.md` §1 and §3 (yesterday's calibration and the
walk fit); `../N1/cpu/RESULTS.md` §3 (measured counts per admissible n, base means, empty fields).

## Why base 64

The search is at b60; b62 is next (≈ $250–380 of GPU time at today's speed) and then b64
(≈ $3.5K), so **b64 is about 90 % of the cost that is still reachable**. Every profile, retune
and A/B so far was taken at b62 or b60, with b64 as a side column. Known about b64 and nothing
more: range [2^75, 2^76), L = 13, 8 roots of 63 (12.7 % of n admissible, against 3.3 % at b62);
the FD top kernel is off at power-of-two bases; about 4 in 10 fields of 1e16 are empty (their
field certificate fails); per admissible n the CPU join does ≈ 3.5e-3 AND pairs, 1.5e-4 AND
survivors and 9.6e-6 full checks on a base mean. b64 is not on the server yet, so its field
size (1e16 or 1e17) is still open.

## Task A: profile b64 and write its roadmap

Box: instance **60171046** (`nice-research-b64-profile`, RTX 3080, 7 h TTL from ~05:50 UTC).
From `~/projects/nice/scratchpad/2026-10-research-program`: `python3 vast.py ssh 60171046`
prints the ssh command; wait for `/root/READY`. `/root/nice` is a clone of the fork with remote
`upstream` fetched. Trees: **today's main** `upstream/main` (c0c357a) and **the open stack**
fork `pr/check-d` (a97e3d7 = main + #250 + #251; #250 does nothing at b64, #251 replaces the
check kernel). L51's profile and ablation switches live on fork `exp/l51-profile` (14f87cd,
whose `join_kernel` is byte-identical to main's); port what you need onto the trees you time, on
a branch `exp/b64-profile` (fork only). Backend cubecl-cuda, `--features gpu,cubecl-cuda`.
Record the card's power cap and clock, and each process's join-kernel register variant (or
alternate configurations inside one process), as L51 and L53 did.

1. **Fields.** b64 production-shaped fields of 1e16 and of 1e17 at ≥ 10 locations spread over
   the base (the same relative positions for both sizes, e.g. 0.05, 0.15, …, 0.95 of the
   range), including the empty ones. For each: is it empty, slices, partitions per launch,
   AND pairs, AND survivors, prefilter survivors, full checks, seconds. From these the **base
   mean of seconds per admissible n** at each field size, on main and on the stack, and the
   same for b62 1e17 at the same relative positions for comparison (yesterday's single mid-base
   b62 field cost 61.9 s on a 340 W card and is known to be 22 % dearer than the base mean).
2. **Shares** on two or three representative non-empty b64 fields per size: top certificates
   (which kernel runs at a power-of-two base, what one top test costs, why the FD kernel is off
   there and whether stepping the tops in binary would be possible), slice setup and the host
   side, bucket/bottoms, join base, AND, walk, prefilter, stage, check, everything else. Per-
   operation costs (ps per pair, ps per survivor, ns per check, ns per top test) next to b62's.
3. **Field size.** Cost per number at 1e16 against 1e17 including empties and every fixed cost,
   on main and on the stack: which size should b64 be inserted at, and by how much does it
   matter?
4. **Constants at b64.** L51 found no retune ≥ 3 % at b62/b60 and did not try b64. Sweep, at
   b64 only: entries per thread, `TRANSPOSE_MIN`, the AND group, `TOP_CAP`, partitions per launch
   / slots, the survivor-list bounds if they bind. Three interleaved rounds for anything that
   moves ≥ 3 %. With 8 roots a top probes 8 buckets instead of 2: check whether the bucket and
   wave logic was tuned around 2.
5. **What is specific to b = 2^6.** Digit extraction is a shift; anything in the kernels that
   still pays for general-base arithmetic at b64 (magic multiplies, corrections, tables)?
6. **Roadmap.** A ranked list of b64 levers, each with: estimated gain per b64 field (and per
   b62 field if it applies there), how it was estimated (measured ablation / instruction count /
   guess), size of the change (simple: constants or a few lines; medium; very large), and what
   would kill it. The program's PR bar is a measured ×1.05 for a simple change up to ×1.10 for a
   very large one, one discrete change per PR, exact counts, no NiceMark scenario below ×0.98.

## Task B (after A, if ≥ 1.5 h of box time remains): the walk's per-pair floor

Yesterday's fit of the survivor path on this kernel: **0.13–0.15 ps per pair regardless of
survivors, + 14 ps × pass rate** (`../N1/gpu-tile/RESULTS.md` §3). At b62 1e17 the floor is
≈ 6 % of a field. Find out what it consists of (ballots, the `plane_any` loop entry per entry
slot and chunk, barriers, anything per chunk that does not depend on survivors) from the SASS
and by ablation, and whether a small change removes a useful part of it at today's shape
without touching the result. If a variant looks worth ≥ ×1.03, A/B it: 3 interleaved rounds at
b62 1e17, b60 1e16 and b64 (your field size from A), counts exact; NiceMark 4 rounds if it
reaches ×1.05. Do not prepare a PR; report the numbers and the diff's size.

## Deliver

`B64/RESULTS.md` in this directory: the base-mean table, the shares, the field-size answer, the
retune table, the roadmap, and Task B's findings; raw logs and scripts under `B64/raw/`. Mark
every number measured, derived or assumed. Counts must be exact against the CPU join on at
least one field per size (`NICE_TEST_JOIN_COMPARE`-style, as earlier work did).

## Rules

Vast only through the instance above: never `vast.py create` or `destroy` (the director
destroys the box; copy results back to ivory as you go). ivory writes only under `B64/` and a
worktree `~/projects/nice/.worktrees/b64-profile` if you need one; no GPU builds on ivory
(9.4 GB free). Push only to the fork; never to `wasabipesto/nice`; no PRs; no subagents. Never
touch the fleet, the server, `~/fleet-run`, demoux or mayalaran. Hard stop 12:15 UTC: write up
what you have.
