# Review brief: one PR branch of the GPU overlap join, before it is opened (2026-11-12)

You are an independent reviewer. The repository is `~/projects/nice` on this machine (ivory);
upstream is `wasabipesto/nice`, the fork `wasabipesto-bot/nice` (git remote `fork`; upstream is
remote `origin`). The project searches for numbers whose square and cube together use every
base-b digit exactly once; the code under review is the GPU "overlap join" in
`common/src/cubecl_join.rs` (read the module docs at its top first, and the part of
`join_kernel` the change touches). A missed candidate is the worst possible defect here:
correctness comes before everything else.

The message that carries this brief names **one branch** (one commit on upstream main
`a7a59c11`), its PR body draft and its results file. Review that branch only. You were not
involved in writing it; do not take its author's claims on trust.

## What to check

1. **The diff** (`git diff origin/main fork/<branch>`): is the change exactly what the commit
   message and the PR body say, and nothing else? Is it correct by construction for every
   device, base and field shape the join accepts, not only the measured ones? Look for the
   failure you would be most embarrassed to have missed: an off-by-one, an overflow path that
   now triggers where it never did, an assumption a comment states but the code does not
   enforce, a constant relation elsewhere in the file (assertions, buffer sizes, flush logic,
   other kernels, the CPU reference, the host side) that depended on the old value.
2. **Independent verification** you can do without a GPU: re-derive the arithmetic yourself
   (a short Python or Rust check of your own is better than re-reading the author's test), run
   the crate's host tests that touch the change (`nice -n 19 cargo test -p nice_common --features cubecl <filter>`
   from a worktree of the branch under `~/projects/nice/.worktrees/`; the shared target
   directory makes this incremental; ivory has about 6 GB of disk, so no release or GPU-backend
   builds), `cargo fmt --all --check`, and
   `cargo clippy -p nice_common --all-targets --features cubecl -- -D warnings`.
3. **The tests the branch adds or relies on:** do they assert what the body says they assert,
   and would they fail if the change were wrong?
4. **The PR body against the evidence:** every number in the body must be in the results file
   and its raw tables under `PRP/raw/` (`ab_table.txt`, `nm_table.txt`, the box logs) or in the
   program's experiment log entry it cites; check a sample of them yourself against the raw
   logs. Are single-round numbers and unmeasured devices stated as such? Does the body claim
   anything the evidence does not support? Does it mention the research program, its
   directories, agents or a model name (it must not)? Is the changelog line accurate, in the
   file's style, and does it oversell?
5. **The measurement's validity:** the gain on the AMD card was measured on an experiment tree
   (the same kernel with the change behind a switch), not on this exact commit. Say whether the
   body states that fairly and whether anything about the experiment tree could make the number
   not transfer.

## Deliver

Write `PRP/REVIEW-<stage|shift>.md` in `~/projects/nice/scratchpad/2026-10-research-program/`:
a verdict first (open as is / open after the listed fixes / do not open), then findings in
order of severity, each with the file and line, what is wrong, how you know, and the fix you
suggest; then what you verified and how (commands and outputs in brief); then what you could
not verify. Do not change the branch, do not push, do not open a PR, do not start subagents,
do not touch any rented machine, the fleet, the server, demoux or mayalaran. Your final message
is a short summary of the verdict and findings for the program's director.
