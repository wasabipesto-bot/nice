# L47 brief: the check kernel after the stack — scoping (2026-11-07 afternoon; no GPU)

## Why (L44 roadmap item 4; L45 confirmed 9.1 % / 11.3 %)

`check_kernel` (common/src/cubecl_join.rs) rebuilds n = P·b^f0 + r0 for each prefilter survivor
and runs the full nice check. After #241/#246 it is 9.1 % of a b62 1e17 field and 11.3 % of b60
1e16 (L45 §A); with #249 and the FD round the field shrinks another ~20 %, so its share rises
toward 11–14 %. L44 §4(c)/§5 says: its fixed grid of 1024 cubes runs 3 waves on a 3080 where 2.51
would do; it recomputes digits 0–7 of n² that the join already proved distinct (the bottom's
digits) with a 49-instruction 64-bit division per limb; the stage + check fusion is a no-go. The
roadmap estimate: ×1.045–1.06 at b62 1e17, ×1.05–1.07 at b60. Kill: scoping predicts < 3 % of the
field; later A/B < ×1.05.

## What to do (reading and arithmetic; L44/raw/sass/ has the check kernel's SASS unpacked, and L45/raw/box/ has per-process SASS/CUDA dumps)

1. Read `check_kernel` and its launch (`launch_batch`), the survivor list format (`surv`: top
   index + r0 per pair), what the check actually computes per survivor (digit extraction of n² and
   n³, how many limbs/digits, the distinctness test, the result write), and how it is sized (1024
   cubes × ? threads; how many survivors per batch at b62 1e17 / b60 1e16: 6.27e10 / 1.63e10 per
   field from L1.7 over 4,009 / 675 batches on the new plans — compute the per-batch load and the
   wave count on a 3080 (68 SMs) and on a 4090/4060).
2. Instruction budget per survivor from the SASS (`L41/raw/classify.py` style): the division
   sequence per limb, the digit loop, the mask ops; compare with the 86.5 ps per check L1.7 fitted
   and the 300 ps per unprefiltered check.
3. Design the rework and estimate each part: (a) size the grid to the device (cubes = f(SM count,
   survivors per batch) via CubeCL's device properties; what does the plan know?); (b) seed the
   digit scan with what is already known — the bottom's digits 0..k (the entry's mask, distinct by
   construction) and the top's certified digits (the record's mask) — so the kernel only converts
   the middle digits k..(2L − cert) of n² and n³; quantify how many digits that removes at b62 1e17
   and b60 1e16; (c) replace the 64-bit division by b per limb with an exact division by b^8 (or the
   largest power that fits a u32 chunk) followed by the FX-style fixed-point extraction of #246
   (eight digits from one 32-bit remainder with multiplies); (d) anything in the survivor list
   layout or the write-back that costs (atomics? the near-miss/hit output path).
4. Exactness: the check decides hits; any change must be exact by construction (the digit
   values are the same; only where they come from changes) — state the argument and the tests
   that pin it (the whole-b42 field: join = stride = reference; the 1e14 COMPARE's hits; the dense
   fields' `checked` counts are unaffected by the check's internals, so what tests the *result*?
   The hit lists — find the tests that compare found numbers, e.g. `NICE_TEST_JOIN_FULL_FIELD`,
   the b10/b20 windows with known hits).
5. Write `L47/SCOPING.md`: the budget, the design with per-part estimates (labelled estimates),
   the go/no-go against the 3 % kill line, and a one-day prototype plan with its codegen gate and
   A/B list. Budget ~2.5 h. No builds, no pushes, no subagents; write nothing else.
