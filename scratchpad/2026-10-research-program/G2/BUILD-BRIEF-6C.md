# The middle-out join, step 6C: make the branch fit to be reviewed (brief, 2026-11-19 12:15 UTC)

You are an engineer on the sixth step of a build. Work alone (do not start subagents). **Hard stop
17:30 UTC; the box destroys itself at about 18:05 UTC. Bundle commits to ivory after every piece.**

## Why

The middle-out join (trunk `dev/middle-out-join`, head `66259bb0`, worktree
`~/projects/nice/.worktrees/midout`) is exact, audited and ×4.09 faster end to end than production's join on
an RTX 3080. It is also 13,300 inserted lines written by seven engineers in two days, and an independent read
this noon found it is not yet fit to be put in front of the project's maintainer. Read, in this order, under
`~/projects/nice/scratchpad/2026-10-research-program/G2/`: `BUILD-BRIEF-1.md` (the owner's decision and rules:
all apply), **`MAINTAINABILITY.md` in full (your specification: its must-fix list M1–M7 and its "should"
list)**, `PR-PLAN.md` (the series the code will later be cut into: your work must make that cut easy, not do
it), then `BUILD-NOTES.md` §1 and the sections it points to.

## Your job

On a new branch **`dev/mo-clean`** from the trunk's head (the trunk itself stays as the archive of what was
measured): the must-fix items, each as its own ordinary commit, each leaving every test passing.

- **M3, the prototype's switches out of the narrow main kernel**: the comptime switches and dead branches
  removed, the launch no longer passing bare literals. **Proof required:** the kernel's generated code is
  byte-identical before and after for the configuration production uses (compare the SPIR-V dump and CubeCL's
  CUDA source), or, where it cannot be identical, exactness by the parity and fault tests plus an unchanged
  ten-field timing.
- **M4, the data layouts written down** where the code uses them: the survivor record, the job word, the top
  index bits, the child-list position, the account words; module docs made true.
- **M5, no reference to anything outside the repository**: the 56 references to notes and the "step 3A / 4S /
  5L" labels replaced by what a reader needs to know (the reason, the invariant), or removed.
- **M6, no public function that returns something that is not a whole, checked field** by accident: the
  part-field and timing functions, the host-tops option with fewer accounts, the timing stops: test-only,
  example-only or clearly named and documented as partial; the route refuses bases it has not been proven on.
- **M7, the client flag hidden from `--help`** until the maintainer has said yes to it.
- **M1, tests in tiers that CI can run.** CI's lavapipe and Metal jobs run every ignored test in `nice_common`
  (read `.github/workflows/gpu-parity.yml` and what filters each step uses). Make three tiers and say in one
  place how each is selected: (a) ordinary tests, CPU only, fast (the coordinate, the CPU reference against
  brute force, wire and route logic); (b) device tests that CI's lavapipe jobs can run in a few minutes with
  both compilers: named so the existing filters select them, small enough (classes per batch, slices) for
  lavapipe's limits, needing no staged data; (c) everything that needs a real card, hours, staged data or
  writes outside the build directory: behind a cargo feature that is in no default or umbrella set, so CI never
  sees it. No test may write to a fixed path such as `/root`.
- **M2, the kernels on the compilers CI uses.** The kernels were validated through the direct SPIR-V compiler
  and on CUDA only. Run tier (b) on lavapipe through **WGSL (naga)** as well as SPIR-V, fix what fails (naga
  rejects things the SPIR-V path accepts; `G2/PORT-NOTES.md` and production's own WGSL lint show the usual
  ones), and replace the prefilter form chosen by the runtime's name with a choice a reader can follow. Metal
  cannot be run here: read the kernels against the Apple rules production follows (`grep -rn "Metal" common/src`
  and the comments around the divide-by-constant workaround) and list what CI's macOS job would exercise.
- Then, if time remains, the "should" items in the order `MAINTAINABILITY.md` ranks them, stopping at 16:45
  to verify and write up.

**Every commit**: fmt and clippy clean on the feature sets CI uses (`just lint` is the standard), production's
suite passing, tier (a) and (b) passing on lavapipe with both compilers, and at the end of the day the full
card tier on CUDA (slice parity, both fault tests, wide parity) and the ten-field base-64 timing against the
trunk's head in the same session (1.62 fs per admissible n on this host this morning): the cleanup must not
cost speed or exactness.

Do not cut the series, do not delete the wide path or the old coordinate or the client route (those are the
maintainer's decisions, asked today), and do not restructure for taste: only what the read lists.

## Machines and rules

- **ivory**: reading, git and notes only; do not build here.
- **One rented box, which I rented and logged in to for you:** the ssh line at the end. Install the toolchain
  (the repo pins it), lavapipe (`mesa-vulkan-drivers`, `vulkan-tools`), `spirv-tools`; **map the production
  hosts to 127.0.0.1 and ::1 with the proof saved before any client binary runs**; nothing ever claims from or
  submits to the production API. Never create or destroy instances; never use another machine. Leave it
  running and idle.
- Branch `dev/mo-clean` from `66259bb0`, own worktree `~/projects/nice/.worktrees/midout-clean` on ivory.
  Ordinary commits (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; bundle to ivory after every piece;
  `git push -u fork dev/mo-clean` from ivory. No pull request, nothing to upstream. No server code. One target
  directory per worktree.

## Deliverables (by 17:30 UTC)

1. The branch on ivory and the fork, everything passing at its head.
2. `G2/CLEAN-NOTES.md`: each must-fix item: what was done, the proof (byte-identity or tests), what is left;
   the three test tiers and how each is run; what failed on WGSL and how it was fixed; the Metal reading; the
   card-tier results and the timing; the "should" items done and not done.
3. Raw logs under `G2/build6c/`.
4. A final report to me of at most 30 lines.

## The box

