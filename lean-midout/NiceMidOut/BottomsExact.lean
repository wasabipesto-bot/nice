/-
L5(a), exactness: the bottom list (and so a slice's parent list) is exactly
the residues `r < b^k` with the forced digits whose `2k` low output digits
are distinct (`botCertDirect b r k = some mask`, the Rust's
`bot_cert_direct`), each with those digits as its mask. Nothing in it needs
`n` to be nice; the completeness for nice numbers (`Bottoms`) is the special
case where the low digits are distinct because all of `n`'s are.

Reused from the earlier library: `botDfs`, `botDigits_eq`, `lowSet`,
`lowSet_zero`, `lowSet_succ`, `mem_lowSet`, `digit_eq_of_modEq`,
`digit_pow_mod_pow`.
-/
import NiceMidOut.Bottoms

namespace NiceMidOut

open NiceSearch

/-- The output digits of `x²` and `x³` below position `j` are pairwise
distinct (as positions of the two powers). -/
def LowDistinct (b x j : ℕ) : Prop :=
  ∀ e e' i i', (e = 2 ∨ e = 3) → (e' = 2 ∨ e' = 3) → i < j → i' < j → ¬ (e = e' ∧ i = i') →
    digit b (x ^ e) i ≠ digit b (x ^ e') i'

theorem lowDistinct_zero (b x : ℕ) : LowDistinct b x 0 := by
  intro _ _ i _ _ _ hi; omega

/-- `botCertDirect`'s digit list holds exactly `lowSet`. -/
theorem botCertDirect_toFinset (b x j : ℕ) :
    ((List.range j).map (digit b (x ^ 2)) ++ (List.range j).map (digit b (x ^ 3))).toFinset =
      lowSet b x j := by
  ext z
  simp [lowSet, List.mem_toFinset]

/-- `botCertDirect`'s digit list has no repeat iff the low digits are distinct. -/
theorem botCertDirect_nodup_iff (b x j : ℕ) :
    ((List.range j).map (digit b (x ^ 2)) ++ (List.range j).map (digit b (x ^ 3))).Nodup ↔
      LowDistinct b x j := by
  rw [List.nodup_append, List.nodup_map_iff_inj_on List.nodup_range,
    List.nodup_map_iff_inj_on List.nodup_range]
  constructor
  · rintro ⟨h2, h3, h23⟩ e e' i i' he he' hi hi' hne hd
    rcases he with rfl | rfl <;> rcases he' with rfl | rfl
    · exact hne ⟨rfl, h2 i (List.mem_range.mpr hi) i' (List.mem_range.mpr hi') hd⟩
    · exact h23 _ (List.mem_map_of_mem (List.mem_range.mpr hi)) _
        (List.mem_map_of_mem (List.mem_range.mpr hi')) hd
    · exact h23 _ (List.mem_map_of_mem (List.mem_range.mpr hi')) _
        (List.mem_map_of_mem (List.mem_range.mpr hi)) hd.symm
    · exact hne ⟨rfl, h3 i (List.mem_range.mpr hi) i' (List.mem_range.mpr hi') hd⟩
  · intro h
    refine ⟨?_, ?_, ?_⟩
    · intro i hi i' hi' hd
      by_contra hne
      exact h 2 2 i i' (Or.inl rfl) (Or.inl rfl) (List.mem_range.mp hi) (List.mem_range.mp hi')
        (fun h' => hne h'.2) hd
    · intro i hi i' hi' hd
      by_contra hne
      exact h 3 3 i i' (Or.inr rfl) (Or.inr rfl) (List.mem_range.mp hi) (List.mem_range.mp hi')
        (fun h' => hne h'.2) hd
    · intro y hy z hz hyz
      rw [List.mem_map] at hy hz
      obtain ⟨i, hi, rfl⟩ := hy
      obtain ⟨i', hi', rfl⟩ := hz
      exact h 2 3 i i' (Or.inl rfl) (Or.inr rfl) (List.mem_range.mp hi) (List.mem_range.mp hi')
        (by omega) hyz

/-- **`bot_cert_direct` as a predicate**: it accepts `x` at depth `j` with
mask `m` iff `x`'s low output digits below `j` are distinct and `m` is them. -/
theorem botCertDirect_eq_some_iff {b x j : ℕ} {m : Finset ℕ} :
    botCertDirect b x j = some m ↔ LowDistinct b x j ∧ m = lowSet b x j := by
  unfold botCertDirect
  simp only
  rw [← botCertDirect_nodup_iff, ← botCertDirect_toFinset b x j]
  split_ifs with h
  · simp only [Option.some.injEq]
    exact ⟨fun h' => ⟨h, h'.symm⟩, fun h' => h'.2.symm⟩
  · simp only [false_iff]
    exact fun h' => h h'.1

/-- Low digits depend only on the residue. -/
theorem lowSet_congr {b x y j : ℕ} (h : x ≡ y [MOD b ^ j]) : lowSet b x j = lowSet b y j := by
  ext z
  rw [mem_lowSet, mem_lowSet]
  constructor
  · rintro ⟨e, i, he, hi, hd⟩
    exact ⟨e, i, he, hi, by rw [← hd]; exact (digit_eq_of_modEq (h.pow e) hi).symm⟩
  · rintro ⟨e, i, he, hi, hd⟩
    exact ⟨e, i, he, hi, by rw [← hd]; exact digit_eq_of_modEq (h.pow e) hi⟩

theorem lowDistinct_congr {b x y j : ℕ} (h : x ≡ y [MOD b ^ j]) (hx : LowDistinct b x j) :
    LowDistinct b y j := by
  intro e e' i i' he he' hi hi' hne
  rw [← digit_eq_of_modEq (h.pow e) hi, ← digit_eq_of_modEq (h.pow e') hi']
  exact hx e e' i i' he he' hi hi' hne

/-- One more position: distinct below `j`, two new distinct digits at `j`
outside the low set, gives distinct below `j + 1`. -/
theorem lowDistinct_succ {b x j : ℕ} (hx : LowDistinct b x j)
    (hne : digit b (x ^ 2) j ≠ digit b (x ^ 3) j)
    (hn2 : digit b (x ^ 2) j ∉ lowSet b x j) (hn3 : digit b (x ^ 3) j ∉ lowSet b x j) :
    LowDistinct b x (j + 1) := by
  have hnew : ∀ e, (e = 2 ∨ e = 3) → digit b (x ^ e) j ∉ lowSet b x j := by
    rintro e (rfl | rfl)
    · exact hn2
    · exact hn3
  intro e e' i i' he he' hi hi' hneq hd
  rcases Nat.lt_or_ge i j with hij | hij <;> rcases Nat.lt_or_ge i' j with hij' | hij'
  · exact hx e e' i i' he he' hij hij' hneq hd
  · have h1 : i' = j := by omega
    rw [h1] at hd
    exact hnew e' he' (mem_lowSet.mpr ⟨e, i, he, hij, hd⟩)
  · have h1 : i = j := by omega
    rw [h1] at hd
    exact hnew e he (mem_lowSet.mpr ⟨e', i', he', hij', hd.symm⟩)
  · have h1 : i = j := by omega
    have h2 : i' = j := by omega
    rw [h1, h2] at hd hneq
    rcases he with rfl | rfl <;> rcases he' with rfl | rfl
    · exact hneq ⟨rfl, rfl⟩
    · exact hne hd
    · exact hne hd.symm
    · exact hneq ⟨rfl, rfl⟩

/-! ### The walk's two directions -/

/-- Every residue with distinct low digits and the forced digits is reached
by the walk, with its low digits as its mask (JOIN-2's induction without
niceness). -/
theorem mem_botDfs_of_lowDistinct {b f0 pp v x : ℕ} (hb : 2 ≤ b) :
    ∀ fuel j, LowDistinct b x (j + fuel) →
      (∀ i, f0 ≤ i → i < f0 + pp → j ≤ i → i < j + fuel → v / b ^ (i - f0) % b = digit b x i) →
      (x % b ^ (j + fuel), lowSet b x (j + fuel)) ∈
        botDfs b f0 pp v fuel j (x % b ^ j) (lowSet b x j) := by
  intro fuel
  induction fuel with
  | zero => intro j _ _; simp [botDfs]
  | succ fuel ih =>
    intro j hd hv
    have hres := mod_pow_succ_eq b x j
    have hg := botDigits_eq (b := b) (r := x % b ^ j) (j := j) (d := digit b x j) (by omega)
      (by intro hj; subst hj; rw [Nat.pow_zero, Nat.mod_one])
    rw [hres, ← digit_pow_mod_pow 2 (by omega : j < j + 1),
      ← digit_pow_mod_pow 3 (by omega : j < j + 1)] at hg
    have hne : digit b (x ^ 2) j ≠ digit b (x ^ 3) j :=
      hd 2 3 j j (Or.inl rfl) (Or.inr rfl) (by omega) (by omega) (by omega)
    have hnew : ∀ e, (e = 2 ∨ e = 3) → digit b (x ^ e) j ∉ lowSet b x j := by
      intro e he hmem
      obtain ⟨e', i, he', hi, heq⟩ := mem_lowSet.mp hmem
      exact hd e' e i j he' he (by omega) (by omega) (by omega) heq
    rw [botDfs, List.mem_flatMap]
    refine ⟨digit b x j, ?_, ?_⟩
    · split_ifs with hf
      · rw [List.mem_singleton]; exact (hv j hf.1 hf.2 le_rfl (by omega)).symm
      · exact List.mem_range.mpr (digit_lt_base (by omega) _ _)
    · rw [hg]
      simp only
      rw [if_neg (by
        rintro (h' | h' | h')
        · exact hne h'
        · exact hnew 2 (Or.inl rfl) h'
        · exact hnew 3 (Or.inr rfl) h'), hres, ← lowSet_succ]
      have := ih (j + 1) (by rwa [show j + 1 + fuel = j + (fuel + 1) by omega])
        (fun i h1 h2 h3 h4 => hv i h1 h2 (by omega) (by omega))
      rwa [show j + 1 + fuel = j + (fuel + 1) by omega] at this

/-- Every member of the walk from a residue `r < b^j` with distinct low
digits and mask `lowSet b r j` extends `r`, stays below `b^(j + fuel)`, has
distinct low digits, its low digits as mask, and the forced digits. -/
theorem botDfs_sound {b f0 pp v : ℕ} (hb : 2 ≤ b) :
    ∀ fuel j r q, r < b ^ j → LowDistinct b r j → q ∈ botDfs b f0 pp v fuel j r (lowSet b r j) →
      q.1 < b ^ (j + fuel) ∧ q.1 % b ^ j = r ∧ LowDistinct b q.1 (j + fuel) ∧
        q.2 = lowSet b q.1 (j + fuel) ∧
        ∀ i, f0 ≤ i → i < f0 + pp → j ≤ i → i < j + fuel → digit b q.1 i = v / b ^ (i - f0) % b := by
  intro fuel
  induction fuel with
  | zero =>
    intro j r q hr hd hq
    simp only [botDfs, List.mem_singleton] at hq
    subst hq
    exact ⟨hr, Nat.mod_eq_of_lt hr, hd, rfl, fun i _ _ h1 h2 => absurd h2 (by omega)⟩
  | succ fuel ih =>
    intro j r q hr hd hq
    rw [botDfs, List.mem_flatMap] at hq
    obtain ⟨d, hdm, hq⟩ := hq
    have hdb : d < b ∧ (f0 ≤ j ∧ j < f0 + pp → d = v / b ^ (j - f0) % b) := by
      split_ifs at hdm with hf
      · rw [List.mem_singleton] at hdm
        exact ⟨by rw [hdm]; exact Nat.mod_lt _ (by omega), fun _ => hdm⟩
      · exact ⟨List.mem_range.mp hdm, fun h => absurd h hf⟩
    have hBj : 0 < b ^ j := Nat.pow_pos (by omega)
    set r' := r + d * b ^ j with hr'
    have hr'lt : r' < b ^ (j + 1) := by
      rw [hr', pow_succ']
      calc r + d * b ^ j < b ^ j + d * b ^ j := Nat.add_lt_add_right hr _
        _ = (d + 1) * b ^ j := by ring
        _ ≤ b * b ^ j := Nat.mul_le_mul_right _ hdb.1
    have hmod' : r' % b ^ j = r := by rw [hr', Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hr]
    have hmod : r' ≡ r [MOD b ^ j] := by
      show r' % b ^ j = r % b ^ j
      rw [hmod', Nat.mod_eq_of_lt hr]
    have hdig : digit b r' j = d := by
      unfold digit
      rw [hr', Nat.add_mul_div_right _ _ hBj, Nat.div_eq_of_lt hr, Nat.zero_add,
        Nat.mod_eq_of_lt hdb.1]
    have hg := botDigits_eq (b := b) (r := r) (j := j) (d := d) (by omega)
      (by intro hj; subst hj; rw [Nat.pow_zero] at hr; omega)
    rw [← hr'] at hg
    rw [hg] at hq
    simp only at hq
    split_ifs at hq with hc
    · simp at hq
    have hL : lowSet b r j = lowSet b r' j := lowSet_congr hmod.symm
    rw [not_or, not_or, hL] at hc
    have hd' : LowDistinct b r' (j + 1) :=
      lowDistinct_succ (lowDistinct_congr hmod.symm hd) hc.1 hc.2.1 hc.2.2
    rw [hL, ← lowSet_succ] at hq
    obtain ⟨h1, h2, h3, h4, h5⟩ := ih (j + 1) r' q hr'lt hd' hq
    rw [show j + 1 + fuel = j + (fuel + 1) by omega] at h1 h3 h4
    refine ⟨h1, ?_, h3, h4, ?_⟩
    · rw [← hmod', ← h2, Nat.mod_mod_of_dvd _ (pow_dvd_pow b (by omega : j ≤ j + 1))]
    · intro i hi1 hi2 hi3 hi4
      rcases Nat.lt_or_ge j i with hji | hji
      · exact h5 i hi1 hi2 hji (by omega)
      · have hij : i = j := by omega
        rw [hij] at hi1 hi2 ⊢
        rw [← digit_mod_pow (k := j + 1) (j := j) (by omega), h2, hdig]
        exact hdb.2 ⟨hi1, hi2⟩

/-! ### The bottom list and the parent list, exactly -/

/-- **L5(a), exactness.** A pair is in the bottom list of depth `k` with
digits `[f, k)` forced to `v` iff its residue is below `b^k`, has the
forced digits, and `bot_cert_direct` accepts it with that mask. -/
theorem mem_bottomsSorted_iff {b k f v : ℕ} (hb : 2 ≤ b) (q : ℕ × Finset ℕ) :
    q ∈ bottomsSorted b k f v ↔
      q.1 < b ^ k ∧ (∀ i, f ≤ i → i < k → digit b q.1 i = v / b ^ (i - f) % b) ∧
        botCertDirect b q.1 k = some q.2 := by
  unfold bottomsSorted
  rw [(List.mergeSort_perm _ _).mem_iff, botCertDirect_eq_some_iff]
  constructor
  · intro hq
    have h := botDfs_sound (f0 := f) (pp := k - f) (v := v) hb k 0 0 q (by simp)
      (lowDistinct_zero b 0) (by rwa [lowSet_zero])
    rw [Nat.zero_add] at h
    exact ⟨h.1, fun i h1 h2 => h.2.2.2.2 i h1 (by omega) (Nat.zero_le _) h2, h.2.2.1, h.2.2.2.1⟩
  · rintro ⟨hlt, hv, hd, hm⟩
    have h := mem_botDfs_of_lowDistinct (f0 := f) (pp := k - f) (v := v) (x := q.1) hb k 0
      (by rwa [Nat.zero_add]) (fun i h1 h2 _ h4 => (hv i h1 (by omega)).symm)
    simp only [Nat.zero_add, pow_zero, Nat.mod_one, lowSet_zero, Nat.mod_eq_of_lt hlt] at h
    rwa [← hm] at h

/-- **L5(a), exactness, for the parents.** A record is a parent of slice
`pip` iff it is `mkParent` of its own residue and mask, the residue is below
`b^(k−1)` with digits `[f0, k−1)` those of `pip`, and `bot_cert_direct`
accepts it at depth `k − 1` with that mask. -/
theorem mem_parents_iff {b : ℕ} {sh : Shape} {pip : ℕ} (hb : 2 ≤ b) (p : Parent) :
    p ∈ parents b sh pip ↔
      p = mkParent b sh.k (p.r, p.mask) ∧ p.r < b ^ (sh.k - 1) ∧
        (∀ i, sh.f0 ≤ i → i < sh.k - 1 → digit b p.r i = pip / b ^ (i - sh.f0) % b) ∧
        botCertDirect b p.r (sh.k - 1) = some p.mask := by
  unfold parents
  rw [List.mem_map]
  constructor
  · rintro ⟨q, hq, rfl⟩
    rw [mem_bottomsSorted_iff hb] at hq
    exact ⟨rfl, hq⟩
  · rintro ⟨hp, h1, h2, h3⟩
    exact ⟨(p.r, p.mask), (mem_bottomsSorted_iff hb _).mpr ⟨h1, h2, h3⟩, hp.symm⟩

/-- Two numbers below `b^m` with the same digits below `m` are equal. -/
theorem eq_of_digit_eq {b x y m : ℕ} (hx : x < b ^ m) (hy : y < b ^ m)
    (h : ∀ i, i < m → digit b x i = digit b y i) : x = y := by
  have key : ∀ i, i ≤ m → x % b ^ i = y % b ^ i := by
    intro i
    induction i with
    | zero => intro _; rw [pow_zero, Nat.mod_one, Nat.mod_one]
    | succ i ih =>
      intro hi
      rw [← mod_pow_succ_eq, ← mod_pow_succ_eq, ih (by omega), h i (by omega)]
  rw [← Nat.mod_eq_of_lt hx, ← Nat.mod_eq_of_lt hy]
  exact key m le_rfl

/-- The forced digits as a quotient: for `r < b^k`, `f ≤ k` and
`v < b^(k − f)`, `r` has digits `[f, k)` of `v` iff `r div b^f = v`. -/
theorem forced_iff_div {b k f v r : ℕ} (hb : 2 ≤ b) (hf : f ≤ k) (hr : r < b ^ k)
    (hv : v < b ^ (k - f)) :
    (∀ i, f ≤ i → i < k → digit b r i = v / b ^ (i - f) % b) ↔ r / b ^ f = v := by
  constructor
  · intro h
    have hq : r / b ^ f < b ^ (k - f) := by
      rw [Nat.div_lt_iff_lt_mul (Nat.pow_pos (by omega)), ← pow_add, Nat.sub_add_cancel hf]
      exact hr
    apply eq_of_digit_eq hq hv
    intro i hi
    rw [digit_div_pow, h (f + i) (by omega) (by omega), Nat.add_sub_cancel_left]
    rfl
  · rintro rfl i h1 _
    unfold digit
    rw [Nat.div_div_eq_div_mul, ← pow_add, Nat.add_sub_cancel' h1]

end NiceMidOut
