/-
The middle-out join's CPU reference, `common/src/midout/cpu.rs` and
`common/src/midout/arith.rs`, as Lean functions. Masks are `Finset ℕ` (the
Rust's `u64`/`u128` words, one bit per digit); the Rust's `u128`/`U384`
arithmetic and `mm` are exact ℕ arithmetic here.

Two forms of the join of one slice:
- `sliceSurvivors`: the definition the theorems are to be about. For each
  class `c`, unit digit `d`, probed top and certified child (parents in
  ascending `r`), the survivors `(d, n, mhi)`.
- `sliceRun`: the Rust's `SliceSetup::new` + `class` as functions (no loop state): parents
  reordered by class and chunk key, 64-child chunks with the common-mask
  skip, and every counter of `Counts`. Its survivors are the Rust's, in the
  Rust's order. Proved in `RunProofs`: its survivors are a permutation of
  `sliceSurvivors`'s (with `mhi` replaced by the prefilter's verdict), and its
  counters `survivors`, `checked` and `parents` are the list's length, the
  passing survivors and the parents; the other counters are tested only.

Reused from the earlier library (`NiceSearch`, commit 4cdaa47f): `digit`,
`numDigits`, `IsNice` (the final check), `cert` / `certDigits` (the top
certificate), `botDfs` / `botDigits` (the bottoms' walk), `joinRoots` (the
residue roots).
-/
import NiceMidOut.Coord

namespace NiceMidOut

open NiceSearch

/-! ### Residue roots and the final check -/

/-- `arith::roots` (`arith.rs:119`) is the earlier library's `joinRoots`. -/
abbrev roots (b : ℕ) : List ℕ := joinRoots b

/-- `unique_digits(n, b)` (`arith.rs:92`): the number of distinct digits of
`n²` and `n³` together, and whether both that number and the total number of
digits are `b`. (The Rust expands a `U384`; the model reads `Nat.digits`.) -/
def uniqueDigits (b n : ℕ) : ℕ × Bool :=
  ((outputDigits b n).toFinset.card,
    decide ((outputDigits b n).toFinset.card = b ∧ (outputDigits b n).length = b))

/-- The final check, `unique_digits(n, b).1` (`arith.rs:92`, `cpu.rs:999`):
the mirror's verdict. That it is `IsNice` is a theorem (`finalCheck_iff`). -/
def finalCheck (b n : ℕ) : Bool := (uniqueDigits b n).2

/-! ### Tops -/

/-- `top_cert_split` (`cpu.rs:181`): the certificate of `[a, c]` at
positions `≥ kpos` (the earlier library's `cert`) and its part at positions
`≥ kmid` (the certified positions are upward closed, so this is
`certDigits` at cap `kmid`). -/
def topCertSplit (b a c kpos kmid : ℕ) : Option (Finset ℕ × Finset ℕ) :=
  (cert b a c kpos).map fun m => (m, (certDigits b a c kmid).toFinset)

/-- A certified top of one unit (`Top`, `cpu.rs:445`). -/
structure Top where
  h : ℕ
  mask : Finset ℕ
  mhi : Finset ℕ
  lo : ℕ
  hi : ℕ
  deriving DecidableEq

/-- The prefixes `unit_tops` tests: `(lead, a, c)` with `[a, c]` the
prefix's interval clipped to the range, empty ones dropped
(`cpu.rs:460–470`). -/
def unitLeads (b lo hi f0 k u : ℕ) : List (ℕ × ℕ × ℕ) :=
  let leadLo := lo / b ^ k
  let leadHi := (hi - 1) / b ^ k
  (List.range' leadLo (leadHi + 1 - leadLo)).filterMap fun lead =>
    let p := lead * b ^ (k - f0) + u
    let a := max (p * b ^ f0) lo
    let c := min (p * b ^ f0 + b ^ f0 - 1) (hi - 1)
    if a ≤ c then some (lead, a, c) else none

/-- `unit_tops` (`cpu.rs:457`): the certified tops of unit `u` (digits
`[f0, k)` of `n`), leads ascending; `tops_tested` is `(unitLeads ..).length`. -/
def unitTops (b lo hi f0 k u : ℕ) : List Top :=
  (unitLeads b lo hi f0 k u).filterMap fun x =>
    (topCertSplit b x.2.1 x.2.2 k (k + 2)).map fun m => ⟨x.1, m.1, m.2, x.2.1, x.2.2⟩

/-! ### Bottoms: parents and children -/

/-- `bot_cert_direct` (`cpu.rs:261`): the low `j` digits of `r²` then of
`r³`, if all distinct. -/
def botCertDirect (b r j : ℕ) : Option (Finset ℕ) :=
  let ds := (List.range j).map (digit b (r ^ 2)) ++ (List.range j).map (digit b (r ^ 3))
  if ds.Nodup then some ds.toFinset else none

/-- `bottoms(base, k, f, forced)` (`cpu.rs:292`) as the earlier library's
`botDfs`: depth `k`, digits `[f, k)` forced to `forced`, sorted by `r` (the
Rust's walk order differs; `parents` sorts). -/
def bottomsSorted (b k f forced : ℕ) : List (ℕ × Finset ℕ) :=
  (botDfs b f (k - f) forced k 0 0 ∅).mergeSort fun x y => x.1 ≤ y.1

/-- A parent of the slice (`Parent`, `cpu.rs:488`). -/
structure Parent where
  r : ℕ
  mask : Finset ℕ
  c2 : ℕ
  c3 : ℕ
  a2 : ℕ
  a3 : ℕ
  cls : ℕ
  deriving DecidableEq

/-- The record `parents_threads` builds from a depth-`(k − 1)` bottom
(`cpu.rs:513–527`): digit `k − 1` of `r²` and `r³`, the affine
coefficients of the child digit, the class mod `b − 1`. -/
def mkParent (b k : ℕ) (q : ℕ × Finset ℕ) : Parent :=
  ⟨q.1, q.2, digit b (q.1 ^ 2) (k - 1), digit b (q.1 ^ 3) (k - 1), 2 * (q.1 % b) % b,
    3 * (q.1 % b) * (q.1 % b) % b, q.1 % (b - 1)⟩

/-- `parents` (`cpu.rs:500`): the slice's parents, `r` ascending. -/
def parents (b : ℕ) (sh : Shape) (pip : ℕ) : List Parent :=
  (bottomsSorted b (sh.k - 1) sh.f0 pip).map (mkParent b sh.k)

/-- `child_mask` (`cpu.rs:536`): the child of `p` at unit digit `d`; `none`
where the Rust returns the empty mask (a certified child's mask is never
empty). -/
def childMask (b : ℕ) (p : Parent) (d : ℕ) : Option (Finset ℕ) :=
  let e2 := (p.c2 + p.a2 * d) % b
  let e3 := (p.c3 + p.a3 * d) % b
  if e2 = e3 ∨ e2 ∈ p.mask ∨ e3 ∈ p.mask then none else some (insert e3 (insert e2 p.mask))

/-! ### The prefilter -/

/-- `prefilter` (`cpu.rs:232`): exempt below `b^⌈(k+2)/2⌉`; otherwise the
`2k + 4` digits at positions `0 .. k + 1` of `n² mod b^(k+2)` and
`n³ mod b^(k+2)` are distinct and the four at positions `k, k + 1` miss
`mhi`. -/
def midPrefilter (b k n : ℕ) (mhi : Finset ℕ) : Bool :=
  if n < b ^ ((k + 2 + 1) / 2) then true
  else
    let m := b ^ (k + 2)
    let r := n % m
    let r2 := r * r % m
    let r3 := r2 * r % m
    let ds := (List.range (k + 2)).map (digit b r2) ++ (List.range (k + 2)).map (digit b r3)
    decide ds.Nodup && (List.range' k 2).all fun j => digit b r2 j ∉ mhi && digit b r3 j ∉ mhi

/-! ### The join of one slice: the definition -/

/-- The tops of unit `d` probed against the children of class `c`: classes
`(rt − (c + d)) mod (b − 1)` over the roots `rt`, in roots order then lead order
(`cpu.rs:794–799`). -/
def probesOf (b : ℕ) (tv : List Top) (c d : ℕ) : List Top :=
  (roots b).flatMap fun rt => tv.filter fun t => t.h % (b - 1) = (rt + (b - 1) - (c + d) % (b - 1)) % (b - 1)

/-- The certified children at unit `d` of the parents `pc`, as `(r, mask)`
(`cpu.rs:803–815`). -/
def kidsOf (b : ℕ) (pc : List Parent) (d : ℕ) : List (ℕ × Finset ℕ) :=
  pc.filterMap fun p => (childMask b p d).map fun x => (p.r, x)

/-- The survivors `(d, n, mhi)` of slice `pip`: for each class `c` and unit
`d`, each top probed (classes `(rt − (c + d)) mod (b − 1)` over the roots
`rt`, `cpu.rs:794–799`) against each certified child of a class-`c` parent,
masks disjoint and `n` in the top's interval (`cpu.rs:849–856`). -/
def sliceSurvivors (b lo hi : ℕ) (sh : Shape) (pip : ℕ) : List (ℕ × ℕ × Finset ℕ) :=
  let ps := parents b sh pip
  (List.range (b - 1)).flatMap fun c =>
    (List.range b).flatMap fun d =>
      (probesOf b (unitTops b lo hi sh.f0 sh.k (pip + d * b ^ (sh.k - 1 - sh.f0))) c d).flatMap
        fun t => (kidsOf b (ps.filter fun p => p.cls = c) d).filterMap fun x =>
          let n := t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1
          if Disjoint t.mask x.2 ∧ t.lo ≤ n ∧ n ≤ t.hi then some (d, n, t.mhi) else none

/-- What `search_field` (`cpu.rs:937`) returns: the nice numbers ascending,
`survivors`, `checked`, `slices`. -/
structure FieldOutcome where
  nice : List ℕ
  survivors : ℕ
  checked : ℕ
  slices : ℕ
  deriving DecidableEq, Repr

/-- The slices of a field, in the Rust's order (`cpu.rs:952–954`). -/
def fieldSlices (c : Coord) (sh : Shape) (vs vz : ℕ) : List ℕ :=
  (c.fieldTs vs vz).flatMap fun t => sh.slicesOf c t

/-- `search_field` (`cpu.rs:937`): `none` where the Rust returns an error
(a shape that does not fit, a field that is not whole quanta; the mask-width
check `b ≤ M::BITS` is not modelled). -/
def searchField (c : Coord) (sh : Shape) (vs vz : ℕ) : Option FieldOutcome :=
  if sh.Fits c ∧ (c.fieldDigits vs vz).isSome then
    let pips := fieldSlices c sh vs vz
    let surv := pips.flatMap fun pip => sliceSurvivors c.b c.lo c.hi sh pip
    let pass := surv.filter fun s => midPrefilter c.b sh.k s.2.1 s.2.2
    some ⟨((pass.filter fun s => finalCheck c.b s.2.1).map fun s => s.2.1).mergeSort,
      surv.length, pass.length, pips.length⟩
  else none

/-! ### The join of one slice, step by step as the Rust runs it -/

/-- `Counts` (`cpu.rs:575`). -/
structure Counts where
  topsTested : ℕ := 0
  tops : ℕ := 0
  parents : ℕ := 0
  children : ℕ := 0
  chunks : ℕ := 0
  pairs : ℕ := 0
  flat : ℕ := 0
  kept : ℕ := 0
  words : ℕ := 0
  survivors : ℕ := 0
  checked : ℕ := 0
  clipped : ℕ := 0
  deriving DecidableEq, Repr

def Counts.toList (c : Counts) : List ℕ :=
  [c.topsTested, c.tops, c.parents, c.children, c.chunks, c.pairs, c.flat, c.kept, c.words,
    c.survivors, c.checked, c.clipped]

/-- How many of `ms` hold each digit `0 .. b − 1` (`digit_count`, `cpu.rs:727`). -/
def digitFreq (b : ℕ) (ms : List (Finset ℕ)) : List ℕ :=
  (List.range b).map fun v => (ms.filter fun m => v ∈ m).length

/-- `key_digits` (`cpu.rs:554`): the 8 digits of largest `fp·ft`, ties by
digit. (The Rust compares the products as `f64`; they are exact below
2^53.) -/
def keyDigits (b : ℕ) (fp ft : List ℕ) : List ℕ :=
  let w := fun x => fp.getD x 0 * ft.getD x 0
  ((List.range b).mergeSort fun x y => w y < w x ∨ (w y = w x ∧ x ≤ y)).take 8

/-- The chunk key of a mask (`cpu.rs:740`): bit `7 − i` for the `i`-th key digit. -/
def chunkKey (rank : List ℕ) (mk : Finset ℕ) : ℕ :=
  (rank.zipIdx.map fun x => if x.1 ∈ mk then 2 ^ (7 - x.2) else 0).sum

/-- `l` in consecutive pieces of `n` (the last may be shorter). -/
def chunksOf {α : Type} (n : ℕ) (l : List α) : List (List α) :=
  (List.range ((l.length + n - 1) / n)).map fun i => (l.drop (i * n)).take n

/-- The survivors `(d, n, pass)` in the Rust's order, and the counters. -/
structure SliceRun where
  counts : Counts
  surv : List (ℕ × ℕ × Bool)

def Counts.add (x y : Counts) : Counts :=
  ⟨x.topsTested + y.topsTested, x.tops + y.tops, x.parents + y.parents, x.children + y.children,
    x.chunks + y.chunks, x.pairs + y.pairs, x.flat + y.flat, x.kept + y.kept, x.words + y.words,
    x.survivors + y.survivors, x.checked + y.checked, x.clipped + y.clipped⟩

def Counts.sum (l : List Counts) : Counts := l.foldr Counts.add {}

/-- `SliceSetup::new` (`cpu.rs:709`): the parents sorted stably by
`(class, 255 − key)`, the tops of each unit, the leads tested per unit. -/
structure Setup where
  ps : List Parent
  topsByD : List (List Top)
  leads : List ℕ

def sliceSetup (b lo hi : ℕ) (sh : Shape) (pip : ℕ) : Setup :=
  let ps0 := parents b sh pip
  let step := b ^ (sh.k - 1 - sh.f0)
  let topsByD := (List.range b).map fun d => unitTops b lo hi sh.f0 sh.k (pip + d * step)
  let fp := digitFreq b (ps0.map (·.mask))
  let ft := digitFreq b (topsByD.flatten.map (·.mask))
  let rank := keyDigits b fp ft
  let sk := fun (p : Parent) => p.cls * 256 + (255 - chunkKey rank p.mask)
  ⟨ps0.mergeSort fun p q => sk p ≤ sk q, topsByD,
    (List.range b).map fun d => (unitLeads b lo hi sh.f0 sh.k (pip + d * step)).length⟩

/-- The common mask of a chunk (`cpu.rs:825–829`): the intersection of its
children's masks. -/
def chunkCommon (ch : List (ℕ × Finset ℕ)) : Finset ℕ :=
  ch.foldl (fun acc x => acc ∩ x.2) ((ch.headD (0, ∅)).2)

/-- One (top, child) pair (`cpu.rs:849–861`): the survivor `(d, n, pass)` when
the masks are disjoint and `n` is in the top's interval. -/
def pairSurv (b k d : ℕ) (t : Top) (x : ℕ × Finset ℕ) : Option (ℕ × ℕ × Bool) :=
  let nn := t.h * b ^ k + d * b ^ (k - 1) + x.1
  if Disjoint t.mask x.2 ∧ t.lo ≤ nn ∧ nn ≤ t.hi then some (d, nn, midPrefilter b k nn t.mhi)
  else none

/-- One probe (top `t`, chunk `ch`), `cpu.rs:837–867`: nothing if the chunk's
common mask meets the top's (the skip); otherwise the word's survivors, in
child order. -/
def probeSurv (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) : List (ℕ × ℕ × Bool) :=
  if (chunkCommon ch ∩ t.mask).Nonempty then [] else ch.filterMap (pairSurv b k d t)

/-- One probe's counters: `kept`, `words` (the word of disjoint children is
not zero), `survivors`, `checked`, `clipped` (`cpu.rs:839–866`). -/
def probeCounts (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) : Counts :=
  if (chunkCommon ch ∩ t.mask).Nonempty then {}
  else
    let w := ch.filter fun x => Disjoint x.2 t.mask
    let s := probeSurv b k d t ch
    { kept := 1, words := if w.isEmpty then 0 else 1, survivors := s.length,
      checked := (s.filter fun x => x.2.2).length, clipped := w.length - s.length }

/-- Class `c` at unit `d` of a set-up slice (`cpu.rs:792–868`): its probes, its
children (parents of class `c` in the setup's order), in 64-child chunks. -/
def unitRun (b : ℕ) (st : Setup) (c d : ℕ) :
    List Top × List (ℕ × Finset ℕ) :=
  (probesOf b (st.topsByD.getD d []) c d, kidsOf b (st.ps.filter fun p => p.cls = c) d)

def unitSurv (b : ℕ) (sh : Shape) (st : Setup) (c d : ℕ) : List (ℕ × ℕ × Bool) :=
  let u := unitRun b st c d
  (chunksOf 64 u.2).flatMap fun ch => u.1.flatMap fun t => probeSurv b sh.k d t ch

def unitCounts (b : ℕ) (sh : Shape) (st : Setup) (c d : ℕ) : Counts :=
  let u := unitRun b st c d
  let top : Counts :=
    { children := u.2.length, pairs := u.2.length * u.1.length, chunks := (u.2.length + 63) / 64 }
  Counts.add top
    (Counts.sum ((chunksOf 64 u.2).map fun ch =>
      Counts.add { flat := u.1.length } (Counts.sum (u.1.map fun t => probeCounts b sh.k d t ch))))

/-- `slice_join` (`cpu.rs:624`) as the Rust runs it: `SliceSetup::new`, then
`class` for each class in order (units in order, 64-child chunks, the
common-mask skip, the word of disjoint children in child order, the
interval test, the prefilter), with the bit-sliced word replaced by its
meaning (a child is in the word iff its mask misses the top's). -/
def sliceRun (b lo hi : ℕ) (sh : Shape) (pip : ℕ) : SliceRun :=
  let st := sliceSetup b lo hi sh pip
  let setup : Counts :=
    { topsTested := st.leads.sum, tops := (st.topsByD.map (·.length)).sum, parents := st.ps.length }
  ⟨Counts.add setup
      (Counts.sum ((List.range (b - 1)).map fun c =>
        Counts.sum ((List.range b).map fun d => unitCounts b sh st c d))),
    (List.range (b - 1)).flatMap fun c => (List.range b).flatMap fun d => unitSurv b sh st c d⟩

end NiceMidOut
