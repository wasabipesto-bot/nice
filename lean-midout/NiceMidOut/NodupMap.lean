/-
Two list lemmas (core Lean only) for "no value appears twice": the values
`π x` of a `flatMap` (or `filterMap`) over a list without repeats have no
repeats when each part's values have none and a value determines its part.
And the digit split `n = h·(b·B) + d·B + r` (with `r < B`, `d < b`) read back.
-/

namespace NiceMidOut

theorem nodup_map_flatMap {α β γ : Type} {π : β → γ} {F : α → List β} :
    ∀ {l : List α}, l.Nodup → (∀ a ∈ l, ((F a).map π).Nodup) →
      (∀ a ∈ l, ∀ a' ∈ l, ∀ x ∈ F a, ∀ y ∈ F a', π x = π y → a = a') →
      ((l.flatMap F).map π).Nodup
  | [], _, _, _ => by simp
  | a :: l, hl, hF, hsep => by
    rw [List.nodup_cons] at hl
    rw [List.flatMap_cons, List.map_append, List.nodup_append]
    refine ⟨hF a List.mem_cons_self,
      nodup_map_flatMap hl.2 (fun a' ha' => hF a' (List.mem_cons_of_mem _ ha'))
        (fun a1 h1 a2 h2 => hsep a1 (List.mem_cons_of_mem _ h1) a2 (List.mem_cons_of_mem _ h2)), ?_⟩
    intro z hz w hw hzw
    subst hzw
    rw [List.mem_map] at hz hw
    obtain ⟨x, hx, rfl⟩ := hz
    obtain ⟨y, hy, hxy⟩ := hw
    rw [List.mem_flatMap] at hy
    obtain ⟨a', ha', hy⟩ := hy
    have := hsep a List.mem_cons_self a' (List.mem_cons_of_mem _ ha') x hx y hy hxy.symm
    subst this
    exact hl.1 ha'

theorem nodup_map_filterMap {α β γ : Type} {π : β → γ} {f : α → Option β} :
    ∀ {l : List α}, l.Nodup →
      (∀ a ∈ l, ∀ a' ∈ l, ∀ x ∈ f a, ∀ y ∈ f a', π x = π y → a = a') →
      ((l.filterMap f).map π).Nodup
  | [], _, _ => by simp
  | a :: l, hl, hsep => by
    rw [List.nodup_cons] at hl
    have ih := nodup_map_filterMap (π := π) (f := f) hl.2
      (fun a1 h1 a2 h2 => hsep a1 (List.mem_cons_of_mem _ h1) a2 (List.mem_cons_of_mem _ h2))
    rw [List.filterMap_cons]
    cases hfa : f a with
    | none => exact ih
    | some x =>
      simp only [List.map_cons, List.nodup_cons]
      refine ⟨?_, ih⟩
      intro hmem
      rw [List.mem_map] at hmem
      obtain ⟨y, hy, hxy⟩ := hmem
      rw [List.mem_filterMap] at hy
      obtain ⟨a', ha', hy⟩ := hy
      have := hsep a List.mem_cons_self a' (List.mem_cons_of_mem _ ha') x (by rw [hfa]; rfl)
        y (by rw [hy]; rfl) hxy.symm
      subst this
      exact hl.1 ha'

/-- The digit split read back. -/
theorem split_read {b B h d r : Nat} (hB : 0 < B) (hd : d < b) (hr : r < B) :
    (h * (b * B) + d * B + r) % B = r ∧ (h * (b * B) + d * B + r) / B % b = d ∧
      (h * (b * B) + d * B + r) / (b * B) = h := by
  have hb : 0 < b := by omega
  have e1 : h * (b * B) + d * B + r = r + B * (h * b + d) := by
    rw [Nat.mul_add, Nat.mul_comm B (h * b), Nat.mul_assoc, Nat.mul_comm B d]; omega
  have hdiv : (h * (b * B) + d * B + r) / B = h * b + d := by
    rw [e1, Nat.add_mul_div_left _ _ hB, Nat.div_eq_of_lt hr, Nat.zero_add]
  refine ⟨?_, ?_, ?_⟩
  · rw [e1, Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt hr]
  · rw [hdiv, Nat.add_comm, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hd]
  · have h2 : (h * (b * B) + d * B + r) / (b * B) = (h * (b * B) + d * B + r) / B / b := by
      rw [Nat.div_div_eq_div_mul, Nat.mul_comm B b]
    rw [h2, hdiv, Nat.add_comm, Nat.add_mul_div_right _ _ hb, Nat.div_eq_of_lt hd, Nat.zero_add]

theorem nodup_flatMap_of {α β : Type} {F : α → List β} {l : List α} (hl : l.Nodup)
    (hF : ∀ a ∈ l, (F a).Nodup) (hsep : ∀ a ∈ l, ∀ a' ∈ l, ∀ x ∈ F a, x ∈ F a' → a = a') :
    (l.flatMap F).Nodup := by
  have h := nodup_map_flatMap (π := id) hl (fun a ha => by rw [List.map_id]; exact hF a ha)
    (fun a ha a' ha' x hx y hy hxy => hsep a ha a' ha' x hx (by rw [show x = y from hxy]; exact hy))
  rwa [List.map_id] at h

theorem nodup_filterMap_of {α β : Type} {f : α → Option β} {l : List α} (hl : l.Nodup)
    (hsep : ∀ a ∈ l, ∀ a' ∈ l, ∀ x ∈ f a, x ∈ f a' → a = a') : (l.filterMap f).Nodup := by
  have h := nodup_map_filterMap (π := id) hl
    (fun a ha a' ha' x hx y hy hxy => hsep a ha a' ha' x hx (by rw [show x = y from hxy]; exact hy))
  rwa [List.map_id] at h

theorem nodup_of_map {α β : Type} (f : α → β) : ∀ {l : List α}, (l.map f).Nodup → l.Nodup
  | [], _ => List.nodup_nil
  | a :: l, h => by
    rw [List.map_cons, List.nodup_cons] at h
    rw [List.nodup_cons]
    exact ⟨fun ha => h.1 (List.mem_map_of_mem ha), nodup_of_map f h.2⟩

theorem ite_some_eq {α : Type} {p : Prop} [Decidable p] {a b : α}
    (h : (if p then some a else none) = some b) : a = b := by
  split at h
  · exact Option.some.inj h
  · cases h

end NiceMidOut
