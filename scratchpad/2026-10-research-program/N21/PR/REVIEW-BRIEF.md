# Review brief: one PR branch of the GPU overlap join, before it is opened (2026-11-13)

You are an independent reviewer. The repository is `~/projects/nice` on this machine (ivory);
upstream is `wasabipesto/nice` (git remote `origin`), the fork `wasabipesto-bot/nice` (remote
`fork`). The project searches for numbers whose square and cube together use every base-b digit
exactly once; the code under review is in the GPU "overlap join", `common/src/cubecl_join.rs`
(read the module docs at its top, the walk in `join_kernel`, and `walk_pf_lean` with its doc
comment). **A missed candidate is the worst possible defect here: correctness comes before
everything else.** You were not involved in writing the change; take none of its claims on
trust.

## The branch

Fork branch **`pr/join-prefilter-popcount-spirv`**, one commit on upstream main `41b4b405`
(fetch both remotes first; the commit id is in the message that carries this brief). What it
claims to do: in the join kernel's fixed-point prefilter, the question "are these four digits
distinct from each other and absent from the pair's digit mask" is asked as one population
count, `popcount(A & !seen) == 4` with A the OR of the four digits' one-hot bits (in the masks'
bit-reversed order), instead of four 64-bit shifts with a sign test and six compares; and only
on the runtime it was measured to help, `wgpu<spirv>` (Vulkan through CubeCL's SPIR-V
compiler). Every other runtime (CUDA, Metal, WGSL) is claimed to compile exactly today's code.
PR body draft: `N21/PR/PR-BODY.md`. Evidence: `N21/RESULTS.md` (the study: variants, exactness
evidence, CUDA timings, the AMD compiler's instruction counts; the change is its variant "M",
mode 8 of the experiment branch), `N21/WINDOW-RESULTS.md` and `N21/raw/demoux/` (timings on the
RX 9070 XT), `N21/PR/NOTES.md` (what the branch's author checked and could not), all under
`~/projects/nice/scratchpad/2026-10-research-program/`.

## What to check

1. **The identity, for every input the kernel can produce.** Digits below the base (at most
   64); the mask's bit order; what happens if two digits are equal, if a digit is in `seen`,
   at digit 0 and digit 63, at base 64 where all 64 bits are in use; the 32-bit halves and how
   the count is summed. Is `popcount(A & !seen) == 4` true exactly when today's test passes?
   Write your own exhaustive or randomised check (Python or Rust) rather than re-reading the
   author's test, and compare it with today's form as the kernel computes it (shifts and sign
   test), not only with the mathematical statement.
2. **The switch.** Is the count form compiled only where `R::name(client)` contains `spirv`, and
   is every other runtime's generated kernel today's code? Read how the comptime argument flows
   from `JoinDevice` into `join_kernel` and `walk_pf_lean`; check CubeCL's runtime names in the
   cargo registry (`cubecl-wgpu`, `cubecl-cuda`, and HIP if present). Could a new comptime
   argument change another runtime's kernel in any way that matters (cache keys, argument
   order)? The author could not compare CUDA kernel sources: say what the claim rests on.
3. **Everything else in the diff:** nothing but the prefilter's test, its docs, the host tests
   and one changelog line should change. Other callers or twins of `walk_pf_lean` (the non-lean
   `walk_pf`, the CPU join's prefilter, test kernels)?
4. **The tests:** do the host tests assert the count form against the old form over a space
   that would catch an error (which bases, which digit tuples, which masks)? Which device tests
   exercise the count form in CI (lavapipe with the SPIR-V compiler) and which the old form?
5. **The PR body against the evidence:** recompute a sample of its numbers from the raw logs
   (`N21/raw/demoux/*.log`, `N21/raw/ab_table.txt`, `N21/raw/aco_table.txt`). The RX 9070 XT
   numbers were measured on an experiment build (main + #255 + #256 with the change behind a
   switch, the same test written slightly differently), not on this commit, and the base-64
   figure is one round: does the body say so plainly, and could anything about that build make
   the numbers not carry over? Is anything claimed that the evidence does not support? Does the
   body mention the research program, its directories, agents or a model name (it must not)?
   Is the changelog line accurate and in the file's style?
6. Host-side checks: `cargo fmt --all --check`; `nice -n 19 cargo clippy -p nice_common
   --all-targets --features cubecl -- -D warnings`; the host tests touching the change. Main now
   pins Rust 1.100.0 (installed on ivory). Use a worktree `~/projects/nice/.worktrees/review-n21`
   (detached at the branch head) with
   `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` so the build is incremental.
   ivory has no GPU, about 5 GB of free disk and a small tmpfs `/tmp`: no release or
   GPU-backend builds.

## Deliver

`N21/PR/REVIEW.md`: the verdict first (open as is / open after the listed fixes / do not open),
findings by severity with file and line, how you know, and the fix you suggest; then what you
verified and how; then what could not be verified without hardware. Do not change the branch,
push, open or comment on a PR, start subagents, or touch any rented machine, the fleet, the
server, demoux or mayalaran. Your final message is a short summary for the program's director.
