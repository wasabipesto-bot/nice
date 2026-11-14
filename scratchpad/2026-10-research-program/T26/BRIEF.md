# T2.6 brief: the top kernels' append without a lane-0 assumption, then an integration check of the open PRs (2026-11-14)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules); `../T2/SOUNDNESS.md` (yesterday's audit, gaps 2 and
5); `../CKF/RESULTS.md`, `../CKF/REVIEW.md` and the fix itself (`git diff bc9d87c7 1f41d649` on fork
`pr/check-d`: `take_entries`, `ensure_checked`, the partly-filled-plane tests): that work is the
model for this task; on upstream main (`41b4b405`): `top_slot`, `top_kernel`, `top_fd_kernel` and
the host code that reads `grp_cnt` and the top records in `common/src/cubecl_join.rs`.

## Task 1 (the must-have): `top_slot` complete on any plane

`top_slot` appends a plane's kept tops into their group's segment. It broadcasts **lane 0's**
group (`plane_broadcast(g, 0)`), lets **only lane 0** take the atomic (`UNIT_POS_PLANE == 0`), and
broadcasts lane 0's result. Its doc says "every lane of the plane must call it" and "lane 0 holds
the plane's lowest prefix index". On a plane that has no active lane 0 (Vulkan does not promise
full subgroups; wgpu does not request them), no lane takes the atomic and the kept tops are
written at offsets that other planes also use: tops overwritten, candidates lost, and nothing on
the host counts that stage. No device in production is known to run such planes (256-thread
groups are full on CUDA, Metal and RADV), which is why this is a robustness fix, not an incident.
Yesterday's fix of the same assumption in PR #251's check kernel is the pattern.

1. **Reproduce on a real device**, as CKF did for the check kernel: a CUDA block whose thread
   count is not a multiple of 32 has a partly filled warp, and a test can also make lane 0's
   prefix dead or absent. Find the smallest test-only launch of the top kernel(s) in which the
   current `top_slot` writes a wrong record index or loses a top, and say exactly what goes
   wrong (and whether CubeCL's CUDA lane arithmetic, `AbsolutePos % PLANE_DIM`, limits what a
   CUDA test can show: CKF found it does for more than one cube). If it cannot be shown on any
   device available, show it with a host model of the kernel's logic and say so plainly.
2. **Fix it by construction:** the group tested, the lane that takes the atomic and the value
   broadcast must come from the lanes that actually run the call (the lowest active lane as
   leader; a ballot where planes are at most 32 lanes, the scans otherwise), never from lane 0 or
   `PLANE_DIM`. Keep the "almost always one atomic per plane" property; say what happens when a
   plane straddles groups. Argue completeness for every plane population on every backend the
   code supports (read CubeCL's sources for what each plane operation does with inactive lanes).
3. **Make the stage verifiable by the host if that is cheap:** for example the number of tops
   appended per batch against the sum of `grp_cnt`, or records written against records read by
   the join. If a real check costs more than about 1 % of a field or needs a redesign, say what
   it would take and stop there.
4. **Exactness and cost:** the partly-filled-plane regression test (fails before, passes after)
   on CUDA and on lavapipe with both compilers; the join's full device suites; dense compares
   against the CPU join at b60 1e16, b62 1e17 and b64 1e17 on CUDA; host tests, fmt, clippy with
   `-D warnings` under the pinned toolchain (Rust 1.100.0). Speed: the fix against main, same
   box, interleaved, three rounds, b62 1e17 and b64 1e17, card cool before each run, no builds
   while timing; it should cost under 1 % of a field. State whether the generated kernels of
   everything except the top kernels are identical to main's.
5. **Deliver** a branch `pr/top-slot-any-plane` on the fork: one commit on upstream main
   `41b4b405` with a one-line changelog entry ending in the placeholder
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`, and a PR body `T26/PR-BODY.md` of at
   most 700 words plus tables (what, why, soundness, exactness, cost, not in this PR; no mention
   of the research program, its directories, agents or model names; ending with the line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`). No PR is opened by you.

## Task 2 (after task 1; correctness only, no timing): the four open PR branches together

Four PRs are open against main and will be merged one after another by the maintainer:
`pr/check-d` (#251, head `1f41d649`), `pr/join-prefilter-shift-pow2` (#255, `42d2afd9`),
`pr/join-survivor-stage-512` (#256, `0f6794a2`), `pr/join-prefilter-popcount-spirv` (#259,
`3b773708`). Each was tested alone. Build an integration branch **`exp/integration-1114`** on the
fork: main with all four merged (the changelog conflicts are trivial; #255 and #259 both touch
`walk_pf_lean`: keep #255's shift form for the digits and #259's population count for the test),
plus your task-1 commit on top as a second variant. On each variant: fmt, clippy, host tests;
the CUDA device suite; lavapipe with both compilers; dense compares against the CPU join at b60
1e16, b62 1e17 and b64 1e17 on CUDA. Report any failure with the smallest reproduction, and
record how you resolved each conflict (the director will use the same resolutions when the PRs
land). If time remains, one timing round of the integration build against main at b62 1e17 and
b64 1e17 on CUDA, for the record.

## Deliver

`T26/RESULTS.md` (the reproduction or model, the fix and its completeness argument, the host
check or why not, every exactness run, the cost table with rounds, clock and power; task 2's
outcome and conflict resolutions), `T26/PR-BODY.md`, raw logs and scripts under `T26/raw/`. Mark
every number measured, derived or assumed.

## The box and the rules

The instance id comes in the message that carries this brief; `python3 vast.py ssh <id>` (from
the program directory) prints the ssh command; wait for `/root/READY` (`/root/FAILED`: clone the
fork yourself). One `CARGO_TARGET_DIR` per tree. Never `vast.py create` or `destroy`. ivory
writes only under `T26/` and a worktree `~/projects/nice/.worktrees/t26-top-slot`; no GPU builds on
ivory (`/tmp` is a small tmpfs). Push only to the fork, only new branch names and new commits on
them; **never force-push, never delete a branch; if a push is refused, report it and do not ask
anyone to do it for you**. Never push to `wasabipesto/nice`; do not open, comment on or edit any
pull request; no subagents. Never touch the fleet, the server, `~/fleet-run`, demoux or
mayalaran. **Commit locally and copy results to ivory early and often: an outage yesterday cut
agents off mid-run.** Hard stop **10:30 UTC**; your final message is a short report for the
program's director.
