# Independent review of two small pull-request branches before they are opened (2026-11-25 05:50 UTC)

You are an independent reviewer. You did not write this code. Work alone (do not start subagents), on this
machine (ivory) only. **Hard stop 07:30 UTC.**

## What you review

Two separate branches on the fork of the "nice" project (a distributed exhaustive search; Rust client and
server; `~/projects/nice`, upstream = remote `origin`, fork = remote `fork`), each one commit on upstream main
`fdbe07d3`, each meant to be opened as its own pull request once you say so:

1. `pr/gpu-software-renderer-error` (`5781393a`, worktree `~/projects/nice/.worktrees/gpu-sw-error`): a client
   started with `--gpu` that ends up on a CPU software renderer (llvmpipe/lavapipe) now stops with an error
   instead of running hundreds of times slower; a hardware device used after a CUDA failure gets a warning.
   Description: `SMALLPR/BODY-1.md`.
2. `pr/ci-spirv-atomic-stores` (`68194bf1`, worktree `~/projects/nice/.worktrees/ci-atomic`): a CI check that
   the SPIR-V the project's kernels compile to keeps every atomic operation their WGSL has (a known optimizer
   trap drops repeated atomic stores of one value). Description: `SMALLPR/BODY-2.md`.

The author's notes: `SMALLPR/NOTES.md` (under `~/projects/nice/scratchpad/2026-10-research-program/`), logs in
`SMALLPR/logs/`. The maintainer's words that authorised them: on (1) *"I don't see an issue with this as long as
everything is properly logged at warning or error level."*; on (2) *"Sure, I don't see why not."* Their bar: one
discrete change per pull request; tests with it; `just lint` clean; **no new command-line flag, environment
switch, mode or CI job**; a changelog line of one short sentence with the placeholder `#NNN`; a description in
plain words that says what a Vulkan or Metal device should expect, with **no reference to any research
program, notes, scratchpad path, agent, assistant or model**.

## Decide for each: open, open with fixes (list them), or hold

1. **Branch 1, correctness and reach.** Read the diff cold. Who is affected: confirm by reading that a machine
   with a real Vulkan or Metal device and no CUDA (the maintainer's own: an AMD card on RADV, an Apple M4)
   takes exactly the path it took before, with no new message; that the fleet's NVIDIA boxes are unchanged
   when CUDA works; that the only new refusals are software renderers. Is the name test for "software
   renderer" safe (false positives on hardware names; what about a pinned `--gpu-wgpu-device`)? Is every reason
   logged at warning or error level as the maintainer asked, and nothing important left at debug (the author
   notes one reason stays at debug under `auto` until the final error: is that acceptable)? Does anything in
   the repository run the client on a software renderer on purpose (workflows, justfile, docs, tests)? Is the
   unit test meaningful, and is the wiring it cannot reach (the CUDA-failure warning) correct by reading?
2. **Branch 2, the check.** Does it fail on the known bad pattern for the right reason and pass on main's
   kernels (the author's CI runs: check them with `gh run list/view -R wasabipesto-bot/nice --branch
   pr/ci-spirv-atomic-stores`)? Is it a new CI *job* (not allowed without a yes) or a step in an existing job?
   Does the script make sense to someone who has not seen the bug (its header, its exit codes)? Can it pass
   vacuously (no kernels paired, logs empty, a renamed kernel): what does it do then? Does the trap kernel in
   the test module affect anything outside tests?
3. **Both:** `just lint` (read the fork CI result for each branch; re-run locally at low priority only if you
   doubt it: `nice -n 19`, `-j 2`, one build at a time, and only if `df -h /` shows more than 8 GB free);
   the changelog lines; the descriptions against the code and the rules above; anything forbidden in commit
   messages or comments.

Do not rewrite; list. Change nothing on the branches; no pushes; no pull request; no comments anywhere. Never
contact the production API. If the tooling denies something, do not work around it: note it.

## Deliverable (by 07:30 UTC)

`SMALLPR/REVIEW.md`: for each branch the verdict in the first line, then findings ranked (must fix before
opening; should; note) with file, line and evidence; what you ran or read yourself; corrections to each
description. Then a report to me of at most 15 lines.
