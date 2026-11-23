/-
L3 (residue classes) and L6 (class compatibility), about the model's `roots`
and `probesOf` (`Join.lean`; Rust `arith::roots`, `arith.rs:119`, and the probe
loop of `SliceSetup::class`, `cpu.rs:794–799`).

- L3 `mod_mem_roots_of_isNice`: a nice `n` has `n mod (b − 1)` among the roots;
  `roots_nodup`, `mem_roots`: the roots are distinct residues below `b − 1`.
- L6 `mem_probesOf_of_isNice`: for a nice `n = h·b^k + d·b^(k−1) + r`, every
  top of lead `h` in a unit's list is probed against class `r mod (b − 1)` at
  unit `d`; `count_probesOf_of_isNice`: exactly as often as it is in the list
  (the roots are distinct, and a top's class picks one root).

Reused from the earlier library: `joinRoots` (= `roots`),
`mem_joinRoots_of_isNice`.
-/
import NiceMidOut.Join

namespace NiceMidOut

open NiceSearch

/-! ### L3 -/

/-- L3. A nice number's residue mod `b − 1` is a root. -/
theorem mod_mem_roots_of_isNice {b n : ℕ} (hb : 2 ≤ b) (h : IsNice b n) :
    n % (b - 1) ∈ roots b :=
  mem_joinRoots_of_isNice hb h

theorem mem_roots {b r : ℕ} :
    r ∈ roots b ↔ r < b - 1 ∧ (r ^ 2 + r ^ 3) % (b - 1) = residueTarget b := by
  unfold roots joinRoots
  rw [List.mem_filter, List.mem_range, decide_eq_true_iff]

theorem roots_nodup (b : ℕ) : (roots b).Nodup :=
  List.nodup_range.filter _

/-! ### L6 -/

/-- With `n ≡ h + x (mod m)`, the class of `h` is `n`'s minus `x`'s, the way
the probe loop computes it. -/
theorem mod_sub_class {m h x n : ℕ} (hm : 0 < m) (hn : n % m = (h + x) % m) :
    h % m = (n % m + m - x % m) % m := by
  have hx : x % m < m := Nat.mod_lt _ hm
  have h2 : x % m + (n % m + m - x % m) ≡ x % m + h [MOD m] := by
    rw [Nat.add_sub_cancel' (by omega)]
    calc n % m + m ≡ n % m [MOD m] := by simp [Nat.ModEq]
      _ ≡ n [MOD m] := Nat.mod_modEq n m
      _ ≡ h + x [MOD m] := hn
      _ ≡ x % m + h [MOD m] := by
        rw [add_comm]; exact (Nat.mod_modEq x m).symm.add_right h
  exact (Nat.ModEq.add_left_cancel' (x % m) h2).symm

/-- `b ≡ 1 (mod b − 1)`, so `h·b^k + d·b^(k−1) + r ≡ h + d + r`. -/
theorem class_split {b h d r k k' : ℕ} (hb : 1 ≤ b) :
    (h * b ^ k + d * b ^ k' + r) % (b - 1) = (h + (r % (b - 1) + d)) % (b - 1) := by
  have h1 : b ≡ 1 [MOD b - 1] := Nat.modEq_sub hb
  have hk : b ^ k ≡ 1 [MOD b - 1] := by simpa using h1.pow k
  have hk' : b ^ k' ≡ 1 [MOD b - 1] := by simpa using h1.pow k'
  have : h * b ^ k + d * b ^ k' + r ≡ h * 1 + d * 1 + r % (b - 1) [MOD b - 1] :=
    ((hk.mul_left h).add (hk'.mul_left d)).add (Nat.mod_modEq r (b - 1)).symm
  rw [this]
  congr 1
  ring

/-- L6 (membership). A top of lead `h` in the list `tv` is among the probes of
class `r mod (b − 1)` at unit `d`, when `n = h·b^k + d·b^(k−1) + r` is nice:
it sits in the bucket of root `n mod (b − 1)`. -/
theorem mem_probesOf_of_isNice {b k n d r : ℕ} {tv : List Top} {t : Top} (hb : 2 ≤ b)
    (h : IsNice b n) (hn : n = t.h * b ^ k + d * b ^ (k - 1) + r) (ht : t ∈ tv) :
    t ∈ probesOf b tv (r % (b - 1)) d := by
  unfold probesOf
  rw [List.mem_flatMap]
  refine ⟨n % (b - 1), mod_mem_roots_of_isNice hb h, List.mem_filter.mpr ⟨ht, ?_⟩⟩
  exact decide_eq_true (mod_sub_class (by omega) (by rw [hn]; exact class_split (by omega)))

/-- The bucket condition picks one root: two residues below `m` with the same
`(rt + m − x) mod m` are equal. -/
theorem root_unique {m x rt rt' : ℕ} (hx : x < m) (hr : rt < m) (hr' : rt' < m)
    (h : (rt + m - x) % m = (rt' + m - x) % m) : rt = rt' := by
  have e1 : (rt + m - x) % m = if rt < x then rt + m - x else rt - x := by
    split_ifs with hlt
    · exact Nat.mod_eq_of_lt (by omega)
    · rw [show rt + m - x = rt - x + m by omega, Nat.add_mod_right, Nat.mod_eq_of_lt (by omega)]
  have e2 : (rt' + m - x) % m = if rt' < x then rt' + m - x else rt' - x := by
    split_ifs with hlt
    · exact Nat.mod_eq_of_lt (by omega)
    · rw [show rt' + m - x = rt' - x + m by omega, Nat.add_mod_right, Nat.mod_eq_of_lt (by omega)]
  rw [e1, e2] at h
  split_ifs at h <;> omega

theorem sum_map_ite_count (l : List ℕ) (a C : ℕ) :
    (l.map fun x => if x = a then C else 0).sum = l.count a * C := by
  induction l with
  | nil => simp
  | cons y l ih =>
    rw [List.map_cons, List.sum_cons, ih, List.count_cons]
    by_cases hy : y = a
    · subst hy; simp; ring
    · simp [hy]

/-- L6 (exactly once). With `n = h·b^k + d·b^(k−1) + r` nice, a top of lead `h`
occurs among the probes of class `r mod (b − 1)` at unit `d` exactly as often
as in the unit's list: one root's bucket holds it, the others do not. -/
theorem count_probesOf_of_isNice {b k n d r : ℕ} {tv : List Top} {t : Top} (hb : 2 ≤ b)
    (h : IsNice b n) (hn : n = t.h * b ^ k + d * b ^ (k - 1) + r) :
    (probesOf b tv (r % (b - 1)) d).count t = tv.count t := by
  have hm : 0 < b - 1 := by omega
  have hx : (r % (b - 1) + d) % (b - 1) < b - 1 := Nat.mod_lt _ hm
  have hcls : t.h % (b - 1) = (n % (b - 1) + (b - 1) - (r % (b - 1) + d) % (b - 1)) % (b - 1) :=
    mod_sub_class hm (by rw [hn]; exact class_split (by omega))
  have hr0 := mod_mem_roots_of_isNice hb h
  have key : ∀ rt ∈ roots b,
      (tv.filter fun t' => t'.h % (b - 1) =
          (rt + (b - 1) - (r % (b - 1) + d) % (b - 1)) % (b - 1)).count t =
        if rt = n % (b - 1) then tv.count t else 0 := by
    intro rt hrt
    by_cases h2 : rt = n % (b - 1)
    · rw [if_pos h2, List.count_filter]
      subst h2
      exact decide_eq_true hcls
    · rw [if_neg h2, List.count_eq_zero]
      intro hmem
      rw [List.mem_filter, decide_eq_true_iff] at hmem
      exact h2 (root_unique hx (mem_roots.mp hrt).1 (Nat.mod_lt _ hm) (hmem.2.symm.trans hcls))
  unfold probesOf
  rw [List.count_flatMap]
  calc _ = ((roots b).map fun rt => if rt = n % (b - 1) then tv.count t else 0).sum := by
        congr 1; exact List.map_congr_left key
    _ = _ := by rw [sum_map_ite_count, List.count_eq_one_of_mem (roots_nodup b) hr0, one_mul]

end NiceMidOut
