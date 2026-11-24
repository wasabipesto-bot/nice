/-
Each number appears at most once in a field's outcome (`searchField_nice_nodup`):
the list `o.nice` has no repeats. The survivors' numbers already have none
(`sliceSurvivors_nodup_n` for a slice; across the slices of a field, a number's
slice is its digits `[f0, k − 1)`, `survivor_slice`): a survivor's `n` is
`h·b^k + d·b^(k−1) + r` with the parent's `r < b^(k−1)` and `d < b`, so `n`
gives back the unit digit `d`, the top's lead `h` (which determines the top of
its unit, `top_eq_of_h`), the parent's `r` (which determines the parent,
`parent_eq_of_r`, and its child) and the parent's class `r mod (b − 1)`; the
lists walked (classes, unit digits, probed tops, children) have no repeats
(`unitTops_nodup`, `probesOf_nodup`, `kidsOf_nodup`, `fieldSlices_nodup`).
-/
import NiceMidOut.EndToEnd
import NiceMidOut.NodupMap

namespace NiceMidOut

open NiceSearch


/-! ### Tops -/

theorem unitLeads_nodup (b lo hi f0 k u : ℕ) : (unitLeads b lo hi f0 k u).Nodup := by
  unfold unitLeads
  refine nodup_of_map Prod.fst (nodup_map_filterMap List.nodup_range' ?_)
  intro a _ a' _ x hx y hy hxy
  simp only [Option.mem_def] at hx hy
  split at hx
  · split at hy
    · rw [← Option.some.inj hx, ← Option.some.inj hy] at hxy
      exact hxy
    · cases hy
  · cases hx

theorem unitTops_nodup (b lo hi f0 k u : ℕ) : (unitTops b lo hi f0 k u).Nodup := by
  unfold unitTops
  refine nodup_filterMap_of (unitLeads_nodup b lo hi f0 k u) ?_
  intro x hx x' hx' t ht ht'
  rw [Option.mem_def, Option.map_eq_some_iff] at ht ht'
  obtain ⟨m, -, hm⟩ := ht
  obtain ⟨m', -, hm'⟩ := ht'
  have hh : x.1 = x'.1 := congrArg Top.h (hm.trans hm'.symm)
  obtain ⟨l, a, c⟩ := x
  obtain ⟨l', a', c'⟩ := x'
  obtain ⟨-, -, ha, hc, -⟩ := mem_unitLeads.mp hx
  obtain ⟨-, -, ha', hc', -⟩ := mem_unitLeads.mp hx'
  change l = l' at hh
  subst hh
  subst ha
  subst hc
  subst ha'
  subst hc'
  rfl

/-- A top of a unit is determined by its lead. -/
theorem top_eq_of_h {b lo hi f0 k u : ℕ} {t t' : Top} (ht : t ∈ unitTops b lo hi f0 k u)
    (ht' : t' ∈ unitTops b lo hi f0 k u) (hh : t.h = t'.h) : t = t' := by
  obtain ⟨hl, hm, hmh⟩ := mem_unitTops.mp ht
  obtain ⟨hl', hm', hmh'⟩ := mem_unitTops.mp ht'
  obtain ⟨-, -, ha, hc, -⟩ := mem_unitLeads.mp hl
  obtain ⟨-, -, ha', hc', -⟩ := mem_unitLeads.mp hl'
  have hlo : t.lo = t'.lo := by rw [ha, ha', hh]
  have hhi : t.hi = t'.hi := by rw [hc, hc', hh]
  have hmask : t.mask = t'.mask := by
    rw [hlo, hhi] at hm
    rw [hm] at hm'
    exact Option.some.inj hm'
  have hmhi : t.mhi = t'.mhi := by rw [hmh, hmh', hlo, hhi]
  cases t
  cases t'
  simp only [Top.mk.injEq]
  exact ⟨hh, hmask, hmhi, hlo, hhi⟩

theorem probesOf_nodup {b c d : ℕ} {tv : List Top} (hb : 2 ≤ b) (htv : tv.Nodup) :
    (probesOf b tv c d).Nodup := by
  unfold probesOf
  refine nodup_flatMap_of (roots_nodup b) (fun _ _ => htv.sublist List.filter_sublist) ?_
  intro rt hrt rt' hrt' t ht ht'
  rw [List.mem_filter] at ht ht'
  have h1 := of_decide_eq_true ht.2
  have h2 := of_decide_eq_true ht'.2
  exact root_unique (m := b - 1) (x := (c + d) % (b - 1)) (Nat.mod_lt _ (by omega)) (mem_roots.mp hrt).1 (mem_roots.mp hrt').1
    (h1.symm.trans h2)

/-! ### Parents and children -/

/-- A parent of a slice is determined by its `r`. -/
theorem parent_eq_of_r {b : ℕ} {sh : Shape} {pip : ℕ} (hb : 2 ≤ b) {p p' : Parent}
    (hp : p ∈ parents b sh pip) (hp' : p' ∈ parents b sh pip) (hr : p.r = p'.r) : p = p' := by
  obtain ⟨e, -, -, hm⟩ := (mem_parents_iff hb p).mp hp
  obtain ⟨e', -, -, hm'⟩ := (mem_parents_iff hb p').mp hp'
  have hmask : p.mask = p'.mask := by
    rw [hr] at hm
    rw [hm] at hm'
    exact Option.some.inj hm'
  calc p = mkParent b sh.k (p.r, p.mask) := e
    _ = mkParent b sh.k (p'.r, p'.mask) := by rw [hr, hmask]
    _ = p' := e'.symm

theorem kid_facts {b : ℕ} {sh : Shape} {pip c d : ℕ} {x : ℕ × Finset ℕ} (hb : 2 ≤ b)
    (hx : x ∈ kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d) :
    x.1 < b ^ (sh.k - 1) ∧ x.1 % (b - 1) = c ∧
      ∃ p ∈ parents b sh pip, p.r = x.1 ∧ childMask b p d = some x.2 := by
  unfold kidsOf at hx
  rw [List.mem_filterMap] at hx
  obtain ⟨p, hp, hpx⟩ := hx
  rw [List.mem_filter] at hp
  obtain ⟨hp, hpc⟩ := hp
  have hpc' : p.cls = c := of_decide_eq_true hpc
  rw [Option.map_eq_some_iff] at hpx
  obtain ⟨m, hm, rfl⟩ := hpx
  obtain ⟨e, hlt, -, -⟩ := (mem_parents_iff hb p).mp hp
  have hcls : p.cls = p.r % (b - 1) := (congrArg Parent.cls e).trans rfl
  have hc2 : p.r % (b - 1) = c := by rw [← hcls]; exact hpc'
  exact ⟨hlt, hc2, p, hp, rfl, hm⟩

theorem kidsOf_nodup {b : ℕ} {sh : Shape} {pip c d : ℕ} (hb : 2 ≤ b) :
    (kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d).Nodup := by
  unfold kidsOf
  refine nodup_filterMap_of ((parents_nodup hb sh pip).sublist List.filter_sublist) ?_
  intro p hp p' hp' x hx hx'
  rw [List.mem_filter] at hp hp'
  rw [Option.mem_def, Option.map_eq_some_iff] at hx hx'
  obtain ⟨m, -, hm⟩ := hx
  obtain ⟨m', -, hm'⟩ := hx'
  exact parent_eq_of_r hb hp.1 hp'.1 (congrArg Prod.fst (hm.trans hm'.symm))

/-- A child is determined by its `r`. -/
theorem kid_eq_of_fst {b : ℕ} {sh : Shape} {pip c d : ℕ} {x x' : ℕ × Finset ℕ} (hb : 2 ≤ b)
    (hx : x ∈ kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d)
    (hx' : x' ∈ kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d) (h : x.1 = x'.1) :
    x = x' := by
  obtain ⟨-, -, p, hp, hpr, hm⟩ := kid_facts hb hx
  obtain ⟨-, -, p', hp', hpr', hm'⟩ := kid_facts hb hx'
  have hpp : p = p' := parent_eq_of_r hb hp hp' (hpr.trans (h.trans hpr'.symm))
  subst hpp
  rw [hm] at hm'
  exact Prod.ext h (Option.some.inj hm')

/-! ### One slice -/

/-- **A slice's survivors have distinct numbers.** -/
theorem sliceSurvivors_nodup_n {b lo hi : ℕ} {sh : Shape} {pip : ℕ} (hb : 2 ≤ b)
    (hk : 1 ≤ sh.k) : ((sliceSurvivors b lo hi sh pip).map fun s => s.2.1).Nodup := by
  have hB : 0 < b ^ (sh.k - 1) := Nat.pow_pos (by omega)
  have hpow : b ^ sh.k = b * b ^ (sh.k - 1) := by
    rw [← pow_succ']
    congr 1
    omega
  have key : ∀ {c d : ℕ} {t : Top} {x : ℕ × Finset ℕ}, d < b →
      x ∈ kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d →
      (t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1) % b ^ (sh.k - 1) % (b - 1) = c ∧
      (t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1) / b ^ (sh.k - 1) % b = d ∧
      (t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1) / b ^ sh.k = t.h ∧
      (t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1) % b ^ (sh.k - 1) = x.1 := by
    intro c d t x hd hx
    obtain ⟨hx1, hxc, -⟩ := kid_facts hb hx
    obtain ⟨e1, e2, e3⟩ := split_read (h := t.h) hB hd hx1
    rw [hpow, e1, e2, e3]
    exact ⟨hxc, rfl, rfl, rfl⟩
  simp only [sliceSurvivors]
  refine nodup_map_flatMap List.nodup_range ?_ ?_
  · intro c _
    refine nodup_map_flatMap List.nodup_range ?_ ?_
    · intro d hd
      rw [List.mem_range] at hd
      refine nodup_map_flatMap (probesOf_nodup hb (unitTops_nodup _ _ _ _ _ _)) ?_ ?_
      · intro t _
        refine nodup_map_filterMap (kidsOf_nodup hb) ?_
        intro x hx x' hx' s hs s' hs' hss
        simp only [Option.mem_def] at hs hs'
        obtain rfl := ite_some_eq hs
        obtain rfl := ite_some_eq hs'
        exact kid_eq_of_fst hb hx hx'
          ((key (t := t) hd hx).2.2.2.symm.trans
            ((congrArg (· % b ^ (sh.k - 1)) hss).trans (key (t := t) hd hx').2.2.2))
      · intro t ht t' ht' s hs s' hs' hss
        simp only [List.mem_filterMap] at hs hs'
        obtain ⟨x, hx, hs⟩ := hs
        obtain ⟨x', hx', hs'⟩ := hs'
        obtain rfl := ite_some_eq hs
        obtain rfl := ite_some_eq hs'
        exact top_eq_of_h (mem_of_mem_probesOf ht) (mem_of_mem_probesOf ht')
          ((key (t := t) hd hx).2.2.1.symm.trans
            ((congrArg (· / b ^ sh.k) hss).trans (key (t := t') hd hx').2.2.1))
    · intro d hd d' hd' s hs s' hs' hss
      rw [List.mem_range] at hd hd'
      simp only [List.mem_flatMap, List.mem_filterMap] at hs hs'
      obtain ⟨t, -, x, hx, hs⟩ := hs
      obtain ⟨t', -, x', hx', hs'⟩ := hs'
      obtain rfl := ite_some_eq hs
      obtain rfl := ite_some_eq hs'
      exact (key (t := t) hd hx).2.1.symm.trans
        ((congrArg (· / b ^ (sh.k - 1) % b) hss).trans (key (t := t') hd' hx').2.1)
  · intro c _ c' _ s hs s' hs' hss
    simp only [List.mem_flatMap, List.mem_filterMap, List.mem_range] at hs hs'
    obtain ⟨d, hd, t, -, x, hx, hs⟩ := hs
    obtain ⟨d', hd', t', -, x', hx', hs'⟩ := hs'
    obtain rfl := ite_some_eq hs
    obtain rfl := ite_some_eq hs'
    exact (key (t := t) hd hx).1.symm.trans
      ((congrArg (· % b ^ (sh.k - 1) % (b - 1)) hss).trans (key (t := t') hd' hx').1)
/-! ### A field -/

/-- A survivor of slice `pip` has `pip` as its digits `[f0, k − 1)`. -/
theorem survivor_slice {b lo hi : ℕ} {sh : Shape} {pip : ℕ} {s : ℕ × ℕ × Finset ℕ}
    (hb : 2 ≤ b) (hhi : 1 ≤ hi) (hfk : sh.f0 + 1 ≤ sh.k) (hpipb : pip < b ^ (sh.k - 1 - sh.f0))
    (hs : s ∈ sliceSurvivors b lo hi sh pip) :
    s.2.1 / b ^ sh.f0 % b ^ (sh.k - 1 - sh.f0) = pip := by
  unfold sliceSurvivors at hs
  simp only [List.mem_flatMap, List.mem_range, List.mem_filterMap] at hs
  obtain ⟨cl, -, d, hd, t, ht, x, -, hx⟩ := hs
  have hcond : t.lo ≤ t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1 ∧
      t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1 ≤ t.hi := by
    split at hx
    · rename_i hc
      exact ⟨hc.2.1, hc.2.2⟩
    · cases hx
  obtain rfl := ite_some_eq hx
  obtain ⟨hlo', hhi'⟩ := hcond
  have htu := mem_of_mem_probesOf ht
  have hleads := (mem_unitTops.mp htu).1
  obtain ⟨-, -, ha, hcc, -⟩ := mem_unitLeads.mp hleads
  have hlh : lo < hi := by
    have : t.lo ≤ t.hi := le_trans hlo' hhi'
    have h1 : lo ≤ t.lo := by rw [ha]; exact le_max_right _ _
    have h2 : t.hi ≤ hi - 1 := by rw [hcc]; exact min_le_right _ _
    omega
  have hu : pip + d * b ^ (sh.k - 1 - sh.f0) < b ^ (sh.k - sh.f0) := by
    have hpow : b ^ (sh.k - sh.f0) = b * b ^ (sh.k - 1 - sh.f0) := by
      rw [← pow_succ']
      congr 1
      omega
    rw [hpow]
    calc pip + d * b ^ (sh.k - 1 - sh.f0) < b ^ (sh.k - 1 - sh.f0) + d * b ^ (sh.k - 1 - sh.f0) :=
          Nat.add_lt_add_right hpipb _
      _ = (d + 1) * b ^ (sh.k - 1 - sh.f0) := by rw [Nat.add_mul, Nat.one_mul, Nat.add_comm]
      _ ≤ b * b ^ (sh.k - 1 - sh.f0) := Nat.mul_le_mul_right _ hd
  obtain ⟨-, -, -, -, hunit⟩ :=
    unitTops_prefix (by omega) (by omega : sh.f0 ≤ sh.k) hlh hu htu hlo' hhi'
  show (t.h * b ^ sh.k + d * b ^ (sh.k - 1) + x.1) / b ^ sh.f0 % b ^ (sh.k - 1 - sh.f0) = pip
  rw [← Nat.mod_mod_of_dvd _ (pow_dvd_pow b (by omega : sh.k - 1 - sh.f0 ≤ sh.k - sh.f0)),
    hunit, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hpipb]

/-- The slices of a field have no repeats. -/
theorem fieldSlices_nodup {c : Coord} {sh : Shape} {vs vz t0 t1 : ℕ} (hb : 0 < c.b)
    (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 ≤ c.k1) (hk : c.k1 < sh.k)
    (hf : c.fieldDigits vs vz = some (t0, t1)) : (fieldSlices c sh vs vz).Nodup := by
  have ht1 := Coord.fieldDigits_le hb hq hf
  have hts : c.fieldTs vs vz = List.range' t0 (t1 - t0) := by
    unfold Coord.fieldTs
    rw [hf]
  unfold fieldSlices
  rw [hts]
  refine nodup_flatMap_of List.nodup_range' (fun _ _ => Shape.slicesOf_nodup hb hf0 hq hk) ?_
  intro t ht t' ht' pip hp hp'
  rw [List.mem_range'_1] at ht ht'
  have e1 := ((Shape.mem_slicesOf_iff hb hf0 hq hk (by omega : t < _)).mp hp).2
  have e2 := ((Shape.mem_slicesOf_iff hb hf0 hq hk (by omega : t' < _)).mp hp').2
  exact e1.symm.trans e2

/-- A slice of a field is below `b^(k − 1 − f0)`. -/
theorem lt_of_mem_fieldSlices {c : Coord} {sh : Shape} {vs vz t0 t1 pip : ℕ} (hb : 0 < c.b)
    (hf0 : sh.f0 ≤ c.q0) (hq : c.q0 ≤ c.k1) (hk : c.k1 < sh.k)
    (hf : c.fieldDigits vs vz = some (t0, t1)) (hpip : pip ∈ fieldSlices c sh vs vz) :
    pip < c.b ^ (sh.k - 1 - sh.f0) := by
  unfold fieldSlices at hpip
  rw [List.mem_flatMap] at hpip
  obtain ⟨t, htm, hpt⟩ := hpip
  unfold Coord.fieldTs at htm
  rw [hf, List.mem_range'_1] at htm
  have ht1 := Coord.fieldDigits_le hb hq hf
  exact ((Shape.mem_slicesOf_iff hb hf0 hq hk (by omega)).mp hpt).1

/-- **Each number appears at most once in a field's outcome** (the audit's
C1): for a valid coordinate, the list of nice numbers `searchField` returns has
no repeats. -/
theorem searchField_nice_nodup {c : Coord} {sh : Shape} {vs vz : ℕ} {o : FieldOutcome}
    (hc : c.Valid) (ho : searchField c sh vs vz = some o) : o.nice.Nodup := by
  unfold searchField at ho
  split at ho
  · rename_i hcond
    obtain ⟨hfit, hsome⟩ := hcond
    obtain ⟨⟨t0, t1⟩, hf⟩ := Option.isSome_iff_exists.mp hsome
    have hb : 2 ≤ c.b := by have := hc.1; omega
    obtain ⟨hf0, hk1k, -⟩ := hfit
    have hq := hc.2.2.2.2.1
    have hhi : 1 ≤ c.hi := by have := Coord.two_le_hi hc; omega
    rw [← Option.some.inj ho]
    show (List.mergeSort _ _).Nodup
    rw [(List.mergeSort_perm _ _).nodup_iff]
    refine List.Nodup.sublist ((List.filter_sublist.trans List.filter_sublist).map _) ?_
    refine nodup_map_flatMap (fieldSlices_nodup (by omega) hf0 (Nat.le_of_lt hq) hk1k hf)
      (fun _ _ => sliceSurvivors_nodup_n hb (by omega)) ?_
    intro pip hpip pip' hpip' s hs s' hs' hss
    have e1 := survivor_slice hb hhi (by omega)
      (lt_of_mem_fieldSlices (by omega) hf0 (Nat.le_of_lt hq) hk1k hf hpip) hs
    have e2 := survivor_slice hb hhi (by omega)
      (lt_of_mem_fieldSlices (by omega) hf0 (Nat.le_of_lt hq) hk1k hf hpip') hs'
    rw [← e1, ← e2, hss]
  · cases ho

end NiceMidOut
