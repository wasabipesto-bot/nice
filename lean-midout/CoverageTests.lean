/-
`lake exe coverage_tests`: the coverage check (`Coord.coversB`, `certOk`) on
work lists built here: covering lists in order, reversed, shuffled, with
duplicates and with overlapping larger fields (all accepted); a gap at the
start, in the middle and at the end, a field not of whole quanta, a field past
the end, the empty list (all refused); `certOk` with a reported nice number
and with a refused coordinate. Then base 64, coordinate (4, 8, 5), with its
262,144 single-quantum fields generated here: the time of `coversB` and of
`certOk`, and the same list without its last field (refused).
-/
import NiceMidOut.Coverage

open NiceMidOut

namespace CoverageTests

def ensure (ok : Bool) (place : String) : StateT ℕ IO Unit := do
  unless ok do throw (IO.userError s!"FAILED: {place}")
  modify (· + 1)

/-- A fixed permutation (deterministic, not sorted): `i ↦ (i·s + 3) mod n` with
`s` coprime to `n`. -/
def shuffle {α : Type} (l : List α) : List α :=
  let a := l.toArray
  let n := a.size
  if n < 3 then l.reverse
  else
    let s := ((List.range' 7 n).find? fun s => Nat.gcd s n == 1).getD 1
    (List.range n).filterMap fun i => a[(i * s + 3) % n]?

/-- The fields of `m` quanta each, from `lo` (the last one shorter if `m`
does not divide the number of quanta). -/
def blockFields (c : Coord) (m : ℕ) : List (ℕ × ℕ) :=
  let nq := (c.vEnd - c.lo) / c.quantum
  (List.range ((nq + m - 1) / m)).map fun i =>
    (c.lo + i * m * c.quantum, (min m (nq - i * m)) * c.quantum)

def smallCases (b k0 k1 q0 : ℕ) : StateT ℕ IO Bool := do
  let some c := Coord.withDigits b k0 k1 q0 | return false
  let place := s!"b{b} ({k0}, {k1}, {q0})"
  let qf := c.quantumFields
  let n := qf.length
  let q := c.quantum
  -- accepted
  ensure (c.coversB qf) s!"{place}: quantum fields in order"
  ensure (c.coversB c.wholeField) s!"{place}: the whole coordinate as one field"
  ensure (c.coversB qf.reverse) s!"{place}: reversed"
  ensure (c.coversB (shuffle qf)) s!"{place}: shuffled"
  ensure (c.coversB (qf ++ qf)) s!"{place}: every field twice"
  ensure (c.coversB (blockFields c 2 ++ blockFields c 3)) s!"{place}: overlapping blocks of 2 and 3 quanta"
  ensure (c.coversB (c.wholeField ++ qf.take 1)) s!"{place}: whole field plus a duplicate quantum"
  -- refused
  ensure (!c.coversB []) s!"{place}: empty list"
  if n ≥ 2 then
    ensure (!c.coversB (qf.drop 1)) s!"{place}: gap at the start"
    ensure (!c.coversB (qf.take (n - 1))) s!"{place}: gap at the end"
    ensure (!c.coversB (shuffle (qf.take (n - 1)))) s!"{place}: gap at the end, shuffled"
  if n ≥ 3 then
    ensure (!c.coversB (qf.eraseIdx (n / 2))) s!"{place}: gap in the middle"
    ensure (!c.coversB (qf.eraseIdx (n / 2) ++ qf.eraseIdx (n / 2))) s!"{place}: gap in the middle, duplicated"
  -- not whole quanta (each of these lists does cover the values)
  if q ≥ 2 then
    ensure (!c.coversB ((c.lo, q + 1) :: qf)) s!"{place}: a field one longer than a quantum"
  if c.lo ≥ 1 then
    ensure (!c.coversB ((c.lo - 1, q + 1) :: qf)) s!"{place}: a field starting before lo"
  ensure (!c.coversB (qf ++ [(c.vEnd, q)])) s!"{place}: a field past vEnd"
  ensure (!c.coversB (qf ++ [(c.lo, 0)])) s!"{place}: an empty field"
  if q ≥ 2 then
    ensure (!c.coversB (qf ++ [(c.lo + 1, q)])) s!"{place}: a field off the quantum grid"
  -- certOk on records
  let recs := qf.map fun f => (f.1, f.2, 0)
  ensure (certOk b k0 k1 q0 recs) s!"{place}: certOk, all counts 0"
  ensure (!certOk b k0 k1 q0 (recs.set (n / 2) (qf[n / 2]!.1, qf[n / 2]!.2, 1)))
    s!"{place}: certOk with one nice number reported"
  ensure (!certOk b k0 k1 q0 (recs.take (n - 1))) s!"{place}: certOk with the last field missing"
  return true

def run : StateT ℕ IO Unit := do
  let mut coords := 0
  for b in List.range' 5 26 do
    for (k0, k1, q0) in [(0, 1, 0), (0, 2, 0), (0, 2, 1), (1, 2, 1), (1, 3, 2), (0, 3, 1)] do
      if ← smallCases b k0 k1 q0 then coords := coords + 1
  ensure (coords ≥ 20) s!"small coordinates tested: {coords}"
  -- refused coordinates
  ensure (!certOk 11 0 1 0 []) "certOk: base 11 has no range"
  ensure (!certOk 10 1 1 0 [(47, 60, 0)]) "certOk: q0 < k0"
  ensure (!certOk 10 0 3 0 [(47, 60, 0)]) "certOk: k1 > L"
  -- base 64
  let some c := Coord.withDigits 64 4 8 5 | throw (IO.userError "FAILED: base 64 (4, 8, 5) refused")
  let t0 ← IO.monoMsNow
  let qf := c.quantumFields
  let n := qf.length
  let t1 ← IO.monoMsNow
  ensure (n == 262144) s!"base 64: {n} quantum fields"
  let ok := c.coversB qf
  ensure ok "base 64: coversB on the quantum fields"
  let t2 ← IO.monoMsNow
  let okRev := c.coversB qf.reverse
  ensure okRev "base 64: coversB on the quantum fields reversed"
  let t3 ← IO.monoMsNow
  let recs := qf.map fun f => (f.1, f.2, 0)
  let okCert := certOk 64 4 8 5 recs
  ensure okCert "base 64: certOk"
  let t4 ← IO.monoMsNow
  ensure (!c.coversB (qf.take (n - 1))) "base 64: the last field missing"
  let t5 ← IO.monoMsNow
  IO.println s!"base 64 (4, 8, 5): lo {c.lo}, vEnd {c.vEnd}, quantum {c.quantum}, {n} fields \
    (generated in {t1 - t0} ms); coversB {t2 - t1} ms in order, {t3 - t2} ms reversed; \
    certOk {t4 - t3} ms; last field missing refused in {t5 - t4} ms"
  IO.println s!"small bases: {coords} coordinates"

end CoverageTests

def main : IO UInt32 := do
  try
    let ((), k) ← CoverageTests.run.run 0
    IO.println s!"coverage_tests: {k} checks passed"
    return 0
  catch e =>
    IO.eprintln s!"coverage_tests: {e}"
    return 1
