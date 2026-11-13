# Review brief: the fix to PR #251's check kernel (2026-11-13)

You are an independent reviewer. The repository is `~/projects/nice` on this machine (ivory);
upstream is `wasabipesto/nice` (git remote `origin`), the fork `wasabipesto-bot/nice` (remote
`fork`). The project searches for numbers whose square and cube together use every base-b digit
exactly once. **A missed candidate is the worst possible defect here**, and the kernel under
review is the one that decides whether a candidate is a hit.

## What you review

Fork branch `pr/check-d` (the branch of upstream PR #251, which replaces the GPU join's
full-check kernel). An audit found that the PR's kernel handed out its work one GPU subgroup
("plane") at a time on the assumption that every plane is full and has a lane 0: lane 0 took
`PLANE_DIM` entries and lane i checked entry `cur + i`. Vulkan does not guarantee full planes,
so entries could be skipped silently. Commit **`8d11e0be`** (on top of `bc9d87c7`) is the fix:
a new `take_entries` (a ballot form for planes of at most 32 lanes, a scan form for wider
ones), a kernel-side count and index sum of the entries checked, and a host check
(`ensure_checked`) that turns a mismatch into an error. Review **the fix commit**
(`git diff bc9d87c7 8d11e0be`) and whatever of the surrounding kernel and host code you need to
judge it. You were not involved in writing it; take none of its claims on trust. The author's
write-up is `CKF/RESULTS.md` and `CKF/PR-BODY-DELTA.md` in
`~/projects/nice/scratchpad/2026-10-research-program/`, raw logs under `CKF/raw/`; the audit that
found the defect is `T2/SOUNDNESS.md` (gap 2) with `T2/models/plane_models.py`.

## Questions to answer

1. **Is the hand-out complete and non-overlapping by construction** for every population of a
   plane (any subset of lanes active, lane 0 present or not, lanes leaving the loop at
   different times, a plane whose lanes split between two calls), in both forms? Write your own
   model of both forms and try to break it; do not reuse the author's.
2. **Per backend, do the plane operations mean what the fix needs?** Read CubeCL's own sources
   in the cargo registry (`~/.cargo/registry/src/*/cubecl-*`): what `plane_ballot`,
   `plane_shuffle`, `plane_sum`, `plane_exclusive_sum` lower to on CUDA, on WGSL through naga, on
   SPIR-V, on Metal and on HIP; whether inactive lanes are excluded; what a 64-lane plane does to
   the ballot's first word; whether a shuffle from a lane index computed at run time is defined
   on each. The device that does most of the project's work is an AMD card on Vulkan with
   64-lane planes, which takes the **scan form**; that form was not run on such hardware. Say
   exactly what its correctness there rests on.
3. **The host check:** does `ensure_checked` compare the right quantities in every path that
   launches the check (ordinary batches, overflowed batches, partition re-runs, the test modes)?
   Can a wrong run pass it (count right, index sum right mod 2^32, entries wrong)? Is a mismatch
   always an error that prevents a result from being reported, never a retry that could
   succeed by accident or an empty result? Is anything read before the kernel has finished?
4. **Did the fix change anything else?** The check's arithmetic, the gate, the hit path, the
   join kernels: the diff should not touch them.
5. **The tests:** would the regression test fail on the old hand-out (the author says it does on
   CUDA with a 100- or 48-thread group) and do the new tests assert what the write-up says? The
   skip-one-entry test mode: can it leak into a production build?
6. **The write-up against the evidence:** check the speed table and a sample of the exactness
   claims in `CKF/PR-BODY-DELTA.md` against the raw logs; say whether the text is fair about
   what was not run on real hardware (the scan form on 64-lane planes, Metal, HIP), and whether
   it mentions the research program, its directories, agents or a model name (it must not).
7. **Is there the same assumption elsewhere on this branch or on main?** The author points at
   `top_slot` (the top kernel's append, on main): it broadcasts lane 0's group and lets only lane
   0 take the atomic. Say whether you agree it has the same dependence, on which devices it could
   matter, and whether anything else in the kernels depends on lane 0 or on `PLANE_DIM` lanes
   being active. Do not fix it.

## Method and limits

Reading, your own models, and host-side checks: `cargo fmt --all --check`,
`nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings` and the
host tests touching the change, from a worktree `~/projects/nice/.worktrees/review-ckf` (detached at
`8d11e0be`) with `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` so the build is
incremental. ivory has no GPU and no Vulkan driver, about 6.5 GB of disk, and `/tmp` is a small
tmpfs. Do not change the branch, push, open or comment on a PR, start subagents, or touch any
rented machine, the fleet, the server, demoux or mayalaran.

## Deliver

`CKF/REVIEW.md`: the verdict first (the PR can be called ready again as is / after the listed
fixes / not yet), findings by severity with file and line, how you know, and the fix you
suggest; then what you verified and how; then what could not be verified without hardware. Your
final message is a short summary for the program's director.
