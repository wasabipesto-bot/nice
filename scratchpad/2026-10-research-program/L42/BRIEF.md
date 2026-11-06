# L42 brief: the CPU join's profile, and whether the top certificates can step by finite differences on the CPU (2026-11-06; CPU on ivory, no GPU)

## Why

Production boxes run CPU threads beside the GPU (demoux: `threads 4`; fleet PR #194 adds a host
CPU client); Anvil runs CPU-only. The CPU join (`common/src/cpu_join.rs`, `overlap_join.rs`) got
#204 (one-endpoint certificate + carry) but not the GPU's later gains: the top certificate by
finite differences across a batch's consecutive partitions (#240: on the GPU the top kernel went
×1.5–1.6 and the field ×1.14 at b62 1e17), the field-certificate prune (#215 — check whether the
CPU join has it), EPT/transposed-AND analogues do not apply (AVX-512 tests 8 masks per
instruction already). Question: what is the CPU join's phase split at b60 1e16 / b62 1e17-shaped
work, and would FD top certificates (and anything else from the GPU series) clear 5 % there?

## What to do (ivory, `nice -n 19`, worktree under `.worktrees/`, own `CARGO_TARGET_DIR` inside it; check `df -h /` first — 15 GB free; keep the target under 5 GB, release build of `nice_client` only, no GPU features)

1. Build the CPU client from upstream main 6f060a9 in release mode (`cargo build --release -p
   nice_client` with default features; if the default pulls GPU deps, use the minimal feature set
   that still has the CPU join). Note build time and target size.
2. Profile the CPU join on a b60 1e14 field and a b62 1e14 field with the client's own timing (the
   `--benchmark` nice-only CPU scenarios in `bench_defs.rs`, and a direct field run with
   `RUST_LOG` phase timers if the CPU join prints them). Use `perf` if `perf` exists on ivory
   (`which perf`); otherwise instrument with a few `Instant` timers on a scratch branch (not for a
   PR). Phases to separate: MSD/interval analysis, top certification (`tops()` / `cert`), bucket
   build/extension, the AND scan (`scan_avx512`/`avx2`), survivor prefilter + full check. Report
   the split as % of the field at 1 and at N threads (ivory's core count under nice; say what else
   was running).
3. If top certification is ≥ 15 % of the CPU join: design the CPU FD step (the GPU design is in
   `L35/DESIGN.md` and PR #240's body: consecutive partitions shift the prefix interval by b^f0,
   so a², a³ digit arrays step by shifted additions; `detailed_fd.rs` has the packed CPU digit
   arithmetic) for `CpuJoin::tops`, estimate the gain from the measured share and the GPU's ×1.6
   kernel ratio, and write the plan. If < 15 %, say what the dominant phase is and whether any GPU
   lever maps to it.
4. Also check and report: does the CPU join have the field-certificate bottom prune (#215's idea)?
   Does its AND loop get the `TRANSPOSE`-style benefit from anything (no)? Is the survivor
   prefilter the same arithmetic as the GPU's `walk_pf` (L41's lean formulation might port)?
5. Write `L42/SCOPING.md` with the profile tables, the verdicts, and a prototype plan if any lever
   clears 5 %. Remove the worktree's target dir when done (`rm -rf <worktree>/target*`), keep the
   worktree. Nothing pushed, no PRs, no subagents, nothing else in the scratchpad touched. Budget
   ~3 h; stop by 10:30 UTC.
