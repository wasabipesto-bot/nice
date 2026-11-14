# Review brief: the stride walk's survivor queues without full-plane assumptions (2026-11-14)

You are an independent reviewer. Repository `~/projects/nice` on this machine (ivory); upstream
`wasabipesto/nice` = git remote `origin`, fork `wasabipesto-bot/nice` = remote `fork` (fetch both).
The project searches for numbers whose square and cube together use every base-b digit exactly
once. **A missed candidate is the worst possible defect here.** The kernel under review decides
which filter survivors are ever fully checked: a survivor that is queued and never checked, or
overwritten in the queue, is a candidate never examined. You were not involved in writing the
change; take none of its claims on trust.

## The branch

Fork branch **`pr/stride-queue-any-plane`**, one commit `85fe64af` on upstream main `41b4b405`
(650 insertions, 66 deletions in `common/src/cubecl_backend.rs`, one CHANGELOG line). On main,
`niceonly_kernel` (the GPU stride walk for nice-only fields) queues the cross filter's survivors
in shared memory and checks them in waves, in two variants that both assume every plane (Vulkan
subgroup, CUDA warp) is full and laid out linearly along `UNIT_POS_X`: the plane-scoped queue
drains `PLANE_DIM` entries per wave through lanes `UNIT_POS_X % PLANE_DIM`; the cube-scoped queue
has lane 0 publish its plane's total at `UNIT_POS_X / PLANE_DIM`. The commit claims to: (1) take
ranks, counts and takes only from the lanes that run (a ballot form for planes of at most 32
lanes, a scan form for wider ones); (2) reserve each plane's queue space (plane-scoped) or each
iteration's offsets (cube-scoped) through shared atomics taken by each plane's lowest running
lane; (3) add an account (survivors queued minus checked, and the same for their low words)
that the host checks, failing the field on a mismatch; (4) add tests with test-only cube sizes
and faults; (5) be faster on CUDA (×1.14 / ×1.26 on b54 stride fields) because ballots replace
scans. The author's write-up: `T26B/RESULTS.md`, `T26B/PR-BODY.md`, raw material under `T26B/raw/`
in `~/projects/nice/scratchpad/2026-10-research-program/`. Two fixes of the same class were
reviewed in the last two days: `CKF/REVIEW.md` and `T26/REVIEW.md` (read them for what is already
established about CubeCL's plane operations per backend, then verify what you rely on).

## Questions

1. **Complete and non-overlapping by construction?** For every population of a plane (any subset
   of lanes running, lane 0 present or not, any layout of planes within the cube, a plane that
   runs out of ranges early, nothing queued) in both queue variants and both forms: every queued
   survivor is checked exactly once; no two planes' queue regions overlap and none runs past the
   shared arrays (check the reservation arithmetic against the arrays' sizes for every cube size
   and plane width the code accepts, including the "two slots per running lane" bound: can a
   plane's queue ever hold more than it reserved?); the loops terminate; control flow that must
   be plane-uniform (or cube-uniform, around `sync_cube`) is. Write your own model of both
   variants and try to break it. Pay special attention to the cube-scoped variant's two
   alternating shared words and the ordering argument around its two barriers: can a lane read a
   word before every plane has added to it, or after the next iteration reset it?
2. **Per backend:** what `plane_ballot`, `plane_exclusive_sum`, `plane_sum`, `plane_broadcast`
   / shuffle, `plane_all`, `sync_plane`, `sync_cube` and the atomics do with inactive lanes on
   CUDA, WGSL through naga, SPIR-V and Metal (CubeCL sources in
   `~/.cargo/registry/src/*/cubecl-*`). Which form does each production device take (RTX cards on
   CUDA; an RX 9070 XT on wgpu SPIR-V with 64-lane planes; an Apple M4 on Metal), and is the
   choice made from what the device reports at run time? What does correctness rest on in each?
3. **Behaviour on full planes** (every production launch today): are the survivors checked, the
   hits and the reported counts identical to main's? Does anything downstream depend on the
   order survivors are checked in?
4. **The account and the host check:** is it computed from what was really queued and really
   checked (not from one quantity twice)? Where is it read, on every path that runs this kernel
   (the client's route, benchmark, retries)? Can it raise a false alarm on a correct run (wrap,
   output overflow, a field with no survivors, early exit)? Is a mismatch always an error that
   prevents a result? What wrong runs would pass it? Does the new use of the count buffer
   collide with anything that already reads it?
5. **The tests:** do the partly-filled-plane tests fail on main and pass on the branch (the box
   below lets you run them on CUDA and on lavapipe with both compilers); can the test-only
   knobs (cube size, forced form, faults) leak into a production build or be set by a user's
   environment in a way that weakens the search; does CI (lavapipe with both compilers, Metal;
   see `.github/workflows/gpu-parity.yml`) run them?
6. **The speed claim and the cost claim.** The numbers were taken at a 130 W power cap (the
   host's setting). Check them against `T26B/raw/` and, time allowing, repeat one interleaved
   pair on the box (main against the branch, `NICE_JOIN_ROUTE=stride`, the author's script and
   field list; card idle before each run, no builds while timing). Is "the scan form costs
   about 0.6 %" measured the way a 64-lane device would run it? One NiceMark scenario had a
   round at ×0.94 (median ×1.02): is the body's account of that fair? Is the claim "every other
   kernel's generated code is identical to main's" established by a sound method?
7. **Scope:** is this one discrete change (both queue variants, one host check), or should it be
   two PRs? Does it depend on anything in open PRs #251 (`pr/check-d`) or #260
   (`pr/top-slot-any-plane`)? (It must stand alone on main; the body mentions `top_slot`'s
   ballot form "as `top_slot`", which on main does not have one: flag wording that only makes
   sense after #260.) Would it conflict with them on merge?
8. **The PR body against the evidence**, and whether it mentions the research program, its
   directories, agents or a model name (it must not); whether it says what a wgpu device should
   expect and what was not measured; whether the changelog line is accurate, one sentence,
   user-facing.

## Method and limits

Reading, your own models (under `T26B/review-model/`), host-side checks from a worktree
`~/projects/nice/.worktrees/review-t26b` (detached at `85fe64af`) with
`CARGO_TARGET_DIR=~/projects/nice/.worktrees/rebase-1112/target` (shared with another reviewer:
cargo's lock makes that safe but slow; `touch` sources before a build you rely on); `nice -n 19`,
two threads at most on ivory; keep 5 GB free; `/tmp` is a small tmpfs. Rust 1.100.0 is what main
pins. **A rented box is yours until 20:45 UTC** (Vast instance 60665092, RTX 3080, 20 cores; it
destroys itself at about 21:15 UTC): from the program directory `python3 vast.py ssh 60665092`
prints the ssh command (add `-o StrictHostKeyChecking=accept-new`, redirect stdin from
/dev/null in scripted calls). The author's trees and builds are on it (see `T26B/RESULTS.md`
for paths); build your own checkouts of `85fe64af` and of main in new directories with their
own `CARGO_TARGET_DIR` if you want results that do not rest on the author's binaries. Never
`vast.py create` or `destroy`. Do not change the branch, do not push, do not open, comment on
or edit any pull request, do not start subagents, do not touch the fleet, the server, demoux or
mayalaran, and do not contact the production API from the box or from ivory (NiceMark pings it
for a latency figure: if you run NiceMark, point its API address at a closed local port or do
not run it).

## Deliver

`T26B/REVIEW.md`: the verdict first (open as is / open after the listed fixes / do not open),
findings by severity with file and line, how you know, and the fix you suggest; then what you
verified and how; then what could not be verified without other hardware. Hard stop **20:45
UTC**. Your final message is a short summary for the program's director.
