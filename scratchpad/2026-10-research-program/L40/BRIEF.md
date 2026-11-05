# L40 brief: walk the AND group's pass words as one set (2026-11-05)

## Why

L37 (`L37/RESULTS.md` §1–2) measured the join's survivor path on main at 54 % of the join (walk
16 %, `walk_pf` 33 %, stage 5 %) = 30 % of a b62 1e17 field, at **25 % lane utilisation**: per
(plane, entry slot, chunk of 32 tops) the walk runs `while plane_any(x != 0)` for 3.36 rounds
(4.45 at b60) while a lane holds 0.84 pass bits on average (1.29 per lane with an entry). The
round body is ~110 SASS instructions (`walk_pf` ≈ 52). Full cross-lane compaction (H1) lost
(×0.94: 172-instruction body, 50 instructions of prefix-sum per slot-chunk), but the agent's
variant `COMPACT=2` — one walk per lane over both entry slots' words, no shuffles — was exact and
×1.015 b62 1e17 / ×1.026 b60 / NiceMark ×1.017 (branch `exp/join-walk-compact` 77241bc,
`NICE_EXP_JOIN_COMPACT=2`). Extending that to the whole AND group — the 2 slots × 4 chunks = 8
pass words a lane has at the end of a group — should cut rounds further: pass bits per lane per
group ≈ 6.7 (Poisson-ish), so max over 32 lanes ≈ 12–13 rounds per group against 8 × 3.36 ≈ 27
today, i.e. about half the rounds. Expected 5–7 % of the field if the per-round cost stays near
110 instructions. Kill: < 5 % at b62 1e17 and b60 1e16, or any NiceMark scenario < ×0.98.

Also fold in: the residue range test in the round body never rejects in production (L37: pass
bits = in-range survivors to within 4 of 1.02e12) — but it is part of exactness (the CPU join has
it), so keep it unless you can show it is implied by the AND (if `t_rlo`/`t_rhi` always cover
`r0` for listed entries, document why and drop it; otherwise keep it).

## What to do, in order

0. Box `nice-research-l40-groupwalk` (RTX 3080, 6 h TTL, instance 59214577): from
   `~/projects/nice/scratchpad/2026-10-research-program` run `python3 vast.py ssh 59214577`; wait for
   `/root/READY`. The clone at /root/nice is of the fork; **base on fork `pr/join-top-record`
   (af21136 = upstream main 6f060a9 + #241)** and A/B against it. Start from the `COMPACT=2` code
   on `exp/join-walk-compact` for the per-lane multi-word walk. All builds and runs on the box;
   nothing built on ivory. Never `vast.py create`/`destroy`. Branch `pr/join-group-walk` on the fork.
1. Design: at the end of each AND group (`cb % AND_GROUP == 0` boundary, after the 4 chunks' `pm`
   words are known for both slots), walk the 8 words as one set: each round, pick the lowest
   non-empty word (a tiny select chain or a word-mask), take its lowest bit, map (slot, chunk,
   bit) → (entry registers, top index), run the existing round body (residue test, `walk_pf`,
   stage append), clear the bit. Keep the stage flush cadence per group (L37 found no difference
   between checking every 4 or 8 chunks). Mind registers (main's join kernel is 40; H1 was 48 with
   spills) and keep the direct-SPIR-V block count in check (keep loops, no 8-way unrolled copies
   of the round body — one body, indexed registers via `Array` or a select chain).
2. Exactness (CUDA): `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54); #240's device
   test; #235's certificate test; both dense fields; whole b42; `NICE_TEST_JOIN_COMPARE=1` at 1e14
   for b57/60/62/64 (counts in `L38/PR-BODY.md`); whole-field counts = the exact counts (b62 1e17
   1,020,844,021,499 / 62,584,252,554; b62 1e16 163,513,599,082 / 10,027,698,695; b60 1e16
   460,847,952,346 / 30,871,838,404; b64 1e16 787,584,956,227 / 47,900,853,327). Lavapipe: the
   `cubecl_join` wgpu tests with naga and the direct SPIR-V compiler (8-lane subgroups: the walk's
   plane ops must stay correct there); WGSL lint as the workflow runs it; fmt; clippy default,
   `nice_client/gpu`, gpu + cubecl-spirv.
3. A/B vs af21136, same box, interleaved with alternating order, medians, 3 rounds: b62 1e17,
   b62 1e16, b60 1e16, b64 1e16, the 1e14 set, NiceMark (2 rounds). Report seconds, spreads,
   ratios, clock per side and clock-normalised ratios (as `L38/RESULTS.md`), ptxas registers and
   spills for `join_kernel`, SASS instruction counts of the round body, and the measured rounds per
   group (add a device counter under a test flag as L37 did) and lane utilisation.
4. If ≥ 5 % at b62 1e17 and b60 1e16 with no NiceMark scenario below ×0.98: squash to one commit
   on af21136 with a CHANGELOG line under "## Unreleased" ending
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`, push, write `L40/PR-BODY.md` in the
   style of `L38/PR-BODY.md` (say it is stacked on #241; no program/scratchpad references). Do not
   open the PR. If below the bar, push the branch and report anyway.
5. Write `L40/RESULTS.md`, raw logs and scripts to `L40/raw/`. Update nothing else in the scratchpad.

## Rules

- Vast only through `vast.py`, never create/destroy (say when the box can go). On ivory: read the
  repo/scratchpad, write only under `scratchpad/2026-10-research-program/L40/`, push/fetch git (if
  GitHub refuses SSH, push over HTTPS with `-c http.extraheader="AUTHORIZATION: bearer $(gh auth token)"`
  to `https://github.com/wasabipesto-bot/nice.git`; never push to wasabipesto/nice). Nothing else
  under `~/projects/nice` outside `.worktrees/` is touched; no live fleet, no `~/fleet-run`, no
  PRs, no subagents.
- If exactness fails twice or the prototype is slower, stop and report the measurements and why.
- Hard stop 11:00 UTC (the box self-destroys ~11:45 UTC). Report whatever is complete.
