# L52 brief: the two-pass scan in the CPU join (2026-11-08; L50 roadmap item 1; CPU on ivory)

## Why

`L50/ROADMAP.md`: on #248's head the scan + survivor extraction is 37.6–39 % of a production-
shaped partition at IPC 1.6 with 62 M branch misses per b60 partition, half of them in the scan
(a 16-bottom chunk holds a survivor ~40 % of the time, so the branch is a coin toss; each survivor
is a `vzeroupper` + a call to `survivor`). The L50 prototype (`L50/raw/l50-scratch.patch`, worktree
`.worktrees/l50-cpu-roadmap`): pass 1 does the AND and writes surviving indices without branching
(a 256-entry lookup table); pass 2 processes the survivors with `survivor` inlined. Measured in
place ×1.16–1.20, +5–6 % with the inlining → **×1.22–1.28 at b60 1e16 and b62 1e17 shapes**, counts
identical. Branch misses 62 M → ~26 M; IPC 2.1 → 2.8. Kill: < ×1.10 at either production shape;
NiceMark CPU < ×1.05; any count change. On an AVX-512 host (not available here) the gain is
estimated ×1.08–1.15; if that path measures < ×1.00 somewhere later, it keeps its current loop.

## Deliverable

Branch `pr/cpu-join-two-pass-scan` on the fork, one squashed commit on fork
`pr/cpu-join-lean-prefilter` 7f5260b (PR #248): the two-pass scan for **all three scan paths**
(`scan_avx512`, `scan_avx2`, `scan_any` in `common/src/cpu_join.rs`), sharing the pass-2 code and
the index-buffer handling; no knobs. The AVX-512 pass 1 cannot run on ivory (Zen 2): write it as
the AVX2 form's sibling, keep the existing path-equivalence tests (whatever compares the scan
paths today) and add one that checks pass 1's survivor index lists are identical across the
available paths and against a scalar reference on random buckets with controlled survivor
densities (0 %, 1 %, 40 %, 100 %). State in the body that the AVX-512 path was compiled and unit-
tested only where its target feature was unavailable (say exactly what ran), and that CI's
x86 runners may or may not have AVX-512 (check what the runner reports in an existing CI log if
you can; otherwise say unknown).

Tests in the PR: the path-equivalence test above; the existing `cpu_join` tests; whole b42
(417,789,835 / 16,879,877, join = reference = stride); b60 and b62 1e14 fields with counts identical
to #248's binary; the opt-in `NICE_TEST_CPU_JOIN_REF=3`. fmt; clippy -D warnings default (CI's);
the GPU feature sets do not touch this file.

## Process (ivory, `nice -n 19`, worktree from 7f5260b with its own `CARGO_TARGET_DIR`; `df -h /` first; release only; the VM has 7 GB RAM — no debuginfo builds; remove targets at the end)

1. A/B vs #248's head: two release binaries, interleaved with alternating order, medians, 3 rounds
   (loads noted; discard rounds with another session's load > 2), at 1 and 4 threads on b60
   1e16-shaped and b62 1e17-shaped partitions (harness in `L50/raw/scripts/` / `L49/raw/scripts/`),
   whole b60/b62/b64 1e14 fields, b58 1e15 if the harness has it; CPU nice-only NiceMark 4 rounds.
   perf (1 thread): branch misses and IPC before/after, as L50 did.
2. `L52/PR-BODY.md` in `L38/PR-BODY.md`'s style: what / why (the profile share, the branch-miss
   story) / soundness (the same AND predicate, the same survivors in the same per-bucket order —
   or say if the order changes and why that is harmless) / measurements (both thread counts,
   fields, NiceMark; Zen 2 VM caveat; AVX-512 estimate) / exactness / not in this PR (the seeded
   check, item 2). Stacked on #248 (on #247). No program/scratchpad references. CHANGELOG line under
   "## Unreleased" ending `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
3. Push (HTTPS fallback to the fork if SSH is refused; never push to wasabipesto/nice). Do not
   open the PR. `L52/PR-RESULTS.md`, raw logs in `L52/raw/`. Rules: no PRs, no GitHub comments, no
   subagents, nothing else in the scratchpad or outside your worktree touched (the main checkout
   runs the live fleet). Hard stop 13:30 UTC.
