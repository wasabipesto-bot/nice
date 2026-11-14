# Review brief: the FD top kernel's append without a lane-0 assumption (2026-11-14)

You are an independent reviewer. The repository is `~/projects/nice` on this machine (ivory);
upstream is `wasabipesto/nice` (git remote `origin`), the fork `wasabipesto-bot/nice` (remote
`fork`). The project searches for numbers whose square and cube together use every base-b digit
exactly once. **A missed candidate is the worst possible defect here.** The kernel under review
decides which "tops" the join ever sees: a top that is not appended, or is written over, is a
set of candidates never examined. You were not involved in writing the change; take none of its
claims on trust.

## The branch

Fork branch **`pr/top-slot-any-plane`**, one commit `f9a25017` on upstream main `41b4b405`
(`git -C ~/projects/nice fetch fork pr/top-slot-any-plane && git -C ~/projects/nice fetch origin
main`). On main, `top_slot` (the append used by `top_fd_kernel` in `common/src/cubecl_join.rs`)
broadcasts lane 0's group and lets only lane 0 take the atomic that reserves the plane's
records; on a GPU subgroup ("plane") without an active lane 0, which Vulkan allows, no lane
reserves and kept tops are written over other records. The commit claims to: (1) choose the
leader, the group tested and the broadcast value from the lanes that actually run the call (the
lowest kept lane; a ballot form for planes of at most 32 lanes, a scan form for wider ones);
(2) add a per-batch account (tops written minus records reserved, and the same for record
indices mod 2^32) that the host checks after every batch (`ensure_appended` / `top_complete`),
failing the field on a mismatch; (3) add tests, including a test-only mode that takes lane 0
out. The author's write-up: `T26/RESULTS.md` and `T26/PR-BODY.md` in
`~/projects/nice/scratchpad/2026-10-research-program/`, raw logs, the reproduction and a host
model under `T26/raw/`. The same class of fix was reviewed yesterday for another kernel:
`CKF/REVIEW.md` (read it for what was already established about CubeCL's plane operations per
backend, then verify what you rely on).

## Questions to answer

1. **Is the append complete and non-overlapping by construction** for every population of a
   plane (any subset of lanes active, any subset kept, lane 0 present or not, nothing kept, kept
   tops of one group or straddling several) in both forms? Each kept top must get a distinct
   record inside its own group's reserved range, and `grp_cnt` must end at the number of tops
   written per group. Write your own model of both forms and try to break it; compare with
   main's behaviour on full planes, where the results (which record each top gets) need not be
   identical but the set of tops per group must be.
2. **Did behaviour change on full planes in a way that matters?** On main the group tested was
   lane 0's "kept or not"; now it is the lowest kept lane's. Does anything downstream (the
   join's reading of the records, the order of tops within a group, the counters in telemetry,
   determinism of results) depend on the old choice?
3. **Per backend:** what `plane_ballot`, `plane_shuffle`, `plane_sum`, `plane_exclusive_sum`,
   `plane_all` do with inactive lanes on CUDA, WGSL through naga, SPIR-V, Metal and HIP (CubeCL
   sources in `~/.cargo/registry/src/*/cubecl-*`); the device that does most of the project's
   work has 64-lane planes and takes the scan form. Say what correctness there rests on, and
   whether this commit's scan form differs from main's scan form on a full plane.
4. **The account and the host check:** is it computed from what was really written and really
   reserved (not from the same quantity twice)? Is it checked on every path that runs the top
   kernel (ordinary batches, re-runs, clipped blocks handled by the other top kernel)? Can it
   raise a false alarm on a correct run (overflowed batches, retries, wrap mod 2^32)? Is a
   mismatch always an error that prevents a result, never a silent retry? What wrong runs would
   pass it?
5. **Cost and scope:** the diff should touch only the FD top kernel's append, its accounting,
   the host check and tests. The author reports +0.2–0.3 % of a field on an RTX 3080 and that
   every other kernel's generated CUDA and WGSL source is identical to main's: check the
   numbers against `T26/raw/box/` and say whether the identity claim's method is sound.
6. **The tests:** would the new tests fail on main's `top_slot` (the author says they do on
   lavapipe with lane 0 taken out, and that CUDA cannot show it); can the test-only modes leak
   into a production build; does CI (lavapipe with both compilers, Metal) run them?
7. **The PR body against the evidence**, and whether it mentions the research program, its
   directories, agents or a model name (it must not). Is the changelog line accurate and short?
8. **Interaction with open PR #251** (fork `pr/check-d`, head `1f41d649`), which also adds words
   to the `ran` array: the author notes that #251's test-only word is hard-coded at
   `ran[STAGES_U32 + 3]` and would collide with this commit's account once both are merged.
   Check the note and say exactly what the second of the two to land must change.

## Method and limits

Reading, your own models, and host-side checks from a worktree
`~/projects/nice/.worktrees/review-t26` (detached at `f9a25017`) with
`CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`: `cargo fmt --all --check`,
`nice -n 19 cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`, the host
tests touching the change. Rust 1.100.0 is what main pins. ivory has no GPU or Vulkan driver,
about 10 GB of disk and a small tmpfs `/tmp`; another reviewer is using two CPU threads, so use
at most two and expect builds to be slow. Do not change the branch, push, open or comment on a
PR, start subagents, or touch any rented machine, the fleet, the server, demoux or mayalaran.

## Deliver

`T26/REVIEW.md`: the verdict first (open as is / open after the listed fixes / do not open),
findings by severity with file and line, how you know, and the fix you suggest; then what you
verified and how (your model under `T26/review-model/`); then what could not be verified without
hardware. Your final message is a short summary for the program's director.
