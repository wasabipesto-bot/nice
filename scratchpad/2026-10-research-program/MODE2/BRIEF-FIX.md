# The middle-out branch through the whole CI matrix, and Metal (brief, 2026-11-26 06:05 UTC)

You are a Rust engineer. Work alone (do not start subagents). **Hard stop 10:00 UTC** (check `date -u`).

## The branch and the job

The "nice" project (`~/projects/nice` on this machine, ivory; upstream = remote `origin`, our fork = remote `fork`)
has a redesigned GPU search join on the fork branch **`dev/mo-mode`** (head `f61cf79e`, worktree
`~/projects/nice/.worktrees/mo-mode`), with a client mode `nice_client midout`. Notes on yesterday's work:
`~/projects/nice/scratchpad/2026-10-research-program/G2/MODE-NOTES.md` (§4 has the CI results). **Nothing from this
branch is opened as a pull request; the maintainer reviews the design first.** Two things to do, as small named
commits on `dev/mo-mode` pushed to `fork` (never to `origin`; never force-push, amend a pushed commit or delete a
branch; commit trailer exactly `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`; no mention of
assistants, agents or a research program in commits, comments or docs):

### 1. Make the branch pass the project's whole CI matrix

The fork's run 45570638702 (on `bbbb4c7e`, one test-only commit before the head) passes everywhere except four
jobs: **Build Linux-i686-gnu, Linux-armv7, Linux-arm-musl, Linux-aarch64**. The same tests fail on the branch's
parent `dev/mo-clean` (run 45569796574), so they are older than the client mode:
- `midout::coord::tests::b65_padded`: `usize::try_from(q / 4099).unwrap()` overflows on 32-bit targets
  (`common/src/midout/coord.rs`, about line 547, test code). Fix the test so that it does the same sampling with
  128-bit arithmetic.
- `client_api_async::tests::ordinary_claims_refuse_a_coordinate_field` (and yesterday's
  `a_server_without_the_endpoint…`, already made to skip in `f61cf79e`): they bind a loopback socket, which the
  emulated i686 runner cannot do (ENOSYS). Decide per test whether the socket is needed at all (a pure function
  under test is better than a skip); skip only where a real socket is the point, and say so in the test.
- `midout::cpu::tests::threaded_slice_join_equals_single_threaded`: **killed (SIGKILL) under the aarch64
  emulator. Diagnose it; do not just skip it.** Read the job's log (`gh run view 45570638702 -R wasabipesto-bot/nice
  --log-failed`, or the job's log by id) for memory and time; work out what the test allocates and how long it
  runs natively and under emulation; if it is simply too big for an emulated runner, cut it to a size that still
  tests what its name says (and keep the big form in the card tier, feature `midout-box-tests`); if it shows a
  real defect, that is the finding.
- Read the four failing jobs' logs fully: there may be more than these three.
- Verify by the fork's CI: `gh workflow run "Rust Cross-Platform Build, Test, and Release" -R wasabipesto-bot/nice
  --ref dev/mo-mode` and `gh workflow run "GPU Device Parity" … --ref dev/mo-mode` (workflows run on a branch only
  when dispatched); the matrix takes about an hour (the arm builds are the slow ones), so push the fixes early
  and use the wait for part 2. `just lint` must pass (the "Format and clippy" job is `just lint`).

### 2. Metal: the join now has evidence on Apple hardware; replace the refusal by what the evidence supports

The client mode refuses an Apple Metal device by name (`client/src/midout_route.rs`, `is_metal`; the module
comment says "the join has never been checked on one"). On 2026-11-26 the branch's device tests ran on a real
Apple M4 (macOS 27.2, `Apple M4 (Metal, wgpu<wgsl>)`, plane width 32): the lavapipe tier, two base-64 slices n for
n, the fault tests, parent sharing, wide parity at bases 40 and 65 all pass, and whole fields run at 12.9 fs per
admissible n with the sampled check equal (logs: `…/2026-10-research-program/MAYALARAN/runs/`). Every field is
also checked on a sampled slice against the CPU in normal operation. So:
- Remove the refusal; in its place log one **warning** at start on a Metal device that says what has and has not
  been checked (checked on an M4 under macOS 27.2; older macOS releases had a Metal compiler defect in division
  by constants, fixed in 26.7.2 and 27.2, which the project's kernel lint guards against; the per-field sampled
  check stays on). Update the module comment, the README lines and the tests of `is_metal` accordingly.
- **Then run the real client mode on the M4** against the development server, as was done on an RTX 3060
  yesterday (`…/EVENTEO/scripts/run_mo.sh`, phase c, is the recipe: `midout_fields --base 64 --spread N`,
  `scripts/midout_coordinator.py`, `nice_client midout --api-base http://127.0.0.1:PORT --repeat`, then
  `scripts/midout_audit.py`, which must exit 0). Three fields are enough (about four minutes each).
  The M4 is the maintainer's machine **mayalaran**: read `README.md` ("Machines the program may use") and the
  memory entry `~/.claude/projects/-home-claude/memory/reference_user_test_machines.md` (the last two entries)
  first. `ssh justin@mayalaran` is the owner's own account: **write only inside `~/claude`**; source
  `~/claude/scripts/env.sh` in every script (it points the API address at a closed local port and keeps cargo's
  registry inside the folder); `~/claude/scripts/build_mo.sh BRANCH TAG` shows how the branch was fetched and
  built there (add `-p nice_client --features cubecl` for the client; builds take one to two minutes); no
  services, launch agents or cron; kill only what you started, by PID; never `pkill -f`. Nothing may contact the
  production API: every client run gets an explicit `--api-base http://127.0.0.1:PORT`.
  mayalaran is also the fastest machine for compiling and for `cargo test`/clippy on this branch: use it for
  that instead of ivory (ivory has 4 slow cores; if you must build on ivory, `nice -n 19`, `-j 2`, one cargo at a
  time).

## Deliverables (by 10:00 UTC)

- `dev/mo-mode` on the fork with the fixes; the fork's CI matrix and device-parity runs on the final head, with
  the result of every job (if the hour-long matrix has not finished by the stop, say which jobs were still
  running and leave the run id).
- `~/projects/nice/scratchpad/2026-10-research-program/MODE2/FIX-NOTES.md`: per failing test the cause, the fix
  and how it was verified; the aarch64 diagnosis with its evidence; the Metal change and the client run on the
  M4 (numbers, audit result, the warning's text); anything else the matrix logs showed; what is not done.
- A final report to me of at most 15 lines. If the tooling denies something, do not work around it: note it.
