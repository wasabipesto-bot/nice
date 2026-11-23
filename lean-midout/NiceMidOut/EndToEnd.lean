/-
The end-to-end theorem (END-MO): `searchField` returns exactly the nice
numbers of the field.

- `searchField_complete`: for a valid coordinate (`Coord.Valid`, what the
  executable constructor `Coord.withDigits` guarantees, `valid_of_withDigits`),
  a shape that fits it and a field the model's own `fieldDigits` accepts,
  `searchField` returns an outcome, and every nice `n` whose `v(n)` lies in
  the field is among its nice numbers.
- `sliceRun_complete`: the same `n` is reported, with the prefilter's verdict
  `true`, by the run form `sliceRun` (the form the fixtures test) of its slice,
  which is one of the field's slices.
- `searchField_sound`: every number `searchField` returns is nice and has
  `v(n)` in the field.

Composed from: L1 (`Coord.mem_fieldSlices_iff`, `Coord.fieldDigits_le`,
`Shape.mem_slicesOf_iff`), L2 (`mem_range_of_isNice`, `Coord.le_numDigits_pow`),
L4 + L6 (`probed_top_of_isNice`, `unitTops_prefix`, `mem_unitTops`,
`mem_unitLeads`), L5 + L7 + L8 (`mem_sliceSurvivors_of_isNice`,
`midPrefilter_of_mem_unitTops`, `mem_of_mem_probesOf`), L9 (`finalCheck_iff`),
and the run form (`sliceRun_surv_perm`).
-/
import NiceMidOut.Pairing
import NiceMidOut.ClassesTops
import NiceMidOut.RangeDigits
import NiceMidOut.CheckProofs
import NiceMidOut.CoordProofs

namespace NiceMidOut

open NiceSearch

/-- A valid coordinate's range ends at `hi ≥ 2` (its last number has at least
one digit). -/
theorem Coord.two_le_hi {c : Coord} (hc : c.Valid) : 2 ≤ c.hi := by
  obtain ⟨-, -, -, -, hq, hL⟩ := hc
  unfold Coord.L at hL
  by_contra h
  have h0 : c.hi - 1 = 0 := by omega
  rw [h0] at hL
  simp [numDigits] at hL
  omega

/-- The slice of a nice number of the field, and its survivor there. -/
theorem slice_survivor_of_isNice {c : Coord} {sh : Shape} {vs vz t0 t1 n : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hf : c.fieldDigits vs vz = some (t0, t1)) (h : IsNice c.b n)
    (hv : vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz) :
    n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) ∈ fieldSlices c sh vs vz ∧
      ∃ t : Top, t ∈ unitTops c.b c.lo c.hi sh.f0 sh.k
          (n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) +
            digit c.b n (sh.k - 1) * c.b ^ (sh.k - 1 - sh.f0)) ∧ t.lo ≤ n ∧ n ≤ t.hi ∧
        (digit c.b n (sh.k - 1), n, t.mhi) ∈
          sliceSurvivors c.b c.lo c.hi sh (n / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0)) := by
  have hc' := hc
  obtain ⟨hb3, -, hr, hk0, hq, hk1⟩ := hc'
  obtain ⟨hf0, hk1k, hkL⟩ := hfit
  have hb : 2 ≤ c.b := by omega
  obtain ⟨hlo, hhi⟩ := mem_range_of_isNice hb hr h
  obtain ⟨h2, h3⟩ := Coord.le_numDigits_pow hc hlo hhi hkL
  refine ⟨(Coord.mem_fieldSlices_iff (by omega) hk0 hf0 hq hk1k hf hlo hhi).mpr hv, ?_⟩
  obtain ⟨t, ht, hth, htlo, hthi, -, -⟩ := probed_top_of_isNice hb (by omega : sh.f0 < sh.k) hlo hhi h
  exact ⟨t, mem_of_mem_probesOf ht, htlo, hthi,
    mem_sliceSurvivors_of_isNice hb h (by omega) h2 h3 ht hth htlo hthi⟩

/-- **END-MO, completeness.** For a valid coordinate `c`, a shape `sh` that fits
it and a field `[vs, vs + vz)` that the model's `fieldDigits` accepts,
`searchField` returns an outcome, and every nice `n` with `v(n)` in the field is
among the outcome's nice numbers. -/
theorem searchField_complete {c : Coord} {sh : Shape} {vs vz t0 t1 : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hf : c.fieldDigits vs vz = some (t0, t1)) :
    ∃ o, searchField c sh vs vz = some o ∧
      ∀ n, IsNice c.b n → vs ≤ c.vOfN n → c.vOfN n < vs + vz → n ∈ o.nice := by
  unfold searchField
  rw [if_pos ⟨hfit, by rw [hf]; rfl⟩]
  refine ⟨_, rfl, fun n h hv1 hv2 => ?_⟩
  obtain ⟨hpip, t, ht, htlo, hthi, hs⟩ := slice_survivor_of_isNice hc hfit hf h ⟨hv1, hv2⟩
  have hb : 2 ≤ c.b := by have := hc.1; omega
  simp only
  rw [(List.mergeSort_perm _ _).mem_iff, List.mem_map]
  refine ⟨(digit c.b n (sh.k - 1), n, t.mhi), ?_, rfl⟩
  rw [List.mem_filter, List.mem_filter, List.mem_flatMap]
  exact ⟨⟨⟨_, hpip, hs⟩, midPrefilter_of_mem_unitTops hb h ht htlo hthi⟩, (finalCheck_iff hb).mpr h⟩

/-- **END-MO, completeness, in the run form.** The same `n` is reported as
`(digit_(k−1) n, n, true)` by `sliceRun` (the Rust's order and counters, the
form the fixtures test) of its slice, which is one of the field's slices. -/
theorem sliceRun_complete {c : Coord} {sh : Shape} {vs vz t0 t1 n : ℕ} (hc : c.Valid)
    (hfit : sh.Fits c) (hf : c.fieldDigits vs vz = some (t0, t1)) (h : IsNice c.b n)
    (hv1 : vs ≤ c.vOfN n) (hv2 : c.vOfN n < vs + vz) :
    ∃ pip ∈ fieldSlices c sh vs vz,
      (digit c.b n (sh.k - 1), n, true) ∈ (sliceRun c.b c.lo c.hi sh pip).surv := by
  obtain ⟨hpip, t, ht, htlo, hthi, hs⟩ := slice_survivor_of_isNice hc hfit hf h ⟨hv1, hv2⟩
  have hb : 2 ≤ c.b := by have := hc.1; omega
  refine ⟨_, hpip, (sliceRun_surv_perm _ _ _ _ _).mem_iff.mpr (List.mem_map.mpr ⟨_, hs, ?_⟩)⟩
  simp only [midPrefilter_of_mem_unitTops hb h ht htlo hthi]

/-- Every survivor of a slice of the field is a number of the range whose
`v` lies in the field. -/
theorem survivor_mem_field {c : Coord} {sh : Shape} {vs vz t0 t1 pip : ℕ}
    {s : ℕ × ℕ × Finset ℕ} (hc : c.Valid) (hfit : sh.Fits c)
    (hf : c.fieldDigits vs vz = some (t0, t1)) (hpip : pip ∈ fieldSlices c sh vs vz)
    (hs : s ∈ sliceSurvivors c.b c.lo c.hi sh pip) :
    c.lo ≤ s.2.1 ∧ s.2.1 < c.hi ∧ vs ≤ c.vOfN s.2.1 ∧ c.vOfN s.2.1 < vs + vz := by
  have hhi2 := Coord.two_le_hi hc
  obtain ⟨hb3, -, -, hk0, hq, -⟩ := hc
  obtain ⟨hf0, hk1k, -⟩ := hfit
  have hb0 : 0 < c.b := by omega
  -- the slice is below `b^(k−1−f0)`
  have hpipb : pip < c.b ^ (sh.k - 1 - sh.f0) := by
    unfold fieldSlices at hpip
    rw [List.mem_flatMap] at hpip
    obtain ⟨t, htm, hpt⟩ := hpip
    unfold Coord.fieldTs at htm
    rw [hf, List.mem_range'_1] at htm
    have ht1 := Coord.fieldDigits_le hb0 hq.le hf
    exact ((Shape.mem_slicesOf_iff hb0 hf0 hq.le hk1k (by omega)).mp hpt).1
  -- unfold the survivor
  unfold sliceSurvivors at hs
  simp only [List.mem_flatMap, List.mem_range, List.mem_filterMap] at hs
  obtain ⟨cl, -, d, hd, t, ht, x, -, hx⟩ := hs
  split_ifs at hx with hcond
  simp only [Option.some.injEq] at hx
  subst hx
  obtain ⟨-, hlo', hhi'⟩ := hcond
  have htu := mem_of_mem_probesOf ht
  have hleads := (mem_unitTops.mp htu).1
  obtain ⟨-, -, ha, hcc, -⟩ := mem_unitLeads.mp hleads
  have hlh : c.lo < c.hi := by
    have : t.lo ≤ t.hi := le_trans hlo' hhi'
    have h1 : c.lo ≤ t.lo := by rw [ha]; exact le_max_right _ _
    have h2 : t.hi ≤ c.hi - 1 := by rw [hcc]; exact min_le_right _ _
    omega
  have hstep : 0 < c.b ^ (sh.k - 1 - sh.f0) := Nat.pow_pos hb0
  have hu : pip + d * c.b ^ (sh.k - 1 - sh.f0) < c.b ^ (sh.k - sh.f0) := by
    have hpow : c.b ^ (sh.k - sh.f0) = c.b * c.b ^ (sh.k - 1 - sh.f0) := by
      rw [← pow_succ']; congr 1; omega
    rw [hpow]
    calc pip + d * c.b ^ (sh.k - 1 - sh.f0) < c.b ^ (sh.k - 1 - sh.f0) + d * c.b ^ (sh.k - 1 - sh.f0) :=
          Nat.add_lt_add_right hpipb _
      _ = (d + 1) * c.b ^ (sh.k - 1 - sh.f0) := by ring
      _ ≤ c.b * c.b ^ (sh.k - 1 - sh.f0) := Nat.mul_le_mul_right _ hd
  obtain ⟨hlo, hhi, -, -, hunit⟩ :=
    unitTops_prefix (by omega) (by omega : sh.f0 ≤ sh.k) hlh hu htu hlo' hhi'
  refine ⟨hlo, hhi, ?_⟩
  set m := t.h * c.b ^ sh.k + d * c.b ^ (sh.k - 1) + x.1
  have hslice : m / c.b ^ sh.f0 % c.b ^ (sh.k - 1 - sh.f0) = pip := by
    rw [← Nat.mod_mod_of_dvd (m / c.b ^ sh.f0) (pow_dvd_pow c.b (by omega : sh.k - 1 - sh.f0 ≤ sh.k - sh.f0)),
      hunit, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hpipb]
  rw [← Coord.mem_fieldSlices_iff hb0 hk0 hf0 hq hk1k hf hlo hhi, hslice]
  exact hpip

/-- **END-MO, soundness.** Every number `searchField` returns for a valid
coordinate, a fitting shape and an accepted field is nice and has `v(n)` in the
field. -/
theorem searchField_sound {c : Coord} {sh : Shape} {vs vz : ℕ} {o : FieldOutcome} {n : ℕ}
    (hc : c.Valid) (ho : searchField c sh vs vz = some o) (hn : n ∈ o.nice) :
    IsNice c.b n ∧ vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz := by
  unfold searchField at ho
  split_ifs at ho with hcond
  obtain ⟨hfit, hsome⟩ := hcond
  obtain ⟨⟨t0, t1⟩, hf⟩ := Option.isSome_iff_exists.mp hsome
  simp only [Option.some.injEq] at ho
  subst ho
  simp only at hn
  rw [(List.mergeSort_perm _ _).mem_iff, List.mem_map] at hn
  obtain ⟨s, hs, rfl⟩ := hn
  rw [List.mem_filter, List.mem_filter, List.mem_flatMap] at hs
  obtain ⟨⟨⟨pip, hpip, hsv⟩, -⟩, hfc⟩ := hs
  obtain ⟨-, -, hv1, hv2⟩ := survivor_mem_field hc hfit hf hpip hsv
  exact ⟨(finalCheck_iff (by have := hc.1; omega)).mp hfc, hv1, hv2⟩

/-- END-MO, completeness, for a coordinate built by the executable constructor
`Coord.withDigits` (the model's `Coord::with_digits`). -/
theorem searchField_complete_of_withDigits {b k0 k1 q0 vs vz t0 t1 : ℕ} {c : Coord} {sh : Shape}
    (hc : Coord.withDigits b k0 k1 q0 = some c) (hfit : sh.Fits c)
    (hf : c.fieldDigits vs vz = some (t0, t1)) :
    ∃ o, searchField c sh vs vz = some o ∧
      ∀ n, IsNice c.b n → vs ≤ c.vOfN n → c.vOfN n < vs + vz → n ∈ o.nice :=
  searchField_complete (Coord.valid_of_withDigits hc) hfit hf

/-- END-MO, soundness, for a coordinate built by `Coord.withDigits`. -/
theorem searchField_sound_of_withDigits {b k0 k1 q0 vs vz n : ℕ} {c : Coord} {sh : Shape}
    {o : FieldOutcome} (hc : Coord.withDigits b k0 k1 q0 = some c)
    (ho : searchField c sh vs vz = some o) (hn : n ∈ o.nice) :
    IsNice c.b n ∧ vs ≤ c.vOfN n ∧ c.vOfN n < vs + vz :=
  searchField_sound (Coord.valid_of_withDigits hc) ho hn

end NiceMidOut
