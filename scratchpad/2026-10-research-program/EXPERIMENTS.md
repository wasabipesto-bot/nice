# Experiments

One section per experiment, newest first. Each records: lead id, date, box (Vast id
and GPU, or host), commit(s) under test, exact commands, raw data path, the table,
and the one-line conclusion. Benchmark claims follow PROPOSAL.md §5: same box,
interleaved A/B, ≥3 rounds, median and spread per scenario, no scenario −2 %.

## L36.1 The five open PRs on one tree vs main, and the profile after them (2026-11-03, agent; `L36/RESULTS.md`, `L36/raw/`; branch `exp/join-all5` 6ddab24 = exp/join-all3 + #240 c7ef3c8 + #239 775b6d9, CHANGELOG-only conflicts, cubecl_join.rs auto-merged = union of the two diffs)

RTX 3080 on machine m137673 **capped at 150 W** (not the 180 W of L29–L35: absolute seconds
not comparable, ratios are; clock wandered ~10 % per binary over the session). main 04693ac vs
all5, 3 interleaved rounds, medians of device s/field:
| field | main → all5 | ratio | product of per-PR ratios |
|---|---|---|---|
| **b62 1e17** | 280.24 → 148.92 | **×1.882** | ×1.843 |
| b62 1e16 | 23.01 → 11.77 | ×1.955 | ×1.790 |
| b60 1e16 | 52.65 → 29.22 | ×1.802 | ×1.760 |
| b64 1e16 | 64.93 → 41.85 | ×1.552 | ×1.560 |
| NiceMark | 3108.8 → 4991.8 | ×1.606 | ×1.625 |
Every round of every field faster (×1.55–1.97); spreads all5 0.1–0.6 % (b60 5.3 %), main
0.9–2.8 %. all5 ran at a lower clock than main (1074 vs 1162 MHz) → ×1.882 is conservative;
clock-normalised ×2.04; a late pair at similar clocks ×1.962 (140.1 vs 274.9 s). #240 gains more
at 150 W (top kernel ×1.70–1.74 vs ×1.585 at 180 W). **Exact:** CUDA parity incl. b50/b54, #240's
device test, #235's certificate test, both dense fields, whole b42; 1e14 COMPARE = main = the PR
bodies; whole-field counts = all3's exact counts every round; lavapipe naga + SPIR-V parity; lint
16 shaders 0 flagged. **Profile all5 b62 1e17** (main on the same box in brackets): top 29.7 %
(42.5; 116.5 → 40.6 s, ×2.87), bucket 1.9 % (0.9), **join 56.1 %** (50.4; 138.2 → 76.7 s, ×1.80),
check 8.2 % (4.1), other 4.1 % (2.0). b60 1e16: top 24.3 % (34.7), join 59.7 % (56.6), check 9.8 %.
The timers cannot split the join into AND and walk.

## L36.2 What a stepped top-kernel slot still pays for, and three exact trims (2026-11-03, agent; `L36/SCOPING.md`, `L36/raw/abl_*.txt`; branch `exp/top-fd-ablate` 47c1b36 on all5)

Stepped slot 0.219 ns per prefix at b62 1e17, 0.212 at b60 (150 W box). Ablation (9 rounds each),
share of the slot (b62 / b60): digit scan 32.5 / 29.9 % (per-digit c0 test and selects 19, run-of-
(b−1)s bookkeeping 14.5, the digit/bit work 6); append 17; carry test 14 (one cost with x mod
b^c0: 13); step 13 (registers 110 → 80 without it); ndig_fast power-table compare 6; carry test +
ndig together 22.5; floor with all six removed 30. In sequence without double counting: append 17,
scan 22, carry+ndig 22, step 8, floor 31. **Skipping the scan when the digits above c0 did not
change cannot work:** per lane they change on 35 % of steps at b62 (4 % at b60) and c0 never
changed in 1.1e9 stepped lanes, but a warp must scan if any lane needs it: 99.6 % of warp-slots at
b62 (85 % at b60). SWAR distinctness and fusing the two scans do not help (the cost is
bookkeeping). **No single change reaches 25 %.** Three exact trims prototyped behind switches:
carry c0 and b^c0 − d across steps (no power-table reads per step) −14.4 / −14.3 %; a
bookkeeping-free path for scanned words wholly above c0 −6.7 / −5.5 %; stepping slots skip forming
a, e and the clip test −2.5 / −1.8 %; **all three −22.3 / −22.9 % of the slot (0.218 → 0.170 ns)
= ×1.041 at b62 1e17 (139.7 → 134.3 s), ~×1.04 b60, exact counts**; pass #240's device test on
CUDA and lavapipe (naga + SPIR-V; blocks 298–310 → 325–343). **Parked: below the bar** (worth
~2 % from the c0 carry alone); the FD kernel is now ~20 % of a b62 1e17 field, the join 56 %.

## L35.2 PR #240: `pr/top-fd` on #237 (2026-11-02, agent; `L35/RESULTS.md` §12, `L35/PR-BODY.md`, `L35/raw/pr-box/`, `raw/analysis_pr.txt`; head c7ef3c8 = one commit on 51410e7, +1495/−169 in cubecl_join.rs)

One FD path (the measured mode, binary d2/d3 stepping); constants `TOP_FD_MIN_UNITS = 2^17`
(slot grouping for small top layers), `TOP_FD_AT_POW2_BASES = false`; `top_kernel` kept for
excluded bases and clipped blocks (`only_clipped`, compiled at device creation); ignored timing
test `cubecl_cuda_top_fd_timing` (env `NICE_TEST_TOPFD_TIMING`, like the other test harnesses).
**Final A/B vs #237 alone** (RTX 3080 180 W, interleaved, medians of 2 rounds; SM 1399–1434 MHz
#237 / 1417–1442 PR):
| field | #237 → PR s/field | ratio | per round |
|---|---|---|---|
| b62 1e17 | 182.3 → 168.8 | **×1.080** | 1.081, 1.078 |
| b62 1e16 | 15.31 → 13.72 | **×1.116** | 1.120, 1.112 |
| b60 1e16 | 36.01 → 33.82 | **×1.065** | 1.061, 1.068 |
| b58 1e16 | 57.42 → 55.03 | ×1.043 | 1.058, 1.029 |
| b64 1e16 (FD off) | 51.23 → 51.14 | ×1.002 | 1.036, 0.968 |
| NiceMark | 4415 → 4431 | ×1.004 | 1.014, 0.993 |
Clock-normalised b62 1e17 ×1.059. **Smaller than on the #235+#236+#237 tree (×1.143 / ×1.136 /
×1.084): 13.5 s saved per b62 1e17 field vs 18.3 s there; the agent did not profile why** (part
of the top kernel's time hides behind the slower join without #236?). Kernel alone on the PR
branch: b62 0.366 → 0.229 ns per prefix-slot (×1.585), b60 ×1.483, b58 ×1.605; a stepped
partition 0.190–0.198 ns. **Counts at 1e16/1e17 are not run-to-run identical on this base** (#235's
timing-dependent stage overrun, removed by #236; both sides vary by a few ppm; found 0 everywhere;
1e14 COMPARE identical to the digit; on the #236 tree every count identical). Exact: new device
test (26 fields, 279 batches, 23 clipped, 237.9 M tops; lavapipe naga + SPIR-V 21 fields),
certificate test = #235's counts, join parity CUDA + lavapipe ×2, dense b58/b62, whole b42, lint
16 shaders 0 flagged (TopKernel@57 still compiled), fmt/clippy. Registers 108–110, no spills,
2 blocks of 256 per SM; direct SPIR-V 298–310 blocks (< TopKernel's 368–386). **PR #240 opened
11:55 UTC**, stacked on #237 (on #235); the body explains the NiceMark neutrality (bit-reversed
partition samples seed every slot) and justifies on whole-field runs. Open program PRs = 5.

## L34.2 Gate screen and PR #239 (2026-11-02, agent; `L34/RESULTS.md` §11–12, `L34/PR-BODY.md`, `L34/raw/`; branch `pr/join-transpose-and` 775b6d9 on #236 fb05597)

Gate screen on #235–#237 (hybrid fcd6581, G=4, 2 interleaved rounds): MIN=128 / **192** / 256 →
b62 1e17 — / ×1.074 / ×1.065; b62 1e16 ×1.092 / ×1.063 / ×1.080; b60 1e16 — / ×1.078 / ×1.065;
b64 1e16 — / ×1.173 / ×1.149; 1e14 b60/b62/b64 ×0.989/0.953/0.970 / ×0.979/0.934/0.944 /
×0.963/0.939/0.970; NiceMark ×1.085 / ×1.107 / ×1.075; b58 MSD-strong ×0.992 / ×1.023 / ×0.999.
Any gate fixes the NiceMark small-bucket case; **no gate fixes 1e14 (×0.93–0.98), even 256 which
transposes nothing there: the cost is the kernel's footprint** (2 KiB shared → 5 cubes/SM instead
of 6, plus one barrier per batch). PR branch: one commit on fb05597, `TRANSPOSE_MIN = 192`,
`AND_GROUP = 4`, no knobs; cherry-picks clean, applies on exp/join-all3 too (CHANGELOG only).
**A/B on #236 alone:** b62 1e17 ×1.055 (183.9 → 174.3 s), b62 1e16 ×1.050, b60 ×1.062, b64 ×1.176,
1e14 b60/b62/b64 ×0.978/0.959/0.975, NiceMark ×1.075 (MSD-strong ×1.017); counts identical;
clocks within 1.3 % at 178–180 W. Registers 40 (= base), 0 spills, SASS 784 → 1,088, shared
14,344 → 16,392 B. Exact at the head: parity incl. b50/b54, dense fields, whole b42 (also all with
`TRANSPOSE_MIN = 0`), 1e14 COMPARE = #236, lavapipe naga + SPIR-V (133–136 blocks), lint 0
flagged, fmt/clippy clean. **PR #239 opened 10:40 UTC** (stacked on #236; the 1e14 caveat is in
the body). Not taken: survivors' top ids from `tl` frees 1 KiB shared but costs 45 registers
(still 5 cubes/SM; 1e14 results mixed).

## L35.1 Top kernel by finite differences across a batch's partitions: prototype A/B (2026-11-02, agent; `L35/DESIGN.md`, `L35/RESULTS.md`, `L35/raw/`; branch `exp/top-fd` fd58370 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_TOP_FD` = 0/1/2)

An unclipped block a = P·b^f0 has a^k = P^k·b^(k·f0): a², a³ are P², P³ shifted with zeros
below, and consecutive partitions are consecutive P, so the kernel keeps the detailed FD's five
packed digit arrays for n = P (23 words at b62 1e17) and steps them by additions; long division
only when a slot seeds (first slot of a batch, or after a gap); the two clipped partitions per
slice go to the old `top_kernel` (`only_clipped`). Production batches are `chunks(0..nparts)`:
consecutive; only P = plo / phi clip. Mode 2 (measured) also steps d2/d3 in binary.
RTX 3080 180 W, interleaved, medians, FD off → FD=2 (binary F 3574f0f):
| field | ratio | per round | s/field |
|---|---|---|---|
| b62 1e17 (5 rounds) | **×1.143** | 1.134–1.154 | 146.1 → 127.8 |
| b62 1e16 (3) | **×1.136** | 1.127–1.143 | 12.23 → 10.76 |
| b60 1e16 (3) | **×1.084** | 1.084–1.095 | 27.40 → 25.27 |
| b64 1e16 (3) | ×0.985 | 0.972–1.011 | → FD off at power-of-two bases (2111f09) |
Head H (post-A/B fixes): b62 1e17 ×1.129 (3 rounds), b62 1e16 ×1.135, b60 ×1.101. Kernel alone:
b62 1e17 0.363 → 0.229 ns per prefix-slot (×1.59), b60 0.333 → 0.226 (×1.47); a stepped slot
0.198 ns at b62 (×1.83 vs top_kernel), a seeded slot 0.350 (the seed is 31–36 % of the FD kernel);
the step's additions are unmeasurably small — what remains is the two certificate scans, the
remainder, the carry tests and the append (one atomic per plane). **NiceMark ×1.000** (rounds
1.015/0.999/1.014) after 6c8db87 compiles the clipped-block kernel at setup (before: ×0.93, all
from b58 MSD-weak ×0.72 = JIT compile inside the timed sample); NiceMark samples partitions in
bit-reversed order, so every slot seeds there and it cannot see the stepping gain. 2111f09 also
splits a batch's slots into groups when the top layer is under 2^17 prefixes: b62 1e14 ×1.16 →
×1.33, b57 1e14 ×1.38 → ×1.42. Registers (ptxas sm_86, no spills): top_kernel 80, FD mode 1 80,
mode 2 109–111 (2 blocks of 256 per SM instead of 3); cube size 64–256 no difference; direct
SPIR-V TopFdKernel 304–316 blocks vs TopKernel 368–386. **Exact:** new device test (both kernels
on the same batches: per-slot counts, bucket counts, sorted entries equal; 26 fields, 279 batches
incl. gaps, a backwards step, 23 clipped, 237.9 M tops on CUDA; lighter on lavapipe naga +
SPIR-V); certificate test = #235's counts; join parity FD=1/2 incl. SPIR-V; dense b58/b62,
whole b42, 1e14 COMPARE b57/60/62/64 identical; lint 0 flagged. Not run on Metal (seed = #237's
trimmed division; step/scan only add, shift, mask). Persistence across batches (not built):
≈ ×1.18 b62 1e17 / ×1.11 b60 at 192 B per prefix (~695 MB per b62 1e17 slice; plan budgeting).
Dead end on the way: binary-d stepping at 160 registers was slower; the real cap was a
same-address atomic the compiler only aggregates in `top_kernel`. Follow-up L35.2: PR branch
`pr/top-fd` on #237, final A/B incl. b58 1e16.

## L34.1 Digit-transposed AND in the join kernel: prototype A/B (2026-11-02, agent; `L34/RESULTS.md`, `L34/raw/`; branch `exp/join-transpose` 432b795 on `exp/join-all3` 0f1a8a7; switch `NICE_EXP_JOIN_TRANSPOSE=1`, `_G` chunks per digit pass, hybrid gate `_MIN`)

RTX 3080 (180 W cap), 3 interleaved rounds, medians, every round faster; A = `exp/join-all3`
(main 04693ac + #235 + #236 + #237), B = switch on, G = 4.
| field | plain, G=4 | hybrid MIN=128 (2 rounds) |
|---|---|---|
| b62 1e17 | ×1.063 (143.17 → 134.73 s) | ×1.075 |
| b62 1e16 | ×1.075 (12.16 → 11.32) | ×1.086 |
| b60 1e16 | ×1.064 (27.08 → 25.46) | ×1.065 |
| b64 1e16 | ×1.140 (38.44 → 33.72) | ×1.129 |
| 1e14 fields | ×0.83–0.92 (3.2 tops per bucket at b62) | ×0.96–0.99 |
| NiceMark | ×1.049 (5538.6 → 5810.8); b58 MSD-strong ×0.90 | ×1.085; b58 MSD-strong ×0.98 |
Join phase −12.5 % at b62 1e17 (75.3 → 65.9 s), −11.9 % at b60; no other phase moved. Against
L1.7's split the AND got only ~×1.3 cheaper, not 2–4×: each digit load is a gather with ~2-way
bank conflicts (d and d+32), so shared-memory wavefronts drop ~25 % (64 → ~48 per warp per 32
tops) while ALU work drops ~3× — the per-top AND is bound by shared loads, not ALU. Building the
transposed copy costs 1.4 % of the field on its own. G=4 beat G=8 (brief's order A) by 0.5–3.4 %
and G=1 (order B) gained nothing. Registers: base 40 (6 cubes/SM); G=4 56 (4/SM; +2 KiB shared
alone caps at 5); hybrid 44 (5/SM). Direct-SPIR-V JoinKernel 109–112 → 123–126 blocks, no
overflow. **Exact everywhere:** CPU-reference parity incl. b50/b54, both dense fields, whole b42,
1e14 counts at b57/60/62/64 identical, every A/B count identical, lavapipe naga + SPIR-V, lint
0 flagged, fmt/clippy clean. **Baseline profile after #237** (b62 1e17, 140.1 s profiled): top
34.6 %, bucket 1.7 %, join 52.8 %, check 6.5 %, other 4.4 %; b60 1e16 join 57.7 %.
Follow-up (L34.2): gate at MIN=256 (full top batches only) / 192, then a PR branch on #236.

## L3.2 GPU detailed finite differences and the readback fix, protocol on a default-power 3080 (2026-10-30, agent; `L3/PR-RESULTS-3080.md`, `L3/pr-raw/3080/`; PRs #224 readback, #225 FD)

RTX 3080 20 GB (58401551, US), power limit 320 W = default = enforced = max; both kernels hit
it (~318 W): division kernel 1755–1770 MHz, FD 1860–1890 MHz (×1.07 clock). `auto` = CubeCL
CUDA. NiceMark detailed GPU, 150 s, A B C × 3:

| | main | readback (rb) | FD | FD/rb | FD/main |
|---|---|---|---|---|---|
| b40_detailed | 1.018e10 | 1.108e10 (+8.8 %) | 3.352e10 | 3.03× | 3.29× |
| b50_detailed | 7.512e9 | 8.052e9 (+7.2 %) | 2.978e10 | 3.70× | 3.96× |
| detailed GPU score | 4609 | 4986 | 16624 | 3.33× | 3.61× |

2e9 windows: FD/rb 3.09× (b40), 3.60× (b50). One 1e10 field (the new server cap, #223): b50
1.218 s → 0.325 s (3.75×), b52 1.288 → 0.333 s (3.86×); the readback fix is nothing at that
size. Per clock FD/rb ≈ 2.8× (b40), 3.5× (b50), same as the capped card yesterday.
Exactness: all CUDA FD tests; main vs FD identical on 100 windows across every base 10–64
(8.6e9 numbers, 261 near-misses); bases 10–28 in full (73 near-misses). Portability: wgpu uses
a 32-bit split seed (no u64 in WGSL); lavapipe passes via naga WGSL and CubeCL SPIR-V, also
`NICE_CUBECL_WIDE=1`; all 19 CI lavapipe tests pass; Metal translated by naga 29.0.4, no Mac
(the macOS CI job is the first real run); HIP not built. Branch heads: readback 6a1e396
(CubeCL `offset_end` read of `count` records, hand-CUDA slices its copy; 3 tests), FD f3a33cf
(`common/src/cubecl_detailed_fd.rs`, FD_RUN_LEN 128, all of bases 10–64's legal ranges;
division kernel kept above 64 and as reference). 4090 numbers pending (agent running).

## L8.1 Near-miss tail test of the probability model (2026-11-01, agent; `L8/RESULTS.md`, `L8/models.py` etc., `L8/data/`)

Exact detailed histograms for bases 12–49 + base 50's 24 % sample (~1.1e9 numbers in the top 7
bins; brute-force recount of b20/22/24 matches the API). **Near tail (3–6 missing digits): the
project's model applied at every depth fits within 2–3 % (pooled 0.97–0.98); the plain iid model is
13 % high** (so dropping August's ×0.846 was right). **A leading-digit factor is missing from λ**:
the top digits of n² and n³ are both set by n's top digits; adding the top digit of each power
brings depths 3–6 to 0.99–1.00 and explains the per-base scatter (χ² 3,890 → 156 over 25 bases;
correlation 0.91); at k = b it is 0.86–1.06 per base; folding it in moves today's 5.45 % to 5.34 %
(ahead: b60 ×0.99, b62 ×0.91, b64 ×1.02). **Two missing digits: 512 observed vs 582 expected, ratio
0.88 [0.81–0.96]**, even across bases but mostly from the bases that flagged it in August; the bases
added since give 0.96 [0.82–1.12]; no arithmetic cause found. One/zero missing: 7 vs 5.7, 0 vs 0.05.
**For the cost model:** the correction at k = b is ~0.67–1.0 (0.53–1.14 with CIs); today's 5.45 %
→ **~4.7 % best guess (3.7–5.3 %)**; nothing shows under-prediction; costs and search order
unchanged; METHODOLOGY's "the tail is untested" → "tested to two missing digits; may be up to
~1.5× optimistic"; 77 % of today's odds come from bases 12–25. Per-base factors: `L8/data/top_factor.csv`.
Proposed (needs the user's OK: it changes the published headline): add the leading-digit factor to
`scratchpad/2026-08-cost-probability/build.py` and the METHODOLOGY note.

## L9.1 H100 SXM and L40S on the join and detailed mode (2026-11-01, agent; `L9/RESULTS.md`, `L9/raw/`)

Upstream main fae7398, `auto` = CubeCL CUDA; nothing uploaded. Both host-capped (H100 500 of 700 W,
~1.6 GHz; L40S 300 of 350 W, ~2.15 GHz), no thermal limits.

| | H100 SXM ($2.14/h) | L40S ($0.54/h) | RTX 3080 180 W ($0.11–0.15/h) |
|---|---|---|---|
| NiceMark nice-only (median of 3) | 8,349 | 10,245 | 3,711 |
| NiceMark detailed (2 runs) | 33,056 | 43,579 | 16,624 (320 W) |
| b60 1e16 s/field | 20.1 | 16.4 | — |
| b62 1e16 s/field | 12.7 | 10.6 | — |
| b62 1e17 s/field | 103.8 / 103.5 | 81.4 / 79.5 | 229 |
| numbers per $ at b62 1e17 | 1.6e18 | 8.3e18 | 1.05–1.43e19 |
| per $ vs the 3080 | 0.11–0.15× | 0.58–0.79× | 1 |
| break-even $/h | 0.24–0.33 | 0.31–0.43 | — |

vs the 4090 (21.6–25.7k NiceMark per $/h): L40S 19.0k (0.74–0.88×), H100 3.9k. Join layout identical
on both (b62 1e17: 7 slices × 3,844 partitions, 3,785 batches of 6, 2,594 MiB); survivor and check
counts match the 3080 to 4–5 figures. The work is integer-bound: the H100's clock cap and bandwidth
do not help. The join's memory budget stops at 4 GiB (join_plan.rs) so 46/80 GB sit idle (slices
were measured not to be a lever in L1.7, so no action). **Fleet guidance:** never buy H100 at
market; L40S only under ~$0.35/h.

## L33.2 Top kernel part 2 as a PR: limb skip + (a) + (c) on #235 (2026-11-01, agent; `L33/PR-RESULTS.md`, `L33/pr-raw/`; PR #237, branch `pr/join-top-cert-2` 252e69e on 6e7475e)

RTX 3080 180 W (1406–1474 MHz), A = #235, interleaved, medians (every round faster):
| field | vs #235 | per round | implied vs main |
|---|---|---|---|
| b62 1e17 (5 rounds) | ×1.100 | 1.089–1.122 | ×1.210 |
| b62 1e16 | ×1.098 | 1.098–1.113 | ×1.196 |
| b60 1e16 | ×1.092 | 1.077–1.110 | ×1.150 |
| b64 1e16 (2 rounds) | ×1.019 | 1.015–1.023 | ×1.015 |
| NiceMark 4048 → 4484 | ×1.108 | 1.094–1.124 | ×1.186 |
Exact: certificate test with #235's counts (102,365 / 33,582 / 69,824) on CUDA, lavapipe naga and
SPIR-V (word-for-word difference check kept); join parity incl. b50/b54 on CUDA and lavapipe SPIR-V;
both dense fields; whole b42; COMPARE 1e14 counts = #235 at b57/60/62/64; digit-count host test;
fmt/clippy ×3; lint 0 flagged; TopKernel constant divisions 539 → 270; SPIR-V blocks 478 → 366
(b57), 496 → 384 (b64). Not run on Metal (M4) — stated in the body. Stacked on #235, independent of
#236. With #236 the three join PRs together project to ≈ ×1.50 at b62 1e17 vs main.

## L33.1 Early reject in top certification: no-go, and the limb-skip side finding (2026-11-01, agent; `L33/SCOPING.md`, `L33/raw/`; branch `exp/top-early-reject` f409f51)

150.7 G pairs counted (one field each at b60 1e16, b62 1e16, b62 1e17). At b62 67.6 % of pairs fail:
60 % share a digit between a² and a³, 33 % repeat within a², 31 % within a³ (overlapping), 1.7 %
closure only; carry/ndig never reject alone. The first repeat is always among the two lowest
certified digits of a power (the parent certified the higher ones); digits come out low first, but
partners come later, often in the other power; nothing is known before the square's 10th pass of
13; 22.5 % of pairs are dead after the square (39.9 % with the parent's cube digits on the device,
+2 words per `tlay` entry; sound on all 150.7 G). **An in-place exit cannot fire (99.9998 % of 32-lane
planes hold a kept pair): ×1.010; block-level compaction ×1.000 (1e17) / ×1.018 (1e16); parent-digit
version ×1.036 (≈ ×1.045–1.053 without its host pass) → the early reject fails the bar.**
**Side finding, clears the bar:** the long division ran all 12 or 18 limbs every pass though the top
ones are known zero; skipping them (~8 lines) cuts 60 % of division steps: exact (certificate test
with #235's counts, join parity, counts identical), no SPIR-V blocks added, lint clean; **×1.051 at
b62 1e17 (6 rounds), ×1.058–1.071 b62 1e16, ×1.057 b60, NiceMark ×1.066**; with the parent-digit
compaction ×1.092–1.099 at b62. PR candidate: limb skip + L31's (a)+(c) (≈ ×1.10 together), needs an
M4 run and a combined measurement.

## L31.2 (a)+(c) on the combined tree (2026-11-01, agent; `L31/AB-COMBINED.md`, `L31/ab-raw/`; branch `exp/top-cert-2b` eb3d7e6 on e9cdac4)

RTX 3080 180 W (m139250), A = combined e9cdac4, interleaved: **b62 1e17 ×1.045 (5 rounds, 1.023–1.057;
A's spread 3.9 %), b62 1e16 ×1.038 (6 rounds), b60 1e16 ×1.059, b64 1e16 ×1.022, NiceMark ×1.041**
(b60 ×1.056, b62 ×1.054, b58 weak ×1.041, strong ×1.019). The ~7 % projection came out at 4–6 %
(top kernel not profiled; gap unexplained). Exact: certificate test with #235's counts on CUDA,
lavapipe naga and SPIR-V (now also checks the power differences word for word; the old binary
search stays in the reference scan); join parity incl. b50/b54, dense fields, whole b42; 1e14
counts = A; new host test for the digit-count constants at bases 10–64; fmt/clippy ×3 clean; lint 0
flagged. SPIR-V TopKernel blocks 478 → 366 (b57), 496 → 384 (b64). **Verdict: no-go narrowly** (b60
clears 5 %, b62 does not). Options for the user: ship as an exact ×1.04–1.06 kernel shrink; add the
Barrett step after an M4 run; fold into the next cert_power change.

## L32.1 Wave padding after #236: bucket-sized tail wave (2026-11-01, agent; `L32/SCOPING.md`, `L32/raw/`; branch `exp/join-padding` ed8bc8c, switch `NICE_EXP_JOIN_TAIL=1`)

Combined tree (e9cdac4), RTX 3080. Accounting: at b62 1e17 every bucket fits one 512-lane wave
(256–479 entries; 78 % of pairs in 288–351); waves use 64.8 % of lanes (35 % empty); b60 1e16 uses
77–79 % (buckets 384–447); buckets under half a wave 0–3 % of pairs. Re-fit over 12 profiled runs:
1.64 ps per real lane-pair, 0.64 ps per empty lane, **21 ps per survivor (61 before #236)**, 104 ps per
top; empty lanes cost 8.7 s per b62 1e17 field (5.1 %), 1.0 s per b60 1e16 field (3.2 %). Candidates:
EPT 1 ×0.92–0.95 (same lanes, twice the waves); packing two small buckets: nothing to pack; EPT 3/4 +
tail ×1.044/×0.973. **Prototype: a partial wave uses only the planes its entries need, planes skip
the AND for slots they don't hold**: removes 87–93 % of empty lanes; exact (join parity incl.
b50/b54, dense fields, COMPARE 1e14; counts = base); WGSL lint clean; SPIR-V blocks 109 → 123;
registers 40 → 41 (likely one fewer resident cube per SM; a 40-register bound would need a spill
CubeCL can't emit). **A/B: b62 1e17 ×1.040 (5 rounds), b62 1e16 ×1.051, b60 1e16 ×1.028, NiceMark
×1.078 (5016 → 5406).** Verdict: below 5 % at the live sizes; NiceMark alone clears it. Not run on
lavapipe or Metal (plane skipping inside the wave must be checked for barrier uniformity there).
**Parked**; `2a681f6` is the measured commit (fails fmt/clippy), head ed8bc8c is clean.

## L30.4 Second card: #235, #236 and both on an RTX 4090 (2026-11-01, agent; `L30/second-card/RESULTS-4090.md`)

RTX 4090 (58626188, GB, $0.309/h; power limit set to 300 W of 450; 2,360–2,470 MHz; no thermal
throttling), interleaved main/#235/#236/both, medians of 3, spreads ≤ 2.9 %:

| | #235 | #236 | both |
|---|---|---|---|
| b62 1e17 | ×1.101 | ×1.181 | ×1.341 |
| b62 1e16 | ×1.116 | ×1.182 | ×1.339 |
| b60 1e16 | ×1.084 | ×1.235 | ×1.361 |
| b64 1e16 | ×1.002 | ×1.309 | ×1.331 |
| NiceMark nice-only | ×1.076 | ×1.167 | ×1.260 (10,093 → 12,718) |

The savings add: `both` within ±1.2 % of the additive prediction (100.4–103.1 % of the product); #235
gains nothing at b64 on one card (the 3080's apparent shortfall came from cross-box comparison).
Exactness on `both`: CPU-reference test passes; 1e14 join = stride and counts = main to the digit;
1e16/1e17 counts identical every run and equal to the 3080's. PR bodies #235/#236 updated with the
second card.

## L30.3 #235 + #236 combined vs main, and the profile after both (2026-11-01, agent; `L30/COMBINED.md`, `L30/combined-raw/`; merge branch `exp/join-235-236` e9cdac4)

Merge: cubecl_join.rs and join_plan.rs merged on their own; only the CHANGELOG line conflicted.
Exactness: CUDA certificate test (L29 counts), join parity incl. b50/b54, both dense fields; 1e14
counts = main at b57/60/62/64; 1e16/1e17 counts = #236's exact counts every run; fmt/clippy/lint clean.
RTX 3080 (m139250, 180 W), interleaved, medians, spreads ≤ 2.2 %, every combined round faster:
**b62 1e17 ×1.365 (226.8 → 166.2 s); b62 1e16 ×1.350; b60 1e16 ×1.379; b64 1e16 ×1.305; NiceMark
3676 → 4871 (×1.325).** Each PR alone on the same box at b62 1e17: #235 saves 20.7 s (×1.100, up
from ×1.075 thanks to its SPIR-V fix), #236 saves 39.4 s (×1.210); product ×1.332, additive 166.65 s
vs measured 166.16 s: **they compound** (each shortens only its own kernel). At b64 #235 does nothing
(×0.996); the combined b64 gain is #236's. **Profile after both:** b62 1e17 top 43.3 %, join 45.9 %,
check 5.7 %, other 5.2 % (main: top 41.3 %, join 50.7 %); b60 1e16 top 36.6 %, join 50.4 %. The stage
never overflows now. **35 % of the join's lanes are padding at b62 1e17** → next levers: the top
kernel (L31's (a)+(c), no Apple risk, ~18 % off the top kernel ≈ 7–8 % whole-field at this share) and
wave padding (L32: bucket-sized tail wave / EPT 1 at 1e17).

## L31.1 Top kernel part 2 scoping (2026-11-01, agent; `L31/SCOPING.md`, `L31/raw/`; branch `exp/top-cert-2` 3eb8e5e, switches `NICE_EXP_TOP_*`)

Top kernel time at b62 1e16 (on #235): long division of a^j 33 %, digit extraction/bookkeeping 22 %,
binary search for ndig(d) 14 %, computing a^j/e^j 10 %, in-kernel bookkeeping 8 %, launch + a/e 6 %,
closure 5 %, carry test 4 %; scan + fill kernels another 16 %. Whole-field (180 W 3080, interleaved,
spreads 1–4 %): (a) e^j − a^j from e − a ×1.020 (b62 1e16) / ×1.016 (b60); (b) Barrett digit step
×1.011 / ×0.995 (CUDA already turns the constant division into a multiply); (c) ndig from the bit
length + one compare ×1.042 / ×1.039 (top kernel −14 %); (a)+(c) ×1.062 / ×1.031, **b62 1e17 ×1.021**;
**all three ×1.056 / ×1.047, b62 1e17 ×1.053.** Certificates identical to #235's everywhere; tests pass
on CUDA and lavapipe (WGSL and SPIR-V); SPIR-V blocks b57 478 → 366 ((a)+(c)) → 258 (all), b64 270
(#235: 496); lint 0 flagged; no constant division in the new code. A PR needs: an M4 run of (b)
(`mul_hi` = 64-bit product >> 32, never divided; unproven on Apple), switches removed, host tests for
the precomputed constants, b64 + NiceMark + an uncapped card. **Parked at ~5 %: marginal; revisit
after #235/#236 land and the combined profile shows the new split.** (c) alone is worth keeping.

## L30.2 Prefilter in the walk, PR #236 (2026-11-01, agent; `L30/RESULTS.md`, `L30/pr-raw/`; branch `pr/join-prefilter-in-walk` dd4a0eb on fae7398)

One commit; the prefilter runs in the set-bit walk before staging and is the only path (no switch);
handles every join shape the host accepts (old test windows b10–64, k = 1–5, with/without key level
run the new code); compile-time zero terms as in `cpu_join`; `mid_pass`, the flush-time prefilter,
its plane compaction and `ext_pk` deleted; the flush is one atomic + a plain copy; join kernel
registers 62 → 39. Memory plan: `ext_q` 8 B per entry×slot (was `ext_pk` 4 B), counted by `Footprint`;
plans +2–11 MiB, partitions per launch unchanged.
RTX 3080 (180 W), interleaved ×3, median device s/field: **b62 1e17 225.9 → 186.0 (×0.823)**, b62
1e16 ×0.846, b60 1e16 ×0.806, b64 1e16 ×0.769; **NiceMark nice-only 3768 → 4500 (×1.194)**; every
round faster; spreads main ≤ 3.1 %, PR ≤ 1.6 %. Exactness: counts identical run to run and to the
prototype; at 1e14 survivors/prefilter survivors/hits = main; larger fields differ from main only
by main's stage overrun; CPU-reference test (CUDA), both dense-field tests now assert exact equality
with the CPU join and pass, whole b42 matches; lavapipe join tests pass via naga and CubeCL SPIR-V
(no RUST_MIN_STACK); lint 0 flagged with JoinKernel@57/BucketKernel@57 met; fmt/clippy ×3/host
suites clean. Not run on Apple (lint is the Metal check). Merges cleanly with #235 except a
one-line CHANGELOG conflict (whichever lands second rebases).

## L30.1 Survivor handling in the join kernel: breakdown and the prefilter-in-the-walk prototype (2026-11-01, agent; `L30/SCOPING.md`, `L30/raw/`; branch `exp/join-survivors` 655f953)

RTX 3080, b62 1e16, profiled join phase, runtime switches removing one piece at a time (2 rounds):
survivor handling = **81 ps per AND survivor** (73 % of the join, 35 % of the field; the fit's 61 ps
understated it because survivors and AND lanes co-vary): prefilter arithmetic 35.5 ps (~290
instructions, rebuilds all 8 digit columns though only positions 6–7 are new); staging + flush
barriers/scans 17.7 ps (the shared atomic ~1 ps); set-bit walk 14.9 ps (23 % lane use); list writes
+ global atomic per flush round 11.9 ps. Prefilter keeps 6.13 / 6.13 / 6.70 % (b62 1e16 / 1e17 / b60
1e16); position 6 alone ~26 %, n²'s digit at 6 alone ~52 %; a third position would leave 20–21 %
(≤ 1.9 % gross, ~1–1.5 % net). Ballot compaction of the atomic ~1 ps (not worth it).
**Prototype (`NICE_EXP_L30=256`, ~110 lines): the prefilter runs in the walk, before the stage,
hoisted as the CPU join does (per-top part, per-entry part, ~50 instructions per pair).** Speed:
**b62 1e17 ×0.833 (225.7 → 188.0 s)**, b62 1e16 ×0.839 (3 rounds; ×0.850 vs main's own binary), b60
1e16 ×0.803; clock-normalised ×0.847 / 0.860 / 0.819. Exact: AND survivors = PROFILE-3's counts to
the last digit at all three sizes; the stage overrun disappears; CPU-join comparison on 4 partitions
equal. Registers 62 → 44 (occupancy is not the source: capping it back costs 1.3 %). Before a PR:
the per-entry buffer in the memory plan; the Metal rule on the new `(ac >> 16) + …` division (a sum
dividend; the lint decides). Unprototyped follow-ups: plane-compacting survivors before the
prefilter (est. 5–10 % more), the third prefilter digit (~1–1.5 %).

## L29.2 #235 SPIR-V compiler stack overflow, cause and fix (2026-11-01, agent; `L29/SPIRV-FIX.md`, `L29/spirv-raw/`; head 6e7475e)

CubeCL's SPIR-V compiler nests ~1 `compile_block` frame per 2 code blocks (~1.1 kB each) on the
device thread `DSD-4-0` (default 2 MiB stack); gdb showed 1,079 nested frames at the overflow. The
PR's certificate test kernel (four power scans + `top_cert`, up to 2,101 blocks; b47 with 3 words
failed first; b50 needs 2.26 MB) overflowed; production kernels did not, but the PR had grown the
b64 top kernel 580 → 778 blocks (peak 620 → 868 kB in the join parity test). naga's WGSL path
compiles differently. **Fix:** `cert_power` branches once per chunk (a chunk wholly below c0 is used
as its value; other chunks fold digits with selects): b64 top kernel 496 blocks (< main's 580),
512 kB peak; the test launches in three parts (largest 548 blocks). Verified on the box (Mesa 25.2.8,
rustc 1.99.1): both lavapipe steps (SPIR-V 24, naga 29), lint 0/15, CUDA parity + certificate test
with L29's exact counts, fmt/clippy clean. Speed RTX 3060 b62 1e16, 2 rounds: main 35.18 s, PR
32.84 (×1.071), fix 32.09 (×1.096 over main). **#235 CI green (25 pass).**

## L29.1 GPU top certificate from one endpoint's digits and a carry test (2026-11-01, agent; `L29/RESULTS.md`, `L29/raw/`; PR #235, branch `pr/join-top-cert-fast` d6cc9da on 9bde4a8)

`cert_power` divides only a^j into digits, keeps both candidate answers while scanning, and picks
with (a^j mod b^c0) + (e^j − a^j) ≥ b^c0; the remainder is built in 16-bit limbs from the digits
below c0 by compile-time-constant multiplies; the long division is #228's; no new division.
Exactness: new test `top_certificates_match_the_lockstep_scan_and_the_cpu` (wgpu + CUDA): 102,365
intervals, 33,582 kept, 69,824 powers taking the carry, word-for-word vs the old lockstep scan and
vs the CPU `Base::cert`/`cert_floor`; all existing join parity tests (b50/b54 windows, dense fields,
whole b42, join = stride), host 221; lint clean; WGSL lint 0 flagged (incl. the test kernel at bases
10–64). Certified-top counts = main at 1e16; survivors/checks = main to the last digit at 1e14 (at
1e16/1e17 they vary run to run on main too, via the stage overrun, by the same amount).
RTX 3080 host-capped 180 W, interleaved, medians of 3 (spreads ≤ 2.7 %, every PR round beat the main
round before it): **b62 1e17 229.3 → 213.3 s (×1.075); b62 1e16 ×1.089; b60 1e16 ×1.053; b64 1e16
×1.040**; NiceMark 3711 → 3976 (×1.071), scenarios ×1.049–1.106, none slower; 1e14 ×1.007–1.055 (2
rounds). Top kernel alone ×1.24 (b62), ×1.22 (b60), ×1.08 (b64: its chunk divisor 2^12 was already
a shift). Not done: e^j still computed in full (only e^j − a^j is needed); a limb-bounded division
variant was bit-identical with no clear gain (patch saved); AMD/Apple not run.

## L1.7 Join profile at b62 1e17 (the live size) on main 9bde4a8 (2026-11-01, agent; `L1/PROFILE-3.md`, `L1/profile3-raw/`; branch `rp/gpu-profile-3` bddf20f)

RTX 3080 10 GB **host-capped at 180 W** (1430–1510 MHz; absolute seconds ~1.22× PROFILE-2's card;
shares and the fit carry over). **b62 1e17: 223 s device per field = 7.28 µs per prefix, the same
as b62 1e16.** Profiled shares (probe excluded, +7.2 % overhead): top certification **37.8 %**, join
45.7 % (survivor handling 26 % of the field, real AND lanes 12 %, per-top chunk cost 4 %, padding
3 %), check 3–4 % unprofiled (7.9 % profiled), bucket 3.3 %, other 5.3 %. Stage-overrun extra
checks 0.014 % (1.1e-4 of survivors). Layout 11 slices, 6,439 batches of 5–8 partitions, 30.6M
prefixes; host setup 19 s CPU per field, overlapped except the first slice.
**Refit (1e16 + 1e17, 12 runs, rms 1.6 %):** join = 1.18 ps × real lane-pair + 0.49 ps × empty lane
+ 60.8 ps × AND survivor + 238 ps × top; fitted on 1e16 alone it predicts 1e17 within 4 %: **1e17
adds no new cost term.**
**Levers at b62 1e17:** (1) top certification: 12 % faster = 5 % win, 25 % = 10 %; it costs 0.77 ns
per (prefix, partition) and only 32 % of those pairs certify; (2) survivor handling: 18 % cheaper
per survivor (or 18 % fewer survivors) = 5 %; (3) AND lanes: 37 % per lane-pair = 5 %; nothing else
reaches 5 % (padding 3 %, per-top 4 %, per-check 2.4 %). **Batches/slices are not levers
(measured):** halving the survivor bound (38 % fewer batches) ×0.994; 11 → 4 slices ×0.991 (wider
slices prune 9.4 % less). Notes: the first unchecked b62 field has no top-layer prefixes (empty);
at b64 #228's top kernel reads ~12 % slower than clock-scaled (b64 not live; card confounded).

## L28.1 Two-word digit mask in the native FD kernel on wgpu (2026-11-01, agent; `L28/RESULTS.md`, `L28/raw/`; branch `pr/fd-u32-mask` 2b8d524, NOT opened)

`fd_mask_u32` moved from cubecl_web.rs into cubecl_detailed_fd.rs and shared; `fd_mask_sc` picks
u64 on CUDA/HIP and the u32 pair on wgpu (switched on `wide_chunk`); no divisions. RTX 3060:
CUDA 3 FD tests + 44-base sweep (132 windows, 9.6e8 numbers, 180 near misses) exact; lavapipe via
naga and via CubeCL SPIR-V: FD tests + browser FD tests + sweep exact; host 221; fmt/clippy clean;
WGSL lint 0 flagged; u64-naming lines in the native FD kernel's WGSL 135 → 32 at b40 (prologue,
seed word split, near-miss record remain); browser kernels' WGSL byte-identical to main.
**Speed:** CUDA PR vs main 0.992 / 1.001 / NiceMark 0.996 (unchanged). **The pair forced on CUDA is
24 % slower** (0.766 / 0.763), so CUDA/HIP keep u64. lavapipe PR 0.91–0.94× main on a noisy shared
host → Vulkan on native-u64 cards (AMD, NVIDIA-wgpu) may lose. **Apple M4 and AMD unmeasured.**
Decision: hold the branch; measure on the M4 and on AMD before opening; if AMD loses, gate the pair
to Metal adapters only (the wgpu backend enum is already read for the earlier Metal gate).

## L24.4 AMD parity for #233, run by the user (2026-10-31; `parity-demoux-1031.json`)

demoux, RX 9070 XT, LibreWolf (Firefox 155, wgpu → naga → Vulkan), `parity.html` served from
ivory (https://100.109.36.42:8443), build ae8b0bd, `gpu_build_info.detailed_kernel = "fd"`.
**199 windows, 25,471,443 numbers, 50 near misses, 0 differences, 23 s wall**; adapter present,
not a fallback (Firefox blanks vendor/architecture/description). Rate check: 2e8 at b40 in 0.117 s
= 1.71e9 n/s with Firefox's 16.7 ms timer steps (sanity floor only; the browser benchmark suite
on AMD is still unmeasured). The user noted LibreWolf now runs it without flags ("they must have
pushed some updates"). With this, #233 is exact on: lavapipe, SPIR-V, SwiftShader, M4 Chromium
(Tint → Metal), M4 native (naga → Metal), and AMD Firefox (naga → Vulkan).

## L24.3 Browser GPU detailed mode by finite differences (PR #233) (2026-10-31, agent; `L24/RESULTS-B.md`, `L24/raw-b/`; branch `pr/web-detailed-fd`, rebased onto main ba03322)

Exactness, 0 differences everywhere: native lavapipe (naga) `web_fd_matches_cpu_detailed` 430
windows (§3.3 list), `web_fd_seed_matches_cpu` 132/132 word for word, existing `web_kernel_*`
tests; CubeCL SPIR-V compiler: same five tests; CUDA FD suite + native lavapipe FD suite (native
kernel unchanged); host 221; fmt/clippy clean (default, gpu, gpu+spirv, wasm crate host and
wasm32 `--no-deps`); WGSL lint 122 shaders 0 flagged (FD kernel + seed probe at all 44 bases; no
u64; hot loop has no division); SwiftShader (CI image) `run.sh`, harness parity 199 + 13 windows,
seed probe 132/132, 78 run-shape runs; **M4 Chromium 151 headless no flags: parity 201 windows
(4.25e8 numbers, 50 near misses) + 440-window sweep, seed probe 132/132, 318 run-shape runs**; M4
native naga→MSL (Firefox's path): five tests pass, with the half-shift reproducer still failing
there as a live control.
**M4 speed (3 rounds, interleaved, spreads ≤0.4 %):** b40 6.59e8 → 4.40e9 (**6.7×**), b50 3.82e8 →
3.86e9 (**10.1×**), browser GPU NiceMark 265 → **2170 (8.2×)**. The browser now runs ~1.8× the native
wgpu FD kernel on the same M4 (guess: the native kernel's u64 mask is emulated on Apple; a u32 mask
there is a separate change = new lead). Run length stays 128 (64 is 3–5.5 % slower, 256 +0.7/+2.4 %).
Machine time 29 min wall (~15 min running). CI cost: +~85 s per lavapipe pass, +~140 s on SPIR-V.
**Coordination:** #231's lint `--require DetailedKernelU32@40/50` must gain `DetailedFdKernelU32@40/50`
(and keep one per-number call) once both are in; whichever lands second carries that edit.

## L24.2 Parity step, adapter check and WGSL lint (PR #231) and the CI flake (2026-10-31)

**PR #231** (`pr/browser-parity-step` 0f87771 on 2a1caf2): `web/search/parity.html` + `parity.js`
compare `process_chunk_gpu` vs `process_chunk_wasm` as raw JSON byte for byte and show adapter info;
the e2e drives the same page (CI: 13 windows, 9.3 s; `--parity hw`: 199 windows, 2.5e7 numbers);
a difference fails with the window and first differing field; a hung window fails and continues;
no adapter → `PARITY SKIPPED`; `--hw` requires a real non-fallback adapter matching
`--expect-vendor` and a warm 2e8 b40 call > 1e8 n/s. `scripts/wgsl-lint.py` + ignored test
`wgsl_dump_for_lint` (browser, detailed, stride, join kernels) in the lavapipe job: 8 s, 14 shaders,
0 flagged on main; flags the pre-#225/#228/#229 shaders and the reproducers. CI e2e 64 s vs 50–53 s
on main. M4 headless: `--hw --parity hw` passes in 26 s (199 windows, 50 near misses identical);
`--parity-random 10`: 639 windows identical; `--expect-vendor amd` fails as designed. Side note:
rootless podman on ivory leaves an empty `oom` file in the cwd; **upstream main has a tracked
`oom` at the repo root since #226** (same cause, the user's commit).
**CI flake diagnosed:** run 41219859643 attempt 1 (main 2a1caf27, NVRTC job) failed
`gpu_niceonly::tests::threaded_pipeline_matches_the_one_field_form_field_by_field` at
gpu_niceonly.rs:1730: left = 250000-wide descriptors, right = 500000-wide; the log shows the
adaptive MSD floor firing under load ("250000 → 270856, cpu waited 33 %"). The same test failed 3×
on the boxes under `--test-threads 8`, always passing alone (L25/L26). Timing-dependent test →
fix = pin the floor in the test (L27, agent running).

## L24.1 Headless WebGPU bring-up on the M4 and PR #230 (seed refactor) (2026-10-31, agents; `L24/BRINGUP-M4.md`, `L24/RESULTS-A.md`)

**Bring-up (22 min of Mac time):** Playwright 1.62 `channel: "chromium"` (Chrome for Testing 151),
macOS 26.3, over SSH, no GUI: adapter `apple`/`metal-3`, `isFallbackAdapter` false, warm 2e8 b40
call 6.56e8 n/s with **no flags**; `--enable-webgpu-developer-features` unmasks "Apple M4";
SwiftShader (CI pin) reports google/swiftshader, fallback true, 1.77e7 n/s. **Today's browser GPU
kernel is exact on Apple through Chrome's Tint:** 201 windows (§3.3 + both 2e8 benchmark windows),
4.25e8 numbers, 46 bases, 50 near misses, 0 differences; repeat identical; extra seeded sweep 440
windows 0 differences; CI subset on SwiftShader ~11 s. Rates: b40 6.58e8, b50 3.83e8, browser GPU
NiceMark 263–265. Harness: fork `exp/browser-gpu-harness` 5eeed09 (`wasm-client/e2e/hw/`).
**PR #230 (`pr/fd-seed-split16` 215952d):** `fd_seed_split16(nw: &Array<u32>, …)`; step helpers,
`fd_to_digits`, `NO_CARRY` pub(crate); CUDA/HIP branch untouched. 3080: fmt, 3 clippy runs, 220
lib tests, 3 CUDA tests (+ `NICE_CUBECL_WIDE=0` exercising the shared fn on the GPU); lavapipe seed
132/132 + FD/near-miss/detailed; **M4 seed 132/132 on Metal**, FD + near-miss pass; the half-shift
reproducer still fails there (control). WGSL: same code up to renaming at 14 bases + the seed
probe at 44 bases; only n's words go through an `array<u32, limbs>`. NiceMark split16 path
+0.2 % / −0.3 % (drift ~1 %). M4 34 min wall (~2 min compute).

## L26.1 Stride prefilter defensive fix (2026-10-31, agent; `L26/RESULTS.md`, `L26/raw/`; PR #229, branch `pr/metal-halfshift-prefilter`)

`candidate_check`'s low-digit prefilter (b ≤ 40 only). The #228 "top pair as one u32" construction
would, at two limbs (b33–40), divide `u32(n_lo >> 32)` = the u64 form of the bug (a compiler folds
the rebuilt halves back into the word; #228 escapes because its pair is a u32 sum). So each pass
divides the top pair as hi·Q + (hi·R + lo)/K with 2^16 = Q·K + R; every dividend is that sum or
`rem << 16 | limb` with a run-time remainder. Python model exact over ~3M cases, no overflow.
RTX 3060 (58548226, 1.08 h): lavapipe probe/cross-filter/`matches_cpu_niceonly`/`finds_69` pass;
CUDA `cubecl_cuda_matches_cpu_niceonly` + local CUDA copies of the probe and cross-filter tests
pass; 27-window sweep b28–40: 9,675 of 1,475,822 survivors = host mirror = main on both runtimes.
WGSL flagged sites main → fix: b30 6→0, b34 6→0, b40 6→0. Host 208/208, fmt/clippy clean. Not
M4-run (the paired form passes there today; the fix is defensive). Note: `matches_cpu_niceonly`
and `finds_69` barely touch the prefilter (none at b10/12/25; b40's 5e6 window launches nothing);
M4-CONFIRM's "b25 runs the prefilter" was wrong. Rebased onto main 7362e18 (CHANGELOG conflict).

## L25.2 M4 confirmation of #228 and the stride prefilter probe (2026-10-31, agent, 8 min of mayalaran; `L25/M4-CONFIRM.md`, `L25/raw/m4/`)

**#228 prediction confirmed (twice):** 472c9a0 + windows fails `cubecl_join_matches_the_cpu_reference`
at b50 with **0 join survivors vs the CPU's 934** (prefilter 0 vs 97); a per-window run shows b54
**0 vs 445** (0 vs 51); the other 18 windows agree. The branch (56b68bf) passes everything incl.
both windows, the b57 frontier field, tight/sliced/refused layouts; `join_sample_runs_partitions_
of_a_production_field` passes on both trees. The device loses every survivor → missed nice numbers
at b49–55 on a Mac without the fix. PR body + comment updated.
**Stride prefilter (cubecl_backend.rs:433–437), main:** `cubecl_prefilter_survivors_match_the_host_
mirror` passes twice at b30/34/40 (every lane width); `cubecl_matches_cpu_niceonly` (b10–80),
`cubecl_cross_filter_survivors_match_the_host_mirror`, `cubecl_niceonly_finds_69_in_base_10` pass.
So the paired `/`+`%` form still dodges the bug today; the fix is defensive (user: fix unless it
costs current work; it runs only at b ≤ 40, so it cannot).

## L25.1 Apple half-shift-divide audit of the GPU kernels (2026-10-31, agent; `L25/AUDIT.md`, `L25/raw/`; PR #228, branch `pr/metal-halfshift-top-kernel` 56b68bf on 472c9a0)

Source audit + WGSL dumps of 97 kernels on lavapipe (RTX 3060 box 58492432, $0.056/h, 1.17 h).
**One production kernel carries the pattern: the join's `top_kernel` (`cert_power`,
cubecl_join.rs:656–665)**: unrolled split16 division, first dividend each pass `x[top] >> 16` ÷ b^k;
28–64 flagged WGSL sites per base. Harmless at b40–44 and b57–64 (top limb of n², n³ is 0; b64's
divisor is a power of two); **wrong on Apple at b49–55** (the low-half model predicts 76–100 % wrong
digits) → lost join survivors → a nice number could be missed on a rescan/verification run on a Mac.
Stride prefilter (b ≤ 40 only) has the shape (6 sites) in a paired `/`+`%` form that passed the M4
probe in August (that August mul-sub failure was very likely this bug). Everything else is clean.
**Fix (ed972c7):** powers in 16-bit limbs, top limb pair divided first (the #225 construction);
no flagged sites in any of the 97 dumped kernels; `56b68bf` adds join windows with survivors at b50
(934/97) and b54 (445/51). CUDA 3/3 and lavapipe 3/3 on the branch and on main+windows; host 208;
lint clean. Throughput 0.997 (b58) / 0.984 (b62), inside main's 1.2 % / 2.4 % spread; survivor and
check counts identical over 3 × 1e14 fields per base. Not run on the M4 (needs a window): main +
windows expected to FAIL `cubecl_join_matches_the_cpu_reference`, the branch to pass.

## L23.1 Browser CPU detailed mode on finite differences (2026-10-31, agent; `L23/RESULTS.md`, `L23/raw/`, `L23/harness/`; PR #227, branch `pr/wasm-detailed-finite-diff` fe38c7e on #221's 7019653)

`process_chunk_wasm` → `process_range_detailed_fd` (2 files, 7 lines). Exactness: old wasm (d1ff798)
vs new, same `wasm-pack` command as CI, headless Chromium 151 (Playwright 1.62 image via rootless
podman on ivory): 141 windows, 36.4M numbers, raw JSON byte-identical (benchmark windows in three
chunkings, the 10M offline field, six windows per base 40–64, full ranges of bases 10–24 with 27
near misses, the e2e's b49 near miss above 2^53, 20M around the first b40 near miss). CI's e2e
`run.sh` passes locally; its CPU-vs-WebGPU histogram check agrees.
Speed (page suite, 60 s, 3 workers, interleaved ×3, M n/s): b40 3.564 → 36.571 (×10.3); b50 4.715
→ 31.127 (×6.6); b50_1t 1.782 → 8.776 (×4.9); NiceMark 246 → 1711 (×7.0); spreads ≤1.8 %. Per
number: wasm 683 → 58 ns (b40), 508 → 70 (b50), 655 → 72 (b60); native on the same box 266/43,
414/49, 541/50. The page + worker pool adds ~45–55 ms fixed per suite window (why `_1t` gains less).
Note: wasm32 clippy without `--no-deps` fails on a pre-existing lint at cubecl_web.rs:63 on main too
(CI never runs it); left alone.

## L3.7 Verification of the fixed FD branch on CUDA and lavapipe (2026-10-30, agent; `L3/verify/VERIFY-297a969.md`)

RTX 3080 (58428313, KR; host-capped at 150 W, 1545 MHz), 297a969: fmt, both lint clippy lines +
`--features gpu`, release build; 209 host tests; CUDA `cubecl_cuda_fd_matches_cpu_detailed` (every
window exact, FD = division = CPU on the benchmark windows, 73 near-misses), `..._matches_cpu_detailed`,
`..._reads_back_every_near_miss`, hand-CUDA `gpu_matches_cpu_detailed_small`; lavapipe all six wgpu
tests incl. `cubecl_fd_seed_matches_cpu` 132/132 windows; reproducer passes on llvmpipe. A
diagnostic build confirmed FD serves every b40/b50 window on CUDA and llvmpipe. Speed vs the
pre-fix PR (18cba8b), interleaved: 1.000× (b40), 0.999× (b50); absolute 2.86e10 / 2.50e10 at 150 W.
**#225 → single commit dbe2ab7 on main 9747e39 (tree = 297a969 + main's pool-size change), body
rewritten, marked ready for review, resolution comment posted.**

## L3.6 Root cause and fix on the M4 (2026-10-30, agent, 1 h 11 min of mayalaran; `L3/METAL-FIX.md`, `L3/metalfix/`; branch `pr/gpu-detailed-fd-metalfix` 297a969)

**Apple GPU compiler bug, confirmed with hand-written MSL (no wgpu/naga):** unsigned division or
remainder by a non-power-of-two constant is wrong when the dividend is a right shift by half the
width: `naga_div(x >> 16u, K)`, `(x >> 16u) % K`, `uint(ulong p >> 32) / K`. The unrolled split16
seed (`fd_to_digits`) made the first dividend of every chunk a bare `top_limb >> 16`, so n²'s (and
at some bases n³'s) digits were wrong from digit 0; limbs were exact. b23 is the same bug (at
K = 12167 a zero dividend returns 4), not a second fault. The per-number kernel is exact because
its long division is a runtime loop with a loop-carried remainder.
**Fix (af41956):** the wgpu seed in 16-bit limbs, u32 arithmetic only, each chunk's division
starting from the top two limbs as one u32 (no bare shift; one division fewer per chunk);
CUDA/HIP path, hot loop, mask and histogram unchanged. d9261a8: `fd_seed` + per-n seed test
`cubecl_fd_seed_matches_cpu` (1024 n at start/middle/end of all 44 bases, word for word) + the
minimal reproducer `metal_half_shift_div_repro` (ignored, `NICE_METAL_DIV_REPRO=1`). 297a969
reverts the gate.
**M4:** seed test failed before at b23, 25, 27–30, 49, 50, 52–55 and passes after; all FD/readback
tests pass; 220-window sweep of bases 10–64 (3.08e7 numbers, incl. run length 1) identical to the
CPU. Speed unchanged vs the PR: b40 2.435e9, b50 2.187e9, NiceMark 1216 (main 330): 3.00× / 4.54×.
Not done: CUDA/Vulkan re-run (verification agent), other Apple GPUs/macOS versions, Apple
Feedback report, **nice-only kernels not audited for the pattern (L25)**.

## L3.5 Metal gate for #225 and the desk root cause (2026-10-30, agent; `L3/METAL-ROOT-CAUSE.md`, `L3/pr-raw/gate/`)

Gate commit d8038d6 (head of `pr/gpu-detailed-fd`): the wgpu context records whether the adapter
backend is Metal (wgpu's backend enum, not the name); `DetailedKernel::for_device(base, metal)`
sends Metal to the per-number kernel; CUDA/HIP/Vulkan/DX12/GL keep FD; unit test
`detailed_kernel_by_device`. RTX 3080 box 58419619: fmt, all clippy lines, 210 lib tests, CUDA FD
tests and lavapipe FD tests pass with FD still serving; speed unchanged (b40 3.339e10 vs
3.331–3.467e10; score 16,591–16,614 vs 16,571–17,121).
**Root cause, modelled:** the seed's digit conversion computes `(x >> 16) / K` on the top word x
of n² and n³; if Apple's compiler divides the low 16 bits of x instead (the 16-bit form of the
2026-10-06 `hi(a·b)/K` miscompile), the model reproduces all 400 per-number results at b50 and
77 of 79 sweep windows exactly, including the base bands, the b32 exemption (power-of-two
divisor) and the passing windows inside failing bases. **b23 is not explained** (top words too
small). Artefacts for the Mac: `h2_repro.swift` (standalone Metal reproducer), `seed-dump-diag.patch`
(ignored test `zz_seed_dump_wgpu`, exact on CUDA and lavapipe). Cheapest fix: seed through the
per-number kernel's shared-memory long division (exact on the M4); never fold into one `x / K`.

## L3.4 #225 on Apple M4 (Metal): WRONG RESULTS (2026-10-30, agent, user-authorised 1 h; `L3/METAL-M4.md`, `L3/pr-raw/m4/`)

mayalaran: macOS 26.3 (25D125), M4, Rust 1.99.1; offline build (179 crates copied from ivory);
29 min of machine time, cleaned up. `auto` = CubeCL wgpu, "Apple M4 (Metal, wgpu<wgsl>)".
- `cubecl_fd_matches_cpu_detailed` FAILS (first b50 window; all b40 windows pass under every run
  shape); `cubecl_reads_back_every_near_miss` FAILS at b23; main's tests pass on the device.
- Per-base sweep: FD wrong at b23, b27–30, b49 (mid), b50, b52 (mid), b53–55; division exact in
  all 79 windows. Per n: 77 % wrong at b23 start, 87 % at b50; window histograms move only a few
  percent (the tests barely catch it).
- Every run length fails incl. 1 number per run → not stepping; seed, packing or mask build as
  compiled by Metal. Root cause unknown; prime suspect the Apple Metal compiler (cf. the
  2026-10-06 hi(a·b)/const miscompile seen via cubecl-metal). WGSL + naga MSL dumps saved.
- The CI "cubecl (Metal) on macOS" job (paravirtual GPU, #218) passed the same commit: it does
  not reproduce real-hardware Metal behaviour.
- Speed (3 rounds, spreads ≤0.3 %): b40 8.116e8 → 2.437e9 (3.00×); b50 4.812e8 → 2.183e9 (wrong
  kernel); NiceMark 329 → 1216. No thermal decline over 60 s reruns.
Action: #225 → draft + comment; gate FD off on Metal adapters pending the root cause.

## L3.3 Second card for #224/#225: RTX 4090 (2026-10-30, agent; `L3/AB-4090.md`, `L3/pr-raw/4090/`)

Vast RTX 4090 (58401579, CA, $0.374/h), not power-limited (480 W limit never reached) but
thermally limited (85–90 °C vs 83 °C target, fan 100 %, slowdown active in every snapshot);
clocks ~2.5–2.6 GHz main/rb, ~2.63 GHz FD. Trees main 46e4dc4 / rb 6a1e396 / fd f3a33cf.

| measurement | rb vs main (b40 / b50) | FD vs main |
|---|---|---|
| NiceMark detailed GPU, 6 interleaved rounds | 1.137 / 1.093 | 3.459 / 3.922 |
| NiceMark score (main 11,493) | 12,800 (×1.114) | 42,296 (×3.680) |
| 2e9 windows, 3 rounds | 1.023 / 1.007 | 3.022 / 3.634 |
| 1e10 fields, production path (`--repeat`, mock API, 3×8) | 0.997 / 0.995 | 3.061 / 3.767 |

FD vs rb per clock 2.87× / 3.31× (3080: 2.78× / 3.42×). An FD 1e10 field is ~0.11–0.12 s, so a
4090 needs ~9 claims/s. Exactness: all FD tests under CUDA; results identical across the three
trees on every window and on all 147 production submissions. wgpu FD test ran on llvmpipe only
(the NVIDIA Vulkan driver did not load in the container). Both PR bodies updated with these.

## L1.6 Partitions per launch + pruned buffer sizing, and the flush race (2026-10-30, agent; `L1/LAUNCH-RESULTS.md`, `L1/launch-raw/`; branches `pr/join-partitions-per-launch` c4ac700, `rp/join-flush-barrier` 61e6ba9 → PR #222, `rp/launch-with-barrier`)

RTX 3080 20 GB (58361499, 320 W = default), 10 GB layouts via test-only `NICE_TEST_JOIN_MAX_BUFFER`.
- **1e14, 10 GB budget, 3 rounds:** ×0.881 / 0.868 / 0.793 / 0.832 of main's time at b58/60/62/64
  (16 → 64 partitions per launch; 211–256 → 53–64 batches). 20 GB: ×0.899 / 0.868 / 0.787 / 0.826.
  Cap 64 beats "as many as fit" (105–177) by 1–4 %; a 16–177 sweep is fastest at 64 at every base.
- **1e16: neutral** (×0.992–1.011); 1e15 neutral with b58 1–2 % slower; NiceMark ×1.002
  (b58_msd_weak ×0.969 in 3 rounds, within that scenario's ±3 % noise here).
- **PARKED (director):** the live fields are 1e16 at b60 and **1e17 at b62** (data API
  `fields`, 2026-10-30), so a change that is neutral above 1e15 does not help production and
  does not move NiceMark. The "production size = 1e14" premise in the L1.5 brief came from a
  stale code comment ("Production fields at the frontier are 1e14"). Keep for small-field work.
- **The extra full checks are a race in `join_kernel`'s per-chunk flush decision**, not stage
  overruns: no barrier between the `s_cnt` load and the next chunk's appends, so a late plane
  can decide alone to flush and the cube's barriers pair at different call sites; stale list
  entries get fully checked and entries can be overwritten (survivors never checked). Frequent
  once cubes grid-stride (>16–19 partitions per launch); possible by the code in main's 1e16
  layouts. Instrumented: 12 of 50 base-runs at ≥64 per launch without the barrier showed a
  signature, 0 of 18 with it; 0 of 76 at 16–32. Fix = one `sync_cube()` after the load; cost
  within noise at 1e14 (×0.99–1.00), ≤ ~1.5 % at 1e16 unresolved. **PR #222.**

## L3.1 GPU detailed mode by finite differences, prototype (2026-10-30, agent; `L3/GPU-FD.md`, `L3/raw-fd/`; branch `exp/gpu-detailed-fd` e0c1b4c on the fork)

Vast RTX 3080 (58350503, KR, $0.108/h), **power-capped at 180 W** (default 340 W): the old
kernel ran ~1,425 MHz, FD ~1,690 MHz, so ~1.18× of the gain is clock; per clock FD is ~2.2×
(b40) / 2.7× (b50). 3 interleaved rounds, medians. Best variant v3: 128 numbers per thread,
high words of n²/n³ masked once per run (they change only on a rare carry; removes 14 of 50
masked digits at b50), one rare-carry branch per step.

| measure | b40 | b50 |
|---|---|---|
| benchmark harness, production host path | 2.60× (2.05e10 vs 7.88e9 n/s) | 3.22× (1.86e10 vs 5.78e9) |
| harness, both arms with the near-miss readback fix | 3.22× | 3.97× |
| 2e9-number window (mostly kernel) | 3.28× | 3.97–4.03× |

Run length flat within 3 % from 64 to 512 numbers per thread. Per-thread histogram was 5–7 %
slower than one shared atomic per number; a 2-digit lookup table within 2 % (both off).
Registers 96 (v1) → 48 (v3), no spills, 83 % occupancy; limited by integer instruction rate:
mask build ~4.5 instructions per digit = 55–60 % of the work, digit adds ~30 %.
Exactness: histogram and near-miss list equal the CPU's at every commit; test covers b40/b50
range start/end, 8 random windows, addend digit-gain windows, a window straddling the range
start (split across the two kernels), under 7 option sets, plus the full 2e8 benchmark windows
and every base 10–28 in full (73 near-misses). CUDA parity test, library tests, clippy clean.
**Side finding (independent of FD):** every call copied back the whole 20 MB near-miss buffer
(~1.7 ms over PCIe 3) even with zero misses; reading only what was written gives +5–8 % for
the current kernel and +30 % for FD. Worth its own small PR.
**Caveat for production:** at FD speed a 1e9-number detailed field is ~40 ms of GPU, so the
claim/submit round trip may dominate wall-clock; server-side detailed field size (BACKLOG 13)
becomes the limiter before the 3–4× shows in production throughput.

## L1.5 Join re-profile on main d1ff798 (prune + EPT 2 + closure + memory budget) (2026-10-30, agent; `L1/PROFILE-2.md`, `L1/profile2-raw/`; branch `rp/gpu-profile-2`)

Vast RTX 3080 **20 GB** (58350591, US, $0.149/h; 320 W cap = default; so the memory budget is
4 GiB and 1e16 layouts differ from 10 GB cards). Profiled with the probe readback excluded;
profiling adds 6–10 % at 1e14, ~0 at 1e16; unprofiled main matches within 1.5 %.

| | device s/field (b58/60/62/64) | top | bucket | join | check | other |
|---|---|---|---|---|---|---|
| 1e14 (20 fields) | 0.689 / 0.585 / 0.569 / 0.679 | 22/19/17/9 % | 11/14/16/14 % | 52/50/49/58 % | 6–7 % | 9–12 % |
| 1e16 (2 fields) | 46.3 / 33.9 / 14.6 / 42.9 | 30/34/41/15 % | ≤1 % | 62/57/51/77 % | 5–7 % | 1–3 % |

Refit at 1e16: 0.62 ps per padded lane-pair + 64 ps per AND survivor (rms 5.7 %, max 11 %,
over-predicts b64: empty lanes are cheaper than filled); + 406 ps per top → rms 2.9 %. At
1e14 the two-term fit fails (rms 33 %); + 15.6 ns per (partition, bucket) work item → rms
5.9 %. Each launch costs ~0.5 ms; **the 1e14 per-field fixed cost is 40–74 % of a field.**

**Levers ranked:** (1) more partitions per launch at 1e14: 16→32 gives ×0.92/0.90/0.83/0.87
of the time, 16→64 ×0.88/0.86/0.78/0.83 (b58/60/62/64); 32 fits 10 GB cards, 64 needs the
lists sized by the pruned slice (#215's deferred buffer sizing); one b64 run at 64 showed
0.4 % extra full checks, cause unknown, to be understood first. (2) survivor handling at
1e16: 25–59 % of device time. (3) top certification: 15–41 % (41 % at b62 1e16). (4) real
AND lanes at 1e16: 13–26 %. (5) wave padding: ~0 at 1e14 (EPT 1 costs ×1.08–1.10), 2–7 %
at 1e16, 9–15 % at b64. (6) bucket build 11–16 % at 1e14. (7) b60 stage overrun ~0.3 %.
(8) partitions per launch at 1e16: nothing.

## L2.2 Detailed finite differences through the client, NiceMark protocol (2026-10-30, agent; `L2/PR-RESULTS.md`, `L2/pr-raw/`; PR #221, branch `pr/detailed-finite-diff` 7019653)

Vast box 58350466: Xeon E5-2682 v4 (Broadwell), container quota 15.36 CPUs (`--threads 0`
→ 15), clocks uncapped. A = main d1ff798, B = branch (045797e, comment-only diff to
7019653), `nice_client detailed --benchmark --benchmark-secs 150`, A B A B A B.

| scenario | A (M n/s) | B | B/A |
|---|---|---|---|
| b40_detailed, 15 threads | 51.55 (−0.1/+0.9 %) | 287.95 (−0.2/+1.2 %) | **5.59×** |
| b50_detailed, 15 threads | 33.80 (−0.3/+0.1 %) | 271.09 (−0.0/+0.5 %) | **8.02×** |
| b50_detailed_1t | 2.22 | 15.23 | **6.85×** |
| detailed score | 1247 | 8424 | **6.76×** |

`--threads 1`: 5.57× / 8.12× / 6.80×, score 6.75×. `--threads 64` (4× oversubscribed,
cgroup throttled): 3.10× / 5.15×, score 4.80×; both trees slow, the new loop more. Pinned
per-number: b40 280→50 ns, b50 435→57, b60 560→58. Tests on the box: 180 passed, 5 ignored.
Production = the packed variant only (8 digits per 64-bit biased add); dispatch in common
(`process_range_detailed_fd`, bases 40–64 with a legal range except 63; others → division);
client's CPU chunk path calls it. Not run: GPU-feature clippy, WASM build (CI will).

## L1.4 Prune against new main on an RTX 4090, and the wave size (2026-10-29, agent; `L1/AB-4090.md`, `L1/pr-raw/4090/`)

Vast RTX 4090 (58197772, Poland, $0.375/h; **power-limited to 330 W**, so absolute times
are slow, ratios hold). A = upstream main 2709d3f (+ the two test-only harness commits);
B = `pr/field-cert-prune` 26a8b15 (rebased prune). 3 interleaved rounds, spreads ≤ 2.4 %.

| fields | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| prune vs main, 1e16 (2 per base) | ×1.097 | ×1.084 | ×1.112 | ×1.205 |
| prune vs main, **1e14 (production size, 20 per base)** | ×1.41 | ×1.50 | ×1.87 | ×1.79 |
| prune + EPT 2 vs main, 1e16 | ×1.19 | ×1.16 | ×1.26 | ×1.52 |
| prune + EPT 2 vs main, 1e14 | ×1.55 | ×1.55 | ×1.97 | ×2.08 |
| old pair on this card (85b5b4e base vs prune), 1e16 | ×1.14 | ×1.14 | ×1.37 | ×1.58 |

The 1e16 gains are below the 3080's day-1 numbers because new main carries #205's EPT 6 at
b62/b64 (a bad wave for pruned buckets) and #203/#206's own gains; the card is not the
cause (old pair reproduces the 3080). NiceMark (prune as pushed): 8086 → 9494 (×1.174);
b58 weak ×1.152, b58 strong ×1.330, b60 weak ×1.075, b62 weak ×1.126; all on the join.
**EPT with the prune: 2 < 3 < 4 < 6 in every round at every base**; 2 beats 4 by
×1.07–1.13 and 6 by ×1.15–1.27; at 1e14 EPT 1 is ~5 % better at b58 and tied elsewhere.
Exactness: `NICE_TEST_JOIN_COMPARE=1` 0 = 0 at every base; survivor and check counts identical
to the last digit across trees at 1e14; CUDA parity 3/3; CPU prune test passes; the 3080's
stage-overrun shift does not appear on new main. Bottoms removed: 55–77 % at 1e16, 72–86 %
at 1e14. Not done: the b64 1e16 dense test timed out at 300 s; NiceMark with EPT 2; EPT 1 at 1e16.

## L2.1 Detailed mode by finite differences, CPU prototype (2026-10-29, agent; `L2/RESULTS.md`, branch `rp/l2-finite-diff` on the fork: b003967 scalar, da9aaeb 8 digits per 64-bit add)

`common/src/detailed_fd.rs::process_range_detailed_fd`, same signature and output as
`process_range_detailed`; bases 40, 42–45, 47–50, 52–55, 57–60, 62, 64 (others fall back).
Not wired into the client. ivory, one thread pinned to core 3, the `b50_detailed_1t` window
(base-range start, 1,000,000 numbers), two passes of 3 interleaved rounds, median ns/number:

| base | old | scalar | × | 8 digits per add | × |
|---|---|---|---|---|---|
| 40 | 265 | 60 | 4.4 | 42 | 6.2–6.3 |
| 50 | 416–418 | 73–74 | 5.6–5.7 | 48–49 | 8.5–8.6 |
| 60 | 537–541 | 89 | 6.0–6.1 | 50–53 | 10.1–10.8 |

Old within ±1 %, new within ±2–5 %. Cycles per number at b50: old 1,390, scalar 244, packed 163.
Exactness: 11 tests, all pass for both variants: per-number equality with `get_num_unique_digits`
on 20 seeded 10k windows plus both range ends at b40/50/60 and b42/47/53/59/64; 7 windows per
base around every digit-gain point of n² and n³; b7 and b10 from n = 0; whole `FieldResults`
identical on the b40_detailed and b50_detailed windows; 27 near-misses identical over bases
10–24. Clippy clean, 179 lib tests pass.
Lessons: LLVM first compiled the digit carry as a mispredicted branch (17.5 misses per number,
only 1.6–2.2×); a branch-free select fixed it, and the GPU port must watch for the same. Packed
version profile: adds + bookkeeping 57 %, mask build 30 %, popcount + histogram 13 %. Production
builds target baseline x86-64, so `count_ones()` is a 17-instruction software popcount (both paths).
Next: wire into `client/src/main.rs` (~line 845) and run the 5 % protocol on b40_detailed,
b50_detailed, b50_detailed_1t (needs a box: ivory cannot build the client); then the GPU port
(each thread walks a run of ≥100 consecutive numbers with ~24 u32 of digit arrays in registers).

## L1.3 Field-certificate bottom prune, GPU A/B (2026-10-28, agent; `L1/PRUNE.md`, `L1/prune-raw/`)

Branches on the fork: `rp/field-cert-prune` (head 4670ffe; the prune is c1174c1, the rest
tests), `rp/field-cert-prune-base` (2d740d3 = 85b5b4e + the same harness, the A tree),
`rp/field-cert-prune-ept` (6e4e895, prune + EPT override). Vast RTX 3080 (58056651),
1e16 fields, 2 per base, the L1.2 starts, A B A B A B (3 rounds), median s/field (spread):

| base | main | prune | speed-up | bottoms removed |
|---|---|---|---|---|
| 58 | 69.36 (0.9 %) | 60.18 (1.1 %) | **1.153×** | 59.5 % |
| 60 | 45.26 (1.2 %) | 39.52 (1.2 %) | **1.145×** | 54.6 % |
| 62 | 26.98 (1.0 %) | 19.07 (0.6 %) | **1.415×** | 74.3 / 66.7 % |
| 64 | 83.42 (2.4 %) | 50.79 (0.6 %) | **1.643×** | 77.1 % |

NiceMark nice-only, 3 rounds, every scenario on the join in both trees: b58_msd_weak
+17.6 %, b58_msd_strong +32.5 %, b60_msd_weak +20.1 %, b62_msd_weak +43.9 %; score
2892 → 3705 (+28 %). Batches and slots identical (buffers still sized by the unpruned
count). At 1e14 production size the prune removes 73–86 %, so production gains are
probably larger (unmeasured).

Exactness on the box: CUDA kernel compiles; 194 host tests; `cubecl_cuda_join_matches_the_cpu_reference`,
the dense-field and whole-field CUDA tests, the CPU reference test, and the throughput
harness with `NICE_TEST_JOIN_COMPARE=1` (join = stride on 1e14 fields) all pass; clippy
`--features gpu -D warnings` clean. One behavioural ripple: the prune tree records 0.94× the
AND survivors and correspondingly more unfiltered prefilter survivors (2–2.5e-4 of
survivors), i.e. survivors that overflow the join kernel's staging area go to the check list
unfiltered, as on main but a little more often; +0.3–0.4 % full checks, and b64 crosses the
dense-field test's 1e-4 limit. Fix for the PR: flush every 16 tops or a larger stage.

**EPT sweep with the prune (`rp/field-cert-prune-ept`):** EPT 2 is best at every base:
×1.088 (b58, 1 round), ×1.053 (b60, 1 round), ×1.060 (b62, 2 rounds), ×1.139 (b64, 2
rounds) over EPT 4; EPT 1 worse than 2 everywhere. Prune + EPT 2 vs main at EPT 4:
**1.51× at b62, 1.91× at b64** (against the L1.2 numbers on the same machine, not
interleaved). So PR #205's EPT 6 and the EPT 5 note both give way to EPT 2 once the prune
is in; pruned buckets are 3–4× smaller, so the wave shrinks.

## L1.2 GPU join phase profile by base (2026-10-28, agent; `L1/GPU-RESULTS.md`, branch `rp/gpu-profile` on the fork)

Vast RTX 3080 (instance 58051111, $0.134/h), upstream 85b5b4e + `NICE_EXP_GPU_PROFILE=1`
(costs 3.9–6.3 % of device time; shares from profiled runs, seconds from unprofiled),
1e16 fields, 2 per base, CubeCL CUDA.

| base | roots | device s/field | top | bucket | join | check | other |
|---|---|---|---|---|---|---|---|
| 58 | 4 | 68.8 | 19.5 % | 3.8 % | 64.8 % | 4.7 % | 7.3 % |
| 60 | 2 | 45.2 | 23.3 % | 5.1 % | 55.8 % | 5.3 % | 10.5 % |
| 62 | 2 | 26.1 | 21.9 % | 7.2 % | 57.9 % | 3.6 % | 9.5 % |
| 64 | 8 | 83.1 | 7.1 % | 3.3 % | 82.6 % | 3.1 % | 3.9 % |

| base | µs/prefix | RX 9070 XT | AND survivors/prefix | prefilter survivors (= full checks) |
|---|---|---|---|---|
| 58 | 11.44 | 11.2 | 63.7k | 3.84k |
| 60 | 8.51 | 6.8–7.3 | 43.8k | 3.10k |
| 62 | 9.96 | 9.2–9.6 | 34.8k | 2.20k |
| 64 | 26.84 | 19.5 | 139.8k | 8.77k |

- Everything but the join kernel costs 4–5 µs per prefix at every base; tops per prefix
  1180–1300 everywhere. The join kernel carries the whole b64 jump (23.0 µs vs 6.1 at b62).
- Survivors per prefix = tops × roots × bucket occupancy (930–1210 at every base) × AND
  pass rate. b64/b62 survivors 4.02× = roots 8/2. b58/b60 1.45× (pass rate 1.41 % vs 1.81 %).
- **Join kernel cost model** (10 fields, four bases, max error 1.9 %): **0.58 ps per
  lane-pair, lanes padded to whole 1024-entry waves, plus 74 ps per AND survivor.** Wave
  padding is 1.07–1.10× at b58/b60 and 1.69–1.72× at b62/b64 (buckets of ~1200 spill into
  a second wave): ~18 % of b64 device time, 12 % of b62's.
- **Entries per thread (`NICE_EXP_JOIN_EPT`, 2 interleaved rounds, first field):** 5 gives
  ×1.12 (b62) and ×1.19 (b64) over 4; 6 (= PR #205) gives ×1.08 / ×1.13, matching #205's
  own 3080 numbers. So 5 beats #205 by 3.4 % / 5.4 % on this card. Needs a third round and
  other GPUs before it is a claim. The model fitted on EPT 4 predicts 5 and 6 within 0.6–3.4 %.
- L4: the check kernel is 3.1–5.3 % of device time (3.8–9.8 % of the join's), under the
  15 % kill criterion.
- Caveats: no hardware counters (`ncu` blocked on Vast); the b60 window used is denser
  (44k survivors/prefix vs ~26k on the 9070 XT's fields) so b60's µs/prefix reads high.

**What the prune should buy (director's estimate from the model, to be measured):** per prefix the
AND term is tops × roots × padded occupancy × 0.58 ps: b58 2.9 µs, b60 1.5, b62 2.8, b64 11.4;
the survivor term 4.7 / 3.2 / 2.6 / 10.3 µs. Pruning 73–86 % of bottoms (1e14 fields) cuts
the AND term by 2× at the current wave size (one wave instead of two) and by 3–7× with a
smaller wave, leaving survivors unchanged: 10–30 % of device time by base.

## L3.0 Detailed mode on the GPU (2026-10-28, agent; `L3/NOTES.md`)

RTX 3080, `auto` = CubeCL CUDA. b40_detailed 1.04e10 n/s, b50_detailed 7.8e9 (references
2.4e9 / 1.5e9 are for a weaker card). CPU 16 threads: b40 4.4e7, b50 2.86e7, one thread
1.87e6. GPU = 236–273× this CPU. `nvidia-smi dmon`: SM 98–99 %, memory controller 0 %.
Kernel: one thread per number; n², n³ in u32 limbs; digits peeled by long division by b⁵
in shared memory; OR into a mask, popcount, one shared atomic into the histogram. About
750 (b40) / 1,000 (b50) integer ops per number ≈ the card's integer throughput:
**compute-bound on the divisions.** The L2 finite-difference scheme (digit arrays updated by
addition) removes exactly those divisions, so L2 and L3 are one lead with a CPU prototype first.

## L1.1 CPU join counts by base (2026-10-28, agent; `L1/RESULTS.md`, branch `rp/l1-selectivity` a76984f on the fork)

Item 23's field per base plus a second field, 6 stratified partitions per field, ivory (EPYC
Rome) under `nice -n 19`, 3 threads; a second round reproduced counts exactly and stage
times within ±5 %. Ignored tests `cpu_join::selectivity::l1_selectivity`, `l1_probe_windows`.

| | b58 | b60 | b62 | b64 |
|---|---|---|---|---|
| roots | 4 | 2 | 2 | 8 |
| L / digits of n², n³ | 12 / 23, 35 | 12 / 24, 36 | 13 / 25, 37 | 13 / 26, 38 |
| bottoms per key list (per class) | 54.8k (961) | 54.9k (931) | 72.7k (1191) | 76.4k (1212) |
| ANDs per top | 3,844 | 1,863 | 2,383 | 9,702 |
| top popcount (n² + n³ known) | 15.7 (7.7 + 7.9) | 16.2 (8.1 + 8.2) | 17.3 (8.9 + 8.5) | 18.4 (9.6 + 8.9) |
| AND pass rate, measured / uniform model | 1.37 / 1.40 % | 1.64 / 1.42 % | 1.25 / 1.23 % | 1.06 / 1.06 % |
| AND survivors per top | 52.7 | 30.5 | 29.8 | 103 |
| full checks per top | 3.3 | 2.0 | 1.9 | 6.6 |
| CPU ms per prefix | 5.8 | 3.5–3.9 | 4.0–4.4 | 11.0–11.5 |
| RX 9070 XT µs per prefix (BACKLOG 68) | 11.2 | 7.0 | 9.4 | 19.5 |

- ANDs per top = roots × mean class size within 0.1 %: hypothesis A holds exactly.
- Pass rates follow the uniform model C(b−pc, 12)/C(b, 12); b64's tops know the most
  digits, so its pass rate is the lowest (0.85× b62). Net AND survivors per top: b64 3.5× b62.
- Tops per prefix (1.2–1.3k) and certificate cost (405–471 ns per prefix tried) are flat.
- Of the +7.6 ms per prefix from b60 to b64: 52 % survivor handling (range test, prefilter,
  dispatch, 32–41 ns each), 33 % the ANDs (0.22 ns each), 9 % full checks. ANDs are 13–17 %
  of a partition at b58–b62 and 26–27 % at b64. CPU scan shares match item 23's Zen 2 profile.
- CPU cost per prefix relative to b60: ×1.6 / 1 / ×1.15 / ×3.1; GPU: ×1.6 / 1 / ×1.33 / ×2.8.

**Lever counts (share of ANDs skipped).** Sub-bucketing by mask ∩ S: digits 0..s−1 skip
21–42 % (s = 4–8); the s most frequent top digits skip 56–81 %, but those digits are the
field's own certificate (4–7 leading digits of n², n³ every top knows). **Dropping bottoms
that share a digit with the field certificate skips 66 / 60 / 70 / 79 % of ANDs at
b58/60/62/64 with no bucketing.** CPU saving bound: 7–12 % at b58–b62, 20–23 % at b64
(only failing ANDs are skipped). GPU share unknown until the GPU profile lands.

## L1.0 Digit-sum class roots per base (2026-10-28, director, no hardware)

In the join each top probes one bottom bucket per root of x² + x³ ≡ b(b−1)/2 (mod b−1)
(overlap_join.rs module doc). The root count by base, from a 3-line enumeration:

| base | b−1 | roots | measured µs/prefix (RX 9070 XT, BACKLOG 68) | survivors per top-layer prefix |
|---|---|---|---|---|
| 58 | 57 = 3·19 | 4 | 11.2 | — |
| 60 | 59 prime | 2 | 6.8–7.3 | ~26k |
| 62 | 61 prime | 2 | 9.2–9.6 | 27–44k |
| 64 | 63 = 7·9 | 8 | 19.5 | 112–176k |

Roots for 40–97: 40:4 41:6 42:2 43:0 44:2 45:2 46:8 47:0 48:2 49:2 50:8 51:0 52:4 53:2
54:2 55:0 56:4 57:6 58:4 59:0 60:2 61:4 62:2 63:0 64:8 65:1 66:4 67:0 68:2 69:2 70:4
71:0 72:2 73:12 74:2 75:0 76:12 77:2 78:4 79:0 80:2 81:2 82:10 83:0 84:2 85:4 86:4
87:0 88:4 89:6 90:2 91:0 92:4 93:2 94:4 95:0 96:4 97:10. (Zero roots = residue-dead
bases, which the server never inserts; matches the known list.)

Reading: the b64 survivor count per prefix is ~4× b62's, exactly the roots ratio 8/2;
per-prefix time is ~2× because the tops phase does not scale with roots. b58 > b60
follows the same ordering (4 vs 2 roots). Hypothesis A of L1 is therefore the
explanation to beat; the CPU counting run (L1/RESULTS.md) checks it and sizes the
signature-bucketing lever.

