# L37 brief: the join kernel after the stack — breakdown by ablation, walk compaction, shuffle LUT (2026-11-04)

## Context

main 6f060a9 now carries #235, #236, #237, #239 and #240 (= `exp/join-all5`, ×1.88 at b62 1e17
over the previous main). Profile after them (L36.1, 150 W card): top 30 %, **join 56 %**, check
8 %, other 6 % at b62 1e17; b60 1e16 join 60 %. The phase timers cannot split the join. From the
L1.7 fit and L34: after #239 the AND phase (real lanes + padding + per-top cost) is perhaps 40–45 %
of the join and is bound by shared-memory wavefronts (the transposed gathers have ~2-way bank
conflicts, L34.1); survivor handling (the set-bit walk with the prefilter in it, the stage, the
flush) is perhaps 40 %, at ~21 ps per AND survivor ≈ 130 lane-instructions per survivor; wave
padding the rest.

Two hypotheses to test, in this order:

**H1 (walk compaction).** The walk is divergence-bound. AND survivors are ~4 % of pairs, so per
32-top chunk an entry slot has Poisson(~1.3) set bits; the warp runs `while plane_any(x != 0)`
for max-over-lanes rounds (≈ 4–5) while only ~1.3/4.5 ≈ 30 % of lanes do useful work in a round,
and each round costs ~40 instructions (trailing zeros, residue range test, `walk_pf` with its
multiplies and constant mods, the stage atomic). Compacting the (lane, bit) pairs across the warp
before testing them — warp prefix sum of popcounts via shuffles, each lane then takes item r·32 +
lane: find the owning lane by a 5-step binary search over the prefix sums (shuffles), fetch that
lane's `x`, `rr`, `ac`, `pc`, `vv` by shuffle, select its n-th set bit (popcount binary search,
no PDEP on GPU), then run the residue test and `walk_pf` with every lane busy — should cut the
survivor path 2× or more. No shared memory needed. Exactness: the same pairs reach the stage; the
order within the stage may differ (atomic order, as today). Expected: survivor handling ~20 % of
the field → 8–10 % if the 2× holds. Kill: < 5 % at b62 1e17 and b60 1e16, or any NiceMark
scenario < ×0.98.

**H2 (shuffle register LUT for the AND, L7 sweep 3 B1).** Replace the shared `t_tr` gathers by
warp shuffles: lane l holds `R_lo[c] = t_tr[c·64 + l]` and `R_hi[c] = t_tr[c·64 + 32 + l]` for
the chunks of a group (loaded once per batch from the shared table, conflict-free), then an
entry's digit d < 32 reads `shfl(R_lo[c], d)` and d ≥ 32 reads `shfl(R_hi[c], d − 32)`. Two loops
per entry (its low digits, then its high digits) so each digit costs one shuffle, not two plus a
select; the warp runs max-over-lanes iterations of each loop (≈ 9–10 each for 12 digits split
binomially, against 24 conflicted LDS wavefronts today). Keep the shared `t_tr` for the build and
the register load (so this does not remove #239's 2 KiB; note it). Kill: < 3 % on the AND-only
ablation or any field slower.

## What to do, in order

0. Box `nice-research-l37-shuffle` (RTX 3080, 7 h TTL, instance 59063596): from
   `~/projects/nice/scratchpad/2026-10-research-program` run `python3 vast.py ssh 59063596`; wait for
   `/root/READY`. The clone at /root/nice is of the fork; add upstream
   `https://github.com/wasabipesto/nice.git` and work from upstream main 6f060a9. All builds and
   runs on the box; nothing built on ivory. Never `vast.py create`/`destroy`. Push work to the fork
   as `exp/join-walk-compact` (H1) and `exp/join-shfl-lut` (H2), each switchable by an env var read
   on the host → comptime flag, so one binary does A/B.
1. **Breakdown of `join_kernel` on main by ablation** at b62 1e17 (1 field) and b60 1e16 (2 fields),
   using `cubecl_cuda_join_throughput_fixed_fields` (fixed starts as in `L30/COMBINED.md` and
   `L34/raw/scripts/`), 3 interleaved rounds each, with env→comptime switches: (a) AND only — compute
   `pm` but force the walk to see 0 (keep a cheap checksum of `pm` alive); (b) walk without
   `walk_pf` (count residue-passing pairs, stage nothing); (c) full (baseline); (d) `TRANSPOSE_MIN`
   huge (per-top AND) to re-measure #239's share on main. Also measure the walk's lane utilisation:
   add a device counter of rounds (`plane_any` iterations) and of useful lane-rounds (lanes with
   `x != 0`) per chunk, or derive it from a CPU counting pass over the AND pass bits of a sample of
   buckets. Write the breakdown (seconds and % of the join and of the field) before touching H1.
2. **H1 prototype** behind `NICE_EXP_JOIN_COMPACT=1`. Exactness first: join parity against the CPU
   reference (incl. b50/b54), both dense fields, whole b42, 1e14 COMPARE counts at b57/60/62/64 (=
   main's: b57 4,850,227,888 / 268,123,373; b60 2,694,700,282 / 180,517,288; b62 1,439,469,648 /
   88,159,810; b64 5,702,041,796 / 346,647,759), whole-field counts = main's exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Then A/B vs main,
   interleaved, 3 rounds: b62 1e17, b62 1e16, b60 1e16, b64 1e16, the 1e14 set, NiceMark
   (`--benchmark-secs 150`, 2 rounds). Registers and occupancy from ptxas as in L34/L35. Lavapipe:
   parity with naga and the direct SPIR-V compiler (the walk uses plane ops: check `plane_any`,
   shuffles are `plane_shuffle`/`plane_broadcast` in CubeCL — confirm what the wgpu path supports
   and that the kernel still compiles there; if shuffles are CUDA-only, gate H1 like `walk_sync`),
   WGSL lint as the workflow runs it.
3. **H2 prototype** behind `NICE_EXP_JOIN_SHFL=1` if ≥ 2.5 h remain before the hard stop: same
   exactness list, A/B on the same fields, and the AND-only ablation with and without it.
4. Write `L37/RESULTS.md` (breakdown table, lane utilisation, H1 and H2 numbers, exactness,
   registers, what did not work and why) and copy raw logs/scripts to `L37/raw/`. Update nothing
   else in the scratchpad; no PRs.

## Rules

- Vast only through `vast.py`, never create/destroy (say when the box can go). On ivory: read
  the repo/scratchpad, write only under `scratchpad/2026-10-research-program/L37/`, push/fetch
  git. Nothing else under `~/projects/nice` outside `.worktrees/` is touched; no live fleet, no
  `~/fleet-run`, no PRs, no subagents.
- If exactness fails twice or a prototype is slower, stop and report the measurements and why.
- Hard stop 11:45 UTC (the box self-destroys ~12:45 UTC). Report whatever is complete.
