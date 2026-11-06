# L41 brief: the lean `walk_pf` prototype (2026-11-06)

Read `L41/SCOPING.md` first: §1 (the round as compiled), §3 (FX fixed-point digit extraction with
its exactness proof, MT shift+compare membership, GM seed-gated top masks, RC residue-test fold),
§6 (the prototype plan: cumulative switch levels, codegen gate, host tests). It is the design; this
brief is the process.

## Base and branch

Base: fork `pr/join-top-record` at **7832f89** (= upstream main 6f060a9 + PR #241, open). Branch
`pr/join-lean-prefilter` on the fork. A/B against 7832f89. All builds and runs on the box
(instance 59373929, `nice-research-l41-leanpf`, RTX 3080, 7 h TTL; `python3 vast.py ssh 59373929`
from this directory; wait for `/root/READY`; the clone at /root/nice is of the fork). Nothing is
built on ivory. Never `vast.py create`/`destroy`.

## Order

1. **Host exhaustive tests first.** FX's claim: for every base 10 ≤ b ≤ 64 and every pair
   (per-top ⌈D·2³²/b²⌉, per-entry A·⌈2³²/b²⌉ as §3.1 defines them) the recovered digits equal the
   exact `% b²`, `/ b`, `% b` values. Test it exhaustively over the full operand ranges the kernel
   can see (the scoping bounds them; if the full range is too large, exhaustive over the
   per-entry/per-top factors with the inner value exhaustive, and random 1e9 samples on the rest)
   as a plain Rust unit test on the host, plus the same for MT's predicate equivalence against the
   current four-mask test on random digit sets. These tests go into the PR.
2. Implement behind `NICE_EXP_JOIN_PF` (env on the host → comptime level): 1 = FX, 2 = +MT, 3 = +GM,
   4 = +RC. **Codegen gate** before any timing: ptxas registers ≤ 48, no spills; SASS of the round
   before the stage at b62 should shrink about as §6 predicts (71 → ~56 / 48 / 45 / 39). Report
   the actual counts per level; if a level does not shrink, find out why before timing it.
3. Exactness at level 3 and level 4 (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl.
   b50/b54); #240's device test; #235's certificate test; both dense fields; whole b42;
   `NICE_TEST_JOIN_COMPARE=1` at 1e14 for b57/60/62/64 (counts in `L38/PR-BODY.md`); whole-field
   counts = the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16
   163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16
   787,584,956,227 / 47,900,853,327). RC needs the clipped-path parity (the windows clipped at both
   ends in the test set) — say which tests cover it. Lavapipe: the `cubecl_join` wgpu tests with
   naga and the direct SPIR-V compiler; the WGSL lint as the workflow runs it (note any new
   `/ K` or `% K` shapes: FX replaces divisions by multiplies, the lint should see fewer); fmt;
   clippy default, `nice_client/gpu`, gpu + cubecl-spirv.
4. **Screen** (one binary, levels 0–4) at b62 1e17 and b60 1e16 with the walk's round counters
   (rounds must not change). Kill if level 3 < ×1.03 at b62 1e17 (the round is not ALU-bound as
   modelled) — then report and stop.
5. **A/B** of the best level vs 7832f89, same box, interleaved with alternating order, medians,
   3 rounds: b62 1e17, b62 1e16, b60 1e16, b64 1e16, the 1e14 set; NiceMark `--benchmark-secs 150`
   **6 rounds** (b58 MSD-strong swings ±4 % between sessions). Clock per side and clock-normalised
   ratios as in `L38/RESULTS.md`.
6. If ≥ 5 % at b62 1e17 and b60 1e16 and no NiceMark scenario < ×0.98 over the 6 rounds: squash to
   one commit on 7832f89 (the level that ships is the only code; no env knob in the PR; the host
   tests stay) with a CHANGELOG line under "## Unreleased" ending
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`, push, and write `L41/PR-BODY.md` in the
   style of `L38/PR-BODY.md` (what / why with the SASS counts / soundness with FX's proof and MT's
   predicate equivalence / measurements, both columns / exactness / registers / not in this PR;
   stacked on #241). No program/scratchpad references. Do not open the PR.
7. Write `L41/RESULTS.md`, raw logs and scripts to `L41/raw/`. Update nothing else in the scratchpad.

## Rules

Vast only through `vast.py`, never create/destroy (say when the box can go). On ivory: read the
repo/scratchpad, write only under `L41/`, push/fetch git (HTTPS fallback with
`-c http.extraheader="AUTHORIZATION: bearer $(gh auth token)"` to the fork if SSH is refused; never
push to wasabipesto/nice). No live fleet, no `~/fleet-run`, no PRs, no subagents. If exactness
fails twice or the kill criterion fires, stop and report. Hard stop 12:30 UTC (the box
self-destroys ~12:45 UTC).
