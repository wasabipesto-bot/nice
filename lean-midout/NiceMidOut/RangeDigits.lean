/-
L2, range and digit lengths. Every nice number lies in the range `[lo, hi)`
of `baseRange` (and of the executable `baseRangeC`); every `n` of a range has
the same number of digits, `L = numDigits (hi − 1)` (`Coord.L`, Rust
`ndigits(end − 1)`, `coord.rs:199`), so `b^(L−1) ≤ n < b^L`, `n²` has at
least `2L − 1` digits and `n³` at least `3L − 2`: for every `k ≤ L` both powers
have at least `k` digits (the side condition the bottoms' and the pairing's
lemmas take).

Reused from the earlier library: `inBaseRange_of_isNice`,
`memBaseRange_of_inBaseRange`, `inBaseRange_of_memBaseRange`,
`numDigits_eq_iff`, `lt_numDigits_iff`, `numDigits_le_iff`; from step 1:
`baseRangeC_eq`.
-/
import NiceMidOut.RangeProofs

namespace NiceMidOut

open NiceSearch

/-- A nice number lies in its base's closed-form range. -/
theorem mem_range_of_isNice {b lo hi n : ℕ} (hb : 2 ≤ b) (hr : baseRange b = some (lo, hi))
    (h : IsNice b n) : lo ≤ n ∧ n < hi := by
  obtain ⟨lo', hi', hr', h1, h2⟩ := memBaseRange_of_inBaseRange hb (inBaseRange_of_isNice h)
  rw [hr] at hr'
  simp only [Option.some.injEq, Prod.mk.injEq] at hr'
  obtain ⟨rfl, rfl⟩ := hr'
  exact ⟨h1, h2⟩

/-- The same with the executable range. -/
theorem mem_rangeC_of_isNice {b lo hi n : ℕ} (hb : 2 ≤ b) (hr : baseRangeC b = some (lo, hi))
    (h : IsNice b n) : lo ≤ n ∧ n < hi :=
  mem_range_of_isNice hb ((baseRangeC_eq b) ▸ hr) h

/-- Digit-count bounds of the powers from the digit count of `n`. -/
theorem numDigits_pow_bounds {b n m : ℕ} (hb : 2 ≤ b) (hn : n ≠ 0) (hm : numDigits b n = m + 1) :
    2 * m < numDigits b (n ^ 2) ∧ numDigits b (n ^ 2) ≤ 2 * m + 2 ∧
      3 * m < numDigits b (n ^ 3) ∧ numDigits b (n ^ 3) ≤ 3 * m + 3 := by
  have hlo : b ^ m ≤ n := (lt_numDigits_iff hb hn m).mp (by omega)
  have hhi : n < b ^ (m + 1) := (numDigits_le_iff hb hn (m + 1)).mp (by omega)
  have hn2 : n ^ 2 ≠ 0 := pow_ne_zero _ hn
  have hn3 : n ^ 3 ≠ 0 := pow_ne_zero _ hn
  have h2lo : b ^ (2 * m) ≤ n ^ 2 := by
    calc b ^ (2 * m) = (b ^ m) ^ 2 := by rw [← pow_mul, mul_comm]
      _ ≤ n ^ 2 := Nat.pow_le_pow_left hlo 2
  have h2hi : n ^ 2 < b ^ (2 * m + 2) := by
    calc n ^ 2 < (b ^ (m + 1)) ^ 2 := Nat.pow_lt_pow_left hhi (by norm_num)
      _ = b ^ (2 * m + 2) := by rw [← pow_mul]; ring_nf
  have h3lo : b ^ (3 * m) ≤ n ^ 3 := by
    calc b ^ (3 * m) = (b ^ m) ^ 3 := by rw [← pow_mul, mul_comm]
      _ ≤ n ^ 3 := Nat.pow_le_pow_left hlo 3
  have h3hi : n ^ 3 < b ^ (3 * m + 3) := by
    calc n ^ 3 < (b ^ (m + 1)) ^ 3 := Nat.pow_lt_pow_left hhi (by norm_num)
      _ = b ^ (3 * m + 3) := by rw [← pow_mul]; ring_nf
  exact ⟨(lt_numDigits_iff hb hn2 _).mpr h2lo, (numDigits_le_iff hb hn2 _).mpr h2hi,
    (lt_numDigits_iff hb hn3 _).mpr h3lo, (numDigits_le_iff hb hn3 _).mpr h3hi⟩

/-- Inside the range every `n` has `(b − 2) / 5 + 1` digits: the output has
`b` digits, `n²` between `2m + 1` and `2m + 2`, `n³` between `3m + 1` and
`3m + 3`, so `5m + 2 ≤ b ≤ 5m + 5`. -/
theorem numDigits_of_inBaseRange {b n : ℕ} (hb : 2 ≤ b) (h : InBaseRange b n) :
    numDigits b n = (b - 2) / 5 + 1 := by
  unfold InBaseRange at h
  have hn : n ≠ 0 := by
    rintro rfl
    simp [numDigits] at h
    omega
  obtain ⟨m, hm⟩ : ∃ m, numDigits b n = m + 1 :=
    ⟨numDigits b n - 1, by have := numDigits_pos_of_ne_zero hb hn; omega⟩
  obtain ⟨a1, a2, a3, a4⟩ := numDigits_pow_bounds hb hn hm
  omega

/-- L2. Every `n` of a range `[lo, hi)` has the digit count of `hi − 1`. -/
theorem numDigits_eq_of_mem_range {b lo hi n : ℕ} (hb : 2 ≤ b) (hr : baseRange b = some (lo, hi))
    (h1 : lo ≤ n) (h2 : n < hi) : numDigits b n = numDigits b (hi - 1) := by
  rw [numDigits_of_inBaseRange hb (inBaseRange_of_memBaseRange hb ⟨lo, hi, hr, h1, h2⟩),
    numDigits_of_inBaseRange hb (inBaseRange_of_memBaseRange hb ⟨lo, hi, hr, by omega, by omega⟩)]

/-- L2 for a valid coordinate: every `n` of its range has `L` digits, lies in
`[b^(L−1), b^L)`, and its square and cube have at least `2L − 1` and `3L − 2`
digits. -/
theorem Coord.digits_of_mem {c : Coord} {n : ℕ} (hc : c.Valid) (h1 : c.lo ≤ n) (h2 : n < c.hi) :
    numDigits c.b n = c.L ∧ 1 ≤ c.L ∧ c.b ^ (c.L - 1) ≤ n ∧ n < c.b ^ c.L ∧
      2 * c.L - 1 ≤ numDigits c.b (n ^ 2) ∧ 3 * c.L - 2 ≤ numDigits c.b (n ^ 3) := by
  obtain ⟨hb3, -, hr, -⟩ := hc
  have hb : 2 ≤ c.b := by omega
  have hL := numDigits_eq_of_mem_range hb hr h1 h2
  have hin := inBaseRange_of_memBaseRange hb ⟨c.lo, c.hi, hr, h1, h2⟩
  have hn : n ≠ 0 := by
    rintro rfl
    unfold InBaseRange at hin
    simp [numDigits] at hin
    omega
  have hpos := numDigits_pos_of_ne_zero hb hn
  unfold Coord.L
  rw [← hL]
  obtain ⟨m, hm⟩ : ∃ m, numDigits c.b n = m + 1 := ⟨numDigits c.b n - 1, by omega⟩
  obtain ⟨hlo, hhi⟩ := (numDigits_eq_iff hb hn m).mp hm
  obtain ⟨a1, -, a3, -⟩ := numDigits_pow_bounds hb hn hm
  rw [hm]
  refine ⟨rfl, by omega, by simpa using hlo, hhi, by omega, by omega⟩

/-- L2, the side condition: for a valid coordinate and `k ≤ L`, every `n` of the
range has at least `k` digits in `n²` and in `n³`. -/
theorem Coord.le_numDigits_pow {c : Coord} {n k : ℕ} (hc : c.Valid) (h1 : c.lo ≤ n) (h2 : n < c.hi)
    (hk : k ≤ c.L) : k ≤ numDigits c.b (n ^ 2) ∧ k ≤ numDigits c.b (n ^ 3) := by
  obtain ⟨-, hL, -, -, a2, a3⟩ := Coord.digits_of_mem hc h1 h2
  omega

end NiceMidOut
