/-
L5(b), the converse: every child the join pairs (`kidsOf` over a slice's
parents of class `c`, at unit digit `d`) is a residue `r + d·b^(k−1)` with
`r` a parent of the slice, `r ≡ c (mod b − 1)`, whose `2k` low output digits
are distinct, and its mask is exactly those digits. With the parents'
exactness (`mem_parents_iff`) this says the children are exactly the depth-`k`
residues with the slice's digits that `bot_cert_direct` accepts. Needed for
the exactness of survivors (L11), not for completeness.
-/
import NiceMidOut.BottomsExact

namespace NiceMidOut

open NiceSearch

/-- **Children, soundly.** A child paired at unit digit `d` among the class-`c`
parents of slice `pip` (shape with `k ≥ 2`): its residue `r` is a parent's
(below `b^(k−1)`, the slice's digits, class `c`), the extended residue
`r + d·b^(k−1)` has distinct low output digits below `k`, and the child's mask
is them. -/
theorem kid_of_mem_kidsOf {b : ℕ} {sh : Shape} {pip c d : ℕ} {x : ℕ × Finset ℕ} (hb : 2 ≤ b)
    (hk : 2 ≤ sh.k) (hx : x ∈ kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d) :
    x.1 < b ^ (sh.k - 1) ∧ x.1 % (b - 1) = c ∧
      (∀ i, sh.f0 ≤ i → i < sh.k - 1 → digit b x.1 i = pip / b ^ (i - sh.f0) % b) ∧
      LowDistinct b (x.1 + d * b ^ (sh.k - 1)) sh.k ∧
      x.2 = lowSet b (x.1 + d * b ^ (sh.k - 1)) sh.k := by
  unfold kidsOf at hx
  rw [List.mem_filterMap] at hx
  obtain ⟨p, hp, hpx⟩ := hx
  rw [List.mem_filter, decide_eq_true_eq] at hp
  obtain ⟨hpm, hcls⟩ := hp
  obtain ⟨hpe, hlt, hforced, hcert⟩ := (mem_parents_iff hb p).mp hpm
  obtain ⟨hdist, hmask⟩ := botCertDirect_eq_some_iff.mp hcert
  obtain ⟨e2, e3⟩ := childMask_digits (b := b) (k := sh.k) (p.r, p.mask) d (by omega) hk
  rw [← hpe] at e2 e3
  have hmod : p.r + d * b ^ (sh.k - 1) ≡ p.r [MOD b ^ (sh.k - 1)] := by
    show (p.r + d * b ^ (sh.k - 1)) % b ^ (sh.k - 1) = p.r % b ^ (sh.k - 1)
    rw [Nat.add_mul_mod_self_right]
  have hL : lowSet b p.r (sh.k - 1) = lowSet b (p.r + d * b ^ (sh.k - 1)) (sh.k - 1) :=
    lowSet_congr hmod.symm
  have hcls' : p.r % (b - 1) = c := (congrArg Parent.cls hpe).symm.trans hcls
  have hsk : sh.k - 1 + 1 = sh.k := by omega
  unfold childMask at hpx
  simp only [e2, e3] at hpx
  split_ifs at hpx with hc
  · simp at hpx
  · simp only [Option.map_some, Option.some.injEq] at hpx
    subst hpx
    rw [hmask, hL, not_or, not_or] at hc
    refine ⟨hlt, hcls', hforced, ?_, ?_⟩
    · have := lowDistinct_succ (lowDistinct_congr hmod.symm hdist) hc.1 hc.2.1 hc.2.2
      rwa [hsk] at this
    · show insert _ (insert _ p.mask) = _
      rw [hmask, hL, ← lowSet_succ, hsk]

end NiceMidOut
