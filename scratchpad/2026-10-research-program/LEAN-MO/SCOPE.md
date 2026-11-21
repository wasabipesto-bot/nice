# Scope: a machine-checked proof that the middle-out join misses no nice number

*2026-11-21, written on ivory by reading only (no Lean build, no code change). Sources: `dev/mo-clean` at `10ddbf17`
(worktree `~/projects/nice/.worktrees/midout-clean`, paths below relative to `common/src/midout/`), the design
`scratchpad/2026-11-midout-design/DESIGN.md`, and upstream draft PR #160 (branch `lean-proofs` on the fork, head
`4cdaa47f`, read in a temporary worktree since removed; Lean paths below are relative to `proofs/`). Lean names
are `NiceSearch.*` with file:line. **[read]** = checked in the code or proof text; **[judged]** = my estimate.*

## 1. What a proof would give, in one paragraph

The join's predicate itself (what tops and bottoms certify, the classes, the prefilter) is covered only by the CPU
reference against brute force on bases 10–25, where nice numbers are nearly absent (DESIGN §4 "What nothing
catches"). A proof closes that hole, and it is real: mutant M04 (`mhi` takes position k+1) drops nice numbers yet
passed the first suite, because base 10, the one small base with a nice number, has the prefilter exempt
(`G2/PR12-REVIEW.md:115,143`). A Lean theorem would show that **the algorithm**, as a Lean function mirroring
`cpu.rs`, returns every nice number of a field, for every base and coordinate meeting stated hypotheses; **not**
that the Rust, the kernels or a run on a card are correct (§5).

## 2. The theorem

**Notation.** `digit b x j = x / b^j % b` (`Spec/Digits.lean:18`), `IsNice b n` = the digits of n² then n³ permute
`0..b−1` (`Spec/Nice.lean:71`), `[lo, hi) = baseRange b` (`Spec/Range.lean:164`, the Rust closed form). A
coordinate `(k0, k1, q0)` with `k0 ≤ q0 < k1 ≤ L` (L = digits of `hi − 1`), `h0 = lo / b^k1`,
`H = (hi−1)/b^k1 − h0 + 1`, and `v(n) = lo + key·H·b^k0 + (h − h0)·b^k0 + n mod b^k0` with `h = n / b^k1`,
`key = n / b^k0 mod b^(k1−k0)` (`coord.rs:239–249`). Quantum `Q = H·b^q0` (`coord.rs:274`). A field `[vs, vs+vz)`
of whole quanta (`coord.rs:283–301`). Shape `(f0, k)` with `f0 ≤ q0`, `k1 < k ≤ L` (`Shape::fits`, `cpu.rs:90–101`).

**Statement (END-MO).** For every b ≥ 3 with a range, every such coordinate, shape and field, and every n:
`IsNice b n ∧ vs ≤ v(n) < vs + vz  ⟹  n ∈ searchField b coord shape vs vz`, and conversely every member of
`searchField` is nice and has `v(n)` in the field. (Optional, stronger, §3 L11: the survivor set of each slice is
exactly the brute-force predicate `q_shape`, `cpu.rs:877–893`, as the Rust tests assert at `cpu.rs:1082`.)

**Proposed Lean signatures** (not compiled; `Coord`, `Shape` are plain structures of naturals):

```lean
def Coord.vOfN (c : Coord) (n : ℕ) : ℕ := c.lo + n % c.b^c.k1 / c.b^c.k0 * (c.H * c.b^c.k0)
    + (n / c.b^c.k1 - c.h0) * c.b^c.k0 + n % c.b^c.k0
def Coord.fieldDigits (c : Coord) (vs vz : ℕ) : List ℕ := List.range' ((vs - c.lo) / c.Q) (vz / c.Q)
def slicesOf (b f0 k q0 k1 t : ℕ) : List ℕ;  def unitTops (b lo hi f0 k u : ℕ) : List Top  -- cpu.rs:105, :457
def parents (b f0 k pip : ℕ) : List (ℕ × Finset ℕ) := botDfs b f0 (k-1-f0) pip (k-1) 0 0 ∅
def childMask (b k : ℕ) (p : ℕ × Finset ℕ) (d : ℕ) : Option (Finset ℕ)   -- cpu.rs:536–544
def sliceJoin (b lo hi f0 k pip : ℕ) : List (ℕ × Finset ℕ)   -- survivors n with their top's mhi
def midPrefilter (b k n : ℕ) (mhi : Finset ℕ) : Bool          -- cpu.rs:232–257
def searchField (c : Coord) (sh : Shape) (vs vz : ℕ) : List ℕ :=
  (c.fieldDigits vs vz).flatMap fun t => (slicesOf c.b sh.f0 sh.k c.q0 c.k1 t).flatMap fun pip =>
    ((sliceJoin c.b c.lo c.hi sh.f0 sh.k pip).filter fun s => midPrefilter c.b sh.k s.1 s.2
      && decide (IsNice c.b s.1)).map Prod.fst

theorem searchField_complete {c : Coord} {sh : Shape} {vs vz n : ℕ} (hc : c.Valid)
    (hr : baseRange c.b = some (c.lo, c.hi)) (hfit : sh.Fits c) (hq : c.Q ∣ vs - c.lo) (hq' : c.Q ∣ vz)
    (hin : c.lo ≤ vs ∧ vs + vz ≤ c.vEnd) (h : IsNice c.b n) (hv : vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz) :
    n ∈ searchField c sh vs vz
theorem searchField_sound ... (hm : n ∈ searchField c sh vs vz) :
    IsNice c.b n ∧ vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz
```

## 3. The lemmas, what #160 already proves, and what is new

Each: statement; generic or base-64; edge cases in the code; reuse.

**L1 Coordinate and coverage.** (a) For `lo ≤ n < hi`: `(v(n) − lo) / Q = n / b^q0 mod b^(k1−q0)` (the field
fixes digits `[q0, k1)`). (b) Whole quanta: `vs ≤ v(n) < vs+vz ⟺ t0 ≤ that value < t1` with `t0, t1` from
`field_digits`. (c) `pip ∈ slicesOf t ⟺ pip < b^(k−1−f0) ∧ pip / b^(q0−f0) mod b^(k1−q0) = t`, no duplicates; so a
field is a whole number of slices and distinct fields share none. (d) Partition: quanta are disjoint and cover.
Generic. Edges: padding at bases whose range is not a multiple of `b^k1` (`n_of_v` returns `None`,
`coord.rs:256–269`; irrelevant to completeness, which goes n → v); `n_count` (`coord.rs:307–329`) is a count, not
needed. Bijection of v (`n_of_v ∘ v_of_n = id`) only for the partition claim. **Reuse: none.** #160's fields are
intervals (`Model/Fields.lean:16–36`, `inField_iff`); its END-2 assumes the field is `[s, e)` sliced into
intervals (`joinField_complete`, `Model/Join.lean:747`, hypothesis `hsl`). New: ~150–250 lines [judged].

**L2 Range and lengths.** Every nice n is in `[lo, hi)`, and both powers have ≥ k + 2 digits when needed. Reuse:
`memBaseRange_of_inBaseRange` (`Spec/Range.lean:183`), `inBaseRange_of_isNice` (:21), `numDigits_sq_cu` (:39).
New: "all n of the range have the same digit count", so `k ≤ L` gives `k ≤ numDigits (n²)` (~30–50 lines). This is
the side condition class that caused v3.2.14's prefilter failure (`CLAIMS.md` row GPU-8).

**L3 Residue classes.** `n mod (b−1) ∈ roots b`. Reuse unchanged: `joinRoots` (`Model/Join.lean:450`) is `roots`
(`arith.rs:119–126`); `mem_joinRoots_of_isNice` (:453), via `mem_residueFilter_of_isNice` (`Model/Residue.lean:46`).

**L4 Top certificate.** For `[a, c] ∋ n`, the digits of a², a³ at positions ≥ k common with c², c³ from the top
down are digits of n², n³ at those positions; a repeat rules the interval out; `mhi` (positions ≥ k+2) is a subset.
"Certified" means equal quotients `a^j / b^i = c^j / b^i` (a carry can never break it, by monotonicity), not equal
single digits. Reuse unchanged: `certPositions`, `cert` (`Model/Join.lean:50,60`), `certPositions_digit` (:69),
`highDigit_of_cert` (:130), `not_isNice_of_cert_none` (:149), `exists_cert_of_isNice` (:180). New: (i) the Rust
scan (`top_cert_split`, `cpu.rs:181–216`, which skips a power whose length differs, :196–198) equals `cert`:
unequal lengths certify no position (~30 lines); (ii) `mhi = cert at cap k+2` and its positions are ≥ k+2
(~30 lines); (iii) `unitTops` lists every nice n's top `(n / b^k, unit n / b^f0 mod b^(k−f0))` with its clipped
interval (template `mem_topLayer_of_isNice`, :215, but simpler: no ancestor layer). Generic. Edges: tops clipped
by the range (`cpu.rs:465–469`, `a > c` skipped) and the survivor's interval test (`cpu.rs:856`); at base 64 none
is clipped, since 2^75 and 2^76 are multiples of 64^4 [read: arithmetic]. Base-64-only and optional: MAXPOP 17
(`gpu.rs:147`), provable from `certFloor_le` (:92), needed only for the device's 17-digit layout.

**L5 Bottoms: parents and children.** (a) A slice's parents are the depth-(k−1) residues with digits
`[f0, k−1) = pip` whose 2(k−1) low output digits are distinct; every nice n's `n mod b^(k−1)` is one, with mask
`lowSet b n (k−1)`. (b) The child at unit d: digit k−1 of the child's square and cube is
`(c2 + 2(r mod b)·d) mod b` and `(c3 + 3(r mod b)²·d) mod b` (`parents_threads`, `cpu.rs:521–525`;
`child_mask`, :536–544), true for k ≥ 2 because `d²·b^(2k−2)` vanishes mod b^k. Reuse: (a) is
`mem_botDfs_of_isNice` (:332) with `pp = k−1−f0`, `v = pip`, fuel k−1 from j = 0 (the Rust walk `bot_children`,
`cpu.rs:355–404`, forces exactly digits `[f, k)`); (b) is one step of the same DFS, `botDigits_eq` (:260), itself
AFF-1 `affine_mid_digit` (`Model/Affine.lean:50`). New: the parent/child split and the record `(c2, c3, a2, a3)`
(~60–120 lines). If the model mirrors the Rust's incremental `r², r³ mod b^k` (`cpu.rs:386–392`), one more
binomial-expansion lemma (~60 lines); otherwise that stays a fixture item. Generic (k ≥ 2 follows from fits).

**L6 Class compatibility.** With `n = h·b^k + d·b^(k−1) + r`: `n ≡ h + d + r (mod b−1)`; the probes of (class c,
unit d) are the tops of class `(rt − (c+d)) mod (b−1)` over roots rt (`cpu.rs:794–799`, tops bucketed by
`h mod (b−1)`, :760–765); so a nice n's top is probed against its child's class exactly once (roots are distinct).
Reuse: `class_eq` (:492) for the congruence. New: the probe-set identity (~40–80 lines). Generic.

**L7 Pairing.** A nice n's top mask and child mask are disjoint (positions ≥ k against < k). Reuse unchanged:
`disjoint_high_lowSet` (:394). New, only if the model keeps the Rust's structure: the bit-sliced word (`cpu.rs:
826–849`): bit i of `¬(OR over the top's digits v of sl[v]) & valid` is set ⟺ child i is disjoint from the top;
the chunk skip (`common & mask ≠ 0`, :839) implies a zero word; the partial-chunk mask (:826). ~100–200 lines on
`Nat.testBit`/`BitVec 64` [judged]. The chunk order and the key (`key_digits`, :554) change only counts.

**L8 Prefilter.** For nice n: digits k, k+1 of n², n³ are four distinct digits missing the 2k low ones and `mhi`
(`cpu.rs:232–257`). Exemption: `n < b^⌈(k+2)/2⌉` passes unconditionally (:236–239) because n² may then lack a
digit at k+1 and zero padding would reject a nice number; above it, n² ≥ b^(k+2), so the digits are real. The
exemption is reached only at small bases (bases 10–14 entirely, `cpu.rs:1118–1120`), and mutant M21 (changing its
threshold) survives every test (`PR12-REVIEW.md:133`): the proof is the only check it would get. Reuse:
`suffixDigits`, `lowDigits`, `mem_lsdBitmap_of_isNice` (`Model/Lsd.lean:47,50,78`) for distinctness at depth k+2,
`digit_ne_of_isNice` (`Model/Affine.lean:101`) for `mhi`. #160's `prefilterAt` (:663) does not carry over: it uses
a floor rule (`prefilterFloor`, :651) where this one separates positions by construction. New ~60–120 lines.

**L9 Final check.** `unique_digits n b = (_, true) ⟺ IsNice b n` (`arith.rs:92–111`). Reuse
`numUniques_eq_iff_isNice` (`Model/Detailed.lean:14`); new: the total-count half (~30–50 lines). It is the
definition, so `searchField_sound` is a few lines, as `joinField_sound` (:771) is.

**L10 Composition.** END-MO from L1–L9: template `mem_joinPartition_of_isNice` (:516, ~80 lines) and
`joinField_complete` (:747). New ~80–150 lines.

**L11 (optional) Exactness of survivors.** Each slice's survivors = `{n of the slice : q_shape n}`, each once:
the converse of L4–L7 plus no duplicates (distinct roots, distinct parents). It is what makes the device's
`survivors`/`checked` counts meaningful as exact (DESIGN §2 stage 7). +200–400 lines [judged].

**The mismatch with #160's overlap join, concretely.** Its join (`Model/Join.lean:1–30`) takes an `L`-digit
interval `[s, e)` and parameters `(t, k, p)`; tops come from a breadth-first ancestor layer `topLayer` (:202), the
low part is `n mod b^f0`, a partition fixes the lowest `p` shared digits and a key the rest. Production uses
f0 = 3, k = 6 at base 64 (DESIGN §1). The middle-out shape at base 64 is f0 = 4, k = 10 (t = 9, overlap 6), and a
slice (digits 4–8) is exactly #160's partition value with p = 5, the unit (digit 9) its key: inside its parameter
family (`hpp : pp ≤ t+k−L`, :516). So per slice the proof is JOIN-5's argument again, but END-2 itself cannot be
reused: fields here are digit sets, not intervals; tops are certified directly (no ancestor pruning, `unit_tops`);
bottoms split at k−1 into parent and child, not at f0; the prefilter differs (L8). **Estimate of coverage:**
about 40–50 % of the proof text needed already exists (L3, L4 core, L5 core, L7, the digit/LSD/range basis)
[judged from the line counts above]; the field structure (L1), the tops' and bottoms' new shape, the prefilter,
the chunk refinement and the composition are new.

## 4. Base-generic versus base-64

Everything in L1–L11 is base-generic (b ≥ 3 with a range, any coordinate and fitting shape): the CPU reference
is generic (3–128, `cpu.rs:1–5`) and the Lean model would be too, so one theorem covers base 64 at (4, 8, 5) with
(4, 10) (`Shape::for_coord`'s special case, `cpu.rs:76–77`), the older (4, 9, 6), and bases 65–70. Base-64-only
facts belong to the device layer and are optional: no clipping, MAXPOP 17, v as a bit permutation
(`coord.rs:20–29`). Edge cases the Lean model does **not** see and that stay with the Rust's tests:

- **Mask width.** A `Finset` has no width; the Rust needs `b ≤ M::BITS` (`mask.rs:147–186`), checked only in
  `search_field` (`cpu.rs:944–948`), not in the public `slice_join`. Above 64 the device is a different program
  (`gpu_wide.rs`) with its own check kernel, unaudited (DESIGN §6.9).
- **Wide arithmetic.** `U384` asserts on overflow (`arith.rs:47–50`); `mm` needs `m < 2^96` (`cpu.rs:155–167`,
  asserts :234, :294); its large-modulus branch runs only from about base 41, so at base 64 one random test
  (`cpu.rs:1346`) and the device's agreement check it (AUDIT-MO §8.3). Optional: `mm`'s split equals `a·c mod m`,
  in the style of `truncated_mul_mod` (`Model/GpuArith.lean:278`), ~40–60 lines.
- **The job split** (over 576 probes as a second instance, `PMAX`, `gpu.rs:138`; over 1,152 an error) is
  device-only; the CPU reference has no window. The probe account (`A_PROBES = 8 × tops`) covers it, no theorem.

## 5. The gap between the theorem and the running code

The theorem is about a Lean function. Between it and a base-64 result stand: (1) the Rust CPU reference
(`cpu.rs`, `arith.rs`, `coord.rs`: u128 and U384 arithmetic, sorting, threads); (2) the CubeCL kernels (32- and
24-bit limbs, `cert_pow` `gpu.rs:1879`, `pf`/`pf24`, transposes, shared parent lists, the `tops5` hierarchy, the
job split) and the narrow/wide split; (3) production's check kernel, which on the device replaces `unique_digits`
(DESIGN §2 stage 5); (4) drivers, the coordinator's bookkeeping (every quantum handed out and submitted), compilers
and hardware. None is covered by the proof.

**The strongest affordable link** [judged]: (a) the Lean model written to be extensionally the Rust reference
(same lists in the same order where order is cheap to keep), and (b) a fixture bridge as #160 has
(`scripts/lean_fixtures.rs` emits tables, `Conformance.lean` diffs them, CI job `lake build --wfail`,
`lake exe conformance`, `check_claims.py`; `.github/workflows/lean.yml`): every survivor, in order, of every slice
of the small bases the Rust tests already run (`check_whole_base`, `cpu.rs:1047`), plus base-64 pieces (top
certificates on sampled prefixes, parents and child masks under sampled slices, prefilter verdicts on random n,
v of sampled n); (c) unchanged, the device-against-CPU sampled slice per field (DESIGN §4). Optional (d): run the
compiled Lean model on a few real base-64 slices and compare n for n with `cpu.rs`. A base-64 slice has ~250M
(probe, chunk) incidences (DESIGN §2 stage 3), so (d) needs the chunked model (L7) and bitmask `Nat` masks, not
`Finset`; J2's measurements found `Nat.lor`/`testBit` fast in Lean (`2026-09-external-repos/README.md:168–186`).
Its run time per slice I cannot determine without a build.

**What the project could then say:** "The middle-out join's algorithm is proved in Lean to return every nice number
of a field, for every base and coordinate meeting the stated hypotheses; the CPU reference agrees with the Lean
model on the published fixtures; the device agreed with the CPU reference, n for n, on a sampled slice of every
field." **Not:** that the base-64 search is formally verified, that base 64's non-existence is machine-checked, or
that the device's output is proved; the sampled check's `1 − (1 − f)^k` (DESIGN §4) is unchanged by the proof.

## 6. Size and plan

**Basis** [read]: #160's overlap join, JOIN-1..6 and END-2, is one commit `ee2cfd19` (dated 2026-10-09): 800 lines
in `Model/Join.lean` (33 theorems), 76 lines of conformance, 112 lines of the fixture generator, 7 registry rows,
on a library of ~4,950 Lean lines with 68 rows proved (`README.md` status table). The proofs use `omega`,
`Nat.ModEq`, list membership; no heavy Mathlib.

**Estimate** [judged]: completeness + soundness (L1–L10) **550–1,000 new Lean lines, 35–55 theorems**, if #160's
library is imported; **+700–1,000** lines if it must be re-created (option A below: the needed subset is
`Spec/*`, `Model/Lsd`, `Residue`, the `outIndex` lemmas from `Model/Msd.lean:116`, `Affine`, `HighDigit` of
`Model/Cross.lean:41`, JOIN-1..3, `Detailed`). Link: Lean conformance 100–150 lines, Rust fixture generator
150–250. Optional: L11 +200–400, chunk refinement for (d) +100–200, `mm` +40–60. Effort: I cannot determine the
hours #160 took (commit dates only); I judge 3–6 working sessions of assisted proof work for L1–L10 plus the link,
on a machine that can build Mathlib.

**Order, each step checked on its own** (sorry-free under `lake build --wfail`, axioms checked by
`check_claims.py`, and a fixture diff against the Rust before the proof is attempted):

1. Environment; model functions only, diffed against small-base fixtures (catches model ≠ code first).
2. L1 (coordinate, slices; fixture: v of sampled n, slice lists). 3. L2, L3, L9 (mostly reuse).
4. L4, L5 (fixtures: certificates, parent lists). 5. L6, L7 (abstract pairing), L8.
6. L10: END-MO complete and sound; registry rows, `Lean:` tags in `midout/*.rs`. 7. Optional: L7's chunk
   refinement and (d), L11, the `mm` lemma.

**Build environment** [read]: Lean `v4.33.1` and Mathlib tag `v4.33.1` (rev `0df444a3`) are pinned
(`lean-toolchain`, `lakefile.toml`, `lake-manifest.json`); Mathlib's cache is ~6 GB (`README.md`, Building). This
machine has 4.5 GB free (`df`, 2026-11-21) and already holds the toolchain (`~/.elan`, 2.9 GB), so it cannot
build. #160's Lean job passes on a GitHub runner (8 min 8 s, `gh pr checks 160`); the workflow runs on pushes and
PRs to `main` or by manual dispatch (`lean.yml:3–16`). Otherwise a box with ≥ ~15 GB free [judged].

## 7. Risks

1. **The model does not match the code** (main risk). The proof is only as good as the claim that the Lean function
   is what `cpu.rs` computes. Mitigation: model first, fixtures before proofs, order-preserving lists. Residual:
   fixtures sample; small bases do not exercise the large-modulus arithmetic. The tension: a proof wants the
   abstract pairing, a base-64 run needs the chunked one; two models joined by L7's refinement.
2. **384-bit arithmetic.** Free in the proof (Lean ℕ); all of it sits in the link (U384, `mm`, u128 bounds, the
   device's limbs): tests and fixtures, optionally small lemmas, never END-MO.
3. **Wide-mask bases.** The theorem covers bases 65–70 of the algorithm for free, but the wide device path and its
   check kernel are separate and unaudited: claims above 64 would be weaker than at 64.
4. **A moving target** (head changed 2026-11-20): each `cpu.rs` change needs fixtures regenerated; tags make
   drift loud. 5. **Effort** is in L1's digit-block arithmetic and L7's bits; no new mathematics [judged].

## 8. Where it could live (for the maintainer)

- **A. Separate directory or repository, depending on nothing in #160** (e.g. `proofs-midout/` on the middle-out
  branch, or its own repository), its own namespace (e.g. `NiceMidOut`) so it can later sit beside `NiceSearch`
  (#160 renamed its root to avoid exactly such a clash, `README.md` Layout). For: reviewable with the middle-out
  PR series, no dependence on a parked PR. Against: re-creates ~700–1,000 lines of #160 (definitions drift; two
  Mathlib pins; a later merge must reconcile `IsNice`, `cert`, `botDfs`). Variant A′: `require` #160's library
  pinned to `4cdaa47f`: reuse without touching #160, but it depends on an unmerged fork commit a force-push could
  orphan.
- **B. An extension of #160 on its own branch** (`Nice/Model/MidOut.lean`, `Nice/Model/Coord.lean`, registry rows,
  fixtures). Most reuse, one registry and CI. Against: stacked on a draft the maintainer parked; the claims checker
  and the fixture generator need the middle-out Rust, which #160's base (`9a4f7406`) does not have, so the branch
  would have to merge `dev/mo-clean` as well; every rebase of either cascades.
- **C. Nothing until asked.** Costs nothing; the hole of §1 stays covered by small-base brute force only.

## 9. What I could not determine

How long #160's proofs took (commit dates only), so the effort is judged; whether a compiled Lean model runs a
base-64 slice in minutes or hours (needs a build); whether the fork's Actions would run `lean.yml` by dispatch (not
tried: no pushes). Nothing was denied by the tooling. The worktree `~/projects/nice/.worktrees/lean-read` (at
`4cdaa47f`) was removed; no other file was written.
