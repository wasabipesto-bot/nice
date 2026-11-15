# N22 brief: the next gain for the RX 9070 XT at bases 62 and 64, found without the card (2026-11-15)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules, "Where the search runs", the note that demoux's GPU
clock follows load); `../EXPERIMENTS.md` entries **N17.1** (the only trustworthy profile of the
join on the RX 9070 XT: prefilter 25.9 % of a base-62 field and 30.4 % at base 64, check 16.3 /
17.5 %, AND 11.1 / 10.5 %, walk 6.1 / 8.0 %), **N21.1–N21.3** (how the last gain there was found
offline: ACO instruction counts for RDNA4 from an offline RADV compile, then confirmed on the
card: −10 of 52 instructions per walk round → ×1.037 at base 62, ×1.080 at base 64), N19, N20,
N14, N16.1; `../N21/RESULTS.md` and `../N21/raw/scripts` (the offline ACO method and its
scripts); `../B64/RESULTS.md` §6 (ranked base-64 levers); `../T26B/REVIEW2.md` "The defect, exactly"
(a compiler rule every new kernel must respect: with CubeCL's SPIR-V compiler, only the first of
several atomic stores of one value in a basic block survives).

## Why

About 86 % of the nice-only search now runs on one AMD RX 9070 XT (RADV, `wgpu<spirv>`, 64-lane
planes), base 62 started today and takes five to six weeks at today's speed, and base 64 is
about 7.8 times base 62. CUDA timings do not predict that card. Five kernel PRs are open and
unmerged; together they are the base you work from: fork branch **`exp/integration-1114`**
(`8bcee21` = upstream main `41b4b40` + #251 check in base-b² limbs + #255 shift digits at base
64 + #256 a 512-entry survivor stage + #259 the population-count prefilter test + #260's top
append fix; upstream main has since gained only a CI change). The card itself is not available
to you. What can be had without it: the instruction stream ACO generates for it, the kernel's
LDS footprint and occupancy, and exactness and no-regression runs on CUDA and lavapipe.

## Task

1. **Where a field's time goes on the card after the five PRs** [derived]: from N17.1's shares
   and each PR's measured gain there, the expected share of each part (top certificates,
   bucket, AND, walk, prefilter, stage and flush, check, per-batch host work) at base 62 1e17
   and base 64 1e17. Say what is measured and what is inferred.
2. **ACO instruction counts on the integration build** for every loop that carries ≥ 5 % of a
   field by task 1 (the walk and prefilter round, the AND, the check kernel's inner loops, the
   FD top kernel's step and certificate, the stage flush): instructions per iteration by kind
   (multiplies, shifts, loads from LDS, branches), the kernel's LDS bytes and the waves per SIMD
   that follow, anything ACO does badly there (64-bit emulation, multiply-high sequences,
   selects that became branches, loads it could not hoist). Use N21's method and scripts;
   record the Mesa version (and note that CI now runs Mesa 26.0.8: build that one if the
   method allows, an Ubuntu 26.04 chroot on the box works, see `../T26B/raw/ci/chroot_setup*.sh`).
3. **Candidates**: exact rewrites that remove instructions or LDS where it counts, each with a
   proof or an exhaustive check of exactness, behind a switch on a branch `exp/n22-rdna4` (new
   branch on the fork, based on `exp/integration-1114`; plain pushes). For each: instructions
   saved per iteration by ACO's count, the predicted gain on the card at base 62 and base 64
   (saved share × part's share, with the N21 calibration: 10 of 52 instructions in a 26–30 %
   part gave ×1.037–1.080), and the CUDA cost or gain: same box, interleaved with the base
   build, three rounds at base 62 1e17 and base 64 1e17 (production-shaped fields: the starts in
   `../N16/raw/scripts/env.sh`), card cool before each run, no builds while timing, power cap
   and clock per run. Exactness for every candidate you keep: dense compares against the CPU
   join on CUDA at both bases, the join's device suites on CUDA and on lavapipe with both
   compilers (**on Mesa 26.0.8 as CI runs it**), counts identical in every timed run.
   Known under-bar items to leave alone unless you find a reason they combine into one
   discrete change: `exp/n21-ffs-pop` (+1–2 %), the denser plan for wgpu devices (N14).
4. **A window plan** for the two or three best candidates: the exact runs to make on the card
   in at most 30 minutes (binaries, fields, rounds, the doubling method of N17.1 where a
   part's cost is needed, the clock and power checks that reject off-point runs), written so
   the director can execute it from `../N21/raw/scripts/window13/go13.sh` as a template.

**Kill criterion:** if no candidate is predicted at ×1.04 or more on the card at base 62 or at
base 64 (the bar for a PR is a measured ×1.05 for a simple change), stop after task 2, write up
the instruction tables and why nothing clears it, and say what the next lever would have to be.

## Rules

Your box is Vast instance **60746198** (RTX 3080, 24 threads; `python3 vast.py ssh 60746198` from
the program directory; `/root/READY` is there; it destroys itself at about 11:40 UTC). Never
`vast.py create` or `destroy`. One `CARGO_TARGET_DIR` per tree. ivory: writes only under `N22/`
and a worktree `~/projects/nice/.worktrees/n22-rdna4`; `nice -n 19`; keep 5 GB free; no GPU or
release builds on ivory; lint with `just lint` (CI's recipe), nothing narrower. Push only to the
fork, only the new branch name `exp/n22-rdna4` (and further new names if needed); never
force-push, never delete a branch; if a push or any action is refused, report it and do not
work around it. Never push to `wasabipesto/nice`; no PR actions; no subagents. Never touch the
fleet, the server, `~/fleet-run`, demoux or mayalaran. No contact with the production API from
the box (if you run NiceMark, point its API address at a closed local port). Copy results to
ivory early and often.

## Deliver

`N22/RESULTS.md` (the verdict against the kill criterion first; the share table; the
instruction tables; each candidate with exactness, ACO counts, predicted gain, CUDA table),
`N22/WINDOW-PLAN.md` if any candidate survives, raw data and scripts under `N22/raw/`. Mark
every number measured, derived or assumed. Hard stop **11:15 UTC**. Your final message is a
short report for the program's director.
