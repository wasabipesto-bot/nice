/-
L4, the top certificate, about the model's `topCertSplit`, `unitLeads` and
`unitTops` (`Join.lean`; Rust `top_cert_split`, `unit_tops`, `cpu.rs:181`,
`:457`).

- (i) `certPositions_eq_nil_of_numDigits_ne`: two powers of unequal length
  certify no position (the Rust skips them, `cpu.rs:196–198`); and
  `mem_certPositions_iff`: a certified position is one from which the two
  powers agree digit by digit all the way up (what the scan's top-down walk
  with its break at the first difference passes). The scan itself as a
  function, proved equal to `topCertSplit`, is in `TopsScan.lean`.
- (ii) `topCertSplit_mhi`: `mhi` is the certificate at cap `kmid`, inside the
  mask; `highDigit_of_mem_unitTops`: every digit of a top's mask is, for every
  `n` of its interval, a digit of `n²` or `n³` at a position `≥ k`, and every
  digit of its `mhi` one at a position `≥ k + 2`.
- (iii) `mem_unitTops_of_isNice`: every nice `n` of the range has its top
  `n / b^k` in `unitTops` of its unit `n / b^f0 mod b^(k − f0)`, with the
  interval of its prefix clipped to the range, and `n` inside it.

Reused from the earlier library: `cert`, `certDigits`, `certPositions`,
`certPositions_digit`, `highDigit_of_cert`, `le_certFloor`, `HighDigit.mono`,
`exists_cert_of_isNice`, `div_mul_le_and_le`, `lt_numDigits_iff`,
`numDigits_le_iff`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-! ### Membership in `unitLeads` and `unitTops` -/

theorem mem_unitLeads {b lo hi f0 k u lead a c : ℕ} :
    (lead, a, c) ∈ unitLeads b lo hi f0 k u ↔
      lo / b ^ k ≤ lead ∧ lead ≤ (hi - 1) / b ^ k ∧
        a = max ((lead * b ^ (k - f0) + u) * b ^ f0) lo ∧
        c = min ((lead * b ^ (k - f0) + u) * b ^ f0 + b ^ f0 - 1) (hi - 1) ∧ a ≤ c := by
  unfold unitLeads
  simp only [List.mem_filterMap, List.mem_range'_1]
  constructor
  · rintro ⟨x, ⟨hx1, hx2⟩, hx⟩
    split_ifs at hx with hac
    simp only [Option.some.injEq, Prod.mk.injEq] at hx
    obtain ⟨rfl, rfl, rfl⟩ := hx
    exact ⟨hx1, by omega, rfl, rfl, hac⟩
  · rintro ⟨h1, h2, rfl, rfl, hac⟩
    refine ⟨lead, ⟨h1, by omega⟩, ?_⟩
    rw [if_pos hac]

theorem mem_unitTops {b lo hi f0 k u : ℕ} {t : Top} :
    t ∈ unitTops b lo hi f0 k u ↔
      (t.h, t.lo, t.hi) ∈ unitLeads b lo hi f0 k u ∧ cert b t.lo t.hi k = some t.mask ∧
        t.mhi = (certDigits b t.lo t.hi (k + 2)).toFinset := by
  unfold unitTops topCertSplit
  rw [List.mem_filterMap]
  constructor
  · rintro ⟨⟨l, a, c⟩, hx, hm⟩
    cases hcert : cert b a c k with
    | none => rw [hcert] at hm; cases hm
    | some m =>
      rw [hcert] at hm
      simp only [Option.map_some, Option.some.injEq] at hm
      subst hm
      exact ⟨hx, hcert, rfl⟩
  · rintro ⟨hx, hc, hm⟩
    refine ⟨(t.h, t.lo, t.hi), hx, ?_⟩
    simp only [hc, Option.map_some]
    rw [← hm]

/-- A unit and its lead make the prefix: `(n / b^k)·b^(k−f0) + (n / b^f0 mod b^(k−f0)) = n / b^f0`. -/
theorem top_lead_unit {b f0 k n : ℕ} (hfk : f0 ≤ k) :
    n / b ^ k * b ^ (k - f0) + n / b ^ f0 % b ^ (k - f0) = n / b ^ f0 := by
  have h1 : n / b ^ f0 / b ^ (k - f0) = n / b ^ k := by
    rw [Nat.div_div_eq_div_mul, ← pow_add, Nat.add_sub_cancel' hfk]
  rw [← h1]
  exact Nat.div_add_mod' _ _

/-- The unit of `n` (digits `[f0, k)`) is the slice (digits `[f0, k − 1)`)
plus the unit digit `d` (digit `k − 1`) times `b^(k−1−f0)`, the form
`sliceSurvivors` asks `unitTops` for. -/
theorem unit_split {b f0 k n : ℕ} (hfk : f0 < k) :
    n / b ^ f0 % b ^ (k - f0) =
      n / b ^ f0 % b ^ (k - 1 - f0) + n / b ^ (k - 1) % b * b ^ (k - 1 - f0) := by
  have hk : k - f0 = k - 1 - f0 + 1 := by omega
  rw [hk, Nat.mod_pow_succ, Nat.div_div_eq_div_mul, ← pow_add,
    show f0 + (k - 1 - f0) = k - 1 by omega]
  ring

/-! ### (iii): every nice `n` has its top listed -/

/-- L4 (iii). For a nice `n` of the range `[lo, hi)`, `unitTops` of `n`'s unit
lists a top with lead `n / b^k`, the interval of `n`'s prefix `n / b^f0`
clipped to the range, and `n` in that interval. -/
theorem mem_unitTops_of_isNice {b lo hi f0 k n : ℕ} (hb : 2 ≤ b) (hfk : f0 ≤ k)
    (hlo : lo ≤ n) (hhi : n < hi) (h : IsNice b n) :
    ∃ t ∈ unitTops b lo hi f0 k (n / b ^ f0 % b ^ (k - f0)),
      t.h = n / b ^ k ∧ t.lo = max (n / b ^ f0 * b ^ f0) lo ∧
        t.hi = min (n / b ^ f0 * b ^ f0 + b ^ f0 - 1) (hi - 1) ∧ t.lo ≤ n ∧ n ≤ t.hi := by
  have hw : 0 < b ^ f0 := Nat.pow_pos (by omega)
  obtain ⟨h1, h2⟩ := div_mul_le_and_le (n := n) hw
  have han : max (n / b ^ f0 * b ^ f0) lo ≤ n := max_le h1 hlo
  have hnc : n ≤ min (n / b ^ f0 * b ^ f0 + b ^ f0 - 1) (hi - 1) := le_min h2 (by omega)
  obtain ⟨m, hm⟩ := exists_cert_of_isNice (c := k) hb han hnc h
  refine ⟨⟨n / b ^ k, m, (certDigits b (max (n / b ^ f0 * b ^ f0) lo)
      (min (n / b ^ f0 * b ^ f0 + b ^ f0 - 1) (hi - 1)) (k + 2)).toFinset,
      max (n / b ^ f0 * b ^ f0) lo, min (n / b ^ f0 * b ^ f0 + b ^ f0 - 1) (hi - 1)⟩,
    ?_, rfl, rfl, rfl, han, hnc⟩
  rw [mem_unitTops]
  refine ⟨?_, hm, rfl⟩
  rw [mem_unitLeads, top_lead_unit hfk]
  exact ⟨Nat.div_le_div_right hlo, Nat.div_le_div_right (by omega), rfl, rfl, le_trans han hnc⟩

/-- L4 (iii) in the form `sliceSurvivors` reads it (`f0 < k`): the unit is
`pip + d·b^(k−1−f0)` with `pip` the slice of `n` and `d` its digit `k − 1`. -/
theorem mem_unitTops_slice_of_isNice {b lo hi f0 k n : ℕ} (hb : 2 ≤ b) (hfk : f0 < k)
    (hlo : lo ≤ n) (hhi : n < hi) (h : IsNice b n) :
    ∃ t ∈ unitTops b lo hi f0 k
        (n / b ^ f0 % b ^ (k - 1 - f0) + n / b ^ (k - 1) % b * b ^ (k - 1 - f0)),
      t.h = n / b ^ k ∧ t.lo = max (n / b ^ f0 * b ^ f0) lo ∧
        t.hi = min (n / b ^ f0 * b ^ f0 + b ^ f0 - 1) (hi - 1) ∧ t.lo ≤ n ∧ n ≤ t.hi := by
  rw [← unit_split hfk]
  exact mem_unitTops_of_isNice hb hfk.le hlo hhi h

/-! ### (ii): the mask and `mhi` -/

theorem certPositions_sublist {b x y c c' : ℕ} (h : c ≤ c') :
    (certPositions b x y c').Sublist (certPositions b x y c) := by
  unfold certPositions
  apply List.monotone_filter_right
  intro i hi
  simp only [decide_eq_true_eq] at hi ⊢
  exact ⟨le_trans h hi.1, hi.2⟩

theorem certDigits_sublist {b a e c c' : ℕ} (h : c ≤ c') :
    (certDigits b a e c').Sublist (certDigits b a e c) :=
  ((certPositions_sublist h).map _).append ((certPositions_sublist h).map _)

/-- L4 (ii). When `topCertSplit` certifies `[a, c]` (`kpos ≤ kmid`), its `mhi`
is exactly the certificate at cap `kmid` and lies inside the mask. -/
theorem topCertSplit_mhi {b a c kpos kmid : ℕ} {m mh : Finset ℕ} (hk : kpos ≤ kmid)
    (h : topCertSplit b a c kpos kmid = some (m, mh)) :
    cert b a c kpos = some m ∧ cert b a c kmid = some mh ∧ mh ⊆ m := by
  unfold topCertSplit at h
  cases hc : cert b a c kpos with
  | none => rw [hc] at h; cases h
  | some m' =>
    rw [hc] at h
    simp only [Option.map_some, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    have hsub := certDigits_sublist (b := b) (a := a) (e := c) hk
    unfold cert at hc ⊢
    split_ifs at hc with hnd
    simp only [Option.some.injEq] at hc
    subst hc
    refine ⟨rfl, by rw [if_pos (hnd.sublist hsub)], ?_⟩
    intro x hx
    rw [List.mem_toFinset] at hx ⊢
    exact hsub.subset hx

/-- The digits at positions certified at cap `c'` are high digits at `c'` of
every `n` of the interval. -/
theorem highDigit_of_mem_certDigits {b a e c' n x : ℕ} (hb : 2 ≤ b) (han : a ≤ n) (hne : n ≤ e)
    (hx : x ∈ certDigits b a e c') : HighDigit b c' n x := by
  unfold certDigits at hx
  rw [List.mem_append, List.mem_map, List.mem_map] at hx
  rcases hx with ⟨i, hi, rfl⟩ | ⟨i, hi, rfl⟩
  · obtain ⟨hc, hlt, hd⟩ := certPositions_digit hb han hne hi
    exact ⟨2, i, Or.inl rfl, hc, hlt, hd⟩
  · obtain ⟨hc, hlt, hd⟩ := certPositions_digit hb han hne hi
    exact ⟨3, i, Or.inr rfl, hc, hlt, hd⟩

/-- L4 (ii), for the listed tops. For a top of `unitTops` and every `n` of its
interval: the mask's digits are digits of `n²` or `n³` at positions `≥ k`, the
`mhi` digits at positions `≥ k + 2`, and `mhi` lies in the mask. -/
theorem highDigit_of_mem_unitTops {b lo hi f0 k u n : ℕ} {t : Top} (hb : 2 ≤ b)
    (ht : t ∈ unitTops b lo hi f0 k u) (hn1 : t.lo ≤ n) (hn2 : n ≤ t.hi) :
    (∀ x ∈ t.mask, HighDigit b k n x) ∧ (∀ x ∈ t.mhi, HighDigit b (k + 2) n x) ∧
      t.mhi ⊆ t.mask := by
  obtain ⟨-, hc, hm⟩ := mem_unitTops.mp ht
  refine ⟨fun x hx => (highDigit_of_cert hb hn1 hn2 hc x hx).mono (le_certFloor _ _ _ _),
    ?_, ?_⟩
  · intro x hx
    rw [hm, List.mem_toFinset] at hx
    exact highDigit_of_mem_certDigits hb hn1 hn2 hx
  · have hs : topCertSplit b t.lo t.hi k (k + 2) = some (t.mask, t.mhi) := by
      unfold topCertSplit; rw [hc, hm]; rfl
    exact (topCertSplit_mhi (by omega) hs).2.2

/-! ### (i): what a certified position is -/

/-- Two numbers of unequal digit length certify no position. -/
theorem certPositions_eq_nil_of_numDigits_ne {b x y c : ℕ} (hb : 2 ≤ b)
    (hne : numDigits b x ≠ numDigits b y) : certPositions b x y c = [] := by
  apply List.eq_nil_iff_forall_not_mem.mpr
  intro i hi
  unfold certPositions at hi
  rw [List.mem_filter, List.mem_range, decide_eq_true_iff] at hi
  obtain ⟨hlen, -, hq⟩ := hi
  have hBi : 0 < b ^ i := Nat.pow_pos (by omega)
  have hy0 : y ≠ 0 := by
    rintro rfl; simp [numDigits] at hlen
  have hyi : b ^ i ≤ y := (lt_numDigits_iff hb hy0 i).mp hlen
  have hq1 : 1 ≤ y / b ^ i := (Nat.one_le_div_iff hBi).mpr hyi
  have hxi : b ^ i ≤ x := (Nat.one_le_div_iff hBi).mp (by omega)
  have hx0 : x ≠ 0 := by omega
  have hlenx : i < numDigits b x := (lt_numDigits_iff hb hx0 i).mpr hxi
  -- above `i`, `x < b^j ↔ y < b^j`, read off the common quotient
  have hlt : ∀ j, i ≤ j → (x < b ^ j ↔ y < b ^ j) := by
    intro j hj
    have hp : b ^ j = b ^ (j - i) * b ^ i := by rw [← pow_add, Nat.sub_add_cancel hj]
    rw [hp, ← Nat.div_lt_iff_lt_mul hBi, ← Nat.div_lt_iff_lt_mul hBi, hq]
  rcases Nat.lt_or_gt_of_ne hne with h | h
  · have := (hlt (numDigits b x) hlenx.le).mp ((numDigits_le_iff hb hx0 _).mp le_rfl)
    have := (numDigits_le_iff hb hy0 _).mpr this
    omega
  · have := (hlt (numDigits b y) hlen.le).mpr ((numDigits_le_iff hb hy0 _).mp le_rfl)
    have := (numDigits_le_iff hb hx0 _).mpr this
    omega

/-- Equal quotients at `i` are equal digits at every position from `i` up. -/
theorem div_pow_eq_iff_digits {b x y i : ℕ} (hb : 2 ≤ b) :
    x / b ^ i = y / b ^ i ↔ ∀ j, i ≤ j → digit b x j = digit b y j := by
  constructor
  · intro h j hj
    unfold digit
    have hp : b ^ j = b ^ i * b ^ (j - i) := by rw [← pow_add, Nat.add_sub_cancel' hj]
    rw [hp, ← Nat.div_div_eq_div_mul, ← Nat.div_div_eq_div_mul, h]
  · intro h
    -- downward from a position above both numbers
    have hB : ∀ s, x / b ^ (i + s) = y / b ^ (i + s) → x / b ^ i = y / b ^ i := by
      intro s
      induction s with
      | zero => exact id
      | succ s ih =>
        intro hs
        apply ih
        have hx := Nat.div_add_mod' (x / b ^ (i + s)) b
        have hy := Nat.div_add_mod' (y / b ^ (i + s)) b
        rw [Nat.div_div_eq_div_mul, ← pow_succ] at hx hy
        have hd := h (i + s) (by omega)
        unfold digit at hd
        have hs' : x / b ^ (i + s + 1) = y / b ^ (i + s + 1) := by
          rw [show i + s + 1 = i + (s + 1) by omega]; exact hs
        calc x / b ^ (i + s) = x / b ^ (i + s + 1) * b + x / b ^ (i + s) % b := hx.symm
          _ = y / b ^ (i + s + 1) * b + y / b ^ (i + s) % b := by rw [hs', hd]
          _ = y / b ^ (i + s) := hy
    apply hB (x + y)
    have h1 : x < b ^ (i + (x + y)) :=
      lt_of_lt_of_le (Nat.lt_pow_self (by omega)) (Nat.pow_le_pow_right (by omega) (by omega))
    have h2 : y < b ^ (i + (x + y)) :=
      lt_of_lt_of_le (Nat.lt_pow_self (by omega)) (Nat.pow_le_pow_right (by omega) (by omega))
    rw [Nat.div_eq_of_lt h1, Nat.div_eq_of_lt h2]

/-- L4 (i). A position is certified exactly when it is at or above the cap,
below the length of `y`, and the two numbers agree digit by digit from it all
the way up: the positions the Rust's top-down scan passes before its first
difference. -/
theorem mem_certPositions_iff {b x y c i : ℕ} (hb : 2 ≤ b) :
    i ∈ certPositions b x y c ↔
      c ≤ i ∧ i < numDigits b y ∧ ∀ j, i ≤ j → digit b x j = digit b y j := by
  unfold certPositions
  rw [List.mem_filter, List.mem_range, decide_eq_true_iff, div_pow_eq_iff_digits hb]
  tauto

end NiceMidOut
