# Review brief: the CPU skip walk as a PR branch (the changes since the first review, the measurements, the body) (2026-11-14)

You are an independent reviewer. Repository `~/projects/nice` on this machine (ivory); upstream
`wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork` (fetch both).
The project searches for numbers whose square and cube together use every base-b digit exactly
once. **A missed candidate is the worst possible defect here.** You were not involved in writing
the change; take none of its claims on trust.

## What is under review

Fork branch **`pr/cpu-join-top-skip`** (`3ba5766a`, one commit on upstream main `41b4b405`): the
CPU overlap join skips a top prefix in the partitions where its last failed certificate shows it
must fail again. It is about to be opened as a pull request. Its history:

- The core change (`e0bf513e`, fork `exp/cpu-top-skip-squashed`) was reviewed this morning and
  found sound: `CPU2/REVIEW.md` in `~/projects/nice/scratchpad/2026-10-research-program/` (read it
  first; its harness is under `CPU2/review/`). You do not repeat that review.
- Since then an engineer made the changes that review suggested. They are separate commits on
  fork **`exp/cpu-top-skip-fixes`** (`e0bf513e` → `e2fe1f5a`: L1 one helper for the first
  certified position, M1 free the per-thread scratch when a field's join ends, L2 a test of the
  carried state, the CHANGELOG line); that branch and the PR branch must have the same tree.
  The engineer's write-up: `CPU2/PR-RESULTS.md`, the body draft `CPU2/PR-BODY.md`, raw logs and
  scripts under `CPU2/raw-pr/`.

## Questions

1. **Same tree?** `git rev-parse` both branch heads' trees. Is the PR branch exactly one commit
   on `origin/main`, and has main moved?
2. **L1 (`4ae3a956`, soundness-critical, hot path):** `cert` and `run` now take the first
   certified position from one helper. Is the helper exactly equivalent to *both* former copies
   for every input the callers can pass (square and cube, the run of `b − 1` digits, the d/d+1
   digit, positions at the boundary `z`, a zero top digit)? Did anything else in `cert`'s
   behaviour change (the set of passing tops must be identical to main's)? **Re-run this
   morning's harness on the final tree**: the big-integer check of the run bound, and main
   against the branch under disorderly schedules (`CPU2/review/`: `cmp_*.rs`, the hook patches,
   `REVIEW.md` "What I verified" for the commands), on as much as fits in about an hour of
   ivory's two threads; say exactly what you re-ran and on which tree. The PR body's
   "Outside this PR" bullet quotes those checks: it may only claim what was run on the final
   tree, so say which of its figures your re-run supports.
3. **M1 (`92960cd1`, the client):** a guard `FreeJoinScratch` whose `Drop` calls
   `rayon::broadcast(|_| JOIN_SCRATCH.take())`. Check, by reading `client/src/main.rs` and
   rayon's sources (`~/.cargo/registry/src/*/rayon-core-*`): which pool the join's partitions
   run on and which pool the broadcast reaches; whether `process_field_join` can itself run on a
   pool thread (then what does `broadcast` do, and can it deadlock?); **whether a worker thread
   can run the broadcast closure while it holds `JOIN_SCRATCH.with_borrow_mut` (a thread that
   blocks inside `run_partition` on a nested rayon call and steals the broadcast job would
   panic on the double borrow): does `run_partition`, or anything called under the borrow, ever
   enter rayon?**; whether two fields' joins can overlap in time on the same pool (the client
   pipelines claims; the GPU route; benchmark mode) and what a `take()` from one field's end
   does to a thread in the middle of the other's (correctness must survive: the state is keyed
   by the join's id; is a mid-partition clear possible at all?); every exit path of
   `process_field_join` (early return, `?`, panic unwinding) and whether a panic inside `Drop`
   during unwinding can abort the process.
4. **L2 (`95ef18da`):** does the new test exercise what it says (interleaved joins on shared
   scratches, out of order, retries, steps back, the `RUN_GAP` edge)? Make at least two mutants
   of the carry rule yourself (in a scratch worktree) and confirm the test fails on each and
   that the older ascending tests do not catch them.
5. **The measurements and the body.** Every number in `CPU2/PR-BODY.md` against
   `CPU2/PR-RESULTS.md` and the raw logs (sample at least: the b62 and b60 rounds at 42 threads,
   the memory table, NiceMark's per-scenario medians). The timed binaries carried a
   measurement-only hook that is not in the commit: read the hook (`raw-pr/scripts`) and say
   whether the timed code is the commit's code and whether the comparison is fair (same hook in
   both, same field, what "slice 0 of 7" leaves unmeasured). Is every single-round or partial
   figure stated as such? Does the body say what happens at b64, what it costs in memory, and
   that no GPU path changes (verify the last from the diff)? Does it mention the research
   program, its directories, agents, reviewers' files or a model name (it must not)? Is the
   changelog line accurate, one sentence, user-facing? The maintainer's bar for a change of this
   size is about ×1.10 at production shapes, with no benchmark scenario below ×0.98: say
   plainly whether the evidence meets it (the b62 figure is ×1.105 on one slice of one field
   on one machine).
6. **Anything else you would be embarrassed to have missed** in `git diff e0bf513e e2fe1f5a`.

## Method and limits

A worktree `~/projects/nice/.worktrees/review-cpu2-pr` (detached at `3ba5766a`); mutants in
`~/projects/nice/.worktrees/review-cpu2-pr-mut`. Rust 1.100.0 is what main pins. Use
`CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` for fmt/clippy/tests (another
reviewer may be building there at times: cargo's lock makes that safe but slow; the directory
is shared between worktrees of the same crate versions, so `touch` the sources you changed
before a build you rely on, and confirm a test binary is the tree you think it is by a string
or a test name). `nice -n 19`, two threads at most; check `df -h /` and keep 5 GB free; `/tmp`
is a small tmpfs. `cargo fmt --all --check`, `cargo clippy --workspace --all-targets -- -D warnings`,
`cargo test -p nice_common` (the tests that touch the change at least). No rented machine. Do
not change either branch, do not push, do not open, comment on or edit any pull request, do not
start subagents, do not touch the fleet, the server, demoux or mayalaran, and do not contact the
production API.

## Deliver

`CPU2/PR-REVIEW.md`: the verdict first (open as is / open after the listed fixes / do not open),
findings by severity with file and line, how you know, and the fix you suggest (for a body
finding: the replacement sentence); then what you verified and how; then what you could not
verify. Hard stop **20:40 UTC**. Your final message is a short summary for the program's
director.
