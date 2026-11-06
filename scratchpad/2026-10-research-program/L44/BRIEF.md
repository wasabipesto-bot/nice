# L44 brief: where the time goes after the November stack, and the ranked shortlist for next week (2026-11-06, analysis only, no GPU)

## Why

Since 2026-10-28 the GPU overlap join has gained #215, #216, #222, #235–#237, #239–#241 (merged
or open) and today #246 (lean prefilter, open) and #247 (CPU FD tops, open). Every remaining
candidate we have measured or estimated is below 5 % alone: top-kernel trims ×1.04 (L36.2),
FD state across batches ≈ ×1.035 (L35), group walk ×1.056 but small-bucket loss (L40), wave-base
trims ×1.017 (L43), bottom record neutral (L39), AND-side rewrites dead (L37). Before spending
more GPU days we want a sober budget of what is left and which combinations or new directions
could clear the bar.

## What to do

1. Read, in this order: `L36/RESULTS.md` (stack profile), `L37/RESULTS.md` (join ablation),
   `L39/RESULTS.md` (why stripped-kernel costs over-state latency-bound parts), `L40/RESULTS.md`,
   `L41/SCOPING.md` + `L41/RESULTS.md` (ALU budget model and the lean prefilter's measured
   effect), `L43/RESULTS.md`, `L35/RESULTS.md` + `L36/SCOPING.md` (top kernel after #240 and its
   trims), `L38/RESULTS.md`, `L1/PROFILE-3.md` (cost-model form), `LEDGER.md` (every lead's
   status), and the PR bodies of #246 and #247 (`gh pr view N --repo wasabipesto/nice --json body
   --jq .body`). Note each number's hardware (150 W vs 180 W vs 320 W cards) and whether it is a
   measurement or an estimate.
2. Build the **post-stack budget** for b62 1e17 and b60 1e16 (the live production shapes) on a
   180 W 3080: device seconds per field by phase (top FD kernel incl. seeds and clipped launch,
   bucket, join split into base / AND / walk rounds / prefilter / stage, check, other) **after
   #241 and #246**, derived from the measured ratios (state the derivation and the uncertainty;
   where two sources disagree, say which you trust and why). Then the same budget as a share of
   wall time at a power cap, noting the clock effects seen (leaner code → lower clock at the cap).
3. **Combinations**: which parked items are independent and could be bundled to clear 5 %
   together (e.g. L36.2 trims + FD persistence on the top kernel; L43's TT2+WH + L37's
   COMPACT=2 + L40's group walk on the lean body), with the register/occupancy and small-bucket
   caveats each carries; estimate each bundle honestly and say what it would take to measure.
4. **New directions** (think, do not prototype): with the join ALU-bound in the walk and shared-
   load-bound in the AND, and the top kernel at ~0.2 ns per stepped slot: (a) can the AND test
   fewer digits per entry (e.g. digits already implied by the field or top certificates) without
   losing exactness; (b) is there a cheaper exact prefilter than the middle-digit one at mid = 2,
   or a stronger one that rejects more per instruction (rejection per instruction is the metric);
   (c) can the stage + check be fused with the walk (survivors checked in place) at production
   survivor rates; (d) is the per-batch structure (6,439 batches per b62 1e17 field) now a cost
   after everything else shrank — re-read L1.7 §6; (e) anything in the MSD/interval stage or the
   bucket kernel that grew in relative terms; (f) the clock/power angle: at a cap, instructions
   that draw less power buy clock — which of our kernels are power-heavy (multiplies, shared
   traffic) and is there a cheaper-in-watts formulation of the same work.
5. Write `L44/ROADMAP.md`: the budget tables, the bundle estimates, the new-direction notes with
   a go/no-go each, and a ranked shortlist of at most five items for the coming week with, for
   each: expected gain (range), confidence, cost (days, $), prerequisite PRs, kill criterion.
   Everything estimated must be labelled as such. Budget about 2.5 h. Write nothing else; no
   builds, no pushes, no subagents.
