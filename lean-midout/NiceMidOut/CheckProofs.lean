/-
L9, the final check. The model's `finalCheck` is the verdict of
`uniqueDigits`, the mirror of the Rust's `unique_digits` (`arith.rs:92`): the
count of distinct output digits and whether that count and the total count
are both `b`. `finalCheck_iff` proves the verdict is `IsNice` (for `b ≥ 2`):
the distinct-count half is `numUniques`, equivalent to `IsNice` inside the
range by the earlier library's `numUniques_eq_iff_isNice`; the total-count
half is what puts `n` in the range. The Rust's digit expansion of a `U384`
is not modelled (the model reads `Nat.digits`); the fixture table `check.json`
compares verdicts and counts with the Rust.

Reused from the earlier library: `IsNice`, `outputDigits`, `numUniques`,
`InBaseRange`, `numUniques_eq_iff_isNice`, `inBaseRange_of_isNice`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-- The total count is the range condition. -/
theorem length_outputDigits (b n : ℕ) :
    (outputDigits b n).length = numDigits b (n ^ 2) + numDigits b (n ^ 3) := by
  simp [outputDigits, numDigits]

/-- L9. The final check (the mirror of `unique_digits`) accepts exactly the
nice numbers. -/
theorem finalCheck_iff {b n : ℕ} (hb : 2 ≤ b) : finalCheck b n = true ↔ IsNice b n := by
  unfold finalCheck uniqueDigits
  rw [decide_eq_true_iff, length_outputDigits]
  constructor
  · rintro ⟨hu, hl⟩
    exact (numUniques_eq_iff_isNice hb hl).mp hu
  · intro h
    have hr := inBaseRange_of_isNice h
    exact ⟨(numUniques_eq_iff_isNice hb hr).mpr h, hr⟩

/-- The mirror's verdict, as a `Bool` equation with `IsNice` decided. -/
theorem uniqueDigits_snd {b n : ℕ} (hb : 2 ≤ b) :
    (uniqueDigits b n).2 = decide (IsNice b n) := by
  apply Bool.eq_iff_iff.mpr
  rw [decide_eq_true_iff]
  exact finalCheck_iff hb

end NiceMidOut
