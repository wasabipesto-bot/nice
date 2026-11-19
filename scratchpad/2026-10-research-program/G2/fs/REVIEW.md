# FS review: is the middle-out field structure a local optimum? (2026-11-19, 05:45–06:40 UTC, ivory CPU only)

Labels: **[M]** exact count from the prototype or a measured time from the build notes; **[D]** derived from
measured numbers; **[G]** guessed. "F678" = the proposed fields (fix digits 6–8, coordinate `(k0, k1, q0) = (4, 9, 6)`);
"F567" = fields fixing digits 5–7 (`(4, 8, 5)`). A *slice* = all n sharing digits 4–8 (the (4, 10) join's unit).

## 1. Answer to the owner

**No, it is not a local optimum. A few percent of speed depends on which middle digits a field fixes. The 5–7 choice gets
that back for the same server work, so it should be used instead of 6–8.**

- **What the field decides, and what it doesn't.** A field fixes three middle digits of n and leaves all others free. Two
  things follow:
  - Any join that splits n into a top part and a bottom part sees every digit of n on one side or the other. That covers
    today's overlap join and every middle-out variant. So it can restrict itself to a field by filtering its lists, and
    its pair work shrinks in proportion. **[proven, by the definition of such a join]**
  - Inside the middle-out family, every field is a union of whole slices. So the join's shape, kernel, chunking,
    pairing method and mask width are all free. The field can even be re-cut later (other fixed digits) without
    redoing any search, though not without server bookkeeping. **[proven]**
- **What can still be lost is small.** Only the work a field lets neighbouring slices share depends on the field:
  - that is tops and parents, 13 % of a slice at base 64 and 23 % at base 65 **[M, stage times on the 3080]**;
  - so no grouping of the same work can beat any other by more than ×1.15 (b64) or ×1.30 (b65) **[D]**;
  - the kernel (71 %) costs the same under every field definition: its work depends only on the slice and the shape.
- **The one real loss I found:**
  - Slices that differ only in digit 8 could share their parents' preparation. Fixing digits 6–8 puts those slices in
    64 different fields.
  - Fixing 5–7 instead leaves digits 4 and 8 free. That keeps the existing top sharing (digit 4) and adds parent
    sharing (digit 8). The per-slice root pass shrinks to 22 % of its size **[M counts]**. Price: about 3–5 % per slice
    against about 1–2 % for the best F678 allows, **≈ 3 % net (b64), ≈ 3–4 % (b65)** **[D/G]**.
  - It costs nothing on the server: the same 262,144 fields of 2^57 at b64, still a bit permutation.
- **Every alternative structure lost or tied** (§3):
  - contiguous ranges of n break even with today's main only at ≥ 1/18 of the base **[D]**;
  - keys on low digits, residues or classes rebuild one side in every field;
  - the k = 9 shape has 1.9–2.0× the pairs at b64 and b65 **[M]**.
- **What would make me wrong:**
  - a search method that is not a prefix–suffix join (BX found none; that finding is measured negative evidence, not a
    proof);
  - fields that must be ≲ 64 slices (for example for CPU clients), where the leftover choices start to matter;
  - a GPU measurement showing that sharing the preparation is worth much more than derived here (unlikely to flip the
    recommendation, only its size).
- **What it costs to back out** of base 64 in this form **[D/G]**:
  - redoing nothing already searched;
  - for a range-based search of the remainder, about ×1.9 on the remainder without its leading-digit prune;
  - or a range-based sweep that skips finished slices, losing about 17 % of the finished fraction (§6).
- **Basis of the judgement:** the claim that this does not block a better peak is my judgement, resting on the proven
  coverage property and BX's measured negatives. The size of the loss is derived from measured stage times and exact
  counts.

## 2. The commitment, precisely (checked against `coord.rs`, `cpu.rs` `Shape::fits` / `slices_of`, PROPOSAL §2)

**What the server and every tool must assume, per base, once fields exist:**

1. **The coordinate**:
   - `v = start + key·(H·b^k0) + (h − h0)·b^k0 + low`, with `key` = digits `[k0, k1)` and `h = n div b^k1`.
   - Base 64 `(4, 9)`: a bit permutation of `[2^75, 2^76)`, no padding.
   - Base 65: padded at `b^9`, 9.5e15 n (0.034 ppm) **[M, `raw/coord_alt.txt`]**.
2. **A field** is `(base, v_start, v_size)` made of whole quanta.
   - One quantum `H·b^q0` = every n whose digits `[q0, k1)` take one value. Every other digit is free, including every
     leading digit.
   - Base 64: 2^57 n, 262,144 quanta, 4,096 slices each. Base 65: 1.011441e18 v, 274,625 quanta, 4,225 slices.
3. **Alignment**: `v_start − start` and `v_size` are multiples of the quantum.
   - `range_size` is the count of real n.
   - A field cannot be smaller than a quantum without a new coordinate.
4. **What can no longer be said**: "searched up to n = X". Interval queries are wrong for sub-ranges, and old clients
   must never claim these fields.
5. **What results mean**: `survivors` and `checked` are functions of (shape, field) and carry the shape label. They are
   not comparable across shapes, which matters for cross-verification by a second implementation.

**What stays free**:
- the shape: natively any `f0 ≤ q0` with `k > k1`; others at the price in §3;
- the slice key, the kernels, the mask width, the chunking, the parent order or key, the prefilter and check;
- the order of slices inside a field, splitting or resuming a field, the devices;
- other bases, each with its own coordinate.

**The engineers' permits/forbids list (BUILD-NOTES §2), corrected:**

| item | as written | correction |
|---|---|---|
| permits 3 | "share parents across the 64 slices that differ in digit 4" | **Wrong.** Parents are depth-9 bottoms (digits 0–8), so slices that differ in d4 have disjoint parents and share only the depth-4 roots, which are already shared per process. What d4-neighbours share is the tops' level-5 certificates (piece C, built). Parents are shared, as depth-8 ancestors, by **d8-neighbours**, and F678 puts those in 64 different fields. |
| forbids 1 | shapes with `k ≤ 9` or `f0 ≥ 7`: "rebuilt per field, 262,144 times per base" | **Overstated.** Only the 64 fields that share the cut digit redo the cut level, and only that level's list. (4, 9) under F678 pays +0.15 fs of preparation [D: measured roots_scan 3.25e-8/adm × 64 × 72 ps], on a shape that is already ×1.9 in pairs. Tops at `f0 ≥ 7` rebuilt ×64 cost < 0.001 fs. What F678 really forbids is *sharing across digits 6–8*, not shapes. |
| forbids 2 | today's overlap join and the stride path cannot search a field | **Overstated.** Today's (3, 6) join has tops down to digit 3, which include digits 5–8, so it can restrict its tops to a field. It then loses its leading-digit prune (×5.0 on its 0.98 fs AND term, RESULTS §2): about ×1.9 of its n-field cost [D]. A v-field is also a union of 2^21 contiguous runs of b^6 n, which a range method can walk. |
| forbids 4 | no other coordinate once fields exist | **Server bookkeeping only.** For the middle-out family it is free in compute: any fixed digits inside 4–8 give unions of slices, so finished work maps onto any re-cut exactly. |
| §3 | "fixing 5–8 would forbid f0 5–6 and the hierarchy across digit 5" | True, but fixing **5–7** was not considered. It keeps `f0 ≤ 5` and `k ≥ 9` natively. It loses `f0 = 6` natively (emulated for < 0.001 fs) and the level-6 top hierarchy (< 0.1 %, §4). |
| code | `Shape::for_coord` = `(k0, k1 + 1)` | Couples the default shape to the coordinate. Under `(4, 8, 5)` the shape must be set explicitly to (4, 10). |

## 3. Alternative structures, priced

**Reference costs:**
- **Base 64:** 1.710 fs per admissible n (main 6.615) **[M, MO.6 / §6]**. Per slice (7.72 ms) **[M, BUILD-NOTES §9.4]**:
  tops 0.361, preparation 0.671, kernel 5.459, expansion 1.108, check 0.120 ms.
- **Base 65:** 3.561 fs **[M]**. Per slice (13.82 ms): tops 1.80, preparation 1.42, kernel 6.72, expansion 3.71,
  check 0.17 ms **[M, §11.4]**.
- **The bottom side B** (preparation + child generation) = 0.150 + 0.139 = **0.29 fs** at b64 **[D]**. The child cost
  is v10's measured 18.5 ps × 7.54e-6. At b65, B = 0.37 + 0.25–0.42 = **0.62–0.79 fs** **[D/G]**, using the wide child
  factor of 1.2–2.0.

| # | structure (what a field is) | join inside it | b64 fs/adm | b65 fs/adm | verdict |
|---|---|---|---|---|---|
| 1 | **F678** (proposed): digits 6–8 | (4, 10) slices; d4/d5 free: top hierarchy (built) + depth-5 parent lists (piece L) | 1.710 [M]; with L −1.1–1.5 % [D/G] | 3.561 [M]; with L −1.3–1.8 % [D/G] | sound baseline |
| 2 | **F567**: digits 5–7, `(4, 8, 5)` | same slices; d4 free (top hierarchy), **d8 free: depth-8 survivor lists shared by 64 slices** | −3.7–5.1 % → ≈1.63–1.65 [D/G] | −4.4–6.0 % → ≈3.35–3.40 [D/G] | **best found**; same server form |
| 3 | coarser: digits 7–8 (262,144 slices) | adds level-6 top hierarchy; d8 still fixed | −0.1 % [D] | −0.3 % [D] | 35 min (b64) / 62 min (b65) per field on a 3080 [D]: over the 1-h claim at b65 |
| 4 | finer: digits 5–8 (64 slices) | no change in compute (d4 free) | = F678 | = F678 | 16.8M / 17.9M fields of 0.5 / 0.9 s: ×64 rows and claims [judged infeasible server-side] |
| 5 | digits 4–6 (d7, d8 free) | deepest bottom sharing, no top hierarchy | ≈ F567 on bottoms; +0.1 ms tops (+1.4 %) [M, hierarchy saving] | +≈1 ms tops (+7 %) [M] | worse than F567 |
| 6 | a run including d9 (e.g. 7–9) | the b units of d9 split across fields | +≈9.5 fs (prep ×64) [D] | dead | dead |
| 7 | low digits 0–2 (residue mod b^3) | bottoms restricted, all tops in every field | +0.081 fs × 262,143 [D] | dead | dead; one halving of d0 costs +4.7 % (b64) / +13 % (b65) [D], the cheapest way to make fields finer if ever needed |
| 8 | n mod m, gcd(m, b) = 1 | neither list can filter; ×m on lists and pairs | dead [D] | dead | dead |
| 9 | F678 × class n mod 63 | preparation repeated per root class | +1.05 fs (8 roots) [D] | n/a (1 root) | loses |
| 10 | leading-range × F678 rectangles (r parts of h) | bottom side rebuilt r times | 1.71 + 0.29(r − 1): r = 2 → 2.00 (×0.85) [D] | 3.56 + 0.62–0.79(r − 1): r = 2 → 4.2–4.35 [D] | loses ~15 % per halving |
| 11 | **contiguous n** (1/m of the base) | the same rectangle with the whole key | m = 1: 1.71 (×3.87 vs main); 2: 2.00 (×3.31); 8: 3.74 (×1.77); **break-even with main at m ≈ 18**; 2^57 n-fields (m = 262,144): ≈ 76,000 fs [D] | m ≈ 28 to break even with the projected 22.9 fs [D] | the design's claim holds (PROPOSAL §4: ×5.1/4.3/3.2/2.2 at older costs) |
| 12 | hash or scatter of slices | same kernel, no neighbour sharing | +1.4 % [M/D] | +7 % [M/D] | no gain: field costs are already uniform to ±2.5 % [M] |
| 13 | three-way top × middle × bottom | the middle digits alone certify nothing (BX A1, measured); enumerating them gives exactly slices | = 1/2 | = 1/2 | it *is* this structure |
| 14 | (4, 9) shape (slice key 4–7, units d8) | native under F567; under F678 +0.15 fs preparation | pairs 7.06e-3 vs 3.58e-3, kept 5.39e-5 vs 2.76e-5, survivors 1.25e-5 vs 2.63e-6 per adm [M, `raw/sample_b64_4_9.txt`] | pairs 8.98e-3 vs 4.61e-3, kept 8.41e-5 vs 4.44e-5 [M] | ×1.9–2.0 work: not a contender at 64/65 |
| 15 | shape varying across the base (per leading region or per field) | fields leave h free, so a client may cut a field by h and run different (f0, k) per region | unpriced (P_T by region not measured) | unpriced | permitted by every digit-run choice equally |
| 16 | one shared parent order per 64 d8-slices (no per-slice sort) | parents generated affinely from depth-8 nodes, sorted once | kept +7.0 % (two slices: 30.86M → 33.03M; 30.78M → 32.93M) [M] | +4.2 % (16.66M → 17.36M) [M] | keep a per-slice sort of the 1.04M parents; share only the root pass |

**Where the F567 gain comes from** (exact per-slice counts, mean of 3 b64 / 2 b65 / 2 b68 slices, `raw/levels_*.txt`,
`raw/price_fs.txt`):

- The preparation is a closed-form pass per depth-4 root (TUNE-RESULTS items 9 and 11): about 65 % of it is
  proportional to the roots processed **[G, the 9070 XT model's split]**.
- The roots processed per slice under each order:
  - no sharing: 9.30M (b64) / 10.89M (b65) / 12.85M (b68);
  - piece L, depth-5 lists per d4 (the most F678 allows): **76.8 % / 77.1 % / 78.0 %**;
  - F567, survivors to depth 8 listed once per (field, d4) and reused across the 64 values of d8:
    **21.9 % / 22.4 % / 24.0 %** (1.89M / 2.28M / 2.90M of the roots).
- Memory as 4-byte root indices for all d4 at once: 0.48 / 0.59 / 0.79 GB **[D]**. That lets the slices run with d4
  innermost, so the built top hierarchy is untouched. This settles REVIEW F4's "tops and bottoms want opposite orders"
  inside one field.

## 4. Future optimisations against the field definition

| optimisation (source) | F678 (proposed) | F567 (recommended) |
|---|---|---|
| main-kernel items: 8-byte records, root pass, LDS diet (BUILD-NOTES §7 D) | permits unchanged | permits unchanged |
| expansion bound (K), two records per lane, 32-bit-limb prefilter (§11.5) | unchanged | unchanged |
| parents' preparation (L) | **depth-5 only**: −1.1–1.5 % / −1.3–1.8 % | **depth-8**: −3.7–5.1 % / −4.4–6.0 % [D/G] |
| top hierarchy, level 5 (C, built; d4 free) | unchanged | unchanged |
| top hierarchy, level 6 (needs d4 and d5 free) | permits (< 0.01 ms b64, ≈ 0.05 ms b65 [D from measured P_T(f0 6) 0.30 / 0.32]) | forbids: the same < 0.1 % / 0.3 % lost |
| sharing **tops** across neighbouring slices | d4-neighbours, same field | d4-neighbours, same field |
| sharing **parents** across neighbouring slices | **forbidden**: d8-neighbours are in 64 fields | **permitted**: d8-neighbours in one field (§3 #2) |
| a different chunking or a shared parent order across slices | inside a slice only | also across d8 (measured: a shared order costs +4–7 % kept, so not worth it as such) |
| table-lookup (four-Russians) pairing; smaller records; mask width | unchanged | unchanged |
| BX pairing headroom (OV-type pairing, ceiling ×1.14–1.36 at today's shape; wants bigger groups) | permits: a field can be one big group keyed on its own digits ((6, 9) shape) | permits: (5, 8) shape |
| shape moves: f0 3–5, k 10–12 (incl. b65 (5, 10), b68–70 (4, 11)) | native | native |
| shape moves: f0 = 6 | native | emulated, < 0.001 fs |
| shape moves: k = 9 | +0.15 fs preparation | native (but ×1.9 work at 64/65 [M]) |
| deeper bottoms at larger bases (b70 (4, 11): the top key digit is d9) | per-base coordinate; `(4, 9, 6)` already leaves d9 and d4 free at b70 | same rule ("fix the middle of the key"): (4, 9, 5) fixes 5–8 at b70, 4,900 slices of 25 ms ≈ 2 min |
| splitting or resuming a field across devices; sampled CPU audit; field-level parent key (a base-level property: 4 random b64 slices give the same first 5 key digits [M]) | unchanged | unchanged |
| a later switch to a range-based search of the remainder | overlap join ×1.9 on the remainder, or a sweep with friction ≈ 17 % × done [D/G] | same (tops at f0 3 cover 5–7 too); contiguous runs inside a field are b^5 n, not b^6 |
| finer fields for slow or CPU clients | low-digit halving, +4.7 % / +13 % | same |

**Weight over time [D]:** these choices act only on the part of a slice around the kernel. If piece D makes the kernel
×2 faster, tops + preparation become 21 % of a b64 slice and the d8 sharing is worth ≈ 6–8 %. The field choice matters
more after the kernel work, not less.

## 5. Recommended field definition (bases 64 and 65)

| | proposed (BUILD-NOTES §2) | **recommended** |
|---|---|---|
| fixed digits | 6–8 | **5–7** (digits 4 and 8 free: the two ends of the (4, 10) slice key) |
| coordinate `(k0, k1, q0)` | (4, 9, 6) | **(4, 8, 5)**: the same formula, only `coord_digits` changes. Bijection checked on 20,000 random n per base [M, `code/coord_alt.py`] |
| b64 form | n bits 24–53 → 45–74 | n bits 24–47 → 51–74 (H = 2^27): still an exact bit permutation of [2^75, 2^76), no padding |
| b64 fields | 262,144 of 2^57, 4,096 slices, ≈ 31 s on a 3080 [M] | **identical**: 262,144 of 2^57, 4,096 slices (64 d4 × 64 d8), ≈ 31 s [D] |
| b65 fields | 274,625 of 1.011441e18 v, 4,225 slices, ≈ 58 s [M] | 274,625 of H·65^5 (H = 871,713,216), 4,225 slices, ≈ 58 s; padding 2.6e14 n (0.0009 ppm) [M/D] |
| shapes native (`fits`) | f0 ≤ 6, k ≥ 10 | f0 ≤ 5, k ≥ 9 (f0 = 6 emulated for < 0.001 fs) |
| neighbour sharing in a field | tops across d4 (and d5) | tops across d4, **parents across d8** |
| speed vs proposed | — | kernel identical [D]; ≈ −3 % (b64), −3–4 % (b65) once the depth-8 lists are built [D/G]; −0.1 % / −0.3 % for the lost level-6 top hierarchy [D] |
| server / schema | option A as in PROPOSAL | identical (field sizes and counts unchanged at b64) |
| code change | — | `coord_digits` → (4, 8, 5); `Shape::for_coord` must return (4, 10) explicitly; the GPU top hierarchy already iterates d4 innermost under `slices_of` |

The rule behind it, for any base and shape: **fix a run strictly inside the slice key, and leave its lowest digit
(for the tops' hierarchy) and its highest digit (for the bottoms' shared parents) free.** For bases 68–69 (4, 10)
that is again (4, 8, 5). For b70 (4, 11) it is (4, 9, 5), or (4, 9, 6) at a field size of 70^3 slices.

If the owner prefers zero change to the built code, F678 is a defensible choice: the difference is a few percent [D/G],
and it can be re-cut later with no lost search (§2). The only reason to decide now is server bookkeeping.

## 6. Evidence, by kind

- **Proven** (by construction):
  - in a prefix–suffix join with f0 < k, every digit of n is fixed by the top or the bottom, so every digit-fixing
    field is a list-level filter for every such join;
  - fields whose fixed digits lie inside 4–8 are unions of (4, 10) slices;
  - which neighbours share what: tops are shared across d4, parents across d8.
- **Measured** (this review, exact):
  - per-depth bottom counts at b64, b65, b68 and b70 (4, 11);
  - (4, 9) counts at b64 and b65;
  - the shared-order kept penalty (+4–7 %);
  - the coordinate bijection and sizes.
- **Measured** (cited): the per-stage times at b64 and b65 (BUILD-NOTES §9.4, §11.4), P_T (`bases/raw/ptop.txt`).
- **Derived**: every fs penalty in §3 and §4, the "any grouping ≤ ×1.15 / ×1.30" bound, the ×1.9 overlap-join fallback,
  break-even m ≈ 18.
- **Guessed**:
  - the preparation's root-proportional share (55–75 %) on the 3080;
  - the wide child-cost factor;
  - the ≈ 17 % sweep friction (today's per-field bucket and upload share, RESULTS §2).

## 7. What I did not get to

- No GPU measurement of the depth-8 parent sharing (needs a card; it is piece L widened to depth 8). It decides whether
  the F567 gain is 3 % or more.
- P_T by leading region (whether a shape that varies across the base pays): unpriced. It is permitted equally by every
  digit-run choice.
- No test run of the built trunk with `(4, 8, 5)`: only the coordinate formula is checked in Python. The `nice_common`
  build was skipped with 4 GB of disk free.
- Not quantified:
  - CPU-client feasibility (fields of 4,096 slices are hours to days on one CPU thread, for either choice);
  - the server's limit on field count, for finer fields;
  - the stride path on b^6 runs.
- Bases 68–70 are covered only by level counts and the rule in §5.

## Files (all under `G2/fs/`)

- `proto/`: a copy of `bases/proto` with a per-depth bottom counter and two additions: the `levels` command and
  `G2_ANCKEY=1` (parents ordered by their depth-8 ancestor). The originals are unmodified.
- `code/coord_alt.py`: the coordinate variants and the bijection check.
- `code/price_fs.py`: the preparation-sharing prices.
- `raw/`:
  - `levels_b64/b65/b68/b70k11.txt`, `sample_b64_4_9.txt`, `sample_b65_4_9.txt`;
  - `anc_*.txt`, `coord_alt.txt`, `price_fs.txt`.
