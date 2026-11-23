/-
The end-to-end theorem without the model's field function as a hypothesis,
and at the level of a whole base.

- `Coord.WholeQuanta`: the plain whole-quanta condition on a field
  `[vs, vs + vz)` (non-empty, inside `[lo, vEnd)`, start and length multiples of
  the quantum). `Coord.fieldDigits_of_wholeQuanta` and
  `Coord.fieldDigits_isSome_iff`: the model's `fieldDigits` accepts exactly
  these fields, proved, not assumed; `searchField_isSome_iff`: `searchField`
  returns an outcome exactly for a fitting shape and such a field.
- `searchField_complete_wq`: completeness with that condition as hypothesis.
- `Coord.Covers`: a list of fields covers the coordinate's values `[lo, vEnd)`.
  `isNice_iff_mem_fields`: for a valid coordinate, a fitting shape and whole-
  quanta fields covering `[lo, vEnd)`, a number is nice iff it is in the
  outcome of one of the fields. `no_nice_of_searched`: if every field of a
  covering list was searched (`searchField` returned an outcome) and every
  outcome's list of nice numbers is empty, the base has no nice number.
- The two tilings the search uses, proved to be instances: the whole
  coordinate as one field (`Coord.wholeField_*`) and the fields of one quantum
  each (`Coord.quantumFields_*`).
-/
import NiceMidOut.EndToEnd

namespace NiceMidOut

open NiceSearch

namespace Coord

/-- A whole-quanta field `[vs, vs + vz)` of the coordinate (`coord.rs:283–301`). -/
def WholeQuanta (c : Coord) (vs vz : ℕ) : Prop :=
  0 < vz ∧ c.lo ≤ vs ∧ vs + vz ≤ c.vEnd ∧ c.quantum ∣ vs - c.lo ∧ c.quantum ∣ vz

/-- The model's field function accepts every whole-quanta field. -/
theorem fieldDigits_of_wholeQuanta {c : Coord} {vs vz : ℕ} (h : c.WholeQuanta vs vz) :
    c.fieldDigits vs vz =
      some ((vs - c.lo) / c.quantum, (vs - c.lo) / c.quantum + vz / c.quantum) := by
  obtain ⟨h1, h2, h3, h4, h5⟩ := h
  unfold fieldDigits
  rw [if_pos ⟨h1, h2, h3, Nat.mod_eq_zero_of_dvd h4, Nat.mod_eq_zero_of_dvd h5⟩]

/-- … and only those. -/
theorem fieldDigits_isSome_iff {c : Coord} {vs vz : ℕ} :
    (c.fieldDigits vs vz).isSome ↔ c.WholeQuanta vs vz := by
  constructor
  · intro h
    unfold fieldDigits at h
    split_ifs at h with hc
    · obtain ⟨h1, h2, h3, h4, h5⟩ := hc
      exact ⟨h1, h2, h3, Nat.dvd_of_mod_eq_zero h4, Nat.dvd_of_mod_eq_zero h5⟩
    · cases h
  · intro h
    rw [fieldDigits_of_wholeQuanta h]
    rfl

/-- A list of fields covers the coordinate's values `[lo, vEnd)`. -/
def Covers (c : Coord) (fs : List (ℕ × ℕ)) : Prop :=
  ∀ v, c.lo ≤ v → v < c.vEnd → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2

end Coord

/-- `searchField` returns an outcome exactly for a fitting shape and a
whole-quanta field. -/
theorem searchField_isSome_iff {c : Coord} {sh : Shape} {vs vz : ℕ} :
    (searchField c sh vs vz).isSome ↔ sh.Fits c ∧ c.WholeQuanta vs vz := by
  rw [← Coord.fieldDigits_isSome_iff]
  unfold searchField
  split_ifs with h
  · exact ⟨fun _ => h, fun _ => rfl⟩
  · exact ⟨fun h' => absurd h' (by simp), fun h' => absurd h' h⟩

/-- **END-MO, completeness, for a whole-quanta field.** -/
theorem searchField_complete_wq {c : Coord} {sh : Shape} {vs vz : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hw : c.WholeQuanta vs vz) :
    ∃ o, searchField c sh vs vz = some o ∧
      ∀ n, IsNice c.b n → vs ≤ c.vOfN n → c.vOfN n < vs + vz → n ∈ o.nice :=
  searchField_complete hc hfit (Coord.fieldDigits_of_wholeQuanta hw)

/-- Every nice number's `v` is a value of the coordinate. -/
theorem vOfN_mem_of_isNice {c : Coord} {n : ℕ} (hc : c.Valid) (h : IsNice c.b n) :
    c.lo ≤ c.vOfN n ∧ c.vOfN n < c.vEnd := by
  obtain ⟨hb3, -, hr, hk0, hq, -⟩ := hc
  obtain ⟨hlo, hhi⟩ := mem_range_of_isNice (by omega) hr h
  exact ⟨Coord.lo_le_vOfN n, Coord.vOfN_lt_vEnd (by omega) (by omega) hlo hhi⟩

/-- **END-MO for a whole base.** For a valid coordinate, a fitting shape and a
list of whole-quanta fields covering `[lo, vEnd)`: a number is nice in the
coordinate's base iff it is in the outcome of one of the fields. -/
theorem isNice_iff_mem_fields {c : Coord} {sh : Shape} {fs : List (ℕ × ℕ)} (hc : c.Valid)
    (hfit : sh.Fits c) (hw : ∀ f ∈ fs, c.WholeQuanta f.1 f.2) (hcov : c.Covers fs) (n : ℕ) :
    IsNice c.b n ↔ ∃ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ n ∈ o.nice := by
  constructor
  · intro h
    obtain ⟨h1, h2⟩ := vOfN_mem_of_isNice hc h
    obtain ⟨f, hf, hv1, hv2⟩ := hcov _ h1 h2
    obtain ⟨o, ho, hmem⟩ := searchField_complete_wq hc hfit (hw f hf)
    exact ⟨f, hf, o, ho, hmem n h hv1 hv2⟩
  · rintro ⟨f, -, o, ho, hn⟩
    exact (searchField_sound hc ho hn).1

/-- **No nice number in the base.** For a valid coordinate and any list of
fields covering `[lo, vEnd)`: if the search of every field returned an
outcome (so the shape fits and every field is whole quanta,
`searchField_isSome_iff`) and every outcome's list of nice numbers is empty,
then no number is nice in the coordinate's base. -/
theorem no_nice_of_searched {c : Coord} {sh : Shape} {fs : List (ℕ × ℕ)} (hc : c.Valid)
    (hcov : c.Covers fs)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) :
    ∀ n, ¬ IsNice c.b n := by
  intro n h
  obtain ⟨h1, h2⟩ := vOfN_mem_of_isNice hc h
  obtain ⟨f, hf, hv1, hv2⟩ := hcov _ h1 h2
  obtain ⟨o, ho, hnil⟩ := hrun f hf
  have hs : (searchField c sh f.1 f.2).isSome := by rw [ho]; rfl
  obtain ⟨hfit, hw⟩ := searchField_isSome_iff.mp hs
  obtain ⟨o', ho', hmem⟩ := searchField_complete_wq hc hfit hw
  rw [ho] at ho'
  cases ho'
  have := hmem n h hv1 hv2
  rw [hnil] at this
  cases this

/-- The base of a coordinate built by `Coord.withDigits` is the one asked for. -/
theorem Coord.b_of_withDigits {b k0 k1 q0 : ℕ} {c : Coord}
    (h : Coord.withDigits b k0 k1 q0 = some c) : c.b = b := by
  unfold Coord.withDigits at h
  split_ifs at h with hb
  split at h
  · split_ifs at h with hlh
    simp only [Option.ite_none_right_eq_some, Option.some.injEq] at h
    obtain ⟨-, rfl⟩ := h
    rfl
  · cases h

/-- **No nice number in base `b`**, for a coordinate built by
`Coord.withDigits b k0 k1 q0`: every field of a covering list searched, every
outcome empty. -/
theorem no_nice_of_searched_withDigits {b k0 k1 q0 : ℕ} {c : Coord} {sh : Shape}
    {fs : List (ℕ × ℕ)} (hc : Coord.withDigits b k0 k1 q0 = some c) (hcov : c.Covers fs)
    (hrun : ∀ f ∈ fs, ∃ o, searchField c sh f.1 f.2 = some o ∧ o.nice = []) :
    ∀ n, ¬ IsNice b n := by
  have h := no_nice_of_searched (Coord.valid_of_withDigits hc) hcov hrun
  rwa [Coord.b_of_withDigits hc] at h

/-! ### The two tilings -/

namespace Coord

/-- The whole coordinate as one field. -/
def wholeField (c : Coord) : List (ℕ × ℕ) := [(c.lo, c.vEnd - c.lo)]

/-- The fields of one quantum each, in order. -/
def quantumFields (c : Coord) : List (ℕ × ℕ) :=
  (List.range (c.b ^ (c.k1 - c.q0))).map fun i => (c.lo + i * c.quantum, c.quantum)

theorem wholeField_wholeQuanta {c : Coord} (hc : c.Valid) :
    ∀ f ∈ c.wholeField, c.WholeQuanta f.1 f.2 := by
  intro f hf
  rw [wholeField, List.mem_singleton] at hf
  subst hf
  rw [← fieldDigits_isSome_iff, fieldDigits_whole (by have := hc.1; omega) hc.2.2.2.2.1.le]
  rfl

theorem wholeField_covers (c : Coord) : c.Covers c.wholeField := by
  intro v h1 h2
  exact ⟨_, List.mem_singleton.mpr rfl, h1, by simp only; omega⟩

theorem quantumFields_wholeQuanta {c : Coord} (hc : c.Valid) :
    ∀ f ∈ c.quantumFields, c.WholeQuanta f.1 f.2 := by
  have hb : 0 < c.b := by have := hc.1; omega
  have hQ := quantum_pos (c := c) hb
  have hE := vEnd_sub_lo (c := c) hc.2.2.2.2.1.le
  have hle : c.lo ≤ c.vEnd := by unfold vEnd; omega
  intro f hf
  rw [quantumFields, List.mem_map] at hf
  obtain ⟨i, hi, rfl⟩ := hf
  rw [List.mem_range] at hi
  refine ⟨hQ, Nat.le_add_right _ _, ?_, ⟨i, by simp [Nat.mul_comm]⟩, dvd_refl _⟩
  have : (i + 1) * c.quantum ≤ c.quantum * c.b ^ (c.k1 - c.q0) := by
    rw [Nat.mul_comm c.quantum]; exact Nat.mul_le_mul_right _ hi
  simp only
  rw [Nat.add_mul, Nat.one_mul] at this
  omega

theorem quantumFields_covers {c : Coord} (hc : c.Valid) : c.Covers c.quantumFields := by
  have hb : 0 < c.b := by have := hc.1; omega
  have hQ := quantum_pos (c := c) hb
  have hE := vEnd_sub_lo (c := c) hc.2.2.2.2.1.le
  intro v h1 h2
  have hlt : v - c.lo < c.quantum * c.b ^ (c.k1 - c.q0) := by
    have : c.lo ≤ c.vEnd := by omega
    omega
  refine ⟨(c.lo + (v - c.lo) / c.quantum * c.quantum, c.quantum), ?_, ?_, ?_⟩
  · rw [quantumFields, List.mem_map]
    exact ⟨(v - c.lo) / c.quantum,
      List.mem_range.mpr ((Nat.div_lt_iff_lt_mul hQ).mpr (by rw [Nat.mul_comm]; exact hlt)), rfl⟩
  · have := Nat.div_mul_le_self (v - c.lo) c.quantum
    simp only
    omega
  · have := Nat.lt_div_mul_add (a := v - c.lo) hQ
    simp only
    omega

end Coord

/-- The whole base as one field: a number is nice iff the one search returns it. -/
theorem isNice_iff_mem_wholeField {c : Coord} {sh : Shape} (hc : c.Valid) (hfit : sh.Fits c)
    (n : ℕ) :
    IsNice c.b n ↔ ∃ o, searchField c sh c.lo (c.vEnd - c.lo) = some o ∧ n ∈ o.nice := by
  rw [isNice_iff_mem_fields hc hfit (Coord.wholeField_wholeQuanta hc) (Coord.wholeField_covers c)]
  simp [Coord.wholeField]

/-- The base quantum by quantum: a number is nice iff the search of one of the
quanta returns it. -/
theorem isNice_iff_mem_quantumFields {c : Coord} {sh : Shape} (hc : c.Valid) (hfit : sh.Fits c)
    (n : ℕ) :
    IsNice c.b n ↔ ∃ f ∈ c.quantumFields, ∃ o, searchField c sh f.1 f.2 = some o ∧ n ∈ o.nice :=
  isNice_iff_mem_fields hc hfit (Coord.quantumFields_wholeQuanta hc) (Coord.quantumFields_covers hc) n

end NiceMidOut
