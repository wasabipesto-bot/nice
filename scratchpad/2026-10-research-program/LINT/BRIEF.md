# Put the middle-out kernels under the project's WGSL lint; two small leftovers (brief, 2026-11-27 06:00 UTC)

You are a Rust engineer. Work alone (do not start subagents). **Hard stop 09:30 UTC** (check `date -u`).

## Background

The "nice" project (`~/projects/nice` on this machine, ivory; upstream = remote `origin`, our fork = remote `fork`)
compiles its GPU kernels with CubeCL. An old Apple Metal compiler defect miscompiled certain divisions by a
constant (`(x >> 16) / K` and `u32(u64 >> 32) / K` forms); Apple fixed it in macOS 26.7.2 and 27.2, and the
project keeps a lint for users on older systems: the test `cubecl_backend::tests::wgsl_dump_for_lint`
(`common/src/cubecl_backend.rs`) compiles the production kernels with `CUBECL_DEBUG_LOG` set so that their WGSL
lands in a log, and `scripts/wgsl-lint.py` reads the log in the CI job "cubecl on lavapipe (Linux)"
(`.github/workflows/gpu-parity.yml`, with a `--require` list of kernel names). On the fork branch **`dev/mo-mode`**
(head `0b6e22e1`, worktree `~/projects/nice/.worktrees/mo-mode`) there is a new join, the middle-out join
(`common/src/midout/gpu.rs`, `gpu_wide.rs`: about 15 narrow and 14 wide kernels), whose client mode now runs on
Apple Metal with a warning. **Found yesterday: the lint's dump does not include the middle-out kernels.** They were
linted once by hand on 2026-11-19 (one site found and fixed then) and read by eye yesterday.

## The job (branch `dev/mo-lint` cut from the fork's `dev/mo-mode` `0b6e22e1`; small named commits; pushes to
`fork` only, never `origin`, never `dev/mo-mode`; never force-push or amend a pushed commit; commit trailer exactly
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no mention of assistants, agents or a research
program in commits, comments or docs; no pull request)

1. **The middle-out kernels into the lint.** Make the dump cover every middle-out kernel that a wgpu device can
   be given at bases 64 and 65 (narrow and wide; every comptime variant the drivers actually launch on a
   32-lane and on a 64-lane device, as far as the dump can force them: say which variants are and are not
   covered and why), by whatever is least invasive: extending `wgsl_dump_for_lint`, or a second dump test in the
   `midout` module that the same CI step runs (the tier-(b) tests `cubecl_midout*` already compile most kernels on
   lavapipe: running them under `CUBECL_DEBUG_LOG` may be all the dump needs). Extend the workflow's lint step
   and its `--require` list so that a kernel that drops out of the dump fails CI. Then **read what the lint
   says**: every flagged site is either a real instance of the miscompiled form (fix it in the kernel the way
   the 2026-11-19 site in `hist2` was fixed, keeping results identical: the tier-(b) tests must pass) or a false
   positive (say why, and do not weaken the lint to hide it without saying so).
   If upstream's `scripts/spirv-atomic-check.py` step is on this branch (it is in upstream pull request #278,
   probably not merged here), leave it alone.
2. **The development server's `/status`** (`scripts/midout_coordinator.py`): add the count of checks that
   disagree with their canon (the audit already treats a disagreement as a problem since yesterday; the
   reviewer asked for the count in `/status` too). One test in the existing end-to-end tests if it fits there.
3. **macOS clippy:** on an Apple machine `cargo clippy -p nice_common -- -D warnings` fails in
   `common/src/cpu_join.rs` (`unused_self` near line 986, `unused_mut` near line 2093: code on a path only
   aarch64-apple compiles; CI's lint runs on Linux and does not see it). This is upstream code, not the branch's:
   **do not fix it on this branch.** Confirm it on upstream `main` (the maintainer's Apple machine is available
   for builds: `ssh justin@mayalaran`; read `README.md` "Machines the program may use" in
   `~/projects/nice/scratchpad/2026-10-research-program/` and the last entries of
   `~/.claude/projects/-home-claude/memory/reference_user_test_machines.md` first; write only inside `~/claude`
   there; source `~/claude/scripts/env.sh`; kill only what you started, by PID), and if it reproduces on `main`,
   prepare a one-commit branch `pr/macos-clippy-cpu-join` from upstream `main` with the fix and a two-line
   description in your notes. Do not open a pull request (an independent review comes first).

## Verifying

- mayalaran is the fastest machine for `cargo test` and clippy (builds in one to two minutes;
  `~/claude/scripts/build_mo.sh` shows how the branch is fetched and built there); it has no lavapipe, but its own
  GPU runs the tier-(b) tests through Metal, which is the device this lint is about: run them there after any
  kernel change. Lavapipe runs in the fork's CI: `gh workflow run "GPU Device Parity" -R wasabipesto-bot/nice --ref
  dev/mo-lint` (workflows run on a branch only when dispatched; the lavapipe job takes about 25 minutes) and
  `gh workflow run "Rust Cross-Platform Build, Test, and Release" … --ref dev/mo-lint` for `just lint` (the
  "Format and clippy" job). The lint step must pass in CI with the middle-out kernels in its `--require` list.
- Never contact the production API. If the tooling denies something, do not work around it: note it.

## Deliverables (by 09:30 UTC)

`dev/mo-lint` on the fork with the CI results on its head; `pr/macos-clippy-cpu-join` if it applies;
`~/projects/nice/scratchpad/2026-10-research-program/LINT/NOTES.md` (what the dump covers now and what it cannot,
what the lint flagged and what was done about each site, the CI runs, the `/status` change, the clippy finding,
what is not done); a final report to me of at most 12 lines.
