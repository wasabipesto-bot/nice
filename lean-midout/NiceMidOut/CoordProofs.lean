/-
L1, the coordinate: `v` is one to one on the range (`nOfV ∘ vOfN = some`),
the quantum index of `v(n)` is the digits `[q0, k1)` of `n`, and a field of
whole quanta is exactly the `n` whose digits `[q0, k1)` lie in its
`fieldDigits`, so fields with disjoint digit ranges are disjoint and the
quanta cover the range.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

namespace Coord

variable {c : Coord} {n : ℕ}

/-- `h = n div b^k1` takes a value in `[h0, h0 + H)` on the range. -/
theorem h_bounds (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    c.h0 ≤ n / c.b ^ c.k1 ∧ n / c.b ^ c.k1 - c.h0 < c.H := by
  have h1 : c.lo / c.b ^ c.k1 ≤ n / c.b ^ c.k1 := Nat.div_le_div_right hlo
  have h2 : n / c.b ^ c.k1 ≤ (c.hi - 1) / c.b ^ c.k1 := Nat.div_le_div_right (by omega)
  unfold H h0 at *
  omega

/-- The part of `v − lo` below the key: `(h − h0)·b^k0 + low < H·b^k0`. -/
theorem rest_lt (hb : 0 < c.b) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 + n % c.b ^ c.k0 < c.H * c.b ^ c.k0 := by
  have hB0 : 0 < c.b ^ c.k0 := Nat.pos_of_ne_zero (pow_ne_zero _ hb.ne')
  have hl : n % c.b ^ c.k0 < c.b ^ c.k0 := Nat.mod_lt _ hB0
  have hh := (h_bounds hlo hhi).2
  have : (n / c.b ^ c.k1 - c.h0 + 1) * c.b ^ c.k0 ≤ c.H * c.b ^ c.k0 :=
    Nat.mul_le_mul_right _ (by omega)
  rw [Nat.add_mul, Nat.one_mul] at this
  omega

theorem vOfN_sub_lo (n : ℕ) :
    c.vOfN n - c.lo = (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 + n % c.b ^ c.k0 +
      n % c.b ^ c.k1 / c.b ^ c.k0 * (c.H * c.b ^ c.k0) := by
  unfold vOfN
  generalize n % c.b ^ c.k1 / c.b ^ c.k0 * (c.H * c.b ^ c.k0) = x
  generalize (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 = y
  generalize n % c.b ^ c.k0 = z
  omega

theorem lo_le_vOfN (n : ℕ) : c.lo ≤ c.vOfN n := by
  unfold vOfN
  generalize n % c.b ^ c.k1 / c.b ^ c.k0 * (c.H * c.b ^ c.k0) = x
  generalize (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 = y
  generalize n % c.b ^ c.k0 = z
  omega

/-- The key of `v(n)`: `(v − lo) div (H·b^k0)` is the digits `[k0, k1)` of `n`. -/
theorem vOfN_div (hb : 0 < c.b) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    (c.vOfN n - c.lo) / (c.H * c.b ^ c.k0) = n % c.b ^ c.k1 / c.b ^ c.k0 := by
  have hr := rest_lt hb hlo hhi
  have hB0 : 0 < c.b ^ c.k0 := Nat.pos_of_ne_zero (pow_ne_zero _ hb.ne')
  have hH : 0 < c.H := by unfold H; omega
  rw [vOfN_sub_lo, Nat.add_mul_div_right _ _ (Nat.mul_pos hH hB0), Nat.div_eq_of_lt hr,
    Nat.zero_add]

theorem vOfN_mod (hb : 0 < c.b) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    (c.vOfN n - c.lo) % (c.H * c.b ^ c.k0) =
      (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 + n % c.b ^ c.k0 := by
  have hr := rest_lt hb hlo hhi
  rw [vOfN_sub_lo, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hr]

/-- L1, one to one: `n_of_v (v_of_n n) = n` on the range. -/
theorem nOfV_vOfN (hb : 0 < c.b) (hk : c.k0 ≤ c.k1) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    c.nOfV (c.vOfN n) = some n := by
  have hB0 : 0 < c.b ^ c.k0 := Nat.pos_of_ne_zero (pow_ne_zero _ hb.ne')
  have hd := vOfN_div hb hlo hhi
  have hm := vOfN_mod hb hlo hhi
  have hh := (h_bounds hlo hhi).1
  have hq : ((n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 + n % c.b ^ c.k0) / c.b ^ c.k0 =
      n / c.b ^ c.k1 - c.h0 := by
    rw [Nat.add_comm, Nat.add_mul_div_right _ _ hB0, Nat.div_eq_of_lt (Nat.mod_lt _ hB0),
      Nat.zero_add]
  have hr : ((n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 + n % c.b ^ c.k0) % c.b ^ c.k0 =
      n % c.b ^ c.k0 := by
    rw [Nat.add_comm, Nat.add_mul_mod_self_right, Nat.mod_mod]
  have hn : (c.h0 + (n / c.b ^ c.k1 - c.h0)) * c.b ^ c.k1 +
      n % c.b ^ c.k1 / c.b ^ c.k0 * c.b ^ c.k0 + n % c.b ^ c.k0 = n := by
    have e1 : c.h0 + (n / c.b ^ c.k1 - c.h0) = n / c.b ^ c.k1 := by omega
    have e2 : n % c.b ^ c.k1 % c.b ^ c.k0 = n % c.b ^ c.k0 :=
      Nat.mod_mod_of_dvd n (pow_dvd_pow c.b hk)
    have e3 := Nat.div_add_mod (n % c.b ^ c.k1) (c.b ^ c.k0)
    have e4 := Nat.div_add_mod n (c.b ^ c.k1)
    rw [e1, ← e2]
    rw [Nat.mul_comm (n % c.b ^ c.k1 / c.b ^ c.k0), Nat.add_assoc, e3, Nat.mul_comm, e4]
  unfold nOfV
  simp only [hd, hm, hq, hr, hn]
  simp [hlo, hhi]

/-- `v` is injective on the range. -/
theorem vOfN_injective (hb : 0 < c.b) (hk : c.k0 ≤ c.k1) {m : ℕ} (hlo : c.lo ≤ n)
    (hhi : n < c.hi) (hlo' : c.lo ≤ m) (hhi' : m < c.hi) (h : c.vOfN n = c.vOfN m) : n = m := by
  have := nOfV_vOfN hb hk hlo hhi
  rw [h, nOfV_vOfN hb hk hlo' hhi'] at this
  exact (Option.some.inj this).symm

/-- `v` lands in `[lo, vEnd)`. -/
theorem vOfN_lt_vEnd (hb : 0 < c.b) (hk : c.k0 ≤ c.k1) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    c.vOfN n < c.vEnd := by
  have hr := rest_lt hb hlo hhi
  have hkey : n % c.b ^ c.k1 / c.b ^ c.k0 < c.b ^ (c.k1 - c.k0) := by
    rw [mod_pow_div_pow hk]
    exact Nat.mod_lt _ (Nat.pos_of_ne_zero (pow_ne_zero _ hb.ne'))
  have hsplit : c.b ^ c.k1 = c.b ^ (c.k1 - c.k0) * c.b ^ c.k0 := by
    rw [← pow_add, Nat.sub_add_cancel hk]
  have : (n % c.b ^ c.k1 / c.b ^ c.k0 + 1) * (c.H * c.b ^ c.k0) ≤
      c.b ^ (c.k1 - c.k0) * (c.H * c.b ^ c.k0) := Nat.mul_le_mul_right _ hkey
  have hv := vOfN_sub_lo (c := c) n
  have hlv := lo_le_vOfN (c := c) n
  have hend : c.vEnd = c.lo + c.b ^ (c.k1 - c.k0) * (c.H * c.b ^ c.k0) := by
    unfold vEnd
    rw [hsplit]
    ring_nf
  rw [Nat.add_mul, Nat.one_mul] at this
  omega

/-- L1(a): the quantum index of `v(n)` is the digits `[q0, k1)` of `n`. -/
theorem vOfN_div_quantum (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0) (hk1 : c.q0 ≤ c.k1)
    (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    (c.vOfN n - c.lo) / c.quantum = n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0) := by
  have hq : c.quantum = c.H * c.b ^ c.k0 * c.b ^ (c.q0 - c.k0) := by
    unfold quantum
    rw [Nat.mul_assoc, ← pow_add, Nat.add_sub_cancel' hk0]
  rw [hq, ← Nat.div_div_eq_div_mul, vOfN_div hb hlo hhi, Nat.div_div_eq_div_mul, ← pow_add,
    Nat.add_sub_cancel' hk0, mod_pow_div_pow hk1]

/-- L1(b): a field of whole quanta is the `v` whose quantum index lies in its
digit range. -/
theorem mem_field_iff {vs vz t0 t1 v : ℕ} (hf : c.fieldDigits vs vz = some (t0, t1))
    (hv : c.lo ≤ v) :
    (vs ≤ v ∧ v < vs + vz) ↔ (t0 ≤ (v - c.lo) / c.quantum ∧ (v - c.lo) / c.quantum < t1) := by
  unfold fieldDigits at hf
  split_ifs at hf with h
  obtain ⟨hz, hl, -, hm, hm'⟩ := h
  simp only [Option.some.injEq, Prod.mk.injEq] at hf
  obtain ⟨rfl, rfl⟩ := hf
  have hQ : 0 < c.quantum := by
    rcases Nat.eq_zero_or_pos c.quantum with h0 | h0
    · rw [h0, Nat.mod_zero] at hm'
      omega
    · exact h0
  have e1 : vs - c.lo = (vs - c.lo) / c.quantum * c.quantum := (Nat.div_mul_cancel
    (Nat.dvd_of_mod_eq_zero hm)).symm
  have e2 : vz = vz / c.quantum * c.quantum := (Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero hm')).symm
  constructor
  · rintro ⟨h1, h2⟩
    constructor
    · exact (Nat.le_div_iff_mul_le hQ).mpr (by omega)
    · apply (Nat.div_lt_iff_lt_mul hQ).mpr
      rw [Nat.add_mul]
      omega
  · rintro ⟨h1, h2⟩
    have h1' := (Nat.le_div_iff_mul_le hQ).mp h1
    have h2' := (Nat.div_lt_iff_lt_mul hQ).mp h2
    rw [Nat.add_mul] at h2'
    omega

/-- L1, a field in terms of `n`: `n` of the range has `v(n)` in a field iff
its digits `[q0, k1)` lie in the field's digit range. -/
theorem vOfN_mem_field_iff {vs vz t0 t1 : ℕ} (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0)
    (hk1 : c.q0 ≤ c.k1) (hf : c.fieldDigits vs vz = some (t0, t1)) (hlo : c.lo ≤ n)
    (hhi : n < c.hi) :
    (vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz) ↔
      (t0 ≤ n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0) ∧ n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0) < t1) := by
  rw [mem_field_iff hf (lo_le_vOfN n), vOfN_div_quantum hb hk0 hk1 hlo hhi]

end Coord

namespace Shape

variable {sh : Shape} {c : Coord}

/-- The `i`-th slice of `t`, rearranged: `i mod A + (t + (i div A)·T)·A`. -/
theorem slice_formula (A T t i : ℕ) :
    i / A * (A * T) + t * A + i % A = i % A + (t + i / A * T) * A := by
  ring

/-- `b^(k1 − f0) = b^(q0 − f0) · b^(k1 − q0)` and
`b^(k − 1 − f0) = b^(k − 1 − k1) · b^(k1 − q0) · b^(q0 − f0)`. -/
theorem slice_pows (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 ≤ c.k1) (hk : c.k1 < sh.k) :
    c.b ^ (c.k1 - sh.f0) = c.b ^ (c.q0 - sh.f0) * c.b ^ (c.k1 - c.q0) ∧
      c.b ^ (sh.k - 1 - sh.f0) =
        c.b ^ (sh.k - 1 - c.k1) * c.b ^ (c.k1 - c.q0) * c.b ^ (c.q0 - sh.f0) := by
  constructor
  · rw [← pow_add]
    congr 1
    omega
  · rw [← pow_add, ← pow_add]
    congr 1
    omega

/-- L1(c): the slices of `t` are exactly the `pip` below `b^(k − 1 − f0)` whose
digits `[q0, k1)` (counted from `f0`) are `t`. -/
theorem mem_slicesOf_iff {t pip : ℕ} (hb : 0 < c.b) (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 ≤ c.k1)
    (hk : c.k1 < sh.k) (ht : t < c.b ^ (c.k1 - c.q0)) :
    pip ∈ sh.slicesOf c t ↔
      pip < c.b ^ (sh.k - 1 - sh.f0) ∧
        pip / c.b ^ (c.q0 - sh.f0) % c.b ^ (c.k1 - c.q0) = t := by
  obtain ⟨hmul, hP⟩ := slice_pows hf0 hq hk
  have hA : 0 < c.b ^ (c.q0 - sh.f0) := pow_pos hb _
  simp only [slicesOf, List.mem_map, List.mem_range]
  rw [hmul, hP]
  generalize c.b ^ (c.q0 - sh.f0) = A at *
  generalize c.b ^ (c.k1 - c.q0) = T at *
  generalize c.b ^ (sh.k - 1 - c.k1) = Hn at *
  constructor
  · rintro ⟨i, hi, rfl⟩
    rw [slice_formula]
    have hdiv : (i % A + (t + i / A * T) * A) / A = t + i / A * T := by
      rw [Nat.add_mul_div_right _ _ hA, Nat.div_eq_of_lt (Nat.mod_lt _ hA), Nat.zero_add]
    refine ⟨?_, ?_⟩
    · have h1 : i / A < Hn := Nat.div_lt_of_lt_mul hi
      have h2 := Nat.mod_lt i hA
      have h3 : (t + i / A * T + 1) * A ≤ Hn * T * A := by
        apply Nat.mul_le_mul_right
        have : (i / A + 1) * T ≤ Hn * T := Nat.mul_le_mul_right _ h1
        rw [Nat.add_mul, Nat.one_mul] at this
        omega
      rw [Nat.add_mul (t + i / A * T) 1 A, Nat.one_mul] at h3
      generalize (t + i / A * T) * A = X at *
      generalize Hn * T * A = Y at *
      generalize i % A = r at *
      omega
    · rw [hdiv, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt ht]
  · rintro ⟨hlt, hmod⟩
    refine ⟨pip / (A * T) * A + pip % A, ?_, ?_⟩
    · have h1 : pip / (A * T) < Hn :=
        Nat.div_lt_of_lt_mul (by rw [show A * T * Hn = Hn * T * A by ring]; exact hlt)
      have h2 := Nat.mod_lt pip hA
      have h3 : (pip / (A * T) + 1) * A ≤ Hn * A := Nat.mul_le_mul_right _ h1
      rw [Nat.add_mul, Nat.one_mul] at h3
      rw [Nat.mul_comm A Hn]
      generalize pip % A = r at *
      generalize pip / (A * T) * A = q at *
      omega
    · have e1 : (pip / (A * T) * A + pip % A) / A = pip / (A * T) := by
        rw [Nat.add_comm, Nat.add_mul_div_right _ _ hA, Nat.div_eq_of_lt (Nat.mod_lt _ hA),
          Nat.zero_add]
      have e2 : (pip / (A * T) * A + pip % A) % A = pip % A := by
        rw [Nat.add_comm, Nat.add_mul_mod_self_right, Nat.mod_mod]
      rw [e1, e2, ← hmod]
      have f1 := Nat.div_add_mod pip A
      have f2 := Nat.div_add_mod (pip / A) T
      rw [Nat.div_div_eq_div_mul] at f2
      calc _ = A * (T * (pip / (A * T)) + pip / A % T) + pip % A := by ring
        _ = pip := by rw [f2, f1]

/-- L1(c): a value's slice list has no repeats. -/
theorem slicesOf_nodup {t : ℕ} (hb : 0 < c.b) (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 ≤ c.k1)
    (hk : c.k1 < sh.k) : (sh.slicesOf c t).Nodup := by
  obtain ⟨hmul, -⟩ := slice_pows hf0 hq hk
  have hA : 0 < c.b ^ (c.q0 - sh.f0) := pow_pos hb _
  have hT : 0 < c.b ^ (c.k1 - c.q0) := pow_pos hb _
  simp only [slicesOf]
  rw [hmul]
  generalize c.b ^ (c.q0 - sh.f0) = A at *
  generalize c.b ^ (c.k1 - c.q0) = T at *
  apply List.Nodup.map_on _ (List.nodup_range)
  intro i _ j _ hij
  rw [slice_formula, slice_formula] at hij
  have hd := congrArg (· / A) hij
  have hm := congrArg (· % A) hij
  rw [Nat.add_mul_div_right _ _ hA, Nat.div_eq_of_lt (Nat.mod_lt _ hA), Nat.zero_add,
    Nat.add_mul_div_right _ _ hA, Nat.div_eq_of_lt (Nat.mod_lt _ hA), Nat.zero_add] at hd
  rw [Nat.add_mul_mod_self_right, Nat.mod_mod, Nat.add_mul_mod_self_right, Nat.mod_mod] at hm
  have hq' : i / A = j / A := Nat.eq_of_mul_eq_mul_right hT (by omega)
  calc i = A * (i / A) + i % A := (Nat.div_add_mod i A).symm
    _ = j := by rw [hq', hm, Nat.div_add_mod]

/-- The digits `[q0, k1)` of `n`, read off its slice `n div b^f0 mod b^(k − 1 − f0)`. -/
theorem slice_digits (n : ℕ) (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 < c.k1) (hk : c.k1 < sh.k) :
    n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) / c.b ^ (c.q0 - sh.f0) % c.b ^ (c.k1 - c.q0) =
      n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0) := by
  rw [mod_pow_div_pow (by omega), Nat.div_div_eq_div_mul, ← pow_add,
    Nat.add_sub_cancel' hf0, Nat.mod_mod_of_dvd _ (pow_dvd_pow c.b (by omega))]

/-- The slice of `n` (its digits `[f0, k − 1)`) is a slice of its field value
(its digits `[q0, k1)`). -/
theorem slice_mem_slicesOf (n : ℕ) (hb : 0 < c.b) (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 < c.k1)
    (hk : c.k1 < sh.k) :
    n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) ∈
      sh.slicesOf c (n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0)) := by
  rw [mem_slicesOf_iff hb hf0 hq.le hk (Nat.mod_lt _ (pow_pos hb _))]
  exact ⟨Nat.mod_lt _ (pow_pos hb _), slice_digits n hf0 hq hk⟩

end Shape

namespace Coord

variable {c : Coord} {n : ℕ}

theorem quantum_pos (hb : 0 < c.b) : 0 < c.quantum :=
  Nat.mul_pos (by unfold H; omega) (pow_pos hb _)

theorem vEnd_sub_lo (hk1 : c.q0 ≤ c.k1) : c.vEnd - c.lo = c.quantum * c.b ^ (c.k1 - c.q0) := by
  unfold vEnd quantum
  rw [Nat.add_sub_cancel_left, Nat.mul_assoc, ← pow_add, Nat.add_sub_cancel' hk1]

/-- L1(d): the whole coordinate is one field, of every digit value. -/
theorem fieldDigits_whole (hb : 0 < c.b) (hk1 : c.q0 ≤ c.k1) :
    c.fieldDigits c.lo (c.vEnd - c.lo) = some (0, c.b ^ (c.k1 - c.q0)) := by
  have hQ := quantum_pos (c := c) hb
  have hT : 0 < c.b ^ (c.k1 - c.q0) := pow_pos hb _
  have hE := vEnd_sub_lo (c := c) hk1
  have hle : c.lo ≤ c.vEnd := by unfold vEnd; omega
  unfold fieldDigits
  rw [hE, if_pos]
  · simp [Nat.mul_div_cancel_left _ hQ]
  · refine ⟨Nat.mul_pos hQ hT, le_refl _, by omega, by simp, Nat.mul_mod_right _ _⟩

/-- A field's digit values lie below `b^(k1 − q0)`. -/
theorem fieldDigits_le {vs vz t0 t1 : ℕ} (hb : 0 < c.b) (hk1 : c.q0 ≤ c.k1)
    (hf : c.fieldDigits vs vz = some (t0, t1)) : t1 ≤ c.b ^ (c.k1 - c.q0) := by
  unfold fieldDigits at hf
  split_ifs at hf with h
  obtain ⟨-, hl, he, hm, hm'⟩ := h
  simp only [Option.some.injEq, Prod.mk.injEq] at hf
  obtain ⟨rfl, rfl⟩ := hf
  have hQ := quantum_pos (c := c) hb
  have hE := vEnd_sub_lo (c := c) hk1
  rw [Nat.mul_comm] at hE
  have e1 : vs - c.lo = (vs - c.lo) / c.quantum * c.quantum :=
    (Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero hm)).symm
  have e2 : vz = vz / c.quantum * c.quantum := (Nat.div_mul_cancel (Nat.dvd_of_mod_eq_zero hm')).symm
  have : ((vs - c.lo) / c.quantum + vz / c.quantum) * c.quantum ≤
      c.b ^ (c.k1 - c.q0) * c.quantum := by
    rw [Nat.add_mul]
    omega
  exact Nat.le_of_mul_le_mul_right this hQ

/-- L1(d): the quanta partition the range: `v(n)` lies in quantum `t` iff `t`
is the digits `[q0, k1)` of `n`. -/
theorem vOfN_mem_quantum_iff (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0) (hk1 : c.q0 ≤ c.k1)
    (hlo : c.lo ≤ n) (hhi : n < c.hi) (t : ℕ) :
    (c.lo + t * c.quantum ≤ c.vOfN n ∧ c.vOfN n < c.lo + t * c.quantum + c.quantum) ↔
      t = n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0) := by
  rw [← vOfN_div_quantum hb hk0 hk1 hlo hhi]
  have hQ := quantum_pos (c := c) hb
  have hv := lo_le_vOfN (c := c) n
  generalize c.vOfN n = v at *
  have key : t = (v - c.lo) / c.quantum ↔
      (t ≤ (v - c.lo) / c.quantum ∧ (v - c.lo) / c.quantum < t + 1) := by omega
  rw [key, Nat.le_div_iff_mul_le hQ, Nat.div_lt_iff_lt_mul hQ, Nat.add_mul, Nat.one_mul]
  constructor <;> rintro ⟨h1, h2⟩ <;> constructor <;> omega

/-- L1(d): every `n` of the range lies in exactly one quantum. -/
theorem existsUnique_quantum (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0) (hk1 : c.q0 ≤ c.k1)
    (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    ∃! t, t < c.b ^ (c.k1 - c.q0) ∧
      (c.lo + t * c.quantum ≤ c.vOfN n ∧ c.vOfN n < c.lo + t * c.quantum + c.quantum) :=
  ⟨n / c.b ^ c.q0 % c.b ^ (c.k1 - c.q0),
    ⟨Nat.mod_lt _ (pow_pos hb _), (vOfN_mem_quantum_iff hb hk0 hk1 hlo hhi _).mpr rfl⟩,
    fun t ht => (vOfN_mem_quantum_iff hb hk0 hk1 hlo hhi t).mp ht.2⟩

/-- L1(c), a field is a whole number of slices: `n` of the range has `v(n)` in
the field iff its slice is one of the field's slices. -/
theorem mem_fieldSlices_iff {sh : Shape} {vs vz t0 t1 : ℕ} (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0)
    (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 < c.k1) (hk : c.k1 < sh.k)
    (hf : c.fieldDigits vs vz = some (t0, t1)) (hlo : c.lo ≤ n) (hhi : n < c.hi) :
    n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) ∈ fieldSlices c sh vs vz ↔
      (vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz) := by
  rw [vOfN_mem_field_iff hb hk0 hq.le hf hlo hhi]
  have hT1 := fieldDigits_le hb hq.le hf
  unfold fieldSlices fieldTs
  rw [hf]
  simp only [List.mem_flatMap, List.mem_range'_1]
  constructor
  · rintro ⟨t, ⟨h1, h2⟩, hmem⟩
    rw [Shape.mem_slicesOf_iff hb hf0 hq.le hk (by omega), Shape.slice_digits n hf0 hq hk] at hmem
    omega
  · intro h
    exact ⟨_, ⟨by omega, by omega⟩, Shape.slice_mem_slicesOf n hb hf0 hq hk⟩

/-- Fields with disjoint digit ranges share no `n`. -/
theorem field_disjoint {vs vz t0 t1 vs' vz' t0' t1' : ℕ} (hb : 0 < c.b) (hk0 : c.k0 ≤ c.q0)
    (hk1 : c.q0 ≤ c.k1) (hf : c.fieldDigits vs vz = some (t0, t1))
    (hf' : c.fieldDigits vs' vz' = some (t0', t1')) (hd : t1 ≤ t0') (hlo : c.lo ≤ n)
    (hhi : n < c.hi) :
    ¬ ((vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz) ∧ (vs' ≤ c.vOfN n ∧ c.vOfN n < vs' + vz')) := by
  rw [vOfN_mem_field_iff hb hk0 hk1 hf hlo hhi, vOfN_mem_field_iff hb hk0 hk1 hf' hlo hhi]
  omega

end Coord

end NiceMidOut
