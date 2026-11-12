# PRP brief: two small PR branches from today's window, with their CUDA numbers (2026-11-12)

You are an engineer on the nice research program (repo `~/projects/nice` on this machine, ivory;
upstream `wasabipesto/nice`, fork `wasabipesto-bot/nice`). Read first: `../README.md` (rails and
the PR rules), `../EXPERIMENTS.md` entries **N17.1** and **N16.1** (today's measurements; the
source of everything below), `../B64/PR-BODY.md` and `../B64/PR-RESULTS.md` (the shape of a PR
body and its measurements in this project: the last one the maintainer merged), `../L48/RESULTS.md`
(how NiceMark and the interleaved A/B protocol are run), and the module docs at the top of
`common/src/cubecl_join.rs` on upstream main.

## Why

About 81 % of the nice-only search runs on one AMD RX 9070 XT (wgpu on Vulkan, CubeCL's SPIR-V
compiler). In a window on that card today two changes measured ≥ ×1.05 there, each small and
discrete. The maintainer's bar is one discrete change per PR, a measured gain of ×1.05 for a
simple change, no benchmark scenario below ×0.98, exact counts. The card cannot be measured
again today; what is missing is each change as a clean branch on upstream main, its regression
numbers on NVIDIA (CUDA), its tests, and a PR body. **You prepare both branches; you do not open
PRs** (an independent reviewer and the director follow).

## Change 1: a smaller shared survivor stage (branch `pr/join-survivor-stage-512`)

`SURV_SH_CAP` 1024 → 512 and `SURV_FLUSH` 512 → 256 in `common/src/cubecl_join.rs` (the join
kernel's shared stage of prefilter survivors: two arrays of `SURV_SH_CAP` words per work group,
written out once `SURV_FLUSH` entries are in it). Read every use and every doc comment that states
the old sizes or reasons about them (the stage's overflow path, the per-batch flush check added
in #249, L51's note that no pair went past a full stage at b60/b62) and make sure the smaller
stage is still correct by construction: a pair that finds the stage full must take the direct
path to the list, never be dropped. Update the docs to the new numbers and say why the size is
what it is: on AMD's RDNA4 the work group's shared memory (18.9 KiB with a 1,024-entry stage)
limits how many work groups run at once, and 4 KiB less raises that by a third; on NVIDIA the
kernel is register-bound and the size does not matter.

Measured today (tree = main's join kernel of 11-09 + #250's top kernel, the two sizes switched
by an environment variable that compiles the same kernel a constant change would):
- RX 9070 XT (RADV, 304 W cap, three rotated rounds, counts identical): **×1.055, ×1.056, ×1.060
  at b62 1e17; ×1.057, ×1.056, ×1.056 at b60 1e16**; base 64 1e17 with a 256-entry stage ×1.062
  (one round; 512 was not run alone there); a one-round screen at b60 gave 512 / 256 / 128 entries
  ×1.063 / ×1.048 / ×1.054.
- RTX 3080 (CUDA, 280 W): ×0.999 at b60 1e16, ×0.994 at b62 1e17 (one round each).
Not measured: an Apple GPU.

## Change 2: the prefilter's digits by shifts at power-of-two bases (branch `pr/join-prefilter-shift-pow2`)

In `walk_pf_lean` (the join kernel's fixed-point middle-digit prefilter) the two leading base-b
digits of a 32-bit fraction f are taken as `mul_hi(f, base)` and `mul_hi(f * base, base)`, for the
square's and the cube's fraction. At b = 2^lg these are bit fields: `f >> (32 - lg)` and
`(f << lg) >> (32 - lg)`, an exact identity. Make the kernel use the shift form when the comptime
base is a power of two (base 64 is the only such base the join takes) and the multiply form
otherwise; nothing changes at any other base. The experiment commit is fork
`exp/n20-mul-probe` f049415 (there behind a switch; in the PR it is unconditional for
power-of-two bases). Check whether the CPU join's prefilter (`cpu_join.rs`, #248) needs the same
(a native compiler folds a multiply by a constant power of two; say what you find, change it
only if it measurably helps). Add a host test of the identity over the edge values and a random
sample, and make sure a device test covers the b64 prefilter (the b64 window of `check_all`
does; say what it asserts).

Measured today: RX 9070 XT, b64 1e17, **150.16 → 142.90 s, ×1.051, counts identical** (one
round; base runs of the same field spread 0.0–0.8 % that hour). Earlier estimate for NVIDIA
(from SASS): ×1.01–1.02.

## What to do on the box

Instance id and ssh come in the message that carries this brief; wait for `/root/READY`
(`/root/FAILED`: clone the fork yourself). CUDA builds `--features gpu,cubecl-cuda`; lavapipe
(`mesa-vulkan-drivers`) for the wgpu device tests with both compilers
(`--features gpu,cubecl` and `--features gpu,cubecl-spirv`). One target directory per tree.

1. Three trees from upstream main (give its commit id in your results): **M** = main, **S** =
   change 1, **F** = change 2. Each branch is exactly one commit on main, with a one-line
   changelog entry in the file's existing style under the unreleased section, ending in a PR
   link placeholder `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))` that the director
   fills when the PR is opened. No other files touched; `cargo fmt --all --check` and
   `cargo clippy -p nice_common --all-targets --features gpu,cubecl-spirv -- -D warnings` clean
   with the pinned toolchain.
2. **Exactness:** the dense compare against the CPU join (`NICE_TEST_JOIN_DENSE*`,
   `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field`) for S at b60 1e16 and b62 1e17 and
   for F at b64 1e16 and 1e17, on CUDA; the full device test suites on CUDA and on lavapipe
   (both compilers) for both branches; for S also one run that forces the stage to overflow
   (a dense field or a temporarily tiny stage in a throwaway build) to show the direct path
   keeps the counts.
3. **Speed on CUDA** (record the card's power cap and clock per run, and each process's
   join-kernel register variant as earlier work did): same box, interleaved, three rounds, M
   against S and M against F at b62 1e17, b60 1e16, b64 1e17 and b64 1e16 (production-shaped
   fields; use the starts in `../N16/raw/scripts/env.sh` plus a b64 1e16 start from
   `../B64/RESULTS.md`), then **NiceMark, four rounds**, M against each. The bar: no scenario
   below ×0.98. F must be identical code at non-power-of-two bases (say how you checked: the
   generated kernel source or its hash).
4. **PR bodies** `PRP/PR-BODY-stage.md` and `PRP/PR-BODY-shift.md` in the style of
   `../B64/PR-BODY.md`: what, why, soundness, measurements (yours on CUDA, and the RX 9070 XT's
   from above, stated as measured on that card with the sizes switched by an environment variable
   on the same kernel, or with the experiment commit for change 2), exactness, a short "Not in
   this PR". No mention of the research program, this directory, agents or fork-only write-ups;
   no model names. Say plainly what was measured in one round only, and that no Apple GPU was
   measured.

## Deliver

`PRP/RESULTS.md` (commit ids, every table with rounds, clock and power, exactness runs, what
you checked by reading), the two PR bodies, raw logs and scripts under `PRP/raw/`; the two
branches pushed to the fork under the names above. Mark every number measured, derived or
assumed.

## Rules

Vast only through the instance you are given: never `vast.py create` or `destroy`. ivory writes
only under `PRP/` and worktrees `~/projects/nice/.worktrees/prp-stage` and `prp-shift`; no GPU
builds on ivory (about 6 GB free; `/tmp` is a small tmpfs). Push only to the fork, only the two
new branch names and new commits on them; **never force-push, never delete a branch; if a push
is refused, report it and do not ask anyone to do it for you**. Never push to
`wasabipesto/nice`; no PRs; no subagents. Never touch the fleet, the server, `~/fleet-run`,
demoux or mayalaran. Hard stop **22:45 UTC**: write up what you have; an unfinished NiceMark
round is fine if you say so, an unverified exactness claim is not.
