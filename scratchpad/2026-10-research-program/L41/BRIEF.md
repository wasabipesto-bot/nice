# L41 brief: the prefilter's arithmetic and the per-wave base, scoped from SASS (2026-11-05, evening; no GPU)

## Why

After #239–#241 the join is ~55 % of a b62 1e17 field. L37's ablation (`L37/RESULTS.md` §1, with
the caveat from L39.1 that stripped-kernel costs are upper bounds for latency-bound parts):
survivor path 54 % of the join (walk 16 %, `walk_pf` 33 %, stage 5 %) at 25 % lane utilisation;
the per-wave base 41 % (of which the top-batch gather, now fixed by #241, was 26 %; entry loads
and prefilter terms 14 %, mostly latency per L39; transposed copy, barriers, work items, atomics
~1 %). L40 showed the walk's divergence can be cut (rounds ×0.65) but the body grew 110 → 139
SASS and small batches lost. The unexplored parts are (1) the round body's own instruction count,
chiefly `walk_pf` (~52 SASS) and the per-round bookkeeping, and (2) what the per-wave base does
per thread besides loads once the top gather is gone.

## What to do (reading and arithmetic only; no box, no builds on ivory)

1. Unpack `L37/raw/box/sass.tgz` (it holds the join kernel's SASS for the ablation modes on main)
   and read `join_kernel` and `walk_pf` on upstream main 6f060a9 (`common/src/cubecl_join.rs`;
   `git show origin/main:common/src/cubecl_join.rs` in /home/claude/projects/nice after
   `git fetch origin main`). Also read #241's diff (fork `pr/join-top-record` af21136) so the base
   you describe is post-#241.
2. Produce an instruction-level breakdown of one walk round as compiled: the pop/select of the
   next bit, the residue test, each term of `walk_pf` (the mul-adds, the constant `mod b^mid`
   and `mod base` / `div base` as mul-shift sequences, the 64-bit mask shifts on 32-bit
   hardware, the compares), the stage append (atomic, two shared stores), the `plane_any`
   loop control, `sync_plane`. Count SASS instructions per part and mark which are on the
   critical path of divergent rounds.
3. For `walk_pf`, propose concrete cheaper formulations and estimate instruction savings:
   e.g. precomputing per-top and per-entry partial products so the pair needs one 32-bit
   multiply-add per power; replacing `% base` and `/ base` on x2/x3 with a single mul-shift and
   a subtract; building the two `1u64 << g` masks via a 32-entry lookup split or a `select`
   on the half; testing distinctness with popcounts instead of two mask ANDs; dropping work
   that the b-specific comptime shape makes constant. Check each against the CPU
   `CpuJoin::prefilter` derivation for exactness; say which ones are exact by construction
   and which need a parity test. Also check whether the residue test (which L37 showed never
   rejects in production but does reject at clipped edges, L40) can be folded into a cheaper
   form or moved after `walk_pf` (cheaper test first, if it rejects more per instruction).
4. Per-wave base: list what every thread does per wave besides the entry loads (the key-level
   `t2/t3/sigma/rho` arithmetic for `ac`/`pc`, the mask ORs, `vv`, the transposed-AND group
   bookkeeping, the per-chunk stage check and barriers, the work-item loop) with SASS counts,
   and say what a wave costs in instructions against its useful AND work. Identify anything
   recomputed per wave that could be computed once per entry in the bucket kernel (which runs
   once per (slot, class) and already writes `ext_q`), or once per work item.
5. Write `L41/SCOPING.md`: the breakdown tables, the candidate changes ranked by estimated
   % of the join (be explicit that these are instruction-count estimates, not measurements),
   their exactness status, and a prototype plan for a GPU day (what to build first, what to
   measure, kill criteria: a change is worth a prototype only if it plausibly removes ≥ 10 %
   of the join's instructions, ≈ 5 % of the field). Budget ~2.5 h. Update nothing else in the
   scratchpad; push nothing; no subagents.
