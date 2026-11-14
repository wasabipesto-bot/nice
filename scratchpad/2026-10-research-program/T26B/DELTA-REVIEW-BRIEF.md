# Follow-up review: the fix of #263's CI failure, and how far the compiler defect behind it reaches (2026-11-14, 22:45 UTC)

You reviewed `pr/stride-queue-any-plane` at `85fe64af` earlier today (`T26B/REVIEW.md`). The PR
(#263) was opened; its first CI run failed the new test on lavapipe (Mesa 26.0.8) with the
SPIR-V compiler. The author traced it and pushed a fix. Read `T26B/CI-FAIL.md` (the author's
account; raw data under `T26B/raw/ci/`: `dump/` holds CubeCL's compilation logs with the SPIR-V,
WGSL and CUDA modules, `box/logs` the runs, `add_mini.py` the minimal kernel, `stores.py` the
script that lists stores in a dumped module) and the CI log `T26B/ci-fail/`. The branch is now
`165192ba` on the fork (your reviewed commit, then the changelog number with a test comment, a
merge of upstream main `54d0aac4`, a one-word comment fix, and the fix).

The author's claim: cubecl-spirv (CubeCL 0.10's direct SPIR-V compiler, which runs cubecl-opt's
pass pipeline) merged the four `store(0)` at constant indices 0–3 of a `SharedMemory<Atomic<u32>>`
into one store to word 0, so the account words started with stale workgroup memory; no survivor
was lost; the fix clears the words at a runtime index. A minimal kernel shows one
`OpAtomicStore` for four stores of the same value and four for four different values. **Which
pass does it, and what exactly it merges, is not established.** That is the important gap: the
project's main production device (an RX 9070 XT on RADV) runs every kernel through this
compiler.

## Questions, in order of importance

1. **Pin the defect down in CubeCL's source** (`~/.cargo/registry/src/*/cubecl-opt-0.10.0`,
   `cubecl-spirv-0.10.0`, `cubecl-ir-*`, `cubecl-core-*`): which pass removes the stores, and
   under exactly what conditions. State the affected class precisely: atomic stores only, or
   plain stores to shared or global arrays as well? Only equal values at different constant
   indices of one array, or across arrays? Other operations with the same shape (`fetch_add`
   of one value at different constant indices, `load`s, `atomic exchange`, plain writes
   `a[0] = x; a[1] = x;`)? Does a runtime index always protect an operation, and is the fix's
   loop safe from the same pass after unrolling or other transformations (check the dumped
   module of `165192ba`)? Why did the minimal kernel's device output read `[7, 7, 0, 0]` with a
   single store in the module (word 1 = 7)? Verify your reading of the source with small
   kernels on the box where the source leaves doubt.
2. **Is anything else exposed?** With the class in hand, check every kernel this compiler
   builds for the project, by dumped modules, not by source alone: on upstream main `54d0aac4`
   (`common/src/cubecl_join.rs`: top, top-FD, join, check kernels; `cubecl_backend.rs`: detailed,
   niceonly in all its variants, smoke); on the open PR branches fork `pr/check-d` (`1f41d649`),
   `pr/top-slot-any-plane` (`ec6a43a1`), `pr/join-prefilter-shift-pow2`, `pr/join-survivor-stage-512`,
   `pr/join-prefilter-popcount-spirv` (their kernels differ from main's only where their diffs
   say); and `165192ba` itself. For each kernel: the list of source-level stores and atomic
   operations of the affected class, and whether the module has every one. A kernel on main
   that loses an operation is a production finding: report it at once in your final message,
   with what it could cause on the RX 9070 XT (lost candidates, wrong counters, or nothing).
   Do not fix anything on main or on other branches.
3. **The fix (`git diff bec91fdd 165192ba`)**: complete for every cube size (including cubes of
   fewer than four units) and both queues; ordered before the first use of each word by a cube
   barrier; no other place in this kernel relies on a constant-index store of the affected
   class (the in-loop clear of the alternating word, the report). Does the account now start
   at zero by construction on every backend? Re-run on the box in the Ubuntu 26.04 chroot the
   author built (`/srv/r26`, see `T26B/CI-FAIL.md` and `raw/ci/chroot_setup*.sh`): the new test
   and the fault tests with both compilers, CI's SPIR-V suite at least three times.
4. **The PR body's status paragraph** (top of `T26B/PR-BODY.md`) against the evidence: is every
   sentence supported? In particular "an investigation build compared every run's survivors
   with the host mirror: all exact" and "the same would have made stride-walk fields fail
   spuriously on any Vulkan device with the SPIR-V build".
5. Draft, in `T26B/CUBECL-ISSUE-DRAFT.md`, a minimal upstream bug report for CubeCL (the kernel,
   the two modules, the pass, versions). It will not be filed by you or by the program; it is
   for the maintainer of this repository to use if they wish. No project-internal references
   in it.

## Method and limits

The box: Vast instance **60696216** (RTX 3080, 48 threads; `python3 vast.py ssh 60696216` from the
program directory; it destroys itself at about 00:00 UTC). The author's trees, binaries and the
26.04 chroot are on it; make your own checkouts and target directories for what you rely on.
Never `vast.py create` or `destroy`. On ivory: reading, `nice -n 19`, two threads, keep 5 GB
free. Do not change any branch, do not push, do not open, comment on or edit any pull request,
do not file anything upstream, do not start subagents, do not touch the fleet, the server,
demoux or mayalaran, no contact with the production API. Copy what you produce on the box to
ivory (`T26B/review2-box/`) before 23:40 UTC.

## Deliver

`T26B/REVIEW2.md`: the verdict on the fix first; then the defect's exact class with the source
lines; then the exposure table per kernel and branch; then findings; then what you could not
verify. Hard stop **23:45 UTC**. Your final message is a short summary for the program's
director: verdict, the class, and whether any kernel on main or in an open PR is exposed.
