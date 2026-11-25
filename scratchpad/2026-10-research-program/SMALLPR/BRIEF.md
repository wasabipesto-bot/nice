# Two small pull requests the maintainer approved on 2026-11-25 (brief, 04:10 UTC)

You are an engineer preparing two small, separate pull requests for the "nice" project (an exhaustive
distributed search; Rust client and server; upstream `wasabipesto/nice` = remote `origin` of `~/projects/nice`,
fork `wasabipesto-bot/nice` = remote `fork`). Work alone (do not start subagents). **Hard stop 09:30 UTC.**
**You do not open the pull requests**: an independent review comes first, and I open them.

## The maintainer's words

1. On "a `--gpu` client whose CUDA runtime cannot start falls back silently to the CPU software renderer
   (correct results, hundreds of times slower); recommendation: make it an error": *"I don't see an issue with
   this as long as everything is properly logged at warning or error level."*
2. On "CubeCL 0.10's SPIR-V optimizer drops repeated atomic stores of one value: add a CI check for that
   pattern": *"Sure, I don't see why not."*

Their bar for pull requests: one discrete change each; a defect fix or a check, with its test; `just lint`
clean; the changelog line one short sentence that links the pull request's own number (use the placeholder
`#NNN`, I fill it in); descriptions in plain words for someone who has seen none of this, with no reference to
any research program, notes, scratchpad path, agent, assistant or model, and saying what a wgpu (Vulkan, Metal)
device should expect when the evidence is from CUDA or a software renderer; no new flag, mode or job without
their explicit yes (**neither of these may add a command-line flag or an environment switch**).

## What is known

1. **The start-up fallback.** `~/projects/nice/scratchpad/2026-10-research-program/SRA/RESULTS.md` (around line
   140, and its section on allocation failures) records how it was seen on a rented NVIDIA box: CUDA context
   creation failed, and the client went on with another device. Establish by reading upstream main
   (`origin/main`, `fdbe07d3`) exactly what happens today for `nice_client --gpu` (and each `--gpu-backend`
   value) when (a) the CUDA runtime is present but cannot create a context, (b) no CUDA runtime exists and a
   hardware Vulkan or Metal device does, (c) no hardware device exists and only a software renderer
   (lavapipe / llvmpipe) does. The defect is the silent use of a **software renderer** by a client that was
   asked for a GPU; a machine with a real Vulkan or Metal device and no CUDA is a normal, supported setup and
   must keep working unchanged (the maintainer's own machines are one AMD card on Vulkan and one Apple M4).
   Decide the smallest change that makes case (c) and the silent part of case (a) loud: an error that stops
   the client when the only device left is a software renderer, with the reason for each device that was
   tried logged at error level, and a warning-level line when a non-CUDA hardware device is used after a CUDA
   failure. Find out first whether anything the project runs on purpose uses the client with a software
   renderer (CI jobs, tests, documented commands: `.github/workflows/`, the justfile, README): if so, the
   change must not break it and you must say how (the library's device tests on lavapipe are not the client
   and must be unaffected).
2. **The atomic-store trap.** CubeCL 0.10's SPIR-V optimizer keeps only the first of several atomic stores of
   one value in a block, so a kernel that is correct through WGSL can silently lose stores through SPIR-V.
   The project found it in its own kernel and worked around it; a comparison script that counts atomic
   operations per kernel in the SPIR-V output against the WGSL output exists
   (`~/projects/nice/scratchpad/2026-10-research-program/T26B/review2-box/scripts/atomcmp.py`,
   `T26B/raw/ci/stores.py`, and `EXPERIMENTS.md` there, entries T26B.2 and the line "SPIR-V against WGSL
   atomic operations: 902 kernel variants, none missing"). Turn that into a check the project's CI runs: where
   the existing GPU workflow (`.github/workflows/gpu-parity.yml` and what it calls) already produces both
   outputs, or as an ordinary Rust test that compiles each kernel both ways and compares the counts,
   whichever is smaller and matches how the repository already checks kernels (it has a WGSL lint for an
   Apple miscompile: look at how that one is wired and follow it). It must fail on the known bad pattern
   (show that with a small kernel in the test that has two atomic stores of one value in a block) and pass on
   every kernel on main.

## How to work

- Two branches from `origin/main` (`fdbe07d3`), two worktrees:
  `pr/gpu-software-renderer-error` in `~/projects/nice/.worktrees/gpu-sw-error`, and
  `pr/ci-spirv-atomic-stores` in `~/projects/nice/.worktrees/ci-atomic`.
- **Builds:** no rented machine is available. ivory (this machine: 4 cores, 7 GB of memory, 19 GB of disk
  free) may build at low priority: `nice -n 19 cargo … -j 2`, **one build at a time**, one target directory
  per worktree, and remove a target directory when its branch is done (`df -h /` before and after; stop if
  free space falls under 8 GB). The software renderer for device tests is the container `localhost/lvp26`
  (Mesa from CI's version; see `~/projects/nice/scratchpad/2026-10-research-program/README.md` and
  `G2/build4s/window/dryrun_lvp.sh` for how it was used). The fork's CI can also build a pushed branch
  (`gh workflow run` with `--ref` on `wasabipesto-bot/nice` for workflows that allow manual dispatch; earlier
  work did this): use it for the full matrix once the branch builds locally.
- `just lint` must pass (it is the repository's standard: read the justfile; run its commands at low priority
  if `just` is not installed).
- Ordinary commits only (never amend, rebase or force); trailer exactly
  `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; plain messages. `git push -u fork <branch>`.
  **No pull request; nothing to `origin`.**
- Never contact the production API; never run a client against it (a client run needs a local stub or a
  closed local port, as the earlier work did: `G2/build4f/box/stub_api.py`).
- If the tooling denies something, do not work around it: note it and report it.

## Deliverables (by 09:30 UTC)

1. The two branches on the fork, each building and passing its tests and `just lint`, each with a changelog
   line carrying `#NNN`.
2. `SMALLPR/NOTES.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`): for each: what the code
   does today (file and line), what you changed and why that and not more, the tests and what they prove,
   what was run where (ivory, the software renderer, the fork's CI) with results, what could not be tested
   (a real CUDA failure cannot be produced here: say how the change was exercised instead), and what a
   reviewer should look at hardest.
3. `SMALLPR/BODY-1.md` and `BODY-2.md`: the two descriptions, at most 250 words each, ending with the line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
4. A final report to me of at most 20 lines.
