/-
L4 (i): the Rust's top certificate scan, as it runs, is the model's
`topCertSplit`.

`topCertScan` mirrors `top_cert_split` (`cpu.rs:181–216`) step for step: for
the square, then the cube, the digit lists of the two ends (least significant
first, `Nat.digits`); a power whose two lists differ in length is skipped
(`cpu.rs:196–198`); otherwise positions are walked from the top down to
`kpos`, stopping at the first position where the digits differ, each digit
added to the mask, the whole scan failing on a digit already in it, and the
digits at positions `≥ kmid` also added to `mhi`.

`topCertScan_eq`: for `b ≥ 2` and `kpos ≤ kmid` (the Rust's documented
precondition; `unit_tops` calls it with `kmid = kpos + 2`, `top_cert` with
`kmid = kpos`), `topCertScan b a c kpos kmid = topCertSplit b a c kpos kmid`.
For `kmid < kpos` the two differ (the model's `mhi` would include positions
below `kpos`); no caller does that.

Not modelled: the Rust's `U384` products and digit expansion (exact ℕ and
`Nat.digits` here), and the mask words (`Finset`).
-/
import NiceMidOut.TopsProofs

namespace NiceMidOut

open NiceSearch

/-! ### The scan -/

/-- The top-down walk over one power (`cpu.rs:199–213`): `j` is the position
above the next one read. -/
def scanLoop (dp dq : List ℕ) (kpos kmid : ℕ) :
    ℕ → Finset ℕ × Finset ℕ → Option (Finset ℕ × Finset ℕ)
  | 0, st => some st
  | j + 1, st =>
    if j < kpos then some st
    else if dp.getD j 0 ≠ dq.getD j 0 then some st
    else if dp.getD j 0 ∈ st.1 then none
    else scanLoop dp dq kpos kmid j
      (insert (dp.getD j 0) st.1, if kmid ≤ j then insert (dp.getD j 0) st.2 else st.2)

/-- One power (`cpu.rs:194–214`): skipped when the two digit lists differ in length. -/
def scanPow (kpos kmid : ℕ) (st : Finset ℕ × Finset ℕ) (pq : List ℕ × List ℕ) :
    Option (Finset ℕ × Finset ℕ) :=
  if pq.1.length ≠ pq.2.length then some st else scanLoop pq.1 pq.2 kpos kmid pq.1.length st

/-- `top_cert_split` (`cpu.rs:181`): the square's pair, then the cube's. -/
def topCertScan (b a c kpos kmid : ℕ) : Option (Finset ℕ × Finset ℕ) :=
  (scanPow kpos kmid (∅, ∅) (Nat.digits b (a ^ 2), Nat.digits b (c ^ 2))).bind fun st =>
    scanPow kpos kmid st (Nat.digits b (a ^ 3), Nat.digits b (c ^ 3))

/-! ### The walk's positions, and the insertions -/

/-- The positions the walk passes, top down. -/
def scanPos (dp dq : List ℕ) (kpos : ℕ) : ℕ → List ℕ
  | 0 => []
  | j + 1 => if j < kpos then [] else if dp.getD j 0 ≠ dq.getD j 0 then [] else j :: scanPos dp dq kpos j

/-- Adding the digits at positions `l`, in order, failing on a repeat. -/
def insLoop (dp : List ℕ) (kmid : ℕ) : List ℕ → Finset ℕ × Finset ℕ → Option (Finset ℕ × Finset ℕ)
  | [], st => some st
  | j :: l, st =>
    if dp.getD j 0 ∈ st.1 then none
    else insLoop dp kmid l
      (insert (dp.getD j 0) st.1, if kmid ≤ j then insert (dp.getD j 0) st.2 else st.2)

theorem scanLoop_eq (dp dq : List ℕ) (kpos kmid : ℕ) :
    ∀ j st, scanLoop dp dq kpos kmid j st = insLoop dp kmid (scanPos dp dq kpos j) st := by
  intro j
  induction j with
  | zero => intro st; rfl
  | succ j ih =>
    intro st
    by_cases h1 : j < kpos
    · rw [scanLoop, scanPos, if_pos h1, if_pos h1]; rfl
    by_cases h2 : dp.getD j 0 = dq.getD j 0
    · rw [scanLoop, scanPos, if_neg h1, if_neg h1, if_neg (not_not.mpr h2),
        if_neg (not_not.mpr h2), insLoop]
      split_ifs <;> first | rfl | exact ih _
    · rw [scanLoop, scanPos, if_neg h1, if_neg h1, if_pos h2, if_pos h2]; rfl

theorem insLoop_eq (dp : List ℕ) (kmid : ℕ) (l : List ℕ) :
    ∀ st, insLoop dp kmid l st =
      if (l.map (dp.getD · 0)).Nodup ∧ ∀ x ∈ l.map (dp.getD · 0), x ∉ st.1 then
        some (st.1 ∪ (l.map (dp.getD · 0)).toFinset,
          st.2 ∪ ((l.filter (kmid ≤ ·)).map (dp.getD · 0)).toFinset)
      else none := by
  induction l with
  | nil => intro st; simp [insLoop]
  | cons j l ih =>
    intro st
    by_cases hj : dp.getD j 0 ∈ st.1
    · rw [insLoop, if_pos hj, if_neg]
      rintro ⟨-, hx⟩
      exact hx (dp.getD j 0) (by rw [List.map_cons]; exact List.mem_cons.mpr (Or.inl rfl)) hj
    · rw [insLoop, if_neg hj, ih]
      have hc : ((l.map (dp.getD · 0)).Nodup ∧
            ∀ x ∈ l.map (dp.getD · 0), x ∉ insert (dp.getD j 0) st.1) ↔
          (((j :: l).map (dp.getD · 0)).Nodup ∧
            ∀ x ∈ (j :: l).map (dp.getD · 0), x ∉ st.1) := by
        simp only [List.map_cons, List.nodup_cons, List.mem_cons, Finset.mem_insert,
          forall_eq_or_imp]
        constructor
        · rintro ⟨hn, hx⟩
          exact ⟨⟨fun hm => (hx _ hm) (Or.inl rfl), hn⟩, hj, fun x hm h' => hx x hm (Or.inr h')⟩
        · rintro ⟨⟨hm, hn⟩, -, hx⟩
          refine ⟨hn, fun x hxm h' => ?_⟩
          rcases h' with rfl | h'
          · exact hm hxm
          · exact hx x hxm h'
      by_cases hcond : (l.map (dp.getD · 0)).Nodup ∧
          ∀ x ∈ l.map (dp.getD · 0), x ∉ insert (dp.getD j 0) st.1
      · rw [if_pos hcond, if_pos (hc.mp hcond)]
        congr 2
        · ext z; simp only [Finset.mem_union, Finset.mem_insert, List.mem_toFinset, List.map_cons,
            List.mem_cons]; tauto
        · ext z
          by_cases hk : kmid ≤ j
          · simp only [hk, if_true, Finset.mem_union, Finset.mem_insert, List.mem_toFinset,
              List.filter_cons, decide_true, List.map_cons, List.mem_cons]; tauto
          · simp only [hk, if_false, Finset.mem_union, List.mem_toFinset, List.filter_cons,
              decide_false, Bool.false_eq_true]
      · rw [if_neg hcond, if_neg (fun h' => hcond (hc.mpr h'))]

theorem mem_scanPos {dp dq : List ℕ} {kpos : ℕ} :
    ∀ j i, i ∈ scanPos dp dq kpos j ↔
      kpos ≤ i ∧ i < j ∧ ∀ i', i ≤ i' → i' < j → dp.getD i' 0 = dq.getD i' 0 := by
  intro j
  induction j with
  | zero => intro i; simp [scanPos]
  | succ j ih =>
    intro i
    by_cases h1 : j < kpos
    · simp only [scanPos, h1, if_true, List.not_mem_nil, false_iff]
      omega
    by_cases h2 : dp.getD j 0 = dq.getD j 0
    · simp only [scanPos, h1, h2, if_false, ne_eq, not_true_eq_false, List.mem_cons, ih]
      constructor
      · rintro (rfl | ⟨hk, hi, hall⟩)
        · refine ⟨by omega, by omega, fun i' h3 h4 => ?_⟩
          rw [show i' = i by omega]; exact h2
        · refine ⟨hk, by omega, fun i' h3 h4 => ?_⟩
          rcases (by omega : i' < j ∨ i' = j) with h | rfl
          · exact hall i' h3 h
          · exact h2
      · rintro ⟨hk, hi, hall⟩
        rcases (by omega : i = j ∨ i < j) with rfl | h
        · exact Or.inl rfl
        · exact Or.inr ⟨hk, h, fun i' h3 h4 => hall i' h3 (by omega)⟩
    · simp only [scanPos, h1, h2, if_false, ne_eq, not_false_eq_true, if_true, List.not_mem_nil,
        false_iff]
      rintro ⟨-, hi, hall⟩
      exact h2 (hall j (by omega) (by omega))

theorem scanPos_nodup (dp dq : List ℕ) (kpos : ℕ) : ∀ j, (scanPos dp dq kpos j).Nodup := by
  intro j
  induction j with
  | zero => simp [scanPos]
  | succ j ih =>
    simp only [scanPos]
    split_ifs
    · exact List.nodup_nil
    · exact List.nodup_nil
    · refine List.nodup_cons.mpr ⟨fun h => ?_, ih⟩
      have := ((mem_scanPos _ _).mp h).2.1
      omega

/-! ### The walk's positions are the certified ones -/

theorem certPositions_nodup (b x y c : ℕ) : (certPositions b x y c).Nodup :=
  List.nodup_range.filter _

/-- With equal lengths, the walk passes exactly the certified positions. -/
theorem scanPos_perm {b x y kpos : ℕ} (hb : 2 ≤ b) (hlen : numDigits b x = numDigits b y) :
    (scanPos (Nat.digits b x) (Nat.digits b y) kpos (Nat.digits b x).length).Perm
      (certPositions b x y kpos) := by
  have hl : (Nat.digits b x).length = numDigits b y := hlen
  rw [List.perm_ext_iff_of_nodup (scanPos_nodup _ _ _ _) (certPositions_nodup _ _ _ _)]
  intro i
  rw [mem_scanPos, mem_certPositions_iff hb, hl]
  simp only [← digit_eq_getD hb]
  constructor
  · rintro ⟨hk, hi, hall⟩
    refine ⟨hk, hi, fun j hj => ?_⟩
    rcases Nat.lt_or_ge j (numDigits b y) with h | h
    · exact hall j hj h
    · rw [digit_eq_zero_of_le hb (by omega), digit_eq_zero_of_le hb h]
  · rintro ⟨hk, hi, hall⟩
    exact ⟨hk, hi, fun j hj _ => hall j hj⟩

/-- One power of the scan, in terms of the certified positions. -/
theorem scanPow_eq {b x y kpos kmid : ℕ} (hb : 2 ≤ b) (hk : kpos ≤ kmid) (st : Finset ℕ × Finset ℕ) :
    scanPow kpos kmid st (Nat.digits b x, Nat.digits b y) =
      if ((certPositions b x y kpos).map (digit b x)).Nodup ∧
          ∀ z ∈ (certPositions b x y kpos).map (digit b x), z ∉ st.1 then
        some (st.1 ∪ ((certPositions b x y kpos).map (digit b x)).toFinset,
          st.2 ∪ ((certPositions b x y kmid).map (digit b x)).toFinset)
      else none := by
  unfold scanPow
  simp only
  by_cases hlen : (Nat.digits b x).length = (Nat.digits b y).length
  · rw [if_neg (not_not.mpr hlen), scanLoop_eq, insLoop_eq]
    have hf : (fun i => (Nat.digits b x).getD i 0) = digit b x :=
      funext fun i => (digit_eq_getD hb x i).symm
    rw [hf]
    have hp := scanPos_perm (kpos := kpos) hb hlen
    have hpm : ((scanPos (Nat.digits b x) (Nat.digits b y) kpos (Nat.digits b x).length).filter
        (kmid ≤ ·)).Perm (certPositions b x y kmid) := by
      rw [List.perm_ext_iff_of_nodup ((scanPos_nodup _ _ _ _).filter _)
        (certPositions_nodup _ _ _ _)]
      intro i
      rw [List.mem_filter, hp.mem_iff, mem_certPositions_iff hb, mem_certPositions_iff hb,
        decide_eq_true_iff]
      constructor
      · rintro ⟨⟨-, h2, h3⟩, h4⟩; exact ⟨h4, h2, h3⟩
      · rintro ⟨h1, h2, h3⟩; exact ⟨⟨by omega, h2, h3⟩, h1⟩
    have hc : (((scanPos (Nat.digits b x) (Nat.digits b y) kpos (Nat.digits b x).length).map
          (digit b x)).Nodup ∧ ∀ z ∈ (scanPos (Nat.digits b x) (Nat.digits b y) kpos
            (Nat.digits b x).length).map (digit b x), z ∉ st.1) ↔
        (((certPositions b x y kpos).map (digit b x)).Nodup ∧
          ∀ z ∈ (certPositions b x y kpos).map (digit b x), z ∉ st.1) := by
      rw [(hp.map (digit b x)).nodup_iff]
      simp only [(hp.map (digit b x)).mem_iff]
    split_ifs with h1 h2 h2
    · rw [List.toFinset_eq_of_perm _ _ (hp.map (digit b x)),
        List.toFinset_eq_of_perm _ _ (hpm.map (digit b x))]
    · exact absurd (hc.mp h1) h2
    · exact absurd (hc.mpr h2) h1
    · rfl
  · rw [if_pos hlen]
    have hne : numDigits b x ≠ numDigits b y := hlen
    rw [certPositions_eq_nil_of_numDigits_ne hb hne, certPositions_eq_nil_of_numDigits_ne hb hne]
    simp

/-- L4 (i). The Rust's scan is the model's `topCertSplit`: the certificate
`cert` at `kpos` and its digits at positions `≥ kmid`. -/
theorem topCertScan_eq {b a c kpos kmid : ℕ} (hb : 2 ≤ b) (hk : kpos ≤ kmid) :
    topCertScan b a c kpos kmid = topCertSplit b a c kpos kmid := by
  unfold topCertScan topCertSplit cert certDigits
  rw [scanPow_eq hb hk]
  by_cases h2 : ((certPositions b (a ^ 2) (c ^ 2) kpos).map (digit b (a ^ 2))).Nodup
  · rw [if_pos ⟨h2, by simp⟩, Option.bind_some, scanPow_eq hb hk]
    simp only [List.nodup_append, List.toFinset_append, Finset.empty_union]
    by_cases h3 : ((certPositions b (a ^ 3) (c ^ 3) kpos).map (digit b (a ^ 3))).Nodup ∧
        ∀ z ∈ (certPositions b (a ^ 3) (c ^ 3) kpos).map (digit b (a ^ 3)),
          z ∉ ((certPositions b (a ^ 2) (c ^ 2) kpos).map (digit b (a ^ 2))).toFinset
    · rw [if_pos h3, if_pos]
      · rfl
      · refine ⟨h2, h3.1, fun u hu v hv huv => ?_⟩
        subst huv
        exact h3.2 u hv (List.mem_toFinset.mpr hu)
    · rw [if_neg h3, if_neg]
      · rfl
      · rintro ⟨-, hn3, hd⟩
        exact h3 ⟨hn3, fun z hz hz2 => hd z (List.mem_toFinset.mp hz2) z hz rfl⟩
  · rw [if_neg (fun h => h2 h.1), Option.bind_none, if_neg]
    · rfl
    · simp only [List.nodup_append]
      exact fun h => h2 h.1

end NiceMidOut
