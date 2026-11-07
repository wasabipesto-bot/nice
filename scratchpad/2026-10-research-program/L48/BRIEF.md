# L48 brief: FD top kernel, round 2 (2026-11-07; L44 roadmap item 2)

## Why

The FD top kernel is 25 % of a b62 1e17 field after #246 (`L45/RESULTS.md` §A: 25.23 s of 100.2 s;
21 % at b60). L36.2 (`L36/SCOPING.md`, branch `exp/top-fd-ablate` 47c1b36 on the old all5 tree)
measured three exact trims of the stepped slot — carry c0 and b^c0 − d across steps (−14.4 %),
a bookkeeping-free path for scanned words wholly above c0 (−6.7 %), stepping slots skipping the
a/e build and clip test (−2.5 %) — together −22 % of the slot = ×1.041 whole-field on that tree
(the top kernel's share was smaller then). L44 adds: a cheaper append (the kept-top append is
one plane ballot + one atomic per plane today — check what remains), a partial x mod b^c0
(only the words that matter), and `SURV_PER_PREFIX` 2 → 1 in `join_plan.rs` (more slots per
batch → fewer seeds: a seeded slot costs 0.35 ns vs 0.20 stepped and seeds are 1 in 5 slots at
b62 1e17; L1.7 found more partitions per launch neutral before FD made seeds expensive — the
plan's survivor bound and memory must still hold). Estimate ×1.05–1.07 at b62 1e17, ×1.04–1.065
at b60. Kill: A/B < ×1.05 at either field → park on the branch (no PR at ×1.04); any NiceMark
scenario < ×0.98 over 6 rounds; the device test failing twice.

## What to do, in order

0. Box: instance 59529585 (`nice-research-l48-fdround2`, RTX 3080, 7 h TTL): `python3 vast.py ssh
   59529585`; wait for `/root/READY`. Base: fork `pr/join-lean-prefilter` f3fb390 (= main + #241 +
   #246). Branch `exp/top-fd-round2` on the fork (→ `pr/top-fd-round2` if the bar is met). All
   builds and runs on the box. Never `vast.py create`/`destroy`. Another agent (L46) changes the
   top kernels' append destination on another branch — keep your changes to the stepped slot's
   arithmetic, the append's instruction count and the plan constant, so the two rebase cleanly.
1. Port the three L36.2 trims from `exp/top-fd-ablate` onto f3fb390 behind a cumulative switch
   `NICE_EXP_TOPFD` (1 = trims, 2 = +append, 3 = +partial remainder, 4 = +SURV_PER_PREFIX 1), each
   level exact by construction; say for each what it removes.
2. Codegen gate: ptxas registers/spills of `top_fd_kernel` per level (it is 108–110 today at 2
   blocks of 256 per SM; do not exceed what keeps 2 blocks), SASS instruction count of the stepped
   slot per level, direct-SPIR-V blocks.
3. Exactness per level: #240's device test (both top kernels on the same batches: per-slot counts,
   bucket counts, sorted entries), #235's certificate test, `cubecl_cuda_join_matches_the_cpu_
   reference`, both dense fields, whole b42, 1e14 COMPARE (counts in `L38/PR-BODY.md`), whole-field
   counts = the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16
   163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16
   787,584,956,227 / 47,900,853,327); lavapipe naga + SPIR-V; lint; fmt; clippy ×3. For level 4
   also report the plan: slots per batch, plan MiB, batches per field at b62 1e17 and b60 1e16
   (must fit a 10 GB card exactly as the plan's bounds say).
4. Screen levels 1–4 at b62 1e17 and b60 1e16 (2 interleaved rounds, one binary) with #240's
   kernel-alone timing test too (ns per stepped slot per level). Then A/B of the best level vs
   f3fb390, 3 interleaved rounds: b62 1e17, b62 1e16, b60 1e16, b64 1e16 (FD is off at b64 —
   confirm neutral), the 1e14 set; NiceMark 6 rounds (NiceMark seeds every slot: expect ~neutral,
   say so). Clock per side and clock-normalised ratios.
5. If ≥ 5 % at both production fields: squash to one commit on f3fb390 (no knobs; the shipped
   level only), CHANGELOG line ending `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`,
   push `pr/top-fd-round2`, write `L48/PR-BODY.md` in `L38/PR-BODY.md`'s style (stacked on #246;
   no program/scratchpad references). Do not open the PR. Below the bar: push the switchable
   branch and report.
6. Write `L48/RESULTS.md`, raw logs in `L48/raw/`.

Rules as for every box agent (Vast via `vast.py` only, never create/destroy; ivory writes only
under `L48/`; HTTPS push fallback to the fork; never push to wasabipesto/nice; no live fleet, no
PRs, no subagents). Hard stop 12:30 UTC (box self-destroys ~12:50 UTC).
