# G2 notes (living; newest at the bottom of each section)

Started 2026-11-16 16:28 UTC. Hard stop 20:45 UTC. Tags: [M] measured here, [P] measured
elsewhere (file cited), [D] derived, [G] guess.

## 0. Inputs taken as given

- Today's GPU field profile on main (N22 table, RTX 3080 ≈ 285 W, 1e17 fields) [P]:
  b62 58.1 s/field = tops 26 %, prefilter 24 %, AND 12 %, walk 7 %, check 7 %, join base 8 %,
  bucket 5 %, upload/host 5 %, other 5 %, copy 1 %. b64 92.8 s/field = prefilter 26 %,
  AND 15 %, walk 11 %, check 11 %, tops 13 %, base 7 %, rest 17 %.
- Counts per admissible n (N1.C1, base means) [P]: b62 pairs 6.7e-3, AND survivors 2.5e-4,
  checks 1.5e-5; b64 3.5e-3 / 1.5e-4 / 9.6e-6. N1 shape (f0 4, k 9): b62 7.56e-3 / 1.39e-5 /
  5.0e-7; b64 6.84e-3 / 1.07e-5 / 3.9e-7.
- N1.G1 [P]: dense ps/pair by tile: 471×336 0.455–0.61; 1460×14750 0.27–0.44; 24×7200 1.11
  (today orientation) / 3.39 (reverse). AND part ∝ the entry's digit count (17–18 fs/digit u32,
  10–14 u64). Survivor path floor 0.13–0.15 ps/pair (per-chunk machinery) + 14 ps × pass rate.
- N5 PSJ model [P]: flat floor ≈ ×4 under today at b62; ideal output-sensitive ×6 (b62) / ×10
  (b64) beyond flat; digit-key indexing ×2–2.5 on the pair term.

## 1. First-principles accounting (before any code) [D]

Write n = (top digits [f0, L)) ∪ (bottom digits [0, k)), overlap o = k − f0 shared digits.
uniform-digit model: P(m) = Π_{i<m} (1 − i/b) = probability that m output digits are distinct.

1. **A pair-tree (dual-tree) join has the same floor as the flat join.** Pair-nodes (top node at
   depth a, bottom node at depth c) with a + c < L branch; the count at a + c = L − 1 is
   W/b · P(cT(a) + 2c) and the expansion to full identification (class-valid children only,
   ≈ 2 per node at b62) costs ≈ A · P(cT(a) + 2c) ≈ A · P(2L − 2 − fuzz) ≈ 6e-3 – 1.4e-2 per
   admissible n at b62: today's pair count (6.7e-3) is already there. In the overlap regime a
   parent pair has exactly one child pair (the shared digit is forced), so a "parent-pair test
   first" never saves. Overlap is the trick of putting both sides deep at once; nothing in the
   tree formulation beats it. The only pair-tree saving that exists is the *block prune*
   (a coarse top ancestor with large fan-out against a deep bottom), which today already takes
   (×3.3 at b62).
2. **Inside a transversal unit (π = shared digits fixed) the internal tree levels are weak.**
   The π digits only enter a certificate once every digit above (tops) or below (bottoms) them
   is fixed, so a trie over the unit's free digits has certificates of cT(≤3) ≈ 4 digits until
   the last level jumps to cT(t). Hierarchical pruning inside a unit is worth ≈ the block prune
   (×3), not ×100.
3. **The bit-sliced AND costs popcount(iterated mask)/chunk width per pair**, i.e. Σ over
   (bottom, top-chunk) incidences of popcount(bottom). Deeper bottoms raise the popcount
   (12 → 18 → 20 digits), so a deeper shape pays more per pair (N1.G1 saw exactly this).
   Today's AND ≈ 6.7e-3 × 12/32 ≈ 2.5e-3 digit-ops per admissible n; N1's shape ≈ 7.6e-3 ×
   18/32 ≈ 4.3e-3 at b62 and 6.8e-3 × 18/32 vs 3.5e-3 × 12/32 at b64 (×2.9). That is why N1
   lost at b64: transversal units lose the leading-block prune (tops of a key span the whole
   base) and pay longer bottom masks.
4. **Small tiles at deep k are structural:** tops per (key, class) = W·b^(−k)·P_T(f0)/(b−1·…);
   at b62 that is 1,460 at k 9 and 24 at k 10 regardless of how the unit is cut. With a bit-
   sliced AND the per-bottom work is popcount × ⌈tops/32⌉, so below 32 tops per group the AND
   cost is per *bottom*, and b^k·P(2k) grows with k. k 10 is the edge at b62, k 10–11 at b64.
5. **Amdahl at ×10.** b62: the AND alone is 12 % of today = 2.1 fs of the 1.77 fs budget per
   admissible n (field basis). So ×10 at b62 needs the AND itself cheaper *and* every other
   stage (88 %) cut to ≲ 4 % of today; at b64 the AND is 15 %, so the rest must go to ≲ 2.5 %.

## 2. Ideas in play (to be tested by counts)

- (a) **Four-Russians AND**: per (bottom, 64-top chunk) do 8 byte lookups into a 8×256×u64
  table built once per chunk (16 KB) instead of popcount (18–20) slice ORs. Cost no longer
  grows with the bottom's depth; ×1.5 (today, 12 digits) to ×2.25–2.5 (deep, 18–20) fewer
  LDS/loads per pair. Exact (it is the same OR, precomputed by byte).
- (b) **Chunk-common certificates** (the block prune made transversal): sort a group's tops by
  their leading digits; each 64-top chunk (and super-chunk) stores the intersection of its
  members' masks; a bottom skips a chunk whose common mask meets it (1 AND). Sound (necessary
  condition for every member). Strength depends on how many leading digits a chunk shares:
  measure on real top lists.
- (c) **Deepest bottom digit generated in registers** (N1's "key digit"): for k 10 the
  materialised list is depth 9 and children are produced on the fly, so the 2.7e16 depth-10
  bottoms are never stored.
- (d) Early exit in the slice loop when a chunk is all dead (≈ −35 % digits); subsumed by (a).

## 3. Prototype (G2/proto, standalone crate, no deps) and what it measured (16:40–17:05 UTC)

`proto/` = exact 256-bit arithmetic, top certificates of an interval (digits of n², n³ constant
over it, positions ≥ k), bottom certificates by an incremental DFS (r², r³ mod b^k), a keyed
join restricted to one *transversal unit* {n in range : digits [u0, u1) = U}, the reference shape
(f0 3, k 6) on the same unit, and pairing variants (scalar, bit-sliced, four-Russians, chunk-skip).
Binary copied to `G2/g2proto.bin`.

- **Exactness vs brute force** [M] (`raw/small_exact.txt`): 14 (base, shape, unit) combinations
  at b10–b28, whole bases, join output == brute-force predicate set, 69 found at b10 by both.
  A u128 power-table overflow (pw saturating at 62^22) was caught by the b62 cross-check and fixed
  before any count below was taken.
- **b62 / b64 units vs the reference shape on the same n** [M]: every n of S_ref that satisfies
  the G2 predicate is in S_new (0 lost; b62 k10 two units both directions; b62 k9 1.62 M members
  streamed; b64 k10 two units streamed), every S_new member satisfies its own predicate (direct
  recomputation, all or ≥ 20,000 sampled).
- **Calibration of the reference implementation**: REF(3,6) survivors per admissible n =
  2.52e-4 (b62, three units) vs production's base mean 2.5e-4 (N1.C1); b64 1.92e-4 vs 1.5e-4
  (production's top certificates/clipping are a little stronger there, or the mean's empty
  fields; within 30 %). REF pairs 2.15e-2 (b62) / 1.76e-2 (b64) *without* the field prune;
  production's 6.7e-3 / 3.5e-3 have it (×3.2 / ×5.0).
- **G2 shape counts** [M] per admissible n (model in brackets):
  b62 (4,9) pairs 7.78e-3 [7.59e-3], surv 1.61e-5, chunk incidences 1.24e-4 [1.22e-4];
  b62 (4,10) pairs 3.87e-3 [3.74e-3], surv 3.3e-6 [3.25e-6], incidences 1.62e-4 [1.62e-4];
  b64 (4,10) pairs 3.52e-3 [3.91e-3], surv 2.6e-6 [2.8e-6], incidences 7.5e-5 [6.6e-5].
  P_T measured per base and f0 (`raw/ptop.txt`), b62 P_T(3) 0.071 / P_T(4) 0.124 = N1's.
- **Chunk-common skip is weak** [M]: kept fraction κ = 0.85 (b62 k9, tops in leading-digit
  order), 0.76 (mask-clustered order), 1.00 at b62 k10 (24 tops per group share nothing), 0.89
  at b64 k10. The leading-block prune does not survive transversality: a 64-top chunk spans
  ~1/23 of the base's leading range, a production field fixes ~3.5 leading digits.
- **CPU pairing costs** [M] (one EPYC-Rome thread, ns per pair): b62 k9 scalar 0.27, bit-sliced
  0.30, **four-Russians 0.11**; b62 k10 (24-top groups) 0.31 / 0.85 / 0.30; b64 k10 (60-top
  groups) 0.27 / 0.41 / 0.14. Four-Russians ≈ 7 ns per (bottom, chunk) incidence on this core.

## 4. Clustering and orientation (17:05–17:50 UTC) [M]

- **Top-driven orientation** (bottoms in 64-chunks, each top probes its roots' class groups) has
  flat incidences = pairs/64 whenever the bottom class groups are ≥ 64 (7,000 at b62 (4,10), 9,100
  at b64 (4,10)), while bottom-driven pays one full chunk per bottom when top groups are small
  (24 at b62 k10). b62 (4,10): BD 1.62e-4 vs TD 6.08e-5 incidences per admissible n.
- **Presence trie** (split on the most frequent digit until ≤ 64): kept/flat 0.57–0.59 TD, 0.60–0.75 BD.
  **Probe-weighted** (split on digit frequency among items × among probes, i.e. the tops' leading
  output digits): TD 0.44–0.51 (`raw/cluster_w_*.txt`). Tree *descent* visits more nodes than the
  flat leaf scan in every case (1.2–2.0× flat): hierarchical skipping does not pay.
- **Flat chunks in a sorted order** (one sort by a probe-weighted frequency key, no trie, no partial
  leaves): child-key kept 0.452 (b64 k10) / 0.499 (b62 k10); **parent-key** (the order of the
  depth-(k−1) parents, which the b sibling units share, so the sort is paid once per super-unit)
  0.483 / 0.526 (`raw/sorted_td.txt`). This is the leading-block prune made transversal: the
  chunk-common digits are the tops' frequent leading digits.
- Child class = (parent class + d) mod (b − 1): parents partitioned by class once serve all b
  units of a super-unit, in the same order.

## 5. CPU pipeline (`G2_PIPE=1`, `proto/src/pipe.rs`) [M]

Parents (depth k−1, shared) → affine children for the unit's digit d (two digits per child:
(c2 + 2 r0 d) mod b and (c3 + 3 r0² d) mod b) → class groups → (optionally sorted) 64-chunks with
bit slices and common masks → top-driven probes → survivors → check. **Survivors identical to the
scalar join** on 2 b62 and 1 b64 (4,10) units. Seconds per admissible n, one thread:
probes 1.1–1.5e-12 (b62 and b64), children 0.5–4e-12 (23–31 ns per parent: unoptimised, u128
stores), parents 1.2e-11 per unit/62 (my DFS re-explores the free low digits per super-unit: ×21
more visits than the shared π-trie; 120 ns/visit), check 6.8e-12 (my 256-bit digit loop, 2 µs;
production's is 34 ns). Production-grade components would put the CPU pipeline near
2–4e-12 s/adm against today's CPU 1.42e-11 (b62) / 6.1e-12 (b64) [D]: the CPU is not where G2's
case is made, the pairing stage is (1.1–1.5e-12 of it).

## 6. Model v2 (`model2.py` → `raw/model2_out.txt`)

GPU unit costs, three scenarios (opt / central / pess), each derived from today's main:
u64 LDS lookup + OR 0.5 / 0.7 / 0.9 ps chip-wide (N1.G1: 10–14 fs per digit per pair in u64 = 0.64–
0.9 ps per 64-wide op; LDS peak ≈ 0.5 ps per 8-byte lookup on the 3080); per-incidence base 2 / 4 /
7 ps; chunk-common test 0.5 / 1 / 1.5 ps; bottom child 0.3 / 1 / 5 ps (5 = today's bucket kernel per
candidate, 0.3 = ~6 integer ops in registers); bottom chunk append+transpose 2 / 4 / 8 ps; sort
5 / 15 / 30 ps per bottom (÷ b when the parents' order is shared); top test 0.17 ns; survivor 17 ps +
check 58 ps × 6 %; other 3 / 5 / 10 %. Baselines: b62 13.2 fs/adm (N22 field ÷ 1.34 field/mean
survivor ratio); b64 4.5 fs (same method, ratio 1.62) or 5.6 fs (N1's 9.2 fs base mean ÷ 1.63, the
N17→N22 field speed-up). Results (central, range):
- b62 (4,10) TD parent-sorted **×10.5** (×4.8–18.4); b62 (4,9) TD clustered ×10.0 (×6.7–14.9);
  b62 (4,9) BD 4R ×8.0 (×5.5–12.1).
- b64 (4,10) TD parent-sorted **×8.4** (×5.1–13.3), ×10.4 against the 5.6 fs baseline.
- AND-only ceilings at optimistic costs: ×50 (b62), ×23 (b64).
- Work unit (§ RESULTS): contiguous batches lose fast (b62 ×6.2 at 1/10 of the base, b64 ×3.5).

## 7. Status at 17:50 UTC

RESULTS.md written (verdict: not killed; b64 ×8.4 central, b62 ×10.5; ×10 plausible, not
demonstrated; needs transversal work units). Open, in order of value:
1. GPU tile microbenchmark (not allowed in this brief): cost per 64-pair word top-driven, per-bottom
   child+transpose cost, today's b64 base mean. These three decide ×10.
2. Better chunk ordering (kept 0.48 → 0.35 would add ≈ ×1.2 at b64): joint top/bottom ordering,
   orderings that target the specific leading digits of each top class group.
3. Production-grade CPU pipeline (parents via the shared π-trie, 3-ns affine children, radix sort)
   to measure the CPU ratio honestly (today's prototype is dominated by my slow DFS and check).
Known prototype limits: top certificates are the plain interval certificate (no closure), so
P_T may differ slightly from production's; REF survivors at b64 are 28 % above production's base
mean (production's certificates or the mean's empty fields).

## 8. Shareable chunk order check (17:50 UTC) [M]

The parent order must be the same for the b sibling units, so its weights cannot be one unit's
class group: with probe weights pooled over all of the unit's tops (`G2_POOLED=1`,
`raw/sorted_td_pooled.txt`) the parent-key kept fraction is 0.488 at b64 k10 (0.483 per-group)
and 0.581 at b62 k10 (0.526). Model updated to the pooled numbers: **b62 (4,10) ×10.1
(×4.7–17.6), b64 (4,10) ×8.3 (×5.1–13.2; ×10.3 vs the 5.6 fs baseline)**. Supersedes §6/§7's
×10.5 / ×8.4.

CPU reading (derived from the measured pieces, not a run): the CPU is a different machine for
this structure. Per child ≈ 5–25 ns and per bottom chunking ≈ 30 ns are comparable to a 64-pair
word (26–37 ns sliced) on one core, while a GPU transposes 32 bottoms per ballot. Best CPU shape is
N1's (4, 9) with the four-Russians AND: ≈ 1.5–1.6e-12 s/adm at b62 and b64 → ≈ ×9 (b62), ≈ ×4
(b64) against today's CPU join.

## 9. Baseline correction (17:58 UTC)

b64's upper baseline is now 5.4 fs, not 5.6: B64.1 (EXPERIMENTS.md, 11-11) measured a 10-field
b64 base mean of 6.46 fs on c0c357a (RTX 3080, 300 W); ÷1.049 (#250+#251 stack) ÷1.13 (#254 FD at
pow2 bases) = 5.4 fs before #255/#256/#259/#260. The N22-field route gives 4.5 fs; both are
consistent with a few further percent from the later merges. b62 cross-check: MU260.1 measured main
0711b16 at 49.8 s per real b62 field (15.2 fs field basis vs my 17.7 from N22's field; base mean
13.2 is within 15 %). Final model: b62 ×10.1 (×4.7–17.6), b64 ×8.3 (×5.1–13.2), ×10.0
(×6.1–15.8) against 5.4 fs.

## 10. Chunk width (18:00 UTC) [M] `raw/sorted_td_chunkwidth.txt`

Parent-key sorted chunks, pooled weights, kept fraction / kept incidences per adm:
b64 k10: width 16 0.387 / 8.5e-5; 32 0.435 / 4.8e-5; 64 0.488 / 2.7e-5; 128 0.550 / 1.5e-5;
256 0.626 / 8.7e-6. b62 k10: 0.455, 0.515, 0.581, 0.655, 0.732. Lookup work ∝ kept × width:
1.36e-3, 1.53e-3, 1.72e-3, 1.95e-3, 2.23e-3 (b64) — narrower chunks skip a little more but pay
more per-incidence overhead; 32–64 is flat within ±15 %. Even 16-wide groups remove only 61 %:
the group test is not a lever beyond what §8 already counts. Confirms RESULTS §4.3.

## 11. Closed 18:05 UTC

Deliverables final: RESULTS.md (verdict first), model2.py → raw/model2_out.txt. If resumed: the
next step is not more CPU work but the GPU tile benchmark of RESULTS §6 (needs a box and a brief).
Cheap CPU follow-ups if wanted: production-grade children/chunking to give an honest CPU ratio;
joint top/bottom chunk ordering (expected ≤ ×1.2 at b64).
