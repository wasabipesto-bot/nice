/-
The coverage certificate: a computable check that a list of searched fields
covers a coordinate, and what its "yes" gives with the whole-base theorem.

- `Coord.coversB c fs`: every field of `fs` is whole quanta and the fields,
  sorted by start, leave no gap in `[lo, vEnd)` (overlaps and duplicates are
  allowed; `NiceMidOut.CoverRaw`).
- `Coord.coversB_sound`: `coversB c fs = true` gives `c.WholeQuanta` for every
  field and `c.Covers fs`, the hypothesis of `no_nice_of_searched_withDigits`.
- `Coord.coversB_complete`, `Coord.coversB_iff`: the converse: whole-quanta
  fields that cover are accepted, whatever their order.
- `no_nice_of_coversB`: with `Coord.withDigits b k0 k1 q0 = some c`,
  `c.coversB fs = true`, and every field's search returning an outcome with no
  nice number, no number is nice in base `b`.
- `certOk b k0 k1 q0 recs`: the decision of the executable `coverage` on its
  own inputs (records `(range_start, range_size, nice_count)`): the coordinate
  is accepted, the records' fields cover it, every count is 0.
  `no_nice_of_certOk`: if `certOk` says yes and each record's search really
  returned an outcome with as many nice numbers as recorded, base `b` has no
  nice number.
-/
import NiceMidOut.WholeBase
import NiceMidOut.CoverRaw

namespace NiceMidOut

open NiceSearch

namespace Coord

/-- The coverage check for a coordinate. -/
def coversB (c : Coord) (fs : List (ℕ × ℕ)) : Bool :=
  coversRaw c.lo c.vEnd c.quantum fs

theorem wholeQuanta_of_wqRaw {c : Coord} {f : ℕ × ℕ}
    (h : wqRaw c.lo c.vEnd c.quantum f = true) : c.WholeQuanta f.1 f.2 := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := wqRaw_iff.mp h
  exact ⟨h1, h2, h3, Nat.dvd_of_mod_eq_zero h4, Nat.dvd_of_mod_eq_zero h5⟩

/-- **The check is sound**: its "yes" is the hypothesis of the whole-base
theorem (and every field is whole quanta). -/
theorem coversB_sound {c : Coord} {fs : List (ℕ × ℕ)} (h : c.coversB fs = true) :
    (∀ f ∈ fs, c.WholeQuanta f.1 f.2) ∧ c.Covers fs := by
  obtain ⟨hw, hcov⟩ := coversRaw_sound h
  exact ⟨fun f hf => wholeQuanta_of_wqRaw (hw f hf), hcov⟩

/-- **The check is complete**: whole-quanta fields that cover are accepted. -/
theorem coversB_complete {c : Coord} {fs : List (ℕ × ℕ)}
    (hw : ∀ f ∈ fs, c.WholeQuanta f.1 f.2) (hcov : c.Covers fs) : c.coversB fs = true := by
  refine coversRaw_complete (fun f hf => ?_) hcov
  obtain ⟨h1, h2, h3, h4, h5⟩ := hw f hf
  exact wqRaw_iff.mpr ⟨h1, h2, h3, Nat.mod_eq_zero_of_dvd h4, Nat.mod_eq_zero_of_dvd h5⟩

theorem coversB_iff {c : Coord} {fs : List (ℕ × ℕ)} :
    c.coversB fs = true ↔ (∀ f ∈ fs, c.WholeQuanta f.1 f.2) ∧ c.Covers fs :=
  ⟨coversB_sound, fun h => coversB_complete h.1 h.2⟩

end Coord

/-- **No nice number in base `b`**, from the check: the coordinate built by
`Coord.withDigits b k0 k1 q0`, `coversB` true on the fields, and every field's
search returned an outcome with an empty nice list. -/
theorem no_nice_of_coversB {b k0 k1 q0 : ℕ} {c : Coord} {sh : Shape} {fs : List (ℕ × ℕ)}
    (hc : Coord.withDigits b k0 k1 q0 = some c) (hcov : c.coversB fs = true)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) :
    ∀ n, ¬ IsNice b n :=
  no_nice_of_searched_withDigits hc (Coord.coversB_sound hcov).2 hrun

/-- The executable's decision on its inputs: base, digit positions, and the
records `(range_start, range_size, nice_count)` of the searched fields. -/
def certOk (b k0 k1 q0 : ℕ) (recs : List (ℕ × ℕ × ℕ)) : Bool :=
  match Coord.withDigits b k0 k1 q0 with
  | some c => c.coversB (recs.map fun r => (r.1, r.2.1)) && recs.all fun r => r.2.2 == 0
  | none => false

/-- **What the executable's "yes" means.** If `certOk` accepts the records
and each record's field, searched with some one shape, really returned an
outcome with as many nice numbers as recorded, then no number is nice in
base `b`. -/
theorem no_nice_of_certOk {b k0 k1 q0 : ℕ} {sh : Shape} {recs : List (ℕ × ℕ × ℕ)}
    (hok : certOk b k0 k1 q0 recs = true)
    (hrec : ∀ c, Coord.withDigits b k0 k1 q0 = some c →
      ∀ r ∈ recs, ∃ o, searchField c sh r.1 r.2.1 = some o ∧ o.nice.length = r.2.2) :
    ∀ n, ¬ IsNice b n := by
  unfold certOk at hok
  split at hok
  · rename_i c hc
    rw [Bool.and_eq_true, List.all_eq_true] at hok
    obtain ⟨hcov, hzero⟩ := hok
    refine no_nice_of_coversB (sh := sh) hc hcov ?_
    intro f hf
    rw [List.mem_map] at hf
    obtain ⟨r, hr, rfl⟩ := hf
    obtain ⟨o, ho, hlen⟩ := hrec c hc r hr
    have h0 : r.2.2 = 0 := beq_iff_eq.mp (hzero r hr)
    rw [h0] at hlen
    exact ⟨o, ho, List.eq_nil_of_length_eq_zero hlen⟩
  · cases hok

end NiceMidOut
