/-
The executable range is the earlier library's: `ceilRootC = ceilRoot` (the
bisection finds the least `r` with `x ≤ r^e`) and so `baseRangeC = baseRange`.
-/
import NiceMidOut.Coord

namespace NiceMidOut

open NiceSearch

/-- The bisection's invariant `lo^e < x ≤ hi^e` with `hi − lo ≤ 2^fuel` gives
the least root. -/
theorem ceilRootC_go_eq {e x : ℕ} (he : e ≠ 0) :
    ∀ (fuel lo hi : ℕ), lo ^ e < x → x ≤ hi ^ e → hi - lo ≤ 2 ^ fuel →
      ceilRootC.go e x lo hi fuel = ceilRoot e x := by
  have close : ∀ lo hi : ℕ, lo ^ e < x → x ≤ hi ^ e → hi ≤ lo + 1 → hi = ceilRoot e x := by
    intro lo hi hl hh hd
    have h1 : ceilRoot e x ≤ hi := (le_ceilRoot_iff he).mpr hh
    have h2 : lo < ceilRoot e x := by
      by_contra hc
      have := (le_ceilRoot_iff he).mp (Nat.le_of_not_lt hc)
      omega
    omega
  intro fuel
  induction fuel with
  | zero =>
    intro lo hi hl hh hd
    simp only [ceilRootC.go]
    exact close lo hi hl hh (by simp at hd; omega)
  | succ f ih =>
    intro lo hi hl hh hd
    rw [pow_succ] at hd
    simp only [ceilRootC.go]
    split_ifs with h1 h2
    · exact close lo hi hl hh h1
    · exact ih _ _ hl h2 (by omega)
    · exact ih _ _ (Nat.lt_of_not_le h2) hh (by omega)

theorem ceilRootC_eq {e : ℕ} (he : e ≠ 0) (x : ℕ) : ceilRootC e x = ceilRoot e x := by
  unfold ceilRootC
  split_ifs with hx
  · rcases Nat.le_one_iff_eq_zero_or_eq_one.mp hx with rfl | rfl
    · exact (Nat.le_zero.mp ((le_ceilRoot_iff he).mpr (Nat.zero_le _))).symm
    · have h1 : ceilRoot e 1 ≤ 1 := (le_ceilRoot_iff he).mpr (by simp)
      have h2 : ¬ ceilRoot e 1 ≤ 0 := fun h => by
        have := (le_ceilRoot_iff he).mp h
        rw [zero_pow he] at this
        omega
      omega
  · apply ceilRootC_go_eq he
    · rw [zero_pow he]; omega
    · exact Nat.le_self_pow he x
    · have h1 := Nat.lt_log2_self (n := x)
      have h2 : 2 ^ (x.log2 + 1) ≤ 2 ^ (x.log2 + 2) := Nat.pow_le_pow_right (by norm_num) (by omega)
      omega

/-- The computable range is the earlier library's `baseRange`. -/
theorem baseRangeC_eq (b : ℕ) : baseRangeC b = baseRange b := by
  have h2 : ceilRootC 2 = ceilRoot 2 := funext (ceilRootC_eq (by norm_num))
  have h3 : ceilRootC 3 = ceilRoot 3 := funext (ceilRootC_eq (by norm_num))
  rcases (by omega : b % 5 = 0 ∨ b % 5 = 1 ∨ b % 5 = 2 ∨ b % 5 = 3 ∨ b % 5 = 4) with
    h | h | h | h | h <;> simp [baseRangeC, baseRange, h, h2, h3]

end NiceMidOut

namespace NiceMidOut

/-- A coordinate the executable constructor accepts satisfies `Coord.Valid`,
the hypothesis the theorems take. -/
theorem Coord.valid_of_withDigits {b k0 k1 q0 : ℕ} {c : Coord}
    (h : Coord.withDigits b k0 k1 q0 = some c) : c.Valid := by
  unfold Coord.withDigits at h
  split_ifs at h with hb
  split at h
  · rename_i lo hi hr
    split_ifs at h with hlh
    simp only [Option.ite_none_right_eq_some, Option.some.injEq] at h
    obtain ⟨hk, rfl⟩ := h
    exact ⟨hb.1, hb.2, (baseRangeC_eq b) ▸ hr, hk.1, hk.2.1, hk.2.2⟩
  · cases h

end NiceMidOut
