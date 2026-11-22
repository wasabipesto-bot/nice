/-
The run form of the slice join reports the definition's survivors: the
survivors of `sliceRun` are a permutation of those of `sliceSurvivors`, with
each top's `mhi` replaced by the prefilter's verdict. The order differs in
two ways only: parents are taken in the setup's key order (a permutation of
`r` order), and the chunks are walked outside the probes.
-/
import NiceMidOut.Join

namespace NiceMidOut

open List

/-! ### List facts -/

theorem flatMap_append_perm {α β : Type} (l : List α) (f g : α → List β) :
    (l.flatMap fun a => f a ++ g a) ~ l.flatMap f ++ l.flatMap g := by
  induction l with
  | nil => simp
  | cons a l ih =>
    simp only [flatMap_cons, append_assoc]
    exact (ih.append_left (g a)).trans (perm_append_comm_assoc _ _ _) |>.append_left (f a)

/-- Two nested `flatMap`s commute up to permutation. -/
theorem flatMap_comm_perm {α β γ : Type} (l₁ : List α) (l₂ : List β) (f : α → β → List γ) :
    (l₁.flatMap fun a => l₂.flatMap fun b => f a b) ~
      (l₂.flatMap fun b => l₁.flatMap fun a => f a b) := by
  induction l₁ with
  | nil => simp
  | cons a l ih =>
    simp only [flatMap_cons]
    exact ((ih.append_left _)).trans (flatMap_append_perm l₂ (f a) _).symm

theorem flatMap_filterMap_flatten {α β : Type} (L : List (List α)) (f : α → Option β) :
    (L.flatMap fun ch => ch.filterMap f) = L.flatten.filterMap f := by
  induction L with
  | nil => simp
  | cons ch L ih => simp [ih, filterMap_append]

theorem chunksOf_aux {α : Type} (n : ℕ) (l : List α) (m : ℕ) :
    ((List.range m).map fun i => (l.drop (i * n)).take n).flatten = l.take (m * n) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [List.range_succ, List.map_append, List.flatten_append, ih]
    simp only [List.map_cons, List.map_nil, List.flatten_cons, List.flatten_nil,
      List.append_nil]
    rw [← List.take_add, Nat.succ_mul]

/-- The chunks concatenate to the list. -/
theorem chunksOf_flatten {α : Type} {n : ℕ} (hn : 0 < n) (l : List α) :
    (chunksOf n l).flatten = l := by
  unfold chunksOf
  rw [chunksOf_aux]
  apply List.take_of_length_le
  have h1 := Nat.div_add_mod (l.length + n - 1) n
  have h2 := Nat.mod_lt (l.length + n - 1) hn
  rw [Nat.mul_comm] at h1
  generalize (l.length + n - 1) / n * n = Q at *
  generalize (l.length + n - 1) % n = R at *
  omega

/-- The common mask lies in every child's mask. -/
theorem foldl_inter_subset (l : List (ℕ × Finset ℕ)) :
    ∀ a : Finset ℕ, l.foldl (fun acc x => acc ∩ x.2) a ⊆ a ∧
      ∀ x ∈ l, l.foldl (fun acc x => acc ∩ x.2) a ⊆ x.2 := by
  induction l with
  | nil => simp
  | cons y l ih =>
    intro a
    obtain ⟨h1, h2⟩ := ih (a ∩ y.2)
    refine ⟨h1.trans Finset.inter_subset_left, ?_⟩
    intro x hx
    rcases List.mem_cons.mp hx with rfl | hx
    · exact h1.trans Finset.inter_subset_right
    · exact h2 x hx

theorem chunkCommon_subset {ch : List (ℕ × Finset ℕ)} {x : ℕ × Finset ℕ} (hx : x ∈ ch) :
    chunkCommon ch ⊆ x.2 :=
  (foldl_inter_subset ch _).2 x hx

/-- The chunk skip loses nothing: when the common mask meets the top's, no
child of the chunk is disjoint from the top. -/
theorem probeSurv_eq (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) :
    probeSurv b k d t ch = ch.filterMap (pairSurv b k d t) := by
  unfold probeSurv
  split_ifs with h
  · symm
    rw [List.filterMap_eq_nil_iff]
    intro x hx
    obtain ⟨z, hz⟩ := h
    rw [Finset.mem_inter] at hz
    have hzx : z ∈ x.2 := chunkCommon_subset hx hz.1
    unfold pairSurv
    rw [if_neg]
    rintro ⟨hd, -⟩
    exact Finset.disjoint_left.mp hd hz.2 hzx
  · rfl

/-! ### The refinement -/

theorem getD_map_range {α : Type} (f : ℕ → α) {b d : ℕ} (a : α) (hd : d < b) :
    ((List.range b).map f).getD d a = f d := by
  simp [List.getD_eq_getElem?_getD, hd]

/-- The definition's survivors with the prefilter's verdict in place of `mhi`. -/
theorem sliceSurvivors_map (b lo hi : ℕ) (sh : Shape) (pip : ℕ) :
    (sliceSurvivors b lo hi sh pip).map (fun x => (x.1, x.2.1, midPrefilter b sh.k x.2.1 x.2.2)) =
      (List.range (b - 1)).flatMap fun c => (List.range b).flatMap fun d =>
        (probesOf b (unitTops b lo hi sh.f0 sh.k (pip + d * b ^ (sh.k - 1 - sh.f0))) c d).flatMap
          fun t => (kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d).filterMap
            (pairSurv b sh.k d t) := by
  unfold sliceSurvivors
  simp only [List.map_flatMap, List.map_filterMap]
  congr 1; funext c; congr 1; funext d; congr 1; funext t; congr 1; funext x
  unfold pairSurv
  dsimp only
  split_ifs <;> rfl

/-- **The run reports the definition's survivors**: `sliceRun`'s survivor list
is a permutation of `sliceSurvivors`'s, with `mhi` replaced by the prefilter's
verdict. -/
theorem sliceRun_surv_perm (b lo hi : ℕ) (sh : Shape) (pip : ℕ) :
    (sliceRun b lo hi sh pip).surv ~
      (sliceSurvivors b lo hi sh pip).map
        (fun x => (x.1, x.2.1, midPrefilter b sh.k x.2.1 x.2.2)) := by
  rw [sliceSurvivors_map]
  unfold sliceRun
  simp only
  apply List.Perm.flatMap_left
  intro c _
  apply List.Perm.flatMap_left
  intro d hd
  rw [List.mem_range] at hd
  unfold unitSurv unitRun
  simp only
  have htv : (sliceSetup b lo hi sh pip).topsByD.getD d [] =
      unitTops b lo hi sh.f0 sh.k (pip + d * b ^ (sh.k - 1 - sh.f0)) := by
    unfold sliceSetup
    exact getD_map_range _ _ hd
  rw [htv]
  generalize probesOf b (unitTops b lo hi sh.f0 sh.k (pip + d * b ^ (sh.k - 1 - sh.f0))) c d = P
  have hK : kidsOf b ((sliceSetup b lo hi sh pip).ps.filter fun p => p.cls = c) d ~
      kidsOf b ((parents b sh pip).filter fun p => p.cls = c) d := by
    unfold kidsOf sliceSetup
    exact ((List.mergeSort_perm _ _).filter _).filterMap _
  simp only [probeSurv_eq]
  refine (flatMap_comm_perm _ _ _).trans ?_
  apply List.Perm.flatMap_left
  intro t _
  rw [flatMap_filterMap_flatten, chunksOf_flatten (by norm_num)]
  exact hK.filterMap _

/-! ### Counters -/

theorem Counts.sum_survivors (l : List Counts) :
    (Counts.sum l).survivors = (l.map (·.survivors)).sum := by
  induction l with
  | nil => rfl
  | cons a l ih => simp [Counts.sum, Counts.add] at ih ⊢; rw [ih]

theorem Counts.sum_checked (l : List Counts) :
    (Counts.sum l).checked = (l.map (·.checked)).sum := by
  induction l with
  | nil => rfl
  | cons a l ih => simp [Counts.sum, Counts.add] at ih ⊢; rw [ih]

theorem probeCounts_survivors (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) :
    (probeCounts b k d t ch).survivors = (probeSurv b k d t ch).length := by
  unfold probeCounts probeSurv
  split_ifs <;> simp

theorem probeCounts_checked (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) :
    (probeCounts b k d t ch).checked = ((probeSurv b k d t ch).filter fun x => x.2.2).length := by
  unfold probeCounts probeSurv
  split_ifs <;> simp

/-- The counter `survivors` is the number of survivors the run reports. -/
theorem sliceRun_survivors (b lo hi : ℕ) (sh : Shape) (pip : ℕ) :
    (sliceRun b lo hi sh pip).counts.survivors = (sliceRun b lo hi sh pip).surv.length := by
  unfold sliceRun unitCounts unitSurv
  simp [Counts.add, Counts.sum_survivors, List.length_flatMap, probeCounts_survivors,
    Function.comp_def]

/-- The counter `checked` is the number of reported survivors that pass the
prefilter. -/
theorem sliceRun_checked (b lo hi : ℕ) (sh : Shape) (pip : ℕ) :
    (sliceRun b lo hi sh pip).counts.checked =
      ((sliceRun b lo hi sh pip).surv.filter fun x => x.2.2).length := by
  unfold sliceRun unitCounts unitSurv
  simp [Counts.add, Counts.sum_checked, List.length_flatMap, List.filter_flatMap,
    probeCounts_checked, Function.comp_def]

theorem Counts.sum_parents (l : List Counts) :
    (Counts.sum l).parents = (l.map (·.parents)).sum := by
  induction l with
  | nil => rfl
  | cons a l ih => simp [Counts.sum, Counts.add] at ih ⊢; rw [ih]

theorem probeCounts_parents (b k d : ℕ) (t : Top) (ch : List (ℕ × Finset ℕ)) :
    (probeCounts b k d t ch).parents = 0 := by
  unfold probeCounts
  split_ifs <;> rfl

/-- The counter `parents` is the number of the slice's parents. -/
theorem sliceRun_parents (b lo hi : ℕ) (sh : Shape) (pip : ℕ) :
    (sliceRun b lo hi sh pip).counts.parents = (parents b sh pip).length := by
  have hu : ∀ st c d, (unitCounts b sh st c d).parents = 0 := by
    intro st c d
    unfold unitCounts
    simp only [Counts.add, Counts.sum_parents, List.map_map, Function.comp_def,
      probeCounts_parents]
    simp
  unfold sliceRun
  simp only [Counts.add, Counts.sum_parents, List.map_map, Function.comp_def, hu]
  simp [sliceSetup, List.length_mergeSort]

end NiceMidOut
