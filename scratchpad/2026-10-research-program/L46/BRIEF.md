# L46 brief: a static bucket order for the top layer — no scan, no fill, no `tl` (2026-11-07)

## Why (L44 roadmap item 1; L45 measured it)

After #241 and #246, `top_scan_kernel` + `top_fill_kernel` cost 9.7 % of a b62 1e17 field and
9.0 % at b60 1e16 (`L45/RESULTS.md` §A: fill 8.6 %, 0.25 ns per kept top — two returning global
atomics and two scattered stores per kept top), plus `tl`'s indirection in the join's batch load
and the per-top `bucket_cnt` atomics in the top kernels. Ceiling if all of it vanishes: ×1.107 /
×1.099; the roadmap's estimate is ×1.05–1.12.

## The idea

A kept top's bucket is `(slot, key, cls)` with `key = P0 mod b` (key level only) and `cls =
(roots[r] + m1 − pc) mod m1` for each digit-sum root r, where `pc = (c0 + v) mod m1`, `c0 = (P0 mod
(b−1))·pdiv_m1 mod m1` is a property of the prefix and `v` is the slot's partition value. So if the
host sorts each slice's top layer `tlay` once by `(key, c0)`, every slot sees the same contiguous
groups of prefixes, with group `(key, c0)` feeding, for slot v, the buckets `(key, (roots[r] −
(c0 + v)) mod m1)` for r in roots. Then:

- the top kernels (`top_fd_kernel`, `top_kernel`'s clipped launch) append each kept top's record
  into **its group's segment of the per-slot record buffer** (segment offsets = prefix sums of
  group sizes, computed once per slice on the host; one append counter per (slot, group), warp-
  aggregated — consecutive prefixes in a warp share a group once the layer is sorted);
- `top_scan_kernel`, `top_fill_kernel`, `tl`, `top_b`, `bucket_cnt` and `cursor` go away;
- a join work item `(slot, key, cls)` reads its tops from the `nroots` group segments `(key,
  (roots[r] − cls − v) mod m1)` — contiguous record ranges, read **sequentially and coalesced**
  (no `tl` gather); the top batch loop iterates over up to `nroots` segments (2 at b62, 8 at b64);
- the plan's footprint drops `tl`/`top_b`/`cursor` and adds the small per-group offset/count
  arrays; the record buffer's capacity per slot stays the layer size.

Exactness: the set of tops per bucket is unchanged; only the order within a bucket changes
(already atomic order today). Every count must match the exact tree to the digit.

## What to do, in order

0. Box: instance 59529576 (`nice-research-l46-static`, RTX 3080, 7 h TTL): `python3 vast.py ssh
   59529576` from this directory; wait for `/root/READY`. Base: fork `pr/join-lean-prefilter`
   f3fb390 (= main 6f060a9 + #241 + #246). Branch `exp/join-static-buckets` on the fork (→
   `pr/join-static-buckets` when PR-ready). All builds and runs on the box; nothing on ivory.
   Never `vast.py create`/`destroy`. Another agent works on the FD top kernel's arithmetic (L48)
   on another box; you will both touch `top_fd_kernel`'s append path — keep your append change
   minimal and self-contained so the two rebase cleanly.
1. Read the host side: `tlay` construction (`FieldSetup`, `build_tlay` or equivalent), `launch_batch`
   (the kernel sequence and bindings), `top_scan_kernel`/`top_fill_kernel`, the work-item layout
   (`work[4*wi..]`: slot, bx, ts, te), the join's `tl[tc + u]` batch load (now reading `top_rec`),
   `join_plan.rs`'s footprint and slot/slice bounds, the device test comparing both top kernels,
   and the CPU join's bucketing (`cpu_join.rs` `list`/`scan`) for the ground truth of which tops
   go where. Write `L46/DESIGN.md` (≤ 2 pages): data layout, host sort and offsets, kernel append,
   work items with `nroots` ranges, what is deleted, the exactness argument, the test plan. Spend
   ≤ 1 h.
2. Implement. Keep `top_scan`/`top_fill` code only if something else needs them (say what); the
   clipped-block launch must append into the same segments. Codegen gate: ptxas registers and
   spills for the join and top kernels (join ≤ 48, no spills in the NVRTC compile — see L45 §
   spills: the runtime compile is the one that matters), direct-SPIR-V block counts.
3. Exactness (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54, the b57
   frontier); #240's device test adapted (both top kernels write the same segments); #235's
   certificate test; both dense fields; whole b42; `NICE_TEST_JOIN_COMPARE=1` at 1e14 for
   b57/60/62/64 (counts in `L38/PR-BODY.md`); whole-field counts = the exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Lavapipe: the
   `cubecl_join` wgpu tests with naga and direct SPIR-V; WGSL lint; fmt; clippy default,
   `nice_client/gpu`, gpu + cubecl-spirv.
4. If exactness passes with time left: A/B vs f3fb390, interleaved, 3 rounds: b62 1e17, b62 1e16,
   b60 1e16, b64 1e16 (b64 has 8 roots: the segment loop matters most there), the 1e14 set;
   NiceMark 6 rounds. Clock per side and clock-normalised ratios. If time runs out, push the
   exact branch and report what remains; a second day is budgeted.
5. Optional rider, measured separately if everything else is done: check the survivor stage once
   per top batch instead of every chunk (L45: exact, ×1.02; the stage never fills).
6. Write `L46/RESULTS.md` (or `PROGRESS.md` if unfinished), raw logs in `L46/raw/`. PR body only
   if the bar is met (≥ 5 % at b62 1e17 and b60 1e16, no NiceMark scenario < ×0.98 over 6 rounds):
   `L46/PR-BODY.md` in `L38/PR-BODY.md`'s style, stacked on #246; do not open the PR.

Rules as for every box agent: Vast only via `vast.py`, never create/destroy (say when the box can
go); on ivory write only under `L46/`; HTTPS push fallback with `gh auth token` to the fork only;
never push to wasabipesto/nice; no live fleet, no PRs, no subagents. Kill: exactness failing
twice, or a measured < ×1.05 at either production field. Hard stop 12:30 UTC (box self-destroys
~12:50 UTC).
