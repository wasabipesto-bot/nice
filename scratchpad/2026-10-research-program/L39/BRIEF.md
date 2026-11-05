# L39 brief: one record per bottom entry for the join's wave loads (2026-11-05)

## Why

L37's ablation of `join_kernel` on main (`L37/RESULTS.md` §1; RTX 3080 at 150 W, b62 1e17,
join 72.4 s of a 129.7 s field) put "entry loads and prefilter terms" at 10.5 s = 14 % of the
join = 8 % of the field. Per wave, each lane loads its entry from three arrays at a random
index: `e = lists[lbase + sl]`, then `bp_r[e]` (1 word), `ext_m[2gi], ext_m[2gi+1]` (the mask)
and `ext_q[2gi], ext_q[2gi+1]` (the prefilter words), `gi = ebase + e` — three sectors for 20
bytes. There are 5.4e10 listed entries per b62 1e17 field. #241 (`pr/join-top-record`, fork
af21136, open) did the same for the tops (three arrays → one 32-byte record) and measured
×1.10 at b62 1e17 / ×1.06 at b60 on a power-capped card (×1.03–1.06 clock-normalised). The
bottom side is about half the size of the top gather in the ablation, so expect 4–6 %.

## What to do, in order

0. Box `nice-research-l39-botrec` (RTX 3080, 6 h TTL, instance 59214557): from
   `~/projects/nice/scratchpad/2026-10-research-program` run `python3 vast.py ssh 59214557`; wait for
   `/root/READY`. The clone at /root/nice is of the fork; **base your branch on fork
   `pr/join-top-record` (af21136, = upstream main 6f060a9 + #241)** so the two records do not
   conflict later; A/B against af21136. All builds and runs on the box; nothing built on ivory.
   Never `vast.py create`/`destroy`. Branch `pr/join-bottom-record` on the fork.
1. Read `bucket_kernel` (it writes `ext_m`/`ext_q` per slot, reading `bp_r` for the residue), the
   join's wave load (`let e = lists[...]` and the five loads after it), `join_plan.rs`'s footprint,
   and anything else that reads `ext_m`/`ext_q`/`bp_r` (`flush_survivors`, `check_kernel`, tests).
   Design the record: one buffer of N u32 per listed slot entry — at least m lo/hi, q0, q1, r
   (5 words; pad to 8 if alignment or the vector loads want it, otherwise consider 16 bytes + a
   separate `r`... measure what matters: the number of sectors per entry). `bp_r[e]` is per
   bottom residue (field-wide); the bucket kernel can copy it into the per-slot record since it
   reads it anyway. The lists stay as they are. Keep everything after the loads unchanged.
2. Exactness (CUDA) on the branch: `cubecl_cuda_join_matches_the_cpu_reference` (incl. b50/b54);
   #240's `cubecl_cuda_top_fd_matches_the_top_kernel`; #235's certificate test; both dense fields;
   whole b42; `NICE_TEST_JOIN_COMPARE=1` at 1e14 for b57/60/62/64 (counts in `L38/PR-BODY.md`);
   whole-field counts = the exact counts (b62 1e17 1,020,844,021,499 / 62,584,252,554; b62 1e16
   163,513,599,082 / 10,027,698,695; b60 1e16 460,847,952,346 / 30,871,838,404; b64 1e16
   787,584,956,227 / 47,900,853,327). Lavapipe: the `cubecl_join` wgpu tests with naga and the
   direct SPIR-V compiler; the WGSL lint as the workflow runs it; fmt; clippy default,
   `nice_client/gpu`, and gpu + cubecl-spirv.
3. A/B vs af21136, same box, interleaved with alternating order, medians, 3 rounds: b62 1e17
   (1 field), b62 1e16, b60 1e16, b64 1e16 (2 fields each), the 1e14 set, NiceMark
   (`--benchmark-secs 150`, 2 rounds). Report seconds, spreads, ratios, SM clock per side and the
   clock-normalised ratio (as `L38/RESULTS.md` does), power cap; ptxas registers for
   `join_kernel` and `bucket_kernel`. Scripts: `L38/raw/scripts/`.
4. If ≥ 5 % at b62 1e17 and b60 1e16 (wall time) with no NiceMark scenario below ×0.98: squash
   to one commit on af21136 with a CHANGELOG line under "## Unreleased" ending
   `([#NNN](https://github.com/wasabipesto/nice/pull/NNN))`, push, and write `L39/PR-BODY.md` in
   the style of `L38/PR-BODY.md` (what / why with the ablation numbers / soundness / measurements
   with both the wall-time and clock-normalised columns / exactness / registers / not in this PR;
   say it is stacked on #241). No mention of the research program, scratchpad, briefs, ledgers or
   fork-only write-ups. Do not open the PR. If below the bar, still push the branch and report.
5. Write `L39/RESULTS.md`, raw logs and scripts to `L39/raw/`. Update nothing else in the scratchpad.

## Rules

- Vast only through `vast.py`, never create/destroy (say when the box can go). On ivory: read the
  repo/scratchpad, write only under `scratchpad/2026-10-research-program/L39/`, push/fetch git
  (if GitHub refuses SSH, push over HTTPS with `-c http.extraheader="AUTHORIZATION: bearer $(gh auth token)"`
  to `https://github.com/wasabipesto-bot/nice.git`; never push to wasabipesto/nice). Nothing else
  under `~/projects/nice` outside `.worktrees/` is touched; no live fleet, no `~/fleet-run`, no
  PRs, no subagents.
- If exactness fails twice or the prototype is slower, stop and report the measurements and why.
- Hard stop 11:00 UTC (the box self-destroys ~11:45 UTC). Report whatever is complete.
