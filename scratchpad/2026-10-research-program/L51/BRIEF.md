# L51 brief: the full stack profiled, ablated and retuned (2026-11-08; measurement, no PR)

## Why

main 6f060a9 + #241 + #246 + #249 + FD round 2 = fork `pr/top-fd-round2` **d813aea**: about 73 s per
b62 1e17 field on a 180 W 3080 (L48.2), ~×2.4 over main. Every budget we have is from before
#249 and the FD round (L45 on #246; L44's derivation). Three questions for the next week's
ranking: (A) where does the field go now, by phase and inside the join; (B) are the kernel
constants tuned on older kernels still right — `JOIN_WG`/EPT (EPT 2 chosen with the prune in
October), `TRANSPOSE_MIN` 192 (chosen on #236), `AND_GROUP` 4 (on #239), the stage check cadence
(now once per batch), `TOP_CAP` 256, the FD kernel's cube size, `check_kernel`'s 1024 cubes (L47
handles that one — leave it); (C) a re-price of L44 §3a/§3f's AND ideas and of L40's group walk on
the lean body, by arithmetic from the new numbers, not by building. Kill: a retune that gives
< 3 % at both production fields is recorded, not shipped; nothing here becomes a PR without a
≥ 5 % measurement (then it becomes a PR brief for tomorrow).

## What to do

0. Box: instance 59671466 (`nice-research-l51-profile`, RTX 3080, 7 h TTL): `python3 vast.py ssh
   59671466`; wait for `/root/READY`; the clone is of the fork; base d813aea; experiment branch
   `exp/l51-profile` on the fork. Another agent (L47) builds the check kernel on another box; do
   not touch `L47/` or `check_kernel`.
1. **Profile** (phase timers: cherry-pick L45's adapted timers from `exp/join-l45-measure` 8a07c05
   — they split top into FD / clipped / (scan / fill are gone now) and need adapting to #249's
   kernel set): 3 profiled runs at b62 1e17 and b60 1e16; phases top FD, bucket, join, check,
   other; profiled vs unprofiled totals. Then the join's ablation (L45's modes: AND only; walk
   without `walk_pf`; full; per-top AND via TRANSPOSE_MIN huge) on d813aea, 3 interleaved
   profiled rounds, so base / AND / walk / prefilter / stage are known after #249 and the lean
   prefilter.
2. **Retune screens** (unprofiled, one binary per knob where the knob is comptime, interleaved,
   2 rounds each at b62 1e17 and b60 1e16; counts must stay exact): EPT 1 / 2 / 3 (JOIN_WG fixed),
   TRANSPOSE_MIN 128 / 192 / 256 / 512, AND_GROUP 2 / 4 / 8, TOP_CAP 128 / 256 / 512 (shared memory
   permitting), the FD kernel's cube size 128 / 256 / 512, and the SURV_FLUSH / stage cadence
   variants if cheap. Report ptxas registers for anything that changes occupancy. Any winner ≥ 3 %
   at both fields gets a 3-round A/B and NiceMark 4 rounds.
3. **Re-price by arithmetic** from the new ablation: L44 §3a (AND testing fewer digits), §3f (power
   /clock formulations), L40's group walk on the 41-instruction round (rounds ×0.65, body +19 for
   the word pick, small-batch loss), L37's COMPACT=2, the AND's shared-load bound now that the AND
   is 8 % of the field. One paragraph each with a go/no-go and a number.
4. Write `L51/RESULTS.md` (profile tables, ablation split, retune table, re-pricing, and a ranked
   list of what is left ≥ 3 %), raw logs in `L51/raw/`. Rules as for every box agent (Vast via
   `vast.py` only; ivory writes only under `L51/`; HTTPS push fallback to the fork; never push to
   wasabipesto/nice; no PRs, no subagents). Hard stop 12:30 UTC.
