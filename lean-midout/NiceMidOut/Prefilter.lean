/-
L8, the prefilter (`midPrefilter`, `prefilter` at `cpu.rs:232`): every nice
number passes it, against any `mhi` made of its digits at positions
`≥ k + 2`, and in particular against its top's `mhi`.

The exemption: below `b^⌈(k+2)/2⌉` the prefilter passes by definition
(`midPrefilter_of_lt`). At or above it, `n² ≥ b^(k+2)`, so both powers have
more than `k + 2` digits and the `2k + 4` digits the rule reads are real
digits of `n²` and `n³`, never zero padding (`lt_numDigits_of_not_exempt`);
that is what makes the rule sound there. Below the threshold the rule may
read padding: at base 10 the nice number 69 fails the bare rule at `k = 3`
(`bare rule` below), so the exemption is not removable.

Reused from the earlier library: `lsdBitmap`, `mem_lsdBitmap_of_isNice`,
`suffixDigits_mod`, `digit_mod_pow`, `digit_ne_of_isNice`, `HighDigit`,
`certDigits_eq`, `certPositions_digit`, `lt_numDigits_iff`, `nice_69`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-- The exemption: below `b^⌈(k+2)/2⌉` the prefilter passes. -/
theorem midPrefilter_of_lt {b k n : ℕ} (mhi : Finset ℕ) (h : n < b ^ ((k + 2 + 1) / 2)) :
    midPrefilter b k n mhi = true := by
  unfold midPrefilter
  rw [if_pos h]

/-- At or above the exemption threshold, both powers have more than `k + 2`
digits: the positions `0 .. k + 1` the rule reads are real. -/
theorem lt_numDigits_of_not_exempt {b k n e : ℕ} (hb : 2 ≤ b) (hn : b ^ ((k + 2 + 1) / 2) ≤ n)
    (he : e = 2 ∨ e = 3) : k + 2 < numDigits b (n ^ e) := by
  have hn1 : 1 ≤ n := le_trans (Nat.one_le_pow _ _ (by omega)) hn
  have hpow : b ^ (k + 2) ≤ n ^ e := by
    calc b ^ (k + 2) ≤ b ^ (2 * ((k + 2 + 1) / 2)) := Nat.pow_le_pow_right (by omega) (by omega)
      _ = (b ^ ((k + 2 + 1) / 2)) ^ 2 := by rw [← pow_mul, Nat.mul_comm]
      _ ≤ n ^ 2 := Nat.pow_le_pow_left hn 2
      _ ≤ n ^ e := Nat.pow_le_pow_right hn1 (by omega)
  exact (lt_numDigits_iff hb (pow_ne_zero e (by omega)) (k + 2)).mpr hpow

/-- **L8.** A nice `n` passes the prefilter at `k` against any `mhi` whose
elements are digits of `n²` or `n³` at positions `≥ k + 2`. No hypothesis on
the digit counts: below the exemption threshold it passes by definition,
above it the counts follow (`lt_numDigits_of_not_exempt`). -/
theorem midPrefilter_of_isNice {b k n : ℕ} {mhi : Finset ℕ} (hb : 2 ≤ b) (h : IsNice b n)
    (hmhi : ∀ x ∈ mhi, HighDigit b (k + 2) n x) : midPrefilter b k n mhi = true := by
  by_cases hex : n < b ^ ((k + 2 + 1) / 2)
  · exact midPrefilter_of_lt mhi hex
  have hn : b ^ ((k + 2 + 1) / 2) ≤ n := Nat.le_of_not_lt hex
  have l2 := lt_numDigits_of_not_exempt hb hn (Or.inl rfl)
  have l3 := lt_numDigits_of_not_exempt hb hn (Or.inr rfl)
  have hr2 : n % b ^ (k + 2) * (n % b ^ (k + 2)) % b ^ (k + 2) = n ^ 2 % b ^ (k + 2) := by
    rw [sq, ← Nat.mul_mod]
  have hr3 : n ^ 2 % b ^ (k + 2) * (n % b ^ (k + 2)) % b ^ (k + 2) = n ^ 3 % b ^ (k + 2) := by
    rw [← Nat.mul_mod, ← pow_succ]
  -- the 2k + 4 digits are distinct
  have hbm := mem_lsdBitmap_of_isNice hb (by omega) (by omega) h (k := k + 2)
  unfold lsdBitmap at hbm
  rw [Finset.mem_filter, suffixDigits_mod] at hbm
  have hnd := hbm.2
  -- the four middle digits miss mhi
  have hmid : ∀ e, (e = 2 ∨ e = 3) → ∀ j, k ≤ j → j < k + 2 → digit b (n ^ e) j ∉ mhi := by
    intro e he j hj1 hj2 hx
    obtain ⟨e', j', he', hj', hlt, hd⟩ := hmhi _ hx
    exact digit_ne_of_isNice hb h he' he hlt (by rcases he with rfl | rfl <;> omega) (by omega) hd
  unfold midPrefilter
  rw [if_neg hex]
  simp only [hr2, hr3, Bool.and_eq_true, decide_eq_true_eq, List.all_eq_true]
  refine ⟨?_, ?_⟩
  · have hm2 : (List.range (k + 2)).map (digit b (n ^ 2 % b ^ (k + 2))) = lowDigits b (k + 2) (n ^ 2) :=
      List.map_congr_left fun j hj => digit_mod_pow (List.mem_range.mp hj)
    have hm3 : (List.range (k + 2)).map (digit b (n ^ 3 % b ^ (k + 2))) = lowDigits b (k + 2) (n ^ 3) :=
      List.map_congr_left fun j hj => digit_mod_pow (List.mem_range.mp hj)
    rw [hm2, hm3]
    exact hnd
  · intro j hj
    rw [List.mem_range'_1] at hj
    rw [digit_mod_pow (by omega : j < k + 2), digit_mod_pow (by omega : j < k + 2)]
    exact ⟨hmid 2 (Or.inl rfl) j hj.1 (by omega), hmid 3 (Or.inr rfl) j hj.1 (by omega)⟩

/-- Every element of `certDigits b a c cap` is, for every `n ∈ [a, c]`, a
digit of `n²` or `n³` at a position `≥ cap` (the `mhi` of a top is
`certDigits` at cap `k + 2`, whether or not the certificate has repeats). -/
theorem certDigits_mem_highDigit {b a c cap n x : ℕ} (hb : 2 ≤ b) (han : a ≤ n) (hnc : n ≤ c)
    (hx : x ∈ certDigits b a c cap) : HighDigit b cap n x := by
  rw [certDigits_eq hb han hnc, List.mem_append, List.mem_map, List.mem_map] at hx
  rcases hx with ⟨i, hi, rfl⟩ | ⟨i, hi, rfl⟩
  · obtain ⟨hc, hlt, -⟩ := certPositions_digit hb han hnc hi
    exact ⟨2, i, Or.inl rfl, hc, hlt, rfl⟩
  · obtain ⟨hc, hlt, -⟩ := certPositions_digit hb han hnc hi
    exact ⟨3, i, Or.inr rfl, hc, hlt, rfl⟩

/-- A top of `unitTops` carries the certificate of its interval at `k` as its
mask and `certDigits` at `k + 2` as its `mhi`. -/
theorem cert_of_mem_unitTops {b lo hi f0 k u : ℕ} {t : Top} (ht : t ∈ unitTops b lo hi f0 k u) :
    cert b t.lo t.hi k = some t.mask ∧ t.mhi = (certDigits b t.lo t.hi (k + 2)).toFinset := by
  unfold unitTops at ht
  rw [List.mem_filterMap] at ht
  obtain ⟨x, -, hx⟩ := ht
  unfold topCertSplit at hx
  cases hc : cert b x.2.1 x.2.2 k with
  | none => rw [hc] at hx; cases hx
  | some m =>
    rw [hc] at hx
    simp only [Option.map_some, Option.some.injEq] at hx
    subst hx
    exact ⟨hc, rfl⟩

/-- **L8 for a top.** A nice `n` in the interval of a top of `unitTops`
passes the prefilter against that top's `mhi`. -/
theorem midPrefilter_of_mem_unitTops {b lo hi f0 k u n : ℕ} {t : Top} (hb : 2 ≤ b)
    (h : IsNice b n) (ht : t ∈ unitTops b lo hi f0 k u) (hlo : t.lo ≤ n) (hhi : n ≤ t.hi) :
    midPrefilter b k n t.mhi = true := by
  apply midPrefilter_of_isNice hb h
  intro x hx
  rw [(cert_of_mem_unitTops ht).2, List.mem_toFinset] at hx
  exact certDigits_mem_highDigit hb hlo hhi hx

/-- The exemption is needed: the rule without it rejects base 10's nice
number 69 at `k = 3` (`69² = 4761` has no digit at position 4, read as a
zero, which `69³ = 328509` also has), while the prefilter passes it. -/
theorem bare_rule_rejects_69 :
    (let m := 10 ^ (3 + 2)
     let r2 := 69 * 69 % m
     let r3 := r2 * 69 % m
     let ds := (List.range (3 + 2)).map (digit 10 r2) ++ (List.range (3 + 2)).map (digit 10 r3)
     decide ds.Nodup) = false ∧ IsNice 10 69 ∧ midPrefilter 10 3 69 ∅ = true :=
  ⟨by decide, nice_69, by decide⟩

end NiceMidOut
