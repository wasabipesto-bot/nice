# L43 brief: the per-wave base trims (2026-11-06)

Read `L41/SCOPING.md` §4 (the per-wave base after #241: ~750 instructions per plane-wave outside
the walk and the AND, 3.5× the AND's useful work; the transposed copy 232 instructions per thread
per batch, 141 ALU; the wave load redone for each top batch of a work item, ~2.3 batches per item)
and §5 candidates 5, 7, 8, 9: (5) the transposed copy as a warp shuffle transpose (−3.5 % of the
join's instructions; exact; 32-lane planes only, so keep the shared-memory build for other plane
sizes); (7) hoist the wave load out of the batch loop (−1.3 %; exact); (8) the AND digit loop at
a fixed trip count (−1.1 %; relies on every entry having exactly 12 digits plus key digits —
verify from the bucket kernel what the mask's popcount is at key level and otherwise before
using it; if it varies, gate or drop); (9) `pc` precomputed in the bucket kernel (−0.5 %; needs a
third word per entry). Together ≈ 6–7 % of the join's instructions ≈ 3–4 % of the field: this is
likely a park, not a PR, but it is the last unmeasured part of the join, and the measurement is
what we want. Kill: < 3 % at b62 1e17 → park with the numbers; no PR below 5 %.

## Base and process

Base: fork `pr/join-top-record` at **7832f89** (main 6f060a9 + #241). Branch `exp/join-wave-base`
on the fork, each candidate behind its own env→comptime switch (`NICE_EXP_JOIN_WB` bitmask) so one
binary screens them separately and together. Box: instance 59373935 (`nice-research-l43-wavebase`,
RTX 3080, 7 h TTL; `python3 vast.py ssh 59373935` from this directory; wait for `/root/READY`). All
builds and runs on the box; nothing on ivory. Never `vast.py create`/`destroy`. Another agent works
on the walk's prefilter on another box (L41); do not touch `walk_pf` or `L41/`.

1. Implement (5), (7), (8 if justified), (9) behind the bitmask. Codegen gate: ptxas registers
   ≤ 48, no spills, direct-SPIR-V block count noted.
2. Exactness for the combined mask (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl.
   b50/b54); #240's device test; both dense fields; whole b42; `NICE_TEST_JOIN_COMPARE=1` at 1e14
   for b57/60/62/64 (counts in `L38/PR-BODY.md`); whole-field counts = the exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Lavapipe (8-lane
   subgroups: (5) must fall back correctly): the `cubecl_join` wgpu tests with naga and direct
   SPIR-V; WGSL lint; fmt; clippy ×3.
3. Screen each candidate alone and all together at b62 1e17 and b60 1e16 (2 interleaved rounds).
4. A/B of the best combination vs 7832f89, 3 interleaved rounds: b62 1e17, b62 1e16, b60 1e16, b64
   1e16, the 1e14 set; NiceMark 4 rounds. Clock per side and clock-normalised ratios.
5. Write `L43/RESULTS.md`, raw logs and scripts to `L43/raw/`. If ≥ 5 % at b62 1e17 and b60 with no
   NiceMark scenario < ×0.98, also squash a PR-ready branch `pr/join-wave-base` (no env knobs) and
   write `L43/PR-BODY.md` in `L38/PR-BODY.md`'s style; do not open the PR. Update nothing else.

Rules as for every box agent: Vast only via `vast.py`; on ivory write only under `L43/`; HTTPS
push fallback with `gh auth token` to the fork only; no live fleet, no PRs, no subagents. Hard
stop 12:30 UTC (box self-destroys ~12:45 UTC).
