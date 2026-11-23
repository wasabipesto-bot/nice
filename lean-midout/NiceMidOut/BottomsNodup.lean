/-
L5(a), no repeats: the bottom list and the parent list of a slice hold each
residue once (`bottomsSorted_nodup`, `parents_nodup`). Distinct digits at a
position lead to distinct residues, so the walk's branches are disjoint.
Needed for counts (L11), not for completeness.
-/
import NiceMidOut.BottomsExact

namespace NiceMidOut

open NiceSearch

/-- The digits the walk tries at position `j`. -/
def botChoices (b f0 pp v j : ℕ) : List ℕ :=
  if f0 ≤ j ∧ j < f0 + pp then [v / b ^ (j - f0) % b] else List.range b

/-- The walk's branch at digit `d`. -/
def botBody (b f0 pp v fuel j r : ℕ) (mask : Finset ℕ) (d : ℕ) : List (ℕ × Finset ℕ) :=
  if (botDigits b r j d).1 = (botDigits b r j d).2 ∨ (botDigits b r j d).1 ∈ mask ∨
      (botDigits b r j d).2 ∈ mask then []
  else botDfs b f0 pp v fuel (j + 1) (r + d * b ^ j)
    (insert (botDigits b r j d).2 (insert (botDigits b r j d).1 mask))

theorem botDfs_succ (b f0 pp v fuel j r : ℕ) (mask : Finset ℕ) :
    botDfs b f0 pp v (fuel + 1) j r mask =
      (botChoices b f0 pp v j).flatMap (botBody b f0 pp v fuel j r mask) := by
  rw [botDfs]; rfl

theorem lt_of_mem_botChoices {b f0 pp v j d : ℕ} (hb : 0 < b) (hd : d ∈ botChoices b f0 pp v j) :
    d < b := by
  unfold botChoices at hd
  split_ifs at hd
  · rw [List.mem_singleton] at hd; rw [hd]; exact Nat.mod_lt _ hb
  · exact List.mem_range.mp hd

theorem botChoices_nodup (b f0 pp v j : ℕ) : (botChoices b f0 pp v j).Nodup := by
  unfold botChoices
  split_ifs
  · exact List.nodup_singleton _
  · exact List.nodup_range

/-- A branch is empty, or the walk from the extended residue with its low
digits as mask (which again has distinct low digits). -/
theorem botBody_cases {b f0 pp v fuel j r d : ℕ} (hb : 2 ≤ b) (hr : r < b ^ j)
    (hd : LowDistinct b r j) (hdb : d < b) :
    botBody b f0 pp v fuel j r (lowSet b r j) d = [] ∨
      (botBody b f0 pp v fuel j r (lowSet b r j) d =
          botDfs b f0 pp v fuel (j + 1) (r + d * b ^ j) (lowSet b (r + d * b ^ j) (j + 1)) ∧
        r + d * b ^ j < b ^ (j + 1) ∧ LowDistinct b (r + d * b ^ j) (j + 1)) := by
  have hmod : r + d * b ^ j ≡ r [MOD b ^ j] := by
    show (r + d * b ^ j) % b ^ j = r % b ^ j
    rw [Nat.add_mul_mod_self_right]
  have hg := botDigits_eq (b := b) (r := r) (j := j) (d := d) (by omega)
    (by intro hj; subst hj; rw [Nat.pow_zero] at hr; omega)
  have hL : lowSet b r j = lowSet b (r + d * b ^ j) j := lowSet_congr hmod.symm
  unfold botBody
  rw [hg]
  simp only
  split_ifs with hc
  · exact Or.inl rfl
  · right
    rw [not_or, not_or, hL] at hc
    refine ⟨by rw [hL, ← lowSet_succ], ?_,
      lowDistinct_succ (lowDistinct_congr hmod.symm hd) hc.1 hc.2.1 hc.2.2⟩
    rw [pow_succ']
    calc r + d * b ^ j < b ^ j + d * b ^ j := Nat.add_lt_add_right hr _
      _ = (d + 1) * b ^ j := by ring
      _ ≤ b * b ^ j := Nat.mul_le_mul_right _ hdb

/-- The walk from a residue with distinct low digits lists no pair twice. -/
theorem botDfs_nodup {b f0 pp v : ℕ} (hb : 2 ≤ b) :
    ∀ fuel j r, r < b ^ j → LowDistinct b r j →
      (botDfs b f0 pp v fuel j r (lowSet b r j)).Nodup := by
  intro fuel
  induction fuel with
  | zero => intro j r _ _; simp [botDfs]
  | succ fuel ih =>
    intro j r hr hd
    rw [botDfs_succ, List.nodup_flatMap]
    refine ⟨fun d hdm => ?_, ?_⟩
    · rcases botBody_cases (fuel := fuel) (f0 := f0) (pp := pp) (v := v) hb hr hd
        (lt_of_mem_botChoices (by omega) hdm) with h | h
      · rw [h]; exact List.nodup_nil
      · rw [h.1]; exact ih _ _ h.2.1 h.2.2
    · refine (botChoices_nodup b f0 pp v j).imp_of_mem ?_
      intro d d' hdm hdm' hne q hq hq'
      have key : ∀ e, e ∈ botChoices b f0 pp v j →
          q ∈ botBody b f0 pp v fuel j r (lowSet b r j) e → q.1 % b ^ (j + 1) = r + e * b ^ j := by
        intro e hem hqe
        rcases botBody_cases (fuel := fuel) (f0 := f0) (pp := pp) (v := v) hb hr hd
          (lt_of_mem_botChoices (by omega) hem) with h | h
        · rw [h] at hqe; cases hqe
        · rw [h.1] at hqe
          exact (botDfs_sound hb fuel (j + 1) _ q h.2.1 h.2.2 hqe).2.1
      have h1 := key d hdm hq
      have h2 := key d' hdm' hq'
      exact hne (Nat.eq_of_mul_eq_mul_right (Nat.pow_pos (by omega))
        (Nat.add_left_cancel (h1.symm.trans h2)))

/-- **The bottom list has no repeats.** -/
theorem bottomsSorted_nodup {b : ℕ} (hb : 2 ≤ b) (k f v : ℕ) : (bottomsSorted b k f v).Nodup := by
  unfold bottomsSorted
  rw [(List.mergeSort_perm _ _).nodup_iff]
  have := botDfs_nodup (f0 := f) (pp := k - f) (v := v) hb k 0 0 (by simp) (lowDistinct_zero b 0)
  rwa [lowSet_zero] at this

/-- **A slice's parent list has no repeats.** -/
theorem parents_nodup {b : ℕ} (hb : 2 ≤ b) (sh : Shape) (pip : ℕ) : (parents b sh pip).Nodup := by
  unfold parents
  refine (bottomsSorted_nodup hb _ _ _).map ?_
  intro q q' h
  have h1 := congrArg Parent.r h
  have h2 := congrArg Parent.mask h
  exact Prod.ext h1 h2

end NiceMidOut
