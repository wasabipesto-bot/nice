# T2.6b brief: the niceonly stride kernel's survivor queues without full-plane and lane-0 assumptions (2026-11-14)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork`).
Read first: `../README.md` (rails, PR rules); `../CKF/REVIEW.md` lines 120–136 (where this defect
was written down); the two fixes of the same class, which are the model for this task:
`../CKF/RESULTS.md` with `git diff bc9d87c7 1f41d649` on fork `pr/check-d` (PR #251:
`take_entries`, `ensure_checked`, the partly-filled-plane tests) and `../T26/RESULTS.md`,
`../T26/REVIEW.md` with `git diff origin/main fork/pr/top-slot-any-plane` (PR #260, opened this
morning: leader = lowest kept lane, per-batch account words, `ensure_appended`, and the test-only
switch that takes lane 0 out); then on upstream main (`41b4b405`) `niceonly_kernel` in
`common/src/cubecl_backend.rs` (both compaction paths, lines 895–1260), the plan code that
chooses between them (2560–2630, 2801–2806), and the host code that reads the kernel's outputs.

## The defect

`niceonly_kernel` (the GPU stride walk for nice-only fields: what runs when the overlap join does
not) queues the cross filter's survivors in shared memory and checks them in dense waves. Both
queue variants assume every plane (Vulkan subgroup, CUDA warp, Metal SIMD group) is full and
laid out linearly along `UNIT_POS_X`:

- **Plane-scoped queue** (the default on `wgpu<spirv>` and on CUDA): slots come from
  `plane_exclusive_sum`, the drain lane is `UNIT_POS_X % PLANE_DIM`, and each wave drains
  `PLANE_DIM` entries (`take = PLANE_DIM`, lane `i < take` checks slot `qn - take + i`,
  `qn -= take`). On a plane with fewer running lanes than `PLANE_DIM`, the entries that fall to
  missing lanes are dropped unchecked: a candidate lost, and nothing on the host counts it.
- **Cube-scoped queue** (the WGSL default): lane 0 (`UNIT_POS_PLANE == 0`) writes the plane's
  total and done flag into `plane_tot[UNIT_POS_X / PLANE_DIM]`. A plane without lane 0 leaves a
  stale total; a subgroup layout that is not linear in `UNIT_POS_X` gives wrong offsets.
  Survivors are overwritten or skipped.

Vulkan does not promise full subgroups and wgpu does not request them; the subgroup-to-local-index
mapping is implementation-defined. No device in production is known to run partly filled planes
(256-thread groups are full on CUDA, Metal and RADV), so this is a robustness fix, not an
incident. A missed candidate is the worst possible defect in this project.

## Task

1. **Reproduce on a real device**, as the two earlier fixes did: a CUDA block whose thread count
   is not a multiple of 32, a test-only switch that takes lanes out, lavapipe (find out what it
   does with planes: earlier work found a subgroup-barrier quirk and that the plane-scoped
   variant "cannot run correctly" on software rasterizers: say why, and whether your fix changes
   that). Find the smallest test-only launch in which each variant loses or duplicates a
   survivor and say exactly what goes wrong. CubeCL's CUDA lowering has `UNIT_POS_PLANE =
   AbsolutePos % PLANE_DIM` (see CKF/RESULTS.md): say what that limits. If a variant's failure
   cannot be shown on any available device, show it with a host model of the kernel's logic and
   say so plainly.
2. **Fix by construction.** The lanes that actually run decide among themselves: positions and
   takes from the subgroup operations and the subgroup's own lane ids (rank among running lanes,
   ballot where planes have at most 32 lanes, scans where wider), never from `PLANE_DIM`,
   `UNIT_POS_X % PLANE_DIM`, `UNIT_POS_X / PLANE_DIM` or lane 0 existing. For the cube-scoped
   variant, decide whether per-plane totals can be made layout-independent cheaply (for example
   an atomic reservation by each plane's lowest running lane) or what else is sound; keep the
   barriers' ordering argument intact. Argue completeness for every plane population on every
   backend the code supports (read CubeCL's sources for what each plane operation does with
   inactive lanes). Keep the code shared with #251's `take_entries` only if that is natural on
   main as it is today: **this branch must stand alone on main and not depend on any open PR**
   (say where it would later share code).
3. **Make it verifiable by the host if that is cheap**: for example, per launch, the number of
   survivors queued against the number checked (two counters, or count and index sum as in
   #251 and #260), verified on the host with a hard error on mismatch. If a real check costs
   more than about 1 % or needs a redesign, say what it would take and stop there.
4. **Exactness and cost.** The partly-filled-plane regression tests (fail before, pass after) on
   CUDA and on lavapipe with both compilers (`--features gpu,cubecl` and
   `--features gpu,cubecl-spirv`), for both queue variants where a device can run them; the
   existing device suites of `cubecl_backend.rs`; whole-field comparisons of the stride walk
   against the CPU on the fields the existing tests use; host tests, `cargo fmt --all --check`,
   `cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings` under
   the pinned toolchain (Rust 1.100.0). **Speed on CUDA** (RTX 3080): the fix against main, same
   box, interleaved, three rounds, the stride walk forced on fields where it is the production
   path or was before the join (find how the route is chosen and forced: `NICE_JOIN_ROUTE`,
   `joins_on`; use NiceMark's stride-walk scenarios if there are any, and one base-50s field
   forced to the stride walk), card cool before each run, no builds while timing, power cap and
   clock recorded per run. The fix should cost under 1 %; NiceMark, four rounds, no scenario
   below ×0.98. State whether the generated kernels of everything except `niceonly_kernel` are
   identical to main's, and what a wgpu device should expect (lavapipe timings are not
   evidence of speed; say what was and was not measured: no AMD or Apple GPU is available).
5. **Deliver** a branch **`pr/stride-queue-any-plane`** on the fork: one commit on upstream main
   `41b4b405` (re-check that main has not moved) with a one-line CHANGELOG entry in the file's
   style under the unreleased section (short and user-facing: one sentence), ending in the
   placeholder `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`; and a PR body
   `T26B/PR-BODY.md` of at most 700 words plus tables (what, why, soundness, exactness, cost,
   what a wgpu device should expect, not in this PR; no mention of the research program, its
   directories, agents or model names; last line
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`). No PR is opened by you.

If the cube-scoped and the plane-scoped fixes turn out to be two independent changes of real
size, deliver the plane-scoped one (the default on the devices that matter) as the branch and
the other as a second branch `pr/stride-queue-cube-any-plane` or as a written plan: one discrete
change per PR.

## Deliver

`T26B/RESULTS.md` (the reproduction or model, the fix and its completeness argument, the host
check or why not, every exactness run, the cost tables with rounds, clock and power),
`T26B/PR-BODY.md`, raw logs and scripts under `T26B/raw/`. Mark every number measured, derived
or assumed.

## The box and the rules

The instance id comes in the message that carries this brief; `python3 vast.py ssh <id>` (run
from the program directory) prints the ssh command; wait for `/root/READY` (`/root/FAILED`:
clone the fork yourself). One `CARGO_TARGET_DIR` per tree. Never `vast.py create` or `destroy`.
On ivory: writes only under `T26B/` and a worktree `~/projects/nice/.worktrees/t26b-stride-queue`;
check `df -h /` first and keep 3 GB free; no GPU or release builds on ivory (for clippy and host
tests use `CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target`, `nice -n 19`); `/tmp`
is a small tmpfs. Push only to the fork, only new branch names and new commits on them; **never
force-push, never delete a branch; if a push is refused, report it and do not ask anyone to do
it for you**. Never push to `wasabipesto/nice`; do not open, comment on or edit any pull
request; no subagents. Never touch the fleet, the server, `~/fleet-run`, demoux or mayalaran; the
production API is not to be contacted from the box at all. **Commit locally and copy results to
ivory early and often: an outage yesterday cut agents off mid-run.** Hard stop **20:45 UTC** (the box destroys itself at about 21:15 UTC):
write up what you have; an unverified exactness claim is not acceptable, an unfinished NiceMark
round is if you say so. Your final message is a short report for the program's director.
