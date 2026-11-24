/-
The coverage check on plain numbers (no coordinate, no Mathlib): a list of
fields `[s, s + z)` covers `[lo, e)` and every field is whole quanta of size
`q` from `lo`. `NiceMidOut.Coverage` states it for a coordinate.

- `wqRaw lo e q f`: the field `f = (s, z)` is non-empty, lies in `[lo, e)`, and
  `q` divides `s − lo` and `z` (`wqRaw_iff`).
- `reach cur fs`: walking the fields in the given order from `cur`, each must
  start at or before the point reached so far; the result is the point reached
  (`none` at the first gap). Overlaps and duplicates are allowed: a value
  searched twice cannot hide a nice number, and the whole-base theorem needs
  only coverage.
- `coversRaw lo e q fs`: every field whole quanta, and the walk of the fields
  sorted by start reaches `e` from `lo`.
- `coversRaw_sound`: `coversRaw lo e q fs = true` gives both properties.
  The walk's soundness (`reach_sound`) does not depend on the order; sorting
  is what makes the check succeed on any covering list (`coversRaw_complete`,
  through `reach_complete`).
-/

namespace NiceMidOut

/-- A field `(s, z)` is whole quanta of `q` in `[lo, e)`. -/
def wqRaw (lo e q : Nat) (f : Nat × Nat) : Bool :=
  decide (0 < f.2) && decide (lo ≤ f.1) && decide (f.1 + f.2 ≤ e) &&
    (f.1 - lo) % q == 0 && f.2 % q == 0

/-- The point reached by walking the fields in order from `cur`; `none` at
the first field that starts after it (a gap). -/
def reach : Nat → List (Nat × Nat) → Option Nat
  | cur, [] => some cur
  | cur, f :: fs => if f.1 ≤ cur then reach (max cur (f.1 + f.2)) fs else none

/-- The fields sorted by start (stable merge sort). -/
def sortFields (fs : List (Nat × Nat)) : List (Nat × Nat) :=
  fs.mergeSort fun x y => decide (x.1 ≤ y.1)

/-- Every field whole quanta, and the sorted fields leave no gap in `[lo, e)`. -/
def coversRaw (lo e q : Nat) (fs : List (Nat × Nat)) : Bool :=
  fs.all (wqRaw lo e q) &&
    match reach lo (sortFields fs) with
    | some r => decide (e ≤ r)
    | none => false

theorem wqRaw_iff {lo e q : Nat} {f : Nat × Nat} :
    wqRaw lo e q f = true ↔
      0 < f.2 ∧ lo ≤ f.1 ∧ f.1 + f.2 ≤ e ∧ (f.1 - lo) % q = 0 ∧ f.2 % q = 0 := by
  simp only [wqRaw, Bool.and_eq_true, decide_eq_true_eq, beq_iff_eq, and_assoc]

/-- The walk is sound in any order: every value from `cur` to the point
reached lies in one of the fields. -/
theorem reach_sound : ∀ (fs : List (Nat × Nat)) (cur r : Nat), reach cur fs = some r →
    ∀ v, cur ≤ v → v < r → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2
  | [], cur, r, h, v, h1, h2 => by
    simp only [reach, Option.some.injEq] at h
    omega
  | f :: fs, cur, r, h, v, h1, h2 => by
    simp only [reach] at h
    split at h
    · rename_i hf
      by_cases hv : v < f.1 + f.2
      · exact ⟨f, List.mem_cons_self, by omega, hv⟩
      · obtain ⟨g, hg, hg1, hg2⟩ := reach_sound fs _ r h v (by omega) h2
        exact ⟨g, List.mem_cons_of_mem _ hg, hg1, hg2⟩
    · cases h

/-- **The check is sound.** -/
theorem coversRaw_sound {lo e q : Nat} {fs : List (Nat × Nat)} (h : coversRaw lo e q fs = true) :
    (∀ f ∈ fs, wqRaw lo e q f = true) ∧
      ∀ v, lo ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2 := by
  unfold coversRaw at h
  rw [Bool.and_eq_true, List.all_eq_true] at h
  obtain ⟨hw, hr⟩ := h
  refine ⟨hw, ?_⟩
  intro v h1 h2
  split at hr
  · rename_i r hreach
    have he : e ≤ r := of_decide_eq_true hr
    obtain ⟨f, hf, hf1, hf2⟩ := reach_sound _ lo r hreach v h1 (by omega)
    exact ⟨f, List.mem_mergeSort.mp hf, hf1, hf2⟩
  · cases hr

/-- The walk of a list sorted by start succeeds and reaches `e` when every
value of `[cur, e)` lies in one of its fields and every field starts below `e`. -/
theorem reach_complete : ∀ (fs : List (Nat × Nat)) (cur e : Nat),
    fs.Pairwise (fun x y => decide (x.1 ≤ y.1) = true) → (∀ f ∈ fs, f.1 < e) →
    (∀ v, cur ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2) →
    ∃ r, reach cur fs = some r ∧ e ≤ r
  | [], cur, e, _, _, hcov => by
    refine ⟨cur, rfl, ?_⟩
    apply Nat.le_of_not_lt
    intro hlt
    obtain ⟨f, hf, -⟩ := hcov cur (Nat.le_refl _) hlt
    cases hf
  | f :: fs, cur, e, hs, hlt, hcov => by
    rw [List.pairwise_cons] at hs
    have hfe := hlt f List.mem_cons_self
    have hstart : f.1 ≤ cur := by
      apply Nat.le_of_not_lt
      intro hgt
      obtain ⟨g, hg, hg1, -⟩ := hcov cur (Nat.le_refl _) (by omega)
      rcases List.mem_cons.mp hg with rfl | hg
      · omega
      · have := of_decide_eq_true (hs.1 g hg)
        omega
    simp only [reach, if_pos hstart]
    refine reach_complete fs _ e hs.2 (fun g hg => hlt g (List.mem_cons_of_mem _ hg)) ?_
    intro v h1 h2
    obtain ⟨g, hg, hg1, hg2⟩ := hcov v (by omega) h2
    rcases List.mem_cons.mp hg with rfl | hg
    · omega
    · exact ⟨g, hg, hg1, hg2⟩

/-- **The check is complete**: whole-quanta fields covering `[lo, e)` are
accepted. -/
theorem coversRaw_complete {lo e q : Nat} {fs : List (Nat × Nat)}
    (hw : ∀ f ∈ fs, wqRaw lo e q f = true)
    (hcov : ∀ v, lo ≤ v → v < e → ∃ f ∈ fs, f.1 ≤ v ∧ v < f.1 + f.2) :
    coversRaw lo e q fs = true := by
  have hsorted : (sortFields fs).Pairwise (fun x y => decide (x.1 ≤ y.1) = true) :=
    List.pairwise_mergeSort (le := fun x y : Nat × Nat => decide (x.1 ≤ y.1))
      (fun _ _ _ hab hbc =>
        decide_eq_true (Nat.le_trans (of_decide_eq_true hab) (of_decide_eq_true hbc)))
      (fun a b => by
        simp only [Bool.or_eq_true, decide_eq_true_eq]
        exact Nat.le_total _ _)
      fs
  have hlt : ∀ f ∈ sortFields fs, f.1 < e := by
    intro f hf
    have := (wqRaw_iff.mp (hw f (List.mem_mergeSort.mp hf)))
    omega
  have hcov' : ∀ v, lo ≤ v → v < e → ∃ f ∈ sortFields fs, f.1 ≤ v ∧ v < f.1 + f.2 := by
    intro v h1 h2
    obtain ⟨f, hf, hf1, hf2⟩ := hcov v h1 h2
    exact ⟨f, List.mem_mergeSort.mpr hf, hf1, hf2⟩
  obtain ⟨r, hr, her⟩ := reach_complete _ lo e hsorted hlt hcov'
  unfold coversRaw
  rw [Bool.and_eq_true, List.all_eq_true, hr]
  exact ⟨hw, decide_eq_true her⟩

end NiceMidOut
