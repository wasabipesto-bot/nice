/-
The middle-out join's work unit: the coordinate `v` of a base and its
fields. Rust: `common/src/midout/coord.rs` (`Coord`, `pow`, `ndigits`) and
`Shape::{for_coord, fits, slices_of}` of `common/src/midout/cpu.rs`.

Executable model, base-generic. Ranges are carried as data (`Coord.lo`,
`Coord.hi`); `baseRangeC` is a computable form of the earlier library's
`NiceSearch.baseRange` (noncomputable: its cube and square roots are
`Nat.find`), checked against the Rust's closed form for every base 3-128
by the conformance executable and proved equal (`baseRangeC_eq`, `RangeProofs`).
-/
import Nice

namespace NiceMidOut

open NiceSearch

/-- The least `r` with `x ≤ r^e` (for `e ≥ 1`), by bisection: a computable
`NiceSearch.ceilRoot`. -/
def ceilRootC (e x : ℕ) : ℕ :=
  if x ≤ 1 then x else go 0 x (Nat.log2 x + 2)
where
  /-- Invariant: `lo^e < x ≤ hi^e`. -/
  go (lo hi : ℕ) : ℕ → ℕ
    | 0 => hi
    | fuel + 1 =>
      if hi ≤ lo + 1 then hi
      else if x ≤ ((lo + hi) / 2) ^ e then go lo ((lo + hi) / 2) fuel
      else go ((lo + hi) / 2) hi fuel

/-- `get_base_range_natural` (`common/src/base_range.rs:14`) with
`ceilRootC`: the same closed form as `NiceSearch.baseRange`. -/
def baseRangeC (b : ℕ) : Option (ℕ × ℕ) :=
  match b % 5 with
  | 0 => some (ceilRootC 3 (b ^ (3 * (b / 5) - 1)), b ^ (b / 5))
  | 1 => none
  | 2 => some (b ^ (b / 5), ceilRootC 3 (b ^ (3 * (b / 5) + 1)))
  | 3 => some (ceilRootC 3 (b ^ (3 * (b / 5) + 1)), ceilRootC 2 (b ^ (2 * (b / 5) + 1)))
  | _ => some (ceilRootC 2 (b ^ (2 * (b / 5) + 1)), ceilRootC 3 (b ^ (3 * (b / 5) + 2)))

/-- `Coord` (`coord.rs:89`): a base, its range `[lo, hi)` and the digit
positions `k0 ≤ q0 < k1`. `h0` and `H` are derived. -/
structure Coord where
  b : ℕ
  lo : ℕ
  hi : ℕ
  k0 : ℕ
  k1 : ℕ
  q0 : ℕ
  deriving Repr, DecidableEq

namespace Coord

/-- `ndigits(end − 1, b)`: digits of the range's last `n` (`coord.rs:199`). -/
def L (c : Coord) : ℕ := numDigits c.b (c.hi - 1)

/-- `h0 = start div b^k1` (`coord.rs:205`). -/
def h0 (c : Coord) : ℕ := c.lo / c.b ^ c.k1

/-- `H = (end − 1) div b^k1 − h0 + 1`, the number of values of
`h = n div b^k1` (`coord.rs:206`). -/
def H (c : Coord) : ℕ := (c.hi - 1) / c.b ^ c.k1 - c.h0 + 1

/-- What `Coord::with_digits` checks (`coord.rs:193–220`), with the range
the earlier library's `baseRange` (the `u128` overflow check is not
modelled: ℕ does not overflow). -/
def Valid (c : Coord) : Prop :=
  3 ≤ c.b ∧ c.b ≤ 128 ∧ baseRange c.b = some (c.lo, c.hi) ∧ c.k0 ≤ c.q0 ∧ c.q0 < c.k1 ∧
    c.k1 ≤ c.L

/-- `Coord::with_digits` (`coord.rs:193`), executable (range from
`baseRangeC`); `none` where the Rust returns an error. -/
def withDigits (b k0 k1 q0 : ℕ) : Option Coord :=
  if 3 ≤ b ∧ b ≤ 128 then
    match baseRangeC b with
    | some (lo, hi) =>
      if lo < hi then
        let c : Coord := ⟨b, lo, hi, k0, k1, q0⟩
        if k0 ≤ q0 ∧ q0 < k1 ∧ k1 ≤ c.L then some c else none
      else none
    | none => none
  else none

/-- `Coord::v_end` (`coord.rs:230`): one past the last `v`. -/
def vEnd (c : Coord) : ℕ := c.lo + c.H * c.b ^ c.k1

/-- `Coord::v_of_n` (`coord.rs:239`):
`v = start + key·(H·b^k0) + (h − h0)·b^k0 + low`. -/
def vOfN (c : Coord) (n : ℕ) : ℕ :=
  c.lo + n % c.b ^ c.k1 / c.b ^ c.k0 * (c.H * c.b ^ c.k0) + (n / c.b ^ c.k1 - c.h0) * c.b ^ c.k0 +
    n % c.b ^ c.k0

/-- `Coord::n_of_v` (`coord.rs:256`): `none` for padding. -/
def nOfV (c : Coord) (v : ℕ) : Option ℕ :=
  let x := v - c.lo
  let key := x / (c.H * c.b ^ c.k0)
  let rest := x % (c.H * c.b ^ c.k0)
  let h := c.h0 + rest / c.b ^ c.k0
  let low := rest % c.b ^ c.k0
  let n := h * c.b ^ c.k1 + key * c.b ^ c.k0 + low
  if c.lo ≤ n ∧ n < c.hi then some n else none

/-- `Coord::quantum` (`coord.rs:274`): `Q = H·b^q0`. -/
def quantum (c : Coord) : ℕ := c.H * c.b ^ c.q0

/-- `Coord::field_digits` (`coord.rs:283`): the values `[t0, t1)` of the
digits `[q0, k1)` of a field `[vs, vs + vz)`; `none` where the Rust refuses
the field (empty, outside the coordinate, or not whole quanta). -/
def fieldDigits (c : Coord) (vs vz : ℕ) : Option (ℕ × ℕ) :=
  if 0 < vz ∧ c.lo ≤ vs ∧ vs + vz ≤ c.vEnd ∧ (vs - c.lo) % c.quantum = 0 ∧ vz % c.quantum = 0 then
    some ((vs - c.lo) / c.quantum, (vs - c.lo) / c.quantum + vz / c.quantum)
  else none

/-- The field's digit values as a list, in the Rust's iteration order. -/
def fieldTs (c : Coord) (vs vz : ℕ) : List ℕ :=
  match c.fieldDigits vs vz with
  | some (t0, t1) => List.range' t0 (t1 - t0)
  | none => []

end Coord

/-- The join's shape `(f0, k)` (`cpu.rs:62`). -/
structure Shape where
  f0 : ℕ
  k : ℕ
  deriving Repr, DecidableEq

namespace Shape

/-- `Shape::for_coord` (`cpu.rs:75`). -/
def forCoord (c : Coord) : Shape :=
  if c.k0 = 4 ∧ c.k1 = 8 ∧ c.q0 = 5 then ⟨4, 10⟩ else ⟨c.k0, c.k1 + 1⟩

/-- `Shape::fits` (`cpu.rs:90`). -/
def Fits (sh : Shape) (c : Coord) : Prop :=
  sh.f0 ≤ c.q0 ∧ c.k1 < sh.k ∧ sh.k ≤ c.L

instance (sh : Shape) (c : Coord) : Decidable (sh.Fits c) := by
  unfold Fits; infer_instance

/-- `Shape::slices_of` (`cpu.rs:105`): the slices (`pip` = digits
`[f0, k − 1)` of `n`) of one value `t` of the field's digits `[q0, k1)`,
in the Rust's order (the digits below `q0` fastest). -/
def slicesOf (sh : Shape) (c : Coord) (t : ℕ) : List ℕ :=
  let loSpan := c.b ^ (c.q0 - sh.f0)
  let hiN := sh.k - 1 - c.k1
  let mid := t * loSpan
  let hiMul := c.b ^ (c.k1 - sh.f0)
  (List.range (loSpan * c.b ^ hiN)).map fun i => i / loSpan * hiMul + mid + i % loSpan

end Shape

end NiceMidOut
