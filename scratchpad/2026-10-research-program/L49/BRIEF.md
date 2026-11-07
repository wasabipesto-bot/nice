# L49 brief: the lean prefilter in the CPU join (2026-11-07; L44 roadmap item 3; CPU on ivory)

## Why

`CpuJoin::prefilter` (`common/src/cpu_join.rs`) is the same arithmetic as the GPU's `walk_pf`;
PR #246 (fork `pr/join-lean-prefilter` f3fb390, open, reviewed) replaced the GPU's mod/div digit
extraction by fixed-point multiplies (FX), the four one-hot masks by shift-and-compare membership
on bit-reversed masks (MT) and gated the top mask by its seed flag (GM). L42's scoping ported
FX + MT + GM to the CPU as `prefilter_lean` and measured ×1.05–1.08 standalone with identical
counts (`L42/SCOPING.md` point 4; scratch code under `L42/raw/`); the residue-test fold (RC) was
×1.00 on the CPU — leave it out. On the CPU join after #247 the prefilter is ~20 % of a
production-shaped partition (L42.1: 17–18 % before #247's top-kernel gain). Estimate ×1.06–1.10.
Kill: < ×1.05 at both production shapes (b60 1e16 and b62 1e17 partitions), or any count differs.

## Deliverable

Branch `pr/cpu-join-lean-prefilter` on the fork, one squashed commit on fork `pr/cpu-join-fd-tops`
caef70e (PR #247, = main 6f060a9 + CPU FD tops): the lean prefilter as the only CPU prefilter
(no knobs), self-contained (its own FX constants and host tests; #246's live in the GPU module and
#246 is not merged — say in the body that the two can share a module once both land). Tests in
the PR: the FX digit-extraction equivalence for every (A, P, D) < b² at every base 10–64 behind an
opt-in env (like #246's exhaustive test) plus a CI-sized version (the constants vs exact ceilings
for every D, the digits for every (P, D) at max A and every (A, D) at max P); the MT predicate vs
the old four-mask test on every digit 4-tuple per base; the lean prefilter vs the division form on
1e6 random pairs per base; the existing `cpu_join` tests; whole b42 (417,789,835 / 16,879,877); b60
and b62 1e14 fields with counts identical to #247's binary (b60 1,326,103,590 / 84,383,498; b62
1,470,093,637 / 87,495,922); the opt-in production reference `NICE_TEST_CPU_JOIN_REF=3`. fmt;
clippy -D warnings default (CI's), and note that the GPU feature sets do not touch this code.

## Process (ivory, `nice -n 19`, worktree under `.worktrees/` from fork `pr/cpu-join-fd-tops`, own `CARGO_TARGET_DIR` inside it; `df -h /` first; release only; remove targets at the end)

1. A/B against #247's head (two release binaries, interleaved with alternating order, medians,
   3 rounds, loads noted) at 1 and 4 threads on b60 1e16-shaped and b62 1e17-shaped partitions
   (the harness in `L42/raw/pr/`) and whole b60/b62/b64 1e14 fields; CPU nice-only NiceMark
   (`--benchmark` without `--gpu`, 150 s) 4 rounds interleaved.
2. `L49/PR-BODY.md` in `L38/PR-BODY.md`'s style: what / why (the CPU profile share, the GPU twin
   #246) / soundness (FX bound — the CPU's operands and ranges, re-derived; MT equivalence; GM) /
   measurements (both thread counts, fields, NiceMark; Zen 2 VM caveat) / exactness / not in this
   PR (RC: measured ×1.00 on the CPU; sharing the FX module with the GPU once #246 lands). Stacked
   on #247. No program/scratchpad references. CHANGELOG line under "## Unreleased" ending
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`.
3. Push (HTTPS fallback to the fork if SSH is refused; never push to wasabipesto/nice). Do not
   open the PR. Write `L49/PR-RESULTS.md`, raw logs in `L49/raw/`. Remove target dirs; keep the
   worktree. No pushes to upstream, no PRs, no GitHub comments, no subagents, nothing else in the
   scratchpad or under `~/projects/nice` outside `.worktrees/` touched. Hard stop 11:00 UTC.
