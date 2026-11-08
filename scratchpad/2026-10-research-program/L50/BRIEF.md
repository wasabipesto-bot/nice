# L50 brief: the CPU join after #247 and #248 — budget and roadmap (2026-11-08; analysis on ivory, no GPU)

## Why

The CPU join gained ×1.25–1.29 (#247, FD top certificates) and ×1.07–1.15 (#248, fixed-point
prefilter) in two days on ivory alone. Production boxes run CPU threads beside the GPU and Anvil
is CPU-only, so CPU throughput counts. What is left on the CPU, and does anything from the GPU
series map (the static bucket order #249? the check kernel's design D as a CPU check? the field-
certificate prune is already there)?

## What to do (ivory, `nice -n 19`; a worktree from fork `pr/cpu-join-lean-prefilter` 7f5260b (= main + #247 + #248) with its own target dir, release build of `nice_client` only (~2 min, ~550 MB); remove targets at the end; `df -h /` first)

1. Profile the CPU join on #248's head with `perf` (available on ivory per L42) at 1 and 4 threads
   on b60 1e16-shaped and b62 1e17-shaped partitions (the harness in `L49/raw/scripts/` /
   `L42/raw/pr/`) and whole b60/b62 1e14 fields: phase split (MSD/interval analysis, top
   certificates incl. seeds vs steps, bucket/extend/lists, the AND scan, survivor prefilter, full
   check, sort, everything else) as % of partition time, with the per-phase instruction counts
   and IPC where perf gives them. Note the load average and that ivory is a Zen 2 VM with AVX2
   (scan = `scan_avx2`).
2. For each phase ≥ 10 %: what the GPU series did to its twin, whether it maps, and an
   instruction-count estimate of the gain: e.g. the full check (`check` on survivors) vs L47's
   design D (base-b² limbs, carry-normalisation digits, a gate before n³ — `L47/SCOPING.md` §3);
   the scan's survivor extraction (L42: ~2.3 cycles per AND, 0.3 of it arithmetic; branch
   mispredictions ~12 % of cycles — is a branch-free extraction or a two-pass scan worth it?);
   the top certificates' seeds (what share now; can the seed be cheaper as #240's was?); the list
   build at small fields. Also AVX-512 vs AVX2: how much of the profile is the scan, and what a
   Zen 4 / AVX-512 host changes (estimate; Anvil's and demoux's CPUs).
3. Write `L50/ROADMAP.md`: the profile tables, a ranked shortlist (≤ 4 items) with expected gain
   (range), confidence, cost (days, $0), kill criterion, and which hardware the estimate assumes.
   Budget ~3 h. No pushes, no PRs, no subagents, nothing else in the scratchpad or outside your
   worktree touched (the main checkout runs the live fleet).
