# N21 PR brief: the prefilter's digit test as one population count, off CUDA (2026-11-13)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules), `../N21/RESULTS.md` (today's study: the loop, the
variants, why each is exact, CUDA timings, the AMD compiler's instruction counts, exactness
evidence), `../N21/WINDOW-RESULTS.md` (this afternoon's measurements on the RX 9070 XT), the
candidate commit `3a4899ee` on fork branch `exp/n21-popcount-test-wgpu` (one commit on upstream
main `a7a59c11`), and for the shape and tone of a PR body in this project, the two bodies the
maintainer has in front of them now: `../PRP/PR-BODY-stage.md` and `../PRP/PR-BODY-shift.md`.

## What the change is and what was measured

In the GPU join's walk, every pair that passes the digit-overlap test runs a fixed-point
prefilter (`walk_pf_lean`) that extracts four digits and asks whether they are distinct from
each other and absent from the pair's digit mask: today four 64-bit shifts with a sign test
plus six compares. The candidate asks the same question as one population count,
`popcount(A & !seen) == 4` with A the OR of the four digits' one-hot bits, on every runtime
except CUDA, where the current form compiles better and the kernel is left as it is.

- RX 9070 XT (wgpu on Vulkan, the card that does most of the project's work), measured today
  with the change behind a switch in an experiment binary on main + #255 + #256, counts identical,
  every run at the card's power cap: **b62 1e17 ×1.040, ×1.034, ×1.037 (three rotated rounds);
  b64 1e17 ×1.080 (one round)**; with the separate "cheaper pop" change on top ×1.049 at b62
  (three rounds) and ×1.100, ×1.097 at b64 (two rounds). b60 was not timed.
- RTX 3080 (CUDA): the population-count form everywhere was 1–2 % slower, which is why this
  branch leaves CUDA's kernel alone.
- Mesa's compiler for that AMD card emits 8 fewer instructions per walk round for it.
- Not measured: any Apple GPU (Metal gets the new form), HIP, DX12.

## Task (no rented machine: ivory only)

1. **Branch `pr/join-prefilter-popcount`** on the fork: exactly one commit on upstream main
   `a7a59c11` with the candidate's change plus one line in `CHANGELOG.md` under the unreleased
   section, in the file's style (short, user-facing), ending in the placeholder
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))` that the director fills when the PR
   is opened. Read the candidate's diff critically before reusing it: the doc comments must say
   what the code does and why CUDA is excluded, with numbers that are in the evidence; nothing
   may refer to the research program or its experiment names. Push it as a new branch name
   (plain push; never force-push; if a push is refused, report it).
2. **Check on ivory:** `cargo fmt --all --check`; `nice -n 19 cargo clippy -p nice_common
   --all-targets --features cubecl -- -D warnings`; the host tests that touch the change
   (`nice -n 19 cargo test -p nice_common --features cubecl <filter>`), with
   `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` so the build is incremental
   (ivory has about 6.5 GB of disk, no GPU, a small tmpfs `/tmp`). Use a worktree
   `~/projects/nice/.worktrees/n21-pr`.
3. **Say exactly what evidence shows CUDA's kernel is unchanged** by this branch (the study
   compared generated kernels or binaries: find what it did and cite it; if it only rests on
   reading the comptime switch, say that) and what device tests the candidate binary passed
   (CUDA dense compares, lavapipe with both compilers), from `../N21/RESULTS.md` §7 and its raw
   logs. Do not claim a run you cannot find in the logs.
4. **PR body `N21/PR/PR-BODY.md`**, at most 800 words plus tables: What; Why; Soundness (the set
   identity, stated so a reader can check it, including how the bit-reversed masks enter);
   Measurements (the RX 9070 XT numbers above, stated as measured on that card with the change
   behind a switch on main with #255 and #256 applied; the CUDA result and why CUDA is left
   alone; the compiler's instruction counts as counts, not timings); Exactness; Not in this PR
   (the cheaper pop: about ×1.01–1.02 more on that card, a ready follow-up; no Apple measurement).
   Say plainly which numbers are one round. No mention of the research program, its
   directories, agents or model names. End the body with the line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

## Deliver

The branch (commit id), `N21/PR/PR-BODY.md`, and `N21/PR/NOTES.md` (what you changed against the
candidate and why; the check outputs; the evidence for step 3). No PR, no comments on PRs, no
subagents, no rented machines; never touch the fleet, the server, `~/fleet-run`, demoux or
mayalaran. Hard stop **17:30 UTC**; your final message is a short report for the program's
director.
