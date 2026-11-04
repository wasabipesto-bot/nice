# L38 brief: one 32-byte record per top for the join's batch loads (2026-11-04)

## Why

L37's ablation of `join_kernel` on main 6f060a9 (`L37/RESULTS.md` §1, RTX 3080 at 150 W, b62
1e17, 129.7 s per field, join 72.4 s): gathering each batch's tops into shared memory costs
18.6 s = 26 % of the join = 14 % of the field. Reading `tl` costs 0.35 s and gathering `top_m`
2.5 s; gathering `top_r` and `top_x` costs 15.7 s. The top arrays are separate (`top_p`, `top_m`,
`top_r`, `top_x`, two u32 each per top, plus `top_b`), indexed by the top id `t = tl[...]`, which
is random per lane. Each lane therefore touches three or four different 32-byte sectors per top
for 24 bytes of payload; every top is loaded once per bucket it probes (`nroots` = 2 at b62,
7.6e10 top loads per field) → ~15 TB of L2 traffic per field. One 32-byte record per top (8 u32:
p lo/hi, m lo/hi, r lo/hi, x lo/hi) makes that one sector per top. Estimated saving 12–16 s per
b62 1e17 field, 9–12 %; at b60 1e16 the same share (base 5.7 of 15.2 s).

## What to do, in order

0. Box `nice-research-l38-toprec` (RTX 3080, 6 h TTL, instance 59082237): from
   `~/projects/nice/scratchpad/2026-10-research-program` run `python3 vast.py ssh 59082237`; wait for
   `/root/READY`. The clone at /root/nice is of the fork; add upstream
   `https://github.com/wasabipesto/nice.git` and branch from upstream main 6f060a9. All builds and
   runs on the box; nothing built on ivory. Never `vast.py create`/`destroy`.
1. Map every reader and writer of `top_p`/`top_m`/`top_r`/`top_x` in `common/src/cubecl_join.rs`
   (`top_kernel`, `top_fd_kernel` and its clipped launch, `join_kernel`'s batch load, `check_kernel`,
   the device test from #240 that compares both top kernels' outputs, `JoinDevice`'s buffers and
   `join_plan.rs`'s footprint). Replace the four arrays by one `top_rec` of 8 u32 per top (same
   total bytes; `top_b` stays as it is for the fill kernel). In the join's batch load each lane
   reads its top's 8 words from one 32-byte-aligned record; try the plain 8 scalar loads first
   (same sector, L1 serves the rest), and `Line<u32>` with line size 4 (two 16-byte loads) if
   CubeCL compiles it on CUDA and wgpu. Keep the shared `t_lo/t_hi/t_rlo/t_rhi/t_dm/t_id` layout
   unchanged downstream so nothing else moves. Branch `pr/join-top-record` on the fork.
2. Exactness (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54); #240's
   `cubecl_cuda_top_fd_matches_the_top_kernel` (adapted to the record); #235's certificate test;
   both dense fields; whole b42; `NICE_TEST_JOIN_COMPARE=1` at 1e14 for b57/60/62/64 (counts in
   `L37/RESULTS.md` / #239's body); whole-field counts = main's exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Lavapipe: parity
   with naga and the direct SPIR-V compiler; the WGSL lint as the workflow runs it; fmt; clippy
   default and `nice_client/gpu`.
3. A/B vs main 6f060a9, same box, interleaved, medians, 3 rounds: b62 1e17 (1 field), b62 1e16,
   b60 1e16, b64 1e16 (2 fields each), the 1e14 set (b60/b62/b64), NiceMark (`--benchmark-secs
   150`, 2 rounds). Scripts: `L37/raw/scripts/`, `L34/raw/scripts/`. Report seconds, spreads, ratios,
   SM clock, power cap; ptxas registers/spills for `join_kernel`, `top_kernel`, `top_fd_kernel`,
   `check_kernel`.
4. If ≥ 5 % at b62 1e17 and b60 1e16 with no NiceMark scenario below ×0.98: squash to one commit
   on main with a CHANGELOG line under "## Unreleased" ending `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`,
   push, and write `L38/PR-BODY.md` in the style of `L34/PR-BODY.md` (what / why with the
   ablation numbers / soundness: same values, same order, only the layout changes / measurements /
   exactness / registers / not in this PR). No mention of the research program, scratchpad,
   briefs, ledgers or fork-only write-ups in the body. Do not open the PR.
5. Write `L38/RESULTS.md`, raw logs and scripts to `L38/raw/`. Update nothing else in the
   scratchpad.

## Rules

- Vast only through `vast.py`, never create/destroy (say when the box can go). On ivory: read
  the repo/scratchpad, write only under `scratchpad/2026-10-research-program/L38/`, push/fetch
  git. Nothing else under `~/projects/nice` outside `.worktrees/` is touched; no live fleet, no
  `~/fleet-run`, no PRs, no subagents.
- If exactness fails twice or the prototype is slower, stop and report the measurements and why.
- Hard stop 13:30 UTC (the box self-destroys ~15:05 UTC). Report whatever is complete.
