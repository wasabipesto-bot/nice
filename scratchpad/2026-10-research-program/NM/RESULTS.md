# NM: near misses as a by-product of the nice-only search — results (2026-11-18)

## Verdict: KILL — on yield (≈ 5 vs the bar of 30), and the CPU cost (+5.7–6.5 % at b62/b64) misses the 3 % bar too. Stop the line.

Variant A at m = 2 would find **about 5 numbers with ≥ b − 2 distinct digits over the rest of
base 62 plus all of base 64** (range 3–9 with the checked-rate uncertainty; Poisson 90 % on top of
that 1–13). The kill bar is 30. Cost fails too, but less decisively: on the CPU (measured, one thread, 5 rounds, counters identical)
m = 2 costs ×1.046 (b60 1e16), ×1.065 (b62 1e17), ×1.057 (b64 1e17) against unmodified main, of which
×1.013–1.037 is the tolerance itself and the rest my prototype's layout overhead at m = 0; on the GPU a
straight edit of the check kernel costs ≈ +7 % (b62) / +11 % (b64) of a field (fails too), a
compacted second pass ≈ +0.6–1.0 % (would pass, priced not timed).

**Why the yield is ~100× below the brief's premise: the digit-sum (mod b − 1) filter.** Every
candidate the nice-only search examines is in a root class, n² + n³ ≡ b(b − 1)/2 (mod b − 1), and
the digit sum of n² ‖ n³ is ≡ n² + n³. A number with b − 1 distinct digits has one digit x doubled
and one y missing, digit sum b(b − 1)/2 + x − y, so in a root class x ≡ y (mod b − 1): only
{x, y} = {0, b − 1}. In a root class the b − 1 near misses are therefore *exactly as many as the
nice numbers* (b! strings each) — base 62's "0.4 numbers with 61 digits" become 4.5e-4. At b − 2
the filter keeps ≈ R/(b − 1) of them (2/61 at b62, 8/63 at b64). No change to the check or the
join's later stages can undo this; only probing all b − 1 classes could, at ×30 (b62) / ×8 (b64)
the join. Even a check that caught *every* root-class b − 2 number would get ≤ ≈ 21 (uniform model,
which overstates; see §2), still under 30.

A second, smaller correction: the brief's "4.5e10 checked per base-62 field" is per *non-empty*
field. Production telemetry (12,370 b62 submissions) gives a mean of 1.22e10 over all fields; 72.6 %
of fields check nothing.

## 1. Definitions and coverage

**Reaches the check** (exactly as `overlap_join::join_range` + `cpu_join`, shape t = L − 3, k = 6,
p = 2, f0 = 3, mid = 2, k2 = 8), for n in the field [s, e):
1. n mod (b − 1) is a root (`FieldSetup::roots`);
2. the top certificate of n's block [P·b³, P·b³ + b³ − 1] ∩ [s, e) is clean: the digits of n² and n³
   at positions ≥ c0 = max(k, digits of hi^j − lo^j) common to both ends are distinct, and the
   **closure** (`close_certificate`) does not empty a domain: at each power's first disagreement
   at or above c0 the digit is d or d + 1; if one of them is already certified the other is added
   to the mask (a digit only a nice n is sure to have there);
3. the bottom: the low 6 digits of n² and of n³ (12) are distinct;
4. bottom ∩ closed top mask = ∅;
5. the prefilter: n²'s and n³'s digits at positions 6, 7 are distinct, new against the bottom, and
   against the closed top mask when every certified position is ≥ k2 (always, in production).

The by-product for tolerance m is {n reaching the check with ≥ b − m distinct digits}: a property
of the field and the join's shape only (slices, partition order, the skip walk and the field-cert
prune do not change it). Brute force of this definition = the prototype's output, **EQUAL on all 20
cases** (`raw/bf2.txt`, `raw/bf.txt`): whole bases 20, 22, 24, 25, 28, 29, 30 (scaled shapes),
b40 whole 1e10 fields, partitions at b44, b45, b50, b60, b62, b64, m = 1, 2, 3 and 64 (count
everything: then the whole repeat histogram matches too). The closure was the one subtlety: without
it the brute force over-counted 1,787 vs 1,451 at b40.

**Fraction of all near misses found** (model: DP over digit occupancies with the digit sum exact,
`code/model.py`, × the measured rates of §2):

| | b − 1 | b − 2 | b − 3 |
|---|---|---|---|
| in a root class, b62 / b64 | 0.11 % / 0.45 % | 3.4 % / 13 % | 3.3 % / 13 % |
| reaching the check (variant A), b62 | ≈ 0.03 % | 0.4–1.3 % | 0.2–0.7 % |
| reaching the check, b64 | ≈ 0.2 % | ≈ 3 % | ≈ 2 % |

Within root classes the position coverage (no repeat among the ~33 digits known before the check)
is 0.71 (b − 1), 0.50 (b − 2), 0.35 (b − 3) by the uniform position model. Small bases, every n by
brute force (b − 1/b − 2/b − 3 in the base → reaching): b20 1/15/222 → 0/0/8, b22 0/10/261 → 0/1/5,
b24 1/3/145 → 0/0/2, b25 0/18/481 → 0/2/19, b28 0/8/367 → 0/0/9, b29 0/4/400 → 0/0/3, b30 0/18/898
→ 0/0/5; the model for the same shapes predicts 5.3 and 61 reaching at b − 2 / b − 3 (seen 3, 56).

**Variants** (exact counts from 30 sampled b62/b64 1e17 runs, 2.2e9 checked survivors, `raw/hist2.txt`):
- Tolerating repeats in the prefilter's 4 digits: per checked survivor today, AND survivors with
  1 prefilter repeat are ×4.2, with 2 ×6.3 (both bases): the check's load ×5.2 / ×11.5. Dead.
- Tolerating shared digits in the AND: by the hypergeometric on the measured mask sizes (top ≈ 17,
  bottom 12, b = 62) pairs sharing one digit are ≈ ×6 those sharing none; the prefilter (24 % of a
  b62 field on the card) and everything after would scale with it. Dead. (Model, not run.)
- Tolerating a repeat in the certificates: ≈ ×2.5 more tops (C(18,2)/62), each feeding the AND. Dead.
  (Model, not run.)
- All three only raise coverage *inside* root classes, which caps the gain at ×2 (§ verdict).
- Tolerating the residue: all b − 1 classes, ×30 / ×8 the join. Dead.

## 2. Yield

Measured repeat histogram of checked survivors vs the uniform-middle model given the digits known at
the check (`code/hist.py`): ratio 1.03–1.09 for j = 7–13 repeats at b62 (7.4e8 survivors, lowest
j seen 6) and 1.04–1.08 at b64 (1.5e9, lowest 6). The model's P(j | checked), × the residue factor
(DP; 1.03 at j = 2, 0.033 at j = 1) × 1.08 calibration: b62 j1 6e-20, j2 6.2e-16, j3 8.0e-14;
b64 j1 1.4e-20, j2 1.3e-16, j3 1.9e-14 (`code/yield.py`).

Checked survivors per 1e17 field: b62 1.22e10 (telemetry, frontier) to 4.15e10 ± 0.9e10 (my 15
slice-sampled runs over 0.15–0.95 of the range); b64 7.5e10 ± 2.3e10 (15 runs; no telemetry yet).

| | fields | ≥ b − 1 | b − 2 | b − 3 |
|---|---|---|---|---|
| rest of b62 (86 %, 82,070) | | ≈ 1e-4 | 0.6–2.1 | 80–270 |
| all of b64 (377,800) | | ≈ 4e-4 | 3.8 (2.6–4.9) | 530 (370–680) |
| **sum** | | ≈ 5e-4 | **4.4–7.0** | 610–950 |
| b60, finished (162,084 × 5.77e9 telemetry) | | ≈ 3e-4 | 2.7 | 320 |
| b58, finished (model × b60's reach calibration 0.54) | | ≈ 2e-4 | ≈ 1.4 | ≈ 160 |

Lost per day of base 62 not running it (1.2 % of the base): ≈ 0.01–0.03 numbers at b − 2,
≈ 1–3 at b − 3.

## 3. Cost

**CPU** (`raw/cost.txt`, one thread, base = unmodified main 7e0113fc vs the prototype, 5 rotated
rounds, CPU2's shapes; survivors, checked and hits identical in every run):

| shape | m = 0 (prototype) | m = 2 | m = 2 vs m = 0 |
|---|---|---|---|
| b60 1e16, 16 partitions | ×1.033 | ×1.046 | ×1.013 |
| b62 1e17, 16 partitions | ×1.026 | ×1.065 | ×1.038 |
| b64 1e17, 8 partitions | ×1.019 | ×1.057 | ×1.037 |

(`raw/cost-clean-summary.txt`; per-round ratios 1.047–1.079 at b62 m = 2.) The m = 0 overhead is the
prototype's (the tolerance dispatch and result fields; the production path is otherwise unchanged)
and a careful implementation could recover most of it; the tolerance's own cost, ×1.013–1.038, is
the scan continuing to the third repeat (most checked survivors repeat within the first few middle
digits). A first run with measurement instrumentation in the per-pair path (`raw/cost-summary.txt`)
read ×1.036 / ×1.093 / ×1.108 at m = 2 and ×1.057 / ×1.090 / ×1.132 at m = 3; discarded as a cost
figure for that reason. By the brief's bar (3 %), CPU m = 2 fails at b62 and b64 against main.

**GPU** (`common/src/cubecl_join.rs` `check_kernel`): the kernel ORs every digit of n² and n³ into a
mask and counts it, so the distinct count is `uniq` already; variant A is (i) gate `seen >= s2 + 2·gl
− m` (`:3611`), (ii) hit `uniq >= base − m` (`:3652`), (iii) write `uniq` next to n (`:3657`,
`NICEONLY_STRIDE`), (iv) the host reads it into `NiceNumberSimple`. The gate is the cost: among
checked survivors (`code/gate.py`, 7.2e5 / 1.4e6 sampled) it passes 1.4e-3 / 1.3e-3 of lanes today and
8.5e-2 / 7.6e-2 at m = 2, so the planes that build n³'s upper limbs go from 4.5 % → 94 % (32 lanes) /
8.8 % → 99.7 % (64 lanes) at b62, 4.0 → 92 % / 7.9 → 99.4 % at b64. Those limbs are 76 of the
check's 119 limb products at b62 (43 before the gate) and 14 of 32 limb normalisations: with a
fixed part of ~20 %, the check becomes ≈ ×1.9–2.1, i.e. **+6.5–7.7 % of a b62 field (check 7 %) and
+10–12 % at b64 (check 11 %)** for the straight edit. A compacted design (lanes that pass the tolerant
gate append to a second list; a second pass builds the rest of n³ for those only, as the join's
survivor stage does) costs ≈ ×1.08–1.09 of the check: **+0.6 % (b62), +1.0 % (b64)**, ±50 % (priced from
counts and the products, not timed; no kernel written, no lavapipe run: not worth it after the kill).

## 4. What the rest of the system would do

Nothing would mistake them for nice numbers, and nothing would show them. Details with lines in
`NOTES.md` (07:50): clients hard-code `num_uniques: base` for nice-only hits (`client/src/main.rs:955`,
`cubecl_backend.rs:3185`, `stride_filter.rs:298,365`); the API stores nice-only numbers unchecked as
given (`api/src/main.rs:347-356`), with niceness = uniques/b; jobs rebuild `bases.numbers` (the source of
`cache_notable_numbers` and the site's chart) only above 20 % detailed coverage
(`jobs/src/main.rs:271,335`, `lib.rs:50`), which b62/b64 will never have; consensus and validation see
detailed submissions only. To show them: a jobs change (fold nice-only numbers in regardless of
coverage) and, prudently, server-side verification of num_uniques in the nice-only branch. Every
backend that runs nice-only fields (CPU join, CubeCL join, the stride paths, hand CUDA) would need
it, or the set depends on who ran the field.

## Files
`NM/NOTES.md` (log), `NM/PROPOSAL.md`, `NM/code/` (`model.py`, `hist.py`, `gate.py`, `yield.py`,
`cost.py`, run scripts), `NM/raw/` (model outputs, `bf*.txt`, `hist2.txt`, `sample.txt`, `cost.txt`).
Prototype: worktree `~/projects/nice/.worktrees/nm-near-miss`, local branch `nm/near-miss`, uncommitted
diff saved as `NM/raw/nm-near-miss.patch`; never pushed.
