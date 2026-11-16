# G2 review: the ×10 claim, attacked (2026-11-16, 17:54–18:25 UTC, independent reviewer, ivory CPU only, ≤ 2 threads at nice 19)

## Verdict

**The claim does not stand as stated. It stands as a design but with a corrected range: central ≈ ×5
per base at b64 (×4.7–5.5 depending on the baseline; band ×2.6–9.6) and ≈ ×4.5–5 at b62 with the
(4, 10) shape (band ×2.5–8.7; the (4, 9) shape does slightly better at b62, ×5.2–5.7).**

- **Soundness and coverage hold.** My own code (written from the definition, not from the prototype)
  agrees with the prototype on every set I tried: whole bases b10, b18 and b25 (6 shape/unit choices,
  3 of them at bases the author did not use), one real b62 unit and one real b64 unit enumerated from
  scratch (18,944 and 183,776 survivors, identical sets), and the author's full CPU pipeline (affine
  children, sorted 64-chunks, common-mask skip, sliced probes) reproduces my independent b62 set exactly.
- **The counts hold** (re-measured on 4 new units per base, within 4–8 % of the author's), and the
  units represent the base (each spans the whole leading range; unit-to-unit spread ≤ 8 %).
- **The ×10 does not.** It rests on GPU unit costs at or beyond the optimistic edge of every measured
  analog, plus one arithmetic error: (1) the 64-pair word is costed at 14.9 ps (b62) / 12.7 ps (b64) where
  the one measured analog of this exact operation (N1.G1, reverse orientation, u64, top in registers with
  15 digits, bottoms transposed) is **17.8 ps uncalibrated, dense phase only, in the most favourable
  tile**, ≈ 25 ps calibrated to production; (2) the b64 four-Russians table is amortized over all 464
  probes of a chunk instead of the ≈ 226 that survive the skip: with that fixed, **the author's own model
  gives ×7.2 at b64 (×4.5–11.4)**, not ×8.3; (3) the bottom side at b62 (children 1 ps, chunking 4 ps,
  a sort shared ÷62) is priced at ≈ 8 instructions per child and a sort ~70× cheaper than any GPU sort of
  10⁶ keys; (4) the top hierarchy and the shared bottom tree need opposite super-unit orders, and the
  model takes both for free.
- **What it would take for ×10 at b64:** an all-in 64-pair word of ≤ 7 ps (my central for every other
  term) to ≤ 11 ps (the author's), i.e. ≈ 2.5× below the best number ever measured for this operation on
  this card. ×10 at b64 is not plausible; ×5–6 is.
- **Is the GPU benchmark still worth a day?** Yes, narrowly: b64 is the only base it can matter for
  (b62 finishes around 2026-12-23 to 2027-01-06, T28.1), its central sits on the ×5 line, and one number
  (the word cost inside a real top-driven tile) decides it. But the go bar must be stated as ×5–6 at b64,
  not ×10, and the author's stop lines (word > 20 ps, bottom > 10 ps) are too lax for the claim: a 19 ps
  word passes them and means ≈ ×6.

## Findings by severity

### F1 (high) — the 64-pair word is costed below every measurement of it

Model (`model2.py`): word = lookups × 0.7 ps + 4 ps base = **14.9 ps** at b62 (15.5 top digits, bit-sliced),
**12.7 ps** at b64 (4R, see F2). Measured analogs, all on the RTX 3080 (N1.G1, `N1/gpu-tile/RESULTS.md`):

| source | per 64-pair word |
|---|---|
| N1.G1 harness, 1,460 × 14,750 tile, **reverse** (tops in registers, bottoms transposed = G2's orientation), u64, D_T 15 | **17.8 ps** (0.278 ps/pair), uncalibrated, dense phase only |
| same, D_T 17 | 18.9 ps |
| AND part per digit-word, u64 (10–14 fs per pair per digit × 64) | 0.64–0.90 ps harness; 0.92–1.29 ps calibrated (×1.43) |
| per-wave base in the big tile (0.103 ps/pair × 64) | 6.6 ps harness; 7.1 calibrated |
| survivor-path floor "per-chunk machinery" (0.13–0.15 ps/pair × 64) | 8.3–9.6 ps — G2 says it drops to "one nonzero test"; unmeasured |
| the only measurement at G2's tile shape (24 tops × 7,200 bottoms, reverse, u32) | 108 ps (3.39 ps/pair; today's kernel mapping, not G2's — but it is the only number at this shape) |

The author's central lookup (0.7 ps) is at the harness's low end before the production calibration, the
base (4 ps) is below the best measured base (6.6), and the "opt" case (0.5 ps, 2 ps) is beyond anything
measured. The harness measured a *big* tile (1,460 tops per entry wave); G2's tiles are 48 probes × ~113
chunks (b62) and 464 probes × ~131 chunks (b64) per (unit, class group) — and the common-mask skip leaves
42–51 % of lanes idle unless kept incidences are compacted, which costs per incidence. My band:
**base 3 / 5 / 7.1 ps, lookup 0.64 / 0.9 / 1.29 ps, survivor flagging 0 / 2 / 8 ps → all-in word
12.9 / 20.9 / 28.3 ps (b62) and 13.5 / 21.8 / 29.3 ps (b64)**. At b64 the word is 61 % of my central total:
it alone decides the ratio (table in §Recomputed).

### F2 (high, arithmetic) — four-Russians at b64 amortized over the wrong count

`model2.py` line `per_inc_lookups = min(TOP_POP, 8 + table / probes_per_chunk)` divides the 2,048-entry
table build by **all** 464 probes of a chunk (8 roots × 58 tops), then charges the result to **kept**
incidences only. Only 0.488 × 464 ≈ 226 probes reach a chunk, so 4R costs 8 + 2048/226 = 17.0 lookups
> 16.4 bit-sliced: 4R does not pay at b64. Fix applied to the author's own model (`review/model2_4rfix.py`,
`review/raw/model2_4rfix_out.txt`): **b64 (4,10) ×8.3 → ×7.2 (×4.5–11.4); ×10.0 → ×8.7 against 5.4 fs.**
b62 is unaffected (48 probes, bit-sliced). On a GPU 4R is worse still: byte-indexed table reads by lanes
holding different probes hit random LDS banks (expected 3–4-way conflicts for 32 random 8-byte reads),
and each table is 16 KB of LDS; the CPU 4R measurements do not transfer.

### F3 (medium-high) — the bottom side at b62 is priced at a few instructions

| term | model central | reviewer low / central / high | reason |
|---|---|---|---|
| child test (two affine digits, mask test, class, compaction) | 1 ps | 1.5 / 3 / 6 ps | ≈ 30 integer instructions (two mod-b reductions, 64-bit mask ops on a 32-bit ALU, ballot/prefix compaction); Ampere issues 64 INT32 lanes/clk/SM = 8.0e12/s → 3.7 ps; the model's 1 ps is ≈ 8 instructions |
| chunking per stored bottom (transpose into 64 slices, common mask, member index, LDS store) | 4 ps | 4 / 7 / 12 ps | 64×64 bit transpose by shuffles ≈ 50 lane-ops per bottom ≈ 6 ps; by ballots ≈ 32 ps |
| parent sort, per parent | 7.4 ps (15 ps per bottom ÷ 62) | 20 / 60 / 150 ps | a device radix sort of ~10⁶ 64-bit keys runs at ~0.5–1 ns per key; **measured here:** a sort only inside LDS tiles destroys the skip (kept 0.58 → 0.72 at 2,048 children, 0.78 at 1,024, 0.89 at 256; b64 0.49 → 0.63 / 0.72 / 0.88, `raw/sweep_tile_key.txt`), but an **8-bit key over the whole class group loses nothing** (kept 0.580 / 0.491), so a one-pass counting sort with the parents' DRAM round trips (≈ 48–64 B per parent) is the realistic cost |

b62 bottom side: model 0.51 fs → reviewer central **1.24 fs** (children 0.51, chunking 0.57, sort 0.16):
45 % of my b62 total, enough on its own to cap b62 (4,10) below ×8 (break-even per stored bottom for ×8 is
negative at my central for everything else; for ×5 ≤ 9.9 ps against my 13.3). b64 is insensitive (0.12 fs).
The order shared by the b sibling units is fine: weights from a sibling unit give the same kept fraction
within 0.5 % (`raw/sibling_weights.txt`, 3 siblings per base).

### F4 (medium) — tops and bottoms want opposite super-unit orders

`model.py` prices tops as "children of certified parents, once per base" (4.39e-7 / 9.23e-8 tested per adm:
the f0 = 4 tops whose f0 = 5 parent is certified). The f0 = 5 parent (digits ≥ 5) is shared by the b
super-units that differ only in digit 4, so the hierarchy is free only with **digit 4 innermost**. The
shared bottom tree ("the whole base visits each tree node once") needs the opposite: a depth-j bottom node
(digits < j) is shared by super-units that differ in digits j..8, so **digit 8 innermost**. Storing either
side's intermediate level is 10¹²–10¹³ entries. The cheaper of the two (`review/order.py`):
- digit 4 innermost: bottoms re-derived from stored depth-4 roots per super-unit, **7.1e-5 / 6.4e-6
  extensions per adm** (0.43× / 0.39× the child count; full u64 modular steps, 3–8 ps each);
- digit 8 innermost: every f0 = 4 top tested, **2.06e-6 / 4.69e-7 per adm** (×4.7 / ×5.1; the prototype
  itself tests every top, `per adm: tops_tested 2.064e-6`).
Unpriced in the model: **+0.21–0.36 fs at b62, +0.03 fs at b64.**

### F5 (medium) — the baseline: fair to within ±20 %, but b62 hardly matters any more

- b62: the model's 13.2 fs (N22 field ÷ a survivors ratio of 1.34) against the most direct number,
  B64.1's 10-field b62 base mean on the #250 + #251 stack, **12.1 fs** (main 0711b16 has #251; MU260's
  49.8 s per real field is consistent: its three fields have 7.1–8.6e11 survivors, near the all-field
  mean of 8.2e11). Instant fields (11–35 % of b62, T28.1) move the base mean between ≈ 11 and ≈ 16 fs.
  Net: the author's b62 baseline is ≈ 8 % generous to G2.
- b64: the model's 4.5 fs is its low end; the direct chain is B64.1's 6.46 fs ÷ 1.049 (#251) ÷ 1.13 (#254)
  = 5.45 fs, a little lower with the b64 shift prefilter: **≈ 5.3 fs**. The author is ≈ 18 % conservative
  here (and reported both). Neither end moves the verdict.
- **Timing:** b62 ends ≈ 2026-12-23 – 2027-01-06 at today's pace (T28.1). Any G2 deployment arrives
  mid-base or later, and the mid-base switch pays the bottom side for the whole base while tops cover
  only the remaining fraction f: b62 at f = 0.5 is ×3.0 at my central (×7.2 at the author's). b64
  (≈ 1.5 years at today's speed) is the only base this lever is for.
- The baseline is a CUDA 3080 number; 81 % of the work runs on the RX 9070 XT through wgpu, where the last
  batch delivered less than half its CUDA gain (T2.1). The ratio must be measured on that card too.

### F6 (medium) — the server change: workable, but bigger than §7 says

- **What works:** a unit "base b, all n whose digits 4–8 lie in [p0, p1)" is algorithm-agnostic (any exact
  client, including a CPU running (4, 9), can search that set), homogeneous (units differ by ≤ 8 % in cost,
  unlike fields: ×2.7 and instant fields), fine-grained (one super-unit is 0.4 ms / 2.4 ms on a 3080, so any
  client speed can be served), resumable at unit granularity, and auditable: the AND-survivor count of a
  unit is a property of (shape, unit), not of the implementation (my independent enumeration reproduced it
  exactly), so T28-style re-run audits carry over.
- **What breaks:** (1) no field and no contiguous range is complete until the whole base is; `check_level`,
  the frontier/claim queues, the per-field site and audit tooling, and "searched up to X" statements all
  need a unit-coverage equivalent; (2) a base can switch only when **every** backend that works on it has a
  G2 implementation (CUDA, wgpu/SPIR-V for RDNA4, Metal for the M4, CPU, wasm) — field clients cannot share
  a G2 base without the switch; (3) detailed (distribution) searches stay field-based; (4) a second
  implementation that agrees on survivor counts is a new artefact to build and maintain.
- **Mid-base switch:** exact under two rules the RESULTS does not state: drop a top only if its interval
  lies **entirely** inside searched fields (top intervals b⁴ are not aligned to 1e17 fields), and use one
  frozen snapshot of completed fields for all units of the base (claimed-but-unsubmitted fields count as
  unsearched; a field later invalidated is a coverage hole that must be re-searched as a field). It is
  not free (F5).

### F7 (low) — soundness, coverage and the author's own exactness evidence

- Read and confirmed: top certificate = digits where ⌊a^e/b^j⌋ = ⌊c^e/b^j⌋ at the clipped ends (monotone,
  sound), positions ≥ k only (disjoint from the bottom's < k); class via b ≡ 1 (mod b − 1); the affine child
  digits (c2 + 2·r0·d) mod b and (c3 + 3·r0²·d) mod b are exact because (p + d·b⁹)ᵉ ≡ pᵉ + e·p^(e−1)·d·b⁹
  (mod b¹⁰) and only p mod b survives the top digit; child class = parent class + d; the common mask is the
  AND of members (`andv.rs`, `pipe.rs`), so a skipped chunk has no disjoint member; the parent-certified
  top hierarchy is sound (child interval ⊂ parent interval).
- **Gap in the author's evidence, now closed:** the prototype's "brute force" compares the join with its own
  predicate `q_shape` (built from the same `top_cert`/`bot_cert_direct`), and the pipeline asserts equal
  survivor **counts**, not sets. My checks: an independent predicate Q*(n) from the definition
  (`review/qstar.py`; own range and class code) equals the prototype's survivor set on b10 (1,2), b18 (1,2),
  b18 (1,3), b25 (1,3), (2,4), (1,4) — whole bases, unit = [f0, k) as in G2 (`raw/independent_small.txt`);
  from-scratch enumeration of real units (`review/unit_indep.py`): b62 U = 45586873807 (1,493 tops, 447,102
  bottoms, 21,884,260 pairs, **18,944 survivors, identical set**), b64 U = 50761296111 (183,776, identical);
  the pipeline's survivor **set** (both orders) equals my b62 set (`raw/pipe62_seed777.txt`). The author's 14
  small runs re-run in my build: all equal (`raw/small_exact_rerun.txt`).
- Range ends: the b62 unit that holds the base's last, clipped top (U = 7687776217; 11,371 tops tested,
  17,235 survivors) is identical between the prototype and my enumeration (`raw/end62_*.txt`); b62's start
  is aligned to 62⁴ (no clipping). The b64 end unit (U = 64⁶ − 1) has no certified bottom, so it is equal
  but uninformative (`raw/end64_*.txt`); the small bases exercise clipping at both ends.

### F8 (low) — counts and representativeness

| per adm | author b62 | mine b62 (4 units) | author b64 | mine b64 (4 units) |
|---|---|---|---|---|
| pairs | 3.87e-3 | 3.68–4.00e-3 | 3.52e-3 | 3.52–3.63e-3 |
| survivors | 3.33e-6 | 3.19–3.44e-6 | 2.61e-6 | 2.61–2.69e-6 |
| bottoms | 8.12e-5 | 8.10–8.14e-5 | 7.54e-6 | 7.54–7.56e-6 |
| flat incidences | 6.08e-5 | 5.78–6.27e-5 | 5.52e-5 | 5.52–5.69e-5 |
| kept (parent key, pooled) | 3.53e-5 | 3.41–3.62e-5 | 2.69e-5 | 2.69–2.80e-5 |

First principles: pairs/adm = P_T(4)·P_B(10) exactly (class-uniform), flat ≈ pairs/64 — both reproduce.
A transversal unit fixes only digits 4–9 and spans every leading digit, so "sampled at particular leading
digits" does not apply; the base mean is the unit mean (spread ≤ 8 %). Inside a unit the leading range is
very uneven (b62 deciles: pairs 0.15× in the first decile — the instant region — to 1.33×, survivors
0.10–1.58×; b64 0.75–1.12× / 0.63–1.23×; `raw/unit6*_indep*.txt`), which matters only for the mid-base
switch.

## Recomputed table (fs per admissible n; `review/model_review.py` → `review/raw/model_review_out.txt`)

Counts: the author's measured ones (confirmed in F8). Unit costs: mine, low / central / high, reasons in
F1–F4; other overhead 3 / 8 / 12 % (launches per super-unit: ≥ 4 kernels incl. the 3-pass counting sort
unless batched); survivors 17 / 30 / 54 ps (N1.G1: 54 ps per survivor at low density) + check.

| b62 (4,10) TD, parent-sorted | author central | reviewer low | **reviewer central** | reviewer high |
|---|---|---|---|---|
| 64-pair words | 0.525 | 0.456 | 0.740 | 1.240 |
| skip tests | 0.061 | 0.030 | 0.061 | 0.122 |
| children | 0.170 | 0.255 | 0.510 | 1.020 |
| chunking + sort | 0.344 | 0.378 | 0.728 | 1.373 |
| tops (+ order, F4) | 0.075 | 0.289 | 0.351 | 0.351 |
| survivors + check | 0.068 | 0.068 | 0.111 | 0.191 |
| other | 0.065 | 0.046 | 0.218 | 0.586 |
| **total** | **1.31** | **1.52** | **2.72** | **4.88** |
| ratio vs 13.2 fs (author) | ×10.1 | ×8.7 | **×4.9** | ×2.7 |
| ratio vs 12.1 fs (direct) | ×9.3 | ×7.9 | **×4.5** | ×2.5 |

| b64 (4,10) TD, parent-sorted | author central | author, F2 fixed | reviewer low | **reviewer central** | reviewer high |
|---|---|---|---|---|---|
| 64-pair words | 0.342 | 0.417 | 0.363 | 0.586 | 0.976 |
| skip tests | 0.055 | 0.055 | 0.028 | 0.055 | 0.110 |
| children + chunking + sort | 0.049 | 0.049 | 0.060 | 0.118 | 0.228 |
| tops (+ order) | 0.016 | 0.016 | 0.029 | 0.041 | 0.049 |
| survivors + check | 0.053 | 0.053 | 0.053 | 0.087 | 0.150 |
| other | 0.027 | 0.031 | 0.016 | 0.077 | 0.206 |
| **total** | **0.542** | **0.621** | **0.550** | **0.965** | **1.721** |
| ratio vs 4.5 fs (author) | ×8.3 | ×7.2 | ×8.2 | **×4.7** | ×2.6 |
| ratio vs 5.3 fs (direct) | ×9.8 | ×8.5 | ×9.6 | **×5.5** | ×3.1 |

Other shapes at my central: b62 (4,9) ×5.2–5.7 (×2.9–9.7) — the better b62 shape once the bottom side is
priced honestly; b64 (4,9) ×2.2–2.6.

Sensitivity at b64 (everything but the word at my central, vs 5.3 fs): word 10 ps → ×8.5; 15 ps → ×6.9;
20 ps → ×5.8; 25 ps → ×5.0. **×10 needs ≤ 6.9 ps; ×8 ≤ 11.4 ps; ×5 ≤ 25 ps.**

## The benchmark: smallest experiment that confirms or kills it

**Question:** what does one real b64 super-unit cost end to end on a GPU in the G2 structure, against
today's main on the same card in the same session? Everything else is secondary; b62 is optional.

**Inputs (CPU, ivory, < 1 h, from this prototype):** for one b64 super-unit π′ (digits 4–8; e.g. the
author's 55472845875 mod 64⁵) — the 1.04e6 depth-9 parents (r, mask, c2, c3, a2, a3, class), already
sorted per class by the pooled 8-bit key; the tops of all 64 units (mask, h, lo, hi, class; ≈ 3,700 per
unit); per unit the expected survivor set and the counts (children, stored bottoms, flat and kept
incidences). ≈ 35 MB. Same for one b62 super-unit if time allows.

**Kernel to build (one, three switches):** grid over (parent class c, parent tile of ≤ 2,048 parents in
LDS or registers); each work group loops over the unit digit d = 0..b−1: affine children → ballot
compaction → 64-chunks transposed in LDS (shuffle transpose) with common masks and member indices →
probes by unit d's tops of the compatible classes, **lanes over chunks**, common-mask test, compaction of
kept (probe, chunk) incidences, bit-sliced OR over the probe's digits, nonzero test, survivors appended
to a global buffer. Switches: (a) probes off (bottom side alone), (b) skip off (all flat incidences),
(c) full. Exactness: every unit's survivor set equals the prototype's (which equals my independent one).
Second, smaller kernel: depth-9 parents of π′ from stored depth-4 roots + the 8-bit counting sort, timed
per parent. Today's main on the same box: 5–10 b64 1e17 fields at 0.05–0.95 of the range, empties counted
(B64.1 protocol).

**Measure:** ps per child and per stored bottom (a), ps per flat incidence and per kept word (c − a, with b
for the skip's worth), ps per parent (prep), end-to-end fs per admissible n of the super-unit (all 64
units, prep included), registers / LDS / occupancy, and today's base mean (fs per admissible n).

**Cards:** RTX 3080 at 300 W (rented, CUDA) first — decisive. RX 9070 XT (demoux window, wgpu/SPIR-V) only
if the 3080 clears ×6: there LDS is 64 KB per work group and production sits at 18.9 KiB for occupancy;
the parent tile may have to live in registers.

**Stop numbers (3080, b64, vs the same-session main):**
- **Stop** if end-to-end > 1.06 fs per admissible n (< ×5 at 5.3 fs), or if the all-in kept word
  > 25 ps, or per stored bottom (its ≈ 2.2 child tests + chunking) > 25 ps.
- **Go to the RX 9070 XT** if end-to-end ≤ 0.88 fs (≥ ×6). Between ×5 and ×6: stop unless one named
  component is measurably the culprit and has a measured fix.
- **The ×10 claim** is confirmed only at end-to-end ≤ 0.53 fs (word ≲ 7–11 ps). Expect ×5–7.
- The author's lines (word > 20 ps, bottom > 10 ps) do not test the claim: a 19 ps word "passes" and
  means ≈ ×6; a 10 ps bottom only matters at b62.

## Files (all under `G2/review/`)

`proto/` (my build; additions: survivor dumps, `G2_TILE` / `G2_KEYBITS` / `G2_NOSORT` sweeps, sibling
weights `G2_SIB`, pipeline set dump), `qstar.py` (independent predicate), `unit_indep.py` (from-scratch
unit enumeration), `order.py` (F4), `model_review.py` (recomputed table), `model2_4rfix.py` (author's
model with F2 fixed); `raw/`: `independent_small.txt`, `unit62_indep.txt`, `unit62_indep_deciles.txt`,
`unit64_indep.txt`, `pipe62_seed777.txt`, `sweep_tile_key.txt`, `sibling_weights.txt`,
`small_exact_rerun.txt`, `model_review_out.txt`, `model2_4rfix_out.txt`, survivor dumps.
