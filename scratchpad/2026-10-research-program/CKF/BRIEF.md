# CKF brief: make the new check kernel complete on partly filled subgroups (2026-11-13)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules); `../T2/SOUNDNESS.md` (today's audit: its gap 2 is
this task, gap 5 and the "every listed survivor was checked" remark are related) with
`../T2/models/plane_models.py`; on fork branch **`pr/check-d`** (head `bc9d87c7`, the branch of
the open upstream PR #251): `check_kernel` in `common/src/cubecl_join.rs`, `common/src/join_check.rs`,
the host code that launches the check and reads its counters, and the check's device tests
(`CHECK_COUNT`, `CHECK_PROBE`, `assert_counts`, `assert_probe`); `../L53/RESULTS.md` or the PR's
own body (`gh pr view 251 --repo wasabipesto/nice`) for what the kernel does and how it was
measured.

## The defect

PR #251 replaces the GPU join's full-check kernel. Its new kernel hands out work one subgroup
("plane") at a time: lane 0 does `ran[STAGES].fetch_add(PLANE_DIM)`, the value is broadcast, and
lane i checks list entry `cur + i`. That covers every entry only if each plane has exactly
`PLANE_DIM` active lanes and has a lane 0. CUDA and Metal guarantee full planes when the group
size is a multiple of the plane size; **Vulkan does not** unless the pipeline asks for full
subgroups, and wgpu does not ask. On a device that runs a partly filled plane, the missing lanes'
entries are never checked, the counter ends at the same value, and the host sees nothing: a
silent loss of candidates in the one kernel that decides whether a number is nice. The audit's
model: 31 of 32 active lanes leaves 3,125 of 100,000 entries unchecked. No measured device is
known to be affected, and the PR must not rely on that. The PR is open upstream; the maintainer
has been asked not to merge it until this is fixed.

## Task

1. **Reproduce it on a real device first.** On CUDA a block whose thread count is not a multiple
   of 32 has a partly filled warp. Launch the check kernel of `bc9d87c7` in its count or probe
   mode with such a group size (a test-only launch; 48 or 100 threads) and show which entries
   are skipped. Do the same on lavapipe if its planes allow it. This run is the regression test
   for the fix: it must fail before and pass after.
2. **Fix the hand-out so it is complete by construction** for any number of active lanes in a
   plane, with or without a lane 0: for example each lane's rank among the plane's active lanes
   (`plane_exclusive_sum` of 1), the plane's active width (`plane_sum` of 1) as the amount the
   leader takes, and a broadcast that does not depend on lane 0 existing. Use only plane
   operations the kernels already rely on elsewhere, or justify a new one for every backend
   (CUDA, WGSL through naga, SPIR-V, Metal, and HIP if the code supports it: check what a
   64-lane plane does to each operation you use; see the audit's gap 5 on ballots).
3. **Make the host able to see an incomplete check:** the kernel counts the list entries it
   actually checked, and the host compares that with the number of entries it listed, for every
   check launch, in every mode. A mismatch must be loud: handled like a dispatch that did not
   run (the existing `ensure_ran` / refit path) or an error, never an empty result. Say what
   happens on a mismatch and test it (a test hook that makes the kernel skip an entry is fine).
4. **Exactness:** the check's device tests in count and probe modes at every shape they cover,
   with full groups and with the partly filled group of step 1, on CUDA and on lavapipe with
   both compilers (`--features gpu,cubecl` and `--features gpu,cubecl-spirv`); the join's full
   device suites; the dense compare against the CPU join on CUDA at b60 1e16, b62 1e17 and b64
   1e17; host tests, `cargo fmt --all --check`, clippy with `-D warnings` as CI runs it.
5. **Speed on CUDA:** the fixed head against `bc9d87c7` and against upstream main `a7a59c11`,
   same box, interleaved, at least three rounds, b62 1e17, b60 1e16, b64 1e17 (starts in
   `../N16/raw/scripts/env.sh`); counts identical; clock, power and the join kernel's register
   variant per run; cool card before each timed run; no builds while timing. The fix must not
   cost more than 2 % of a field against `bc9d87c7`; say what it costs.
6. **Deliver the fix as new commits on `pr/check-d`** (plain pushes to the fork; the branch is an
   open PR, so every pushed commit must build, pass the host tests and be formatted) and a
   replacement for the PR body's soundness and measurement sections in `CKF/PR-BODY-DELTA.md`
   (what changed, why, the new numbers; no mention of the research program, its directories,
   agents or model names).

## Deliver

`CKF/RESULTS.md` (the reproduction with its numbers, the fix and why it is complete for any plane
population on every backend, the host check and what a mismatch does, every exactness run, the
speed tables with rounds, clock and power), `CKF/PR-BODY-DELTA.md`, raw logs and scripts under
`CKF/raw/`, and the commits on `pr/check-d`. Mark every number measured, derived or assumed.

## The box and the rules

The instance id comes in the message that carries this brief; `python3 vast.py ssh <id>` (from
the program directory) prints the ssh command; wait for `/root/READY` (`/root/FAILED`: clone the
fork yourself). One `CARGO_TARGET_DIR` per tree. Never `vast.py create` or `destroy`. ivory
writes only under `CKF/` and a worktree `~/projects/nice/.worktrees/ckf-check-d`; no GPU builds on
ivory (7 GB free; `/tmp` is a small tmpfs). Push only to the fork branch `pr/check-d`, only as
new commits (fast-forward); **never force-push, never delete a branch; if a push is refused,
report it and do not ask anyone to do it for you**. Never push to `wasabipesto/nice`; do not
comment on, edit or change the state of any pull request; no subagents. Never touch the fleet,
the server, `~/fleet-run`, demoux or mayalaran. Copy results to ivory as you go. Hard stop
**11:45 UTC**; your final message is a short report for the program's director.
