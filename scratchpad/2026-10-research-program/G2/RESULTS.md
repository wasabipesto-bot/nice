# G2 results: a second-generation join (2026-11-16, 16:28–18:05 UTC, one ivory thread)

## Verdict against the kill criterion

**Not killed. The best sound structure models at ×8.3 per base at b64 (range ×5.1–13.2 over the
GPU unit-cost band; ×10.0 against the upper end of today's b64 baseline) and ×10.1 at b62
(range ×4.7–17.6; the (4, 9) variant gives ×10.0, range ×6.7–14.9).** ×10 at both bases is the
central value at b62 and the central-to-optimistic part of the band at b64: it is plausible, not
demonstrated. Every count in the model is measured on real b62/b64 data by an exact CPU
prototype; the ratios rest on three GPU unit costs that are derived from today's kernels, not
measured (§6), and on today's b64 base-mean cost (4.5–5.4 fs per admissible n, §2).

The structure needs the server's work unit to become **transversal** (a slice of the shared
middle digits across the whole base, not an interval of n); with contiguous ranges it needs
≥ 1/10 of the base per unit at b62 (×6.2) and the whole base at b64. With today's 1e17 fields
nothing of it transfers beyond ≈ ×1.05 (§7).

## 1. The design ("G2"), one paragraph per decision

- **Shape (f0 4, k 10)**: tops are prefixes of n down to digit 4, bottoms are n mod b^10; they
  share digits 4–9. Forced by Amdahl (§3): f0 3 tops cost 2.7 fs/adm at b62 even when built once
  per base; k 11 bottoms cost ≥ 1.6 fs/adm to *generate* (b^11·P(20)/A = 5.2e-3 children per
  admissible n at b62). k 9 is the runner-up at b62.
- **Work unit = super-unit π′ = digits 4–8 of n**, every leading value, every low value
  (62^5 = 9.2e8 super-units at b62, 64^5 = 1.1e9 at b64; 0.43 ms / 2.4 ms each on a 3080-class
  card). Inside it, the b units of digit 9.
- **Bottoms as a shared tree, the deepest digit in registers**: the depth-9 parents of π′ are
  built once (in a π-trie order across super-units, so the whole base visits each tree node
  once), and each of the b units gets one child per parent from two affine digits
  ((c2 + 2·r0·d) mod b, (c3 + 3·r0²·d) mod b). Depth-10 bottoms (2.7e16 at b62) are never stored.
  Child class = parent class + d (mod b − 1), so one class partition of the parents serves all
  b units.
- **Top-driven pairing over sorted 64-chunks**: the parents are sorted once per super-unit by a
  probe-weighted presence key (digits that are frequent in the tops' certificates first — the
  leading output digits); children inherit the order and are cut into 64-chunks per class group,
  each with bit-slices and a common mask. Each top probes its roots' class groups chunk by chunk:
  one AND with the chunk's common mask (skips 42–51 %), otherwise one 64-wide test (bit-sliced
  over the top's ~16 digits, or 8 four-Russians byte lookups when ≥ ~300 probes share a chunk).
  This is the leading-block prune of today's fields made transversal.
- **Survivors** (≈ 1e-3 of pairs) go to the existing prefilter and check: 3.3e-6 / 2.6e-6 per
  admissible n at b62 / b64, ÷75 / ÷58 against today. The survivor path and the check drop out
  of the profile, and so does the per-pair survivor machinery (one nonzero test per 64-pair word).

## 1b. What is new against N1 (the parked transversal join, ×3 GPU)

N1 = (4, 9), bottom-driven, flat bit-sliced AND, per-pair survivor machinery. G2 keeps N1's
transversal unit and adds, each measured on real data: top-driven pairing (flat incidences =
pairs/64 even at k 10, where N1's 24-top tiles died), k 10 with the deepest bottom digit generated
from shared parents (never stored; N1's memory wall), probe-weighted sorted chunks with a
common-mask skip (the field prune made transversal: kept 0.45–0.58), four-Russians words where a
chunk has enough probes, and one nonzero test per 64-pair word instead of per-pair survivor
machinery (N1.G1's 0.13–0.15 ps per pair floor). N1 GPU projection on the same baseline method:
≈ ×3 (b62), ≈ ×2 (b64).

## 2. Amdahl table: today's main (GPU, base mean per admissible n)

Today's b62: N22 field (58.1 s per 1e17 field) ÷ 1.34 (field/base-mean survivor ratio vs N1.C1)
= **13.2 fs** (cross-check: MU260.1 measured main 0711b16 at 49.8 s per real b62 field = 15.2 fs
on the field basis). b64: 92.8 s ÷ 1.62 = **4.5 fs**; upper end 5.4 fs = B64.1's measured
10-field base mean on c0c357a (6.46 fs) ÷ the measured gains of #250/#251 (×1.049) and #254
(×1.13) since, before the later merges. [M]/[D]

| stage | b62 fs | b64 fs | count per adm (base mean) | what forces the count |
|---|---|---|---|---|
| tops (FD kernel) | 3.46 | 0.59 | ≈ 2e-5 tested | f0 3 and per-field top lists: every field tests its own W/b^3 prefixes |
| prefilter + walk | 4.13 | 1.67 | 2.5e-4 / 1.5e-4 AND survivors | k 6: bottoms carry only 12 digits because a contiguous field rebuilds all b^k bottoms per slice |
| AND + join base | 2.62 | 0.98 | 6.7e-3 / 3.5e-3 pairs | P_T(3)·P_B(6) ÷ field prune (×3.2 / ×5.0) |
| check | 0.89 | 0.50 | 1.5e-5 / 9.6e-6 | prefilter pass rate (6 %) |
| bucket, upload, host, other, copy | 2.15 | 0.76 | per slice, per batch | 1e17 fields, 11 slices |

## 3. Amdahl table: G2 (central unit costs; fs per admissible n)

| stage | b62 (4,10) | b64 (4,10) | count per adm [M unless noted] | unit cost [D/G] |
|---|---|---|---|---|
| 64-wide tests (kept incidences) | 0.53 | 0.34 | 3.5e-5 / 2.7e-5 (pairs 3.9e-3 / 3.5e-3; flat 6.1e-5 / 5.5e-5) | b62 15.5 slice lookups × 0.7 ps + 4 ps; b64 8 + 2048/464 lookups × 0.7 + 4 |
| chunk-common tests | 0.06 | 0.06 | 6.1e-5 / 5.5e-5 | 1 ps |
| bottom children | 0.17 | 0.02 | 1.7e-4 / 1.7e-5 [D] | 1 ps (0.3–5) |
| bottom chunking | 0.34 | 0.03 | 8.1e-5 / 7.5e-6 bottoms | 4 ps + 15 ps sort ÷ b |
| tops | 0.08 | 0.02 | 4.4e-7 / 9.2e-8 tested [D] | 0.17 ns (today's FD) |
| survivors + checks | 0.07 | 0.05 | 3.3e-6 / 2.6e-6 | 17 ps + 6 % × 58 ps |
| other (launch, host) | 0.06 | 0.03 | | 5 % [G] |
| **total** | **1.31** | **0.54** | | **×10.1 / ×8.3** |

## 4. Where the ceiling is, and why (so nobody re-walks it)

1. **Pairs are forced.** In any keyed prefix–suffix join every n whose top and bottom
   certificates are both valid is one tested pair: pairs/adm = P_T(f0)·P_B(k) (measured within
   10 % of the digit model). A pair *tree* does not beat it: in the overlap regime a parent pair
   has exactly one child pair (the shared digit is forced), and outside it the pair-nodes at
   a + c = L − 1 already cost ≈ A·P(2L − 2 − fuzz) ≈ 6e-3–1.4e-2 per adm, today's count
   (NOTES §1).
2. **The affordable shapes are pinned.** Tops at f0 ≤ 3 cost ≥ 2.7 fs (b62) / 0.6 fs (b64) per
   adm even once per base; bottoms at k ≥ 11 cost ≥ 5.2e-3 (b62) / 5.4e-4 (b64) child
   generations per adm plus the chunking of 2.4e-3 / 2.4e-4 stored bottoms. So pairs ≥ 3.9e-3
   (b62) and 3.5e-3 (b64). **At b64 that is exactly today's pruned pair count: G2 does not test
   fewer pairs than today there; it makes each pair ≈ ×6–8 cheaper all-in** (1.29 ps today vs
   0.15 ps).
3. **Group tests remove about half.** A 64-chunk of masks with 16–20 of 62–64 digits shares at
   most 3–4 digits (groups of 10^3–10^4 hold ≥ 64 members containing a given s-set only for
   s ≤ 3–4). Measured kept fractions: 0.45–0.58 with probe-weighted ordering, 0.57–0.77 without,
   1.0 for 24-top groups; narrower chunks (16–32) keep 0.39–0.52 at more overhead per word. Hierarchical descent (trie internal nodes) visits 1.0–2.0× the flat
   chunk count: it never pays.
4. **A 64-pair word costs ≥ 8 LDS lookups** (≈ 4–6 ps chip-wide on the 3080 class) with
   four-Russians tables, or popcount(probe) ≈ 16 lookups bit-sliced. Hence the AND-only floor:
   0.27 fs (b62) / 0.20 fs (b64) at optimistic costs, a ceiling of ×50 / ×23 for the AND alone;
   with the bottom and survivor terms the structure's optimistic edge is ×18 / ×13.
5. **What would have to break for ×20 or more**: a group test that removes ≥ 90 % of 64-pair
   words (needs ≥ 6 common digits per chunk: impossible at these densities), bottom children
   at k 11 for ≲ 0.05 ps each (one instruction), or a predicate on the middle digits outside both
   views (the BX line). Also tried and rejected: tree descent over chunks, bottom-driven pairing
   at k 10 (24-top groups: one full word per bottom), four-Russians tables per bottom chunk when
   < ~300 probes share it, k 11 in either orientation, f0 5 (tops free but 6.3e-3 pairs), chunk
   prune by leading-digit order alone (κ 0.85–0.89: a 64-chunk spans 1/23 of the base's leading
   range where a field fixes 3.5 digits).

## 5. Evidence: measured, derived, guessed

**Measured on ivory** (prototype `proto/`, binary `g2proto.bin`, logs in `raw/`):
- Exactness: 14 whole-base runs at b10–b28 equal brute force (69 found at b10); on real b62 and
  b64 units the G2 shape and a reimplementation of today's (3, 6) shape agree on every n
  satisfying both predicates (two b62 k10 units both directions, 1.62 M members at b62 k9 and two
  b64 k10 units streamed; 0 lost); the CPU pipeline (affine children, sorted chunks, common-mask
  skip, slice and four-Russians probes) reproduces the scalar join's survivors exactly on all runs.
- The reference reimplementation's survivors per adm = production's base mean at b62 (2.52e-4 vs
  2.5e-4; b64 1.92e-4 vs 1.5e-4).
- All G2 counts per adm in §3 (pairs, flat and kept chunk incidences in four orderings,
  bottoms, survivors), P_T per base and f0, on 3 units per (base, shape) at k 10, 1–2 at k 9;
  spread between units < 6 %.
- CPU costs (one EPYC-Rome thread): pairing 0.11 ns/pair four-Russians bottom-driven at b62 k9
  (scalar 0.27, sliced 0.30); top-driven probes 1.1–1.5e-12 s per admissible n at b62/b64 k10
  (today's whole CPU join: 1.42e-11 / 6.1e-12); top-driven four-Russians 16–19 ns per kept
  incidence + 6.7 µs per table on CPU (sliced 26–37 ns: tables do not pay on the CPU).

**Derived**: every GPU unit cost (§6), the shared-tree visit counts (digit model, checked
against the per-unit DFS), today's base mean (field ÷ survivor ratio), the work-unit table.
**Guessed**: "other" overhead 3–10 %, the bottom chunk/sort costs on a GPU.

## 6. The three numbers that decide it (measure these next)

1. Cost of a 64-pair test on the card, top-driven tile (chunk slices or tables in shared
   memory, tops streamed): model 9.6–15 ps central. If ≥ 20 ps, b64 drops to ≈ ×6.
2. Per-bottom cost of child generation + transposition into chunks (b62 is sensitive: 0.51 of
   1.31 fs): model 1 + 4 ps. At today's bucket-kernel cost (5 ps per child) b62 (4,10) falls to
   ×6.7 and the (4,9) shape (bottoms negligible) becomes the b62 choice at ×10.0 (×6.7–14.9).
3. Today's b64 base-mean cost (4.5–5.4 fs per admissible n): a whole-base sample of field
   times on the current main.

A GPU tile microbenchmark on one real b62 and one b64 super-unit (CUDA, u64 slices; counts
already known from this prototype) settles 1 and 2 in under a day. Kill if 1 > 20 ps or 2 > 10 ps.

## 7. What the server's work unit would have to be

- **Needed:** units keyed by the shared middle digits: "base b, shape (4, 10), super-units
  π′ ∈ [p0, p1)" in a fixed enumeration of digits 4–8, each covering every leading and low
  digit. Not an interval of n (a virtual coordinate v(n) that orders n by π′ first would let the
  server keep ranges). Size: 1e6 super-units ≈ 7 min (b62) / 40 min (b64) on a 3080-class card;
  ≈ 900 / 1,100 units per base. A whole base: ≈ 110 card-hours at b62 (today ≈ 1,150) and
  ≈ 720 at b64 (today ≈ 6,000–7,200).
- **What changes server-side:** a unit table and claim/submit path for π′-ranges with its own
  consensus/verification (a second implementation can verify any unit exactly, as the prototype's
  cross-check does), progress shown as π′ coverage, a client mode. **Mid-base switch at b62 is
  clean:** a unit simply drops tops whose interval lies in fields already searched (exact; the
  bottoms, which are cheap, are unchanged).
- **Without the change:** contiguous units must be ≥ 1/10 of the base (≈ 1e21 n, ~10,000 of
  today's fields) to keep ×6 at b62, and the whole base at b64 (×6.3; ×3.5 at 1/10)
  (`raw/model2_workunit.txt`, computed for the unsorted variants). With today's 1e17 fields the bottoms would be rebuilt 95,000
  times per base and G2's shape is dead; only the four-Russians test transfers into today's
  shape (12-digit bottoms: 8 lookups instead of 12 on the 12 % AND share), ≈ ×1.05.

## Files

`NOTES.md` (living notes, §1 the first-principles accounting, §3–6 the measurements),
`model.py` (uniform-digit count model, b58–64, `raw/model_out.txt`), `model2.py` (GPU cost
model from measured counts, `raw/model2_out.txt`, `raw/model2_workunit.txt`), `proto/` (crate:
`arith.rs`, `join.rs`, `andv.rs`, `pipe.rs`, `main.rs`), `g2proto.bin`, `raw/*.txt` (every run).
