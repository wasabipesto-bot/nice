/-
L5, the bottoms of the middle-out join: parents and children.

- (a) Completeness: every nice `n`'s residue `n mod b^(k−1)`, with its low
  output digits `lowSet b n (k − 1)` as the mask, is a parent of `n`'s slice
  `n div b^f0 mod b^(k−1−f0)` (`mkParent_mem_parents_of_isNice`).
- (a) Exactness: the bottom list is exactly the residues below `b^k` with the
  forced digits whose `2k` low output digits are distinct, each with those
  digits as its mask (`mem_bottomsSorted_iff`, `mem_parents_iff`).
- (b) The child at unit `d`: the parent record's two affine expressions are
  digit `k − 1` of the child's square and cube (`childMask_digits`); for a
  nice `n` its child is certified with mask `lowSet b n k`
  (`childMask_of_isNice`), and it is a child of its class
  (`mem_kidsOf_of_isNice`).

Reused from the earlier library: `botDfs`, `botDigits_eq` (JOIN-2's digit
step, itself AFF-1), `mem_botDfs_of_isNice` (JOIN-2), `lowSet`,
`lowSet_succ`, `mem_lowSet`, `digit_ne_of_isNice`, `digit_mod_pow`,
`digit_pow_mod_pow`, `mod_pow_div_pow`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-! ### Digit bookkeeping -/

/-- Digit `i` of `n`, read off the block `n div b^f0 mod b^w` that holds
positions `[f0, f0 + w)`. -/
theorem block_digit {b n f0 w i : ℕ} (hi1 : f0 ≤ i) (hi2 : i < f0 + w) :
    n / b ^ f0 % b ^ w / b ^ (i - f0) % b = digit b n i := by
  rw [mod_pow_div_pow (by omega : i - f0 ≤ w),
    Nat.mod_mod_of_dvd _ (dvd_pow_self b (by omega : w - (i - f0) ≠ 0)), Nat.div_div_eq_div_mul,
    ← pow_add, Nat.add_sub_cancel' hi1]
  rfl

/-- The residue one digit deeper: `n mod b^(j+1) = n mod b^j + digit_j · b^j`. -/
theorem mod_pow_succ_eq (b n j : ℕ) : n % b ^ j + digit b n j * b ^ j = n % b ^ (j + 1) := by
  rw [Nat.mod_pow_succ]; unfold digit; ring

/-- The unit of `n` (digits `[f0, k)`) is its slice (digits `[f0, k − 1)`)
plus digit `k − 1` at position `k − 1 − f0`. -/
theorem unit_eq_slice_add {b n f0 k : ℕ} (hf : f0 < k) :
    n / b ^ f0 % b ^ (k - f0) =
      n / b ^ f0 % b ^ (k - 1 - f0) + digit b n (k - 1) * b ^ (k - 1 - f0) := by
  have h := mod_pow_succ_eq b (n / b ^ f0) (k - 1 - f0)
  rw [show k - 1 - f0 + 1 = k - f0 by omega] at h
  rw [← h]
  unfold digit
  rw [Nat.div_div_eq_div_mul, ← pow_add, show f0 + (k - 1 - f0) = k - 1 by omega]

/-- `n` is its top `n div b^k`, its digit `k − 1` and its residue mod
`b^(k−1)`, the way a survivor is assembled (`sliceSurvivors`). -/
theorem eq_top_unit_residue (b n k : ℕ) (hk : 1 ≤ k) :
    n = n / b ^ k * b ^ k + digit b n (k - 1) * b ^ (k - 1) + n % b ^ (k - 1) := by
  have h := mod_pow_succ_eq b n (k - 1)
  rw [Nat.sub_add_cancel hk] at h
  rw [Nat.add_assoc, Nat.add_comm (digit b n (k - 1) * b ^ (k - 1)), h]
  exact (Nat.div_add_mod' n (b ^ k)).symm

/-! ### L5(a): every nice number's residue is a parent -/

/-- The bottom list of depth `k` with digits `[f, k)` forced to `n`'s holds
`n`'s residue mod `b^k` with its low output digits, for a nice `n` with at
least `k` digits in both powers. -/
theorem mem_bottomsSorted_of_isNice {b k f n : ℕ} (hb : 2 ≤ b) (h : IsNice b n)
    (h2 : k ≤ numDigits b (n ^ 2)) (h3 : k ≤ numDigits b (n ^ 3)) :
    (n % b ^ k, lowSet b n k) ∈ bottomsSorted b k f (n / b ^ f % b ^ (k - f)) := by
  unfold bottomsSorted
  rw [(List.mergeSort_perm _ _).mem_iff]
  have hm := mem_botDfs_of_isNice (f0 := f) (pp := k - f) (v := n / b ^ f % b ^ (k - f)) hb h
    (fun i hi1 hi2 => block_digit hi1 hi2) k 0 (by omega) (by omega)
  simpa only [Nat.zero_add, pow_zero, Nat.mod_one, lowSet_zero] using hm

/-- **L5(a), completeness.** For a nice `n` whose powers have at least
`k − 1` digits, `n`'s parent record (residue `n mod b^(k−1)`, mask
`lowSet b n (k − 1)`) is among the parents of `n`'s slice. -/
theorem mkParent_mem_parents_of_isNice {b n : ℕ} {sh : Shape} (hb : 2 ≤ b) (h : IsNice b n)
    (h2 : sh.k - 1 ≤ numDigits b (n ^ 2))
    (h3 : sh.k - 1 ≤ numDigits b (n ^ 3)) :
    mkParent b sh.k (n % b ^ (sh.k - 1), lowSet b n (sh.k - 1)) ∈
      parents b sh (n / b ^ sh.f0 % b ^ (sh.k - 1 - sh.f0)) :=
  List.mem_map_of_mem (mem_bottomsSorted_of_isNice hb h h2 h3)

/-- The parent record's fields, as `sliceSurvivors` reads them. -/
theorem mkParent_fields (b k : ℕ) (q : ℕ × Finset ℕ) :
    (mkParent b k q).r = q.1 ∧ (mkParent b k q).mask = q.2 ∧ (mkParent b k q).cls = q.1 % (b - 1) :=
  ⟨rfl, rfl, rfl⟩

/-! ### L5(b): the child's two new digits -/

/-- **L5(b).** For `k ≥ 2`, any residue `r` and unit digit `d`, the parent
record's affine expressions `(c2 + a2·d) mod b` and `(c3 + a3·d) mod b` are
digit `k − 1` of `(r + d·b^(k−1))²` and of its cube (`parents_threads` and
`child_mask`, `cpu.rs:521–544`). No bound on `r` is needed. -/
theorem childMask_digits {b k : ℕ} (q : ℕ × Finset ℕ) (d : ℕ) (hb : 0 < b) (hk : 2 ≤ k) :
    ((mkParent b k q).c2 + (mkParent b k q).a2 * d) % b =
        digit b ((q.1 + d * b ^ (k - 1)) ^ 2) (k - 1) ∧
      ((mkParent b k q).c3 + (mkParent b k q).a3 * d) % b =
        digit b ((q.1 + d * b ^ (k - 1)) ^ 3) (k - 1) := by
  have hg := botDigits_eq (b := b) (r := q.1) (j := k - 1) (d := d) hb (fun h => absurd h (by omega))
  unfold botDigits at hg
  rw [if_neg (by omega)] at hg
  obtain ⟨h1, h2⟩ := Prod.mk.inj hg
  refine ⟨?_, ?_⟩
  · rw [← h1]
    simp only [mkParent, digit]
    rw [Nat.mul_comm d]
  · have ha3 : 3 * (q.1 % b) * (q.1 % b) % b = 3 * (q.1 % b * (q.1 % b) % b) % b := by
      rw [Nat.mul_mod_mod 3 (q.1 % b * (q.1 % b)) b, Nat.mul_assoc]
    rw [← h2]
    simp only [mkParent, digit]
    rw [ha3, Nat.mul_comm d]

/-- **L5(b) for a nice number.** For a nice `n`, `k ≥ 2`, and both powers
with at least `k` digits, the child of `n`'s parent at `n`'s digit `k − 1`
is certified, with mask `n`'s low output digits below `k`. -/
theorem childMask_of_isNice {b k n : ℕ} (hb : 2 ≤ b) (h : IsNice b n) (hk : 2 ≤ k)
    (h2 : k ≤ numDigits b (n ^ 2)) (h3 : k ≤ numDigits b (n ^ 3)) :
    childMask b (mkParent b k (n % b ^ (k - 1), lowSet b n (k - 1))) (digit b n (k - 1)) =
      some (lowSet b n k) := by
  obtain ⟨e2, e3⟩ := childMask_digits (b := b) (k := k) (n % b ^ (k - 1), lowSet b n (k - 1))
    (digit b n (k - 1)) (by omega) hk
  have hres := mod_pow_succ_eq b n (k - 1)
  rw [Nat.sub_add_cancel (by omega : 1 ≤ k)] at hres
  simp only at e2 e3
  rw [hres, ← digit_pow_mod_pow 2 (by omega : k - 1 < k)] at e2
  rw [hres, ← digit_pow_mod_pow 3 (by omega : k - 1 < k)] at e3
  have hne : digit b (n ^ 2) (k - 1) ≠ digit b (n ^ 3) (k - 1) :=
    digit_ne_of_isNice hb h (Or.inl rfl) (Or.inr rfl) (by omega) (by omega) (by omega)
  have hnew : ∀ e, (e = 2 ∨ e = 3) → digit b (n ^ e) (k - 1) ∉ lowSet b n (k - 1) := by
    intro e he hmem
    obtain ⟨e', i, he', hi, heq⟩ := mem_lowSet.mp hmem
    exact digit_ne_of_isNice hb h he' he (by rcases he' with rfl | rfl <;> omega)
      (by rcases he with rfl | rfl <;> omega) (by omega) heq
  unfold childMask
  simp only [e2, e3]
  rw [if_neg (by
    rintro (h' | h' | h')
    · exact hne h'
    · exact hnew 2 (Or.inl rfl) h'
    · exact hnew 3 (Or.inr rfl) h')]
  have hs := lowSet_succ b n (k - 1)
  rw [Nat.sub_add_cancel (by omega : 1 ≤ k)] at hs
  rw [hs]
  rfl

/-- **L5, the form the composition uses.** For a nice `n` of a shape with
`2 ≤ k` and both powers with at least `k` digits: among the
parents of `n`'s slice of class `n mod b^(k−1) mod (b − 1)`, at `n`'s digit
`k − 1`, the child `(n mod b^(k−1), lowSet b n k)` is listed. -/
theorem mem_kidsOf_of_isNice {b n : ℕ} {sh : Shape} (hb : 2 ≤ b) (h : IsNice b n)
    (hk : 2 ≤ sh.k) (h2 : sh.k ≤ numDigits b (n ^ 2))
    (h3 : sh.k ≤ numDigits b (n ^ 3)) :
    (n % b ^ (sh.k - 1), lowSet b n sh.k) ∈
      kidsOf b ((parents b sh (n / b ^ sh.f0 % b ^ (sh.k - 1 - sh.f0))).filter
        fun p => p.cls = n % b ^ (sh.k - 1) % (b - 1)) (digit b n (sh.k - 1)) := by
  unfold kidsOf
  rw [List.mem_filterMap]
  refine ⟨mkParent b sh.k (n % b ^ (sh.k - 1), lowSet b n (sh.k - 1)), ?_, ?_⟩
  · rw [List.mem_filter]
    exact ⟨mkParent_mem_parents_of_isNice hb h (by omega) (by omega), by simp [mkParent]⟩
  · rw [childMask_of_isNice hb h hk h2 h3]
    rfl

end NiceMidOut
