/-
The tops' half of a slice's join for the composition (L10): L4 and L6
packaged in the form `sliceSurvivors` reads them, and the converse facts a
listed top gives about every `n` of its interval.

- `n_split`: `n = (n / b^k)·b^k + d·b^(k−1) + r` with `d` digit `k − 1` and
  `r = n mod b^(k−1)`, the form `sliceSurvivors` rebuilds `n` in.
- `unitTops_prefix`: for a non-empty range `lo < hi` (with `hi = 0` the
  model's `hi − 1` would admit `n = 0`), every `n` in a listed top's interval
  lies in the range,
  has lead `t.h` and unit `u` (so a survivor is a number of its slice).
- `probed_top_of_isNice`: for a nice `n` of the range and `f0 < k`, the probes
  of unit `d` against class `r mod (b − 1)` hold a top of lead `n / b^k` whose
  interval holds `n`, whose mask digits are high digits of `n` at `≥ k` and whose
  `mhi` digits are high digits at `≥ k + 2`.
-/
import NiceMidOut.TopsProofs
import NiceMidOut.ClassesProofs

namespace NiceMidOut

open NiceSearch

/-- `n` from its top, its digit `k − 1` and its residue mod `b^(k−1)`. -/
theorem n_split {b k n : ℕ} (hk : 1 ≤ k) :
    n = n / b ^ k * b ^ k + n / b ^ (k - 1) % b * b ^ (k - 1) + n % b ^ (k - 1) := by
  have h1 : n / b ^ (k - 1) / b = n / b ^ k := by
    rw [Nat.div_div_eq_div_mul, ← pow_succ, Nat.sub_add_cancel hk]
  have h2 := Nat.div_add_mod' (n / b ^ (k - 1)) b
  have h3 := Nat.div_add_mod' n (b ^ (k - 1))
  rw [h1] at h2
  have hp : b ^ k = b * b ^ (k - 1) := by rw [← pow_succ', Nat.sub_add_cancel hk]
  calc n = n / b ^ (k - 1) * b ^ (k - 1) + n % b ^ (k - 1) := h3.symm
    _ = (n / b ^ k * b + n / b ^ (k - 1) % b) * b ^ (k - 1) + n % b ^ (k - 1) := by rw [h2]
    _ = _ := by rw [hp]; ring

/-- Every `n` of a listed top's interval is in the range, with the top's lead
and the unit asked for. -/
theorem unitTops_prefix {b lo hi f0 k u n : ℕ} {t : Top} (hb : 1 ≤ b) (hfk : f0 ≤ k) (hlh : lo < hi)
    (hu : u < b ^ (k - f0)) (ht : t ∈ unitTops b lo hi f0 k u) (hn1 : t.lo ≤ n) (hn2 : n ≤ t.hi) :
    lo ≤ n ∧ n < hi ∧ n / b ^ f0 = t.h * b ^ (k - f0) + u ∧ n / b ^ k = t.h ∧
      n / b ^ f0 % b ^ (k - f0) = u := by
  obtain ⟨hl, -, -⟩ := mem_unitTops.mp ht
  obtain ⟨-, -, ha, hc, -⟩ := mem_unitLeads.mp hl
  have hw : 0 < b ^ f0 := Nat.pow_pos (by omega)
  have hn1' : (t.h * b ^ (k - f0) + u) * b ^ f0 ≤ n := le_trans (ha ▸ le_max_left _ _) hn1
  have hn2' : n ≤ (t.h * b ^ (k - f0) + u) * b ^ f0 + b ^ f0 - 1 :=
    le_trans hn2 (hc ▸ min_le_left _ _)
  have hlo : lo ≤ n := le_trans (ha ▸ le_max_right _ _) hn1
  have hhi : n ≤ hi - 1 := le_trans hn2 (hc ▸ min_le_right _ _)
  have hhi0 : 0 < hi := by omega
  have hp : n / b ^ f0 = t.h * b ^ (k - f0) + u := by
    apply Nat.div_eq_of_lt_le
    · exact hn1'
    · rw [Nat.add_mul, one_mul]; omega
  have hd : n / b ^ k = t.h := by
    rw [show b ^ k = b ^ f0 * b ^ (k - f0) by rw [← pow_add, Nat.add_sub_cancel' hfk],
      ← Nat.div_div_eq_div_mul, hp, Nat.add_comm, Nat.add_mul_div_right _ _ (by omega),
      Nat.div_eq_of_lt hu, zero_add]
  refine ⟨hlo, by omega, hp, hd, ?_⟩
  rw [hp, Nat.add_comm, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hu]

/-- L4 + L6 for the composition. A nice `n` of the range `[lo, hi)`, with
`f0 < k`, slice `pip = n / b^f0 mod b^(k−1−f0)`, unit digit `d = n / b^(k−1) mod b`
and residue `r = n mod b^(k−1)`: among the probes `sliceSurvivors` makes for
class `r mod (b − 1)` and unit `d`, a top of lead `n / b^k` whose interval
holds `n`, with the mask's digits high digits of `n` at positions `≥ k` and
`mhi`'s at `≥ k + 2`. -/
theorem probed_top_of_isNice {b lo hi f0 k n : ℕ} (hb : 2 ≤ b) (hfk : f0 < k)
    (hlo : lo ≤ n) (hhi : n < hi) (h : IsNice b n) :
    ∃ t ∈ probesOf b
        (unitTops b lo hi f0 k (n / b ^ f0 % b ^ (k - 1 - f0) + n / b ^ (k - 1) % b * b ^ (k - 1 - f0)))
        (n % b ^ (k - 1) % (b - 1)) (n / b ^ (k - 1) % b),
      t.h = n / b ^ k ∧ t.lo ≤ n ∧ n ≤ t.hi ∧ (∀ x ∈ t.mask, HighDigit b k n x) ∧
        (∀ x ∈ t.mhi, HighDigit b (k + 2) n x) := by
  obtain ⟨t, ht, hh, -, -, h1, h2⟩ := mem_unitTops_slice_of_isNice hb hfk hlo hhi h
  obtain ⟨hm, hmh, -⟩ := highDigit_of_mem_unitTops hb ht h1 h2
  refine ⟨t, mem_probesOf_of_isNice (k := k) hb h ?_ ht, hh, h1, h2, hm, hmh⟩
  rw [hh]
  exact n_split (by omega)

end NiceMidOut
