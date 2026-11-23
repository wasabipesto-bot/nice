/-
L9, the final check. The model's `finalCheck` is `IsNice`, decided
(`finalCheck_iff`). `uniqueDigits` mirrors the Rust's `unique_digits`
(`arith.rs:92`): the count of distinct output digits and whether that count
and the total count are both `b`; `uniqueDigits_snd` proves its verdict is
`finalCheck`, for every `n` (the Rust's digit expansion of a `U384` is not
modelled: the model reads `Nat.digits`; the fixtures' nice lists compare the
two). The distinct-count half alone is `numUniques`, whose equivalence with `IsNice` inside the range is the earlier
library's `numUniques_eq_iff_isNice`; the total-count half is what puts `n`
in the range.

Reused from the earlier library: `IsNice`, `outputDigits`, `numUniques`,
`InBaseRange`, `numUniques_eq_iff_isNice`, `inBaseRange_of_isNice`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-- L9. The final check is the definition. -/
theorem finalCheck_iff {b n : ℕ} : finalCheck b n = true ↔ IsNice b n := by
  unfold finalCheck
  exact decide_eq_true_iff

/-- `unique_digits(n, b)` (`arith.rs:92`): distinct output digits, and whether
both the distinct and the total count are `b`. -/
def uniqueDigits (b n : ℕ) : ℕ × Bool :=
  ((outputDigits b n).toFinset.card,
    decide ((outputDigits b n).toFinset.card = b ∧ (outputDigits b n).length = b))

/-- The total count is the range condition. -/
theorem length_outputDigits (b n : ℕ) :
    (outputDigits b n).length = numDigits b (n ^ 2) + numDigits b (n ^ 3) := by
  simp [outputDigits, numDigits]

/-- L9. The Rust's verdict (both counts `b`) is the model's final check. -/
theorem uniqueDigits_snd {b n : ℕ} (hb : 2 ≤ b) :
    (uniqueDigits b n).2 = finalCheck b n := by
  unfold uniqueDigits finalCheck
  apply Bool.eq_iff_iff.mpr
  rw [decide_eq_true_iff, decide_eq_true_iff, length_outputDigits]
  constructor
  · rintro ⟨hu, hl⟩
    exact (numUniques_eq_iff_isNice hb hl).mp hu
  · intro h
    have hr := inBaseRange_of_isNice h
    exact ⟨(numUniques_eq_iff_isNice hb hr).mpr h, hr⟩

end NiceMidOut
