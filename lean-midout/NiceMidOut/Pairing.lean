/-
L7, pairing: a nice `n`'s top mask (its certified digits at positions
`≥ k`) and its child mask (`lowSet b n k`, positions `< k`) are disjoint, so
the pair `(top, child)` passes the survivor test of `sliceSurvivors`, and,
through the chunk skip (`probeSurv_eq`, already proved in `RunProofs`), of the
run form too: `n` is reported, with the prefilter's verdict `true` (L8).

Reused from the earlier library: `disjoint_high_lowSet` (JOIN-3),
`highDigit_of_cert`, `le_certFloor`, `HighDigit.mono`. From this branch:
`cert_of_mem_unitTops`, `midPrefilter_of_mem_unitTops` (`Prefilter`),
`probeSurv_eq` (`RunProofs`).
-/
import NiceMidOut.Prefilter
import NiceMidOut.RunProofs

namespace NiceMidOut

open NiceSearch

/-- **L7.** For a nice `n` in the interval of a top of `unitTops` at `k`,
with both powers having at least `k` digits, the top's mask and `n`'s low
output digits below `k` are disjoint. -/
theorem disjoint_top_lowSet {b lo hi f0 k u n : ℕ} {t : Top} (hb : 2 ≤ b) (h : IsNice b n)
    (ht : t ∈ unitTops b lo hi f0 k u) (hlo : t.lo ≤ n) (hhi : n ≤ t.hi)
    (h2 : k ≤ numDigits b (n ^ 2)) (h3 : k ≤ numDigits b (n ^ 3)) :
    Disjoint t.mask (lowSet b n k) :=
  disjoint_high_lowSet hb h h2 h3 fun x hx =>
    HighDigit.mono (le_certFloor b t.lo t.hi k)
      (highDigit_of_cert hb hlo hhi (cert_of_mem_unitTops ht).1 x hx)

/-- **L7, the survivor test.** For a nice `n` written as
`t.h·b^k + d·b^(k−1) + r` with `t` a top of `unitTops` whose interval holds
`n`, the pair of `t` with the child `(r, lowSet b n k)` is a survivor of
`sliceSurvivors`'s test: the masks are disjoint and `n` is in the interval. -/
theorem pair_passes_of_isNice {b lo hi f0 k u n d r : ℕ} {t : Top} (hb : 2 ≤ b) (h : IsNice b n)
    (ht : t ∈ unitTops b lo hi f0 k u) (hn : n = t.h * b ^ k + d * b ^ (k - 1) + r)
    (hlo : t.lo ≤ n) (hhi : n ≤ t.hi) (h2 : k ≤ numDigits b (n ^ 2))
    (h3 : k ≤ numDigits b (n ^ 3)) :
    Disjoint t.mask (lowSet b n k) ∧ t.lo ≤ t.h * b ^ k + d * b ^ (k - 1) + r ∧
      t.h * b ^ k + d * b ^ (k - 1) + r ≤ t.hi := by
  subst hn
  exact ⟨disjoint_top_lowSet hb h ht hlo hhi h2 h3, hlo, hhi⟩

/-- **L7 with L8, the run form's pair.** The same pair through `pairSurv`
(the run form's pair test, `cpu.rs:849–861`) reports `(d, n, true)`. -/
theorem pairSurv_of_isNice {b lo hi f0 k u n d r : ℕ} {t : Top} (hb : 2 ≤ b) (h : IsNice b n)
    (ht : t ∈ unitTops b lo hi f0 k u) (hn : n = t.h * b ^ k + d * b ^ (k - 1) + r)
    (hlo : t.lo ≤ n) (hhi : n ≤ t.hi) (h2 : k ≤ numDigits b (n ^ 2))
    (h3 : k ≤ numDigits b (n ^ 3)) :
    pairSurv b k d t (r, lowSet b n k) = some (d, n, true) := by
  have hp := pair_passes_of_isNice hb h ht hn hlo hhi h2 h3
  have hf := midPrefilter_of_mem_unitTops hb h ht hlo hhi
  unfold pairSurv
  simp only
  rw [← hn] at hp ⊢
  rw [if_pos hp, hf]

/-- **L7, the chunk skip.** In any chunk holding the nice child, the run
form's probe of `t` reports `(d, n, true)`: the skip on the chunk's common
mask never drops it (`probeSurv_eq`). -/
theorem mem_probeSurv_of_isNice {b lo hi f0 k u n d r : ℕ} {t : Top}
    {ch : List (ℕ × Finset ℕ)} (hb : 2 ≤ b) (h : IsNice b n)
    (ht : t ∈ unitTops b lo hi f0 k u) (hn : n = t.h * b ^ k + d * b ^ (k - 1) + r)
    (hlo : t.lo ≤ n) (hhi : n ≤ t.hi) (h2 : k ≤ numDigits b (n ^ 2))
    (h3 : k ≤ numDigits b (n ^ 3)) (hch : (r, lowSet b n k) ∈ ch) :
    (d, n, true) ∈ probeSurv b k d t ch := by
  rw [probeSurv_eq, List.mem_filterMap]
  exact ⟨_, hch, pairSurv_of_isNice hb h ht hn hlo hhi h2 h3⟩

end NiceMidOut
