/-
Conformance: the Lean model of the middle-out join against tables written by
the Rust CPU reference (`common/examples/midout_lean_fixtures.rs`, files in
`fixtures/`). Every table is recomputed with the model and compared entry for
entry; the first difference is printed with its place and the exit code is 1.
Run from `lean-midout/` with `lake exe conformance`.
-/
import NiceMidOut
import Lean.Data.Json

open Lean NiceMidOut

namespace Conformance

/-- Stop at the first difference. -/
def ensure (ok : Bool) (place : String) : IO Unit :=
  unless ok do throw (IO.userError s!"MISMATCH at {place}")

/-- The first index at which two lists differ, with both entries. -/
def firstDiff {α : Type} [BEq α] [ToString α] (model want : List α) : Option String :=
  let rec go (i : ℕ) : List α → List α → Option String
    | [], [] => none
    | x :: xs, y :: ys => if x == y then go (i + 1) xs ys else some s!"entry {i}: model {x}, Rust {y}"
    | x :: _, [] => some s!"entry {i}: model has {x}, Rust has no more"
    | [], y :: _ => some s!"entry {i}: model has no more, Rust has {y}"
  go 0 model want

def ensureList {α : Type} [BEq α] [ToString α] (model want : List α) (place : String) : IO Unit :=
  match firstDiff model want with
  | none => pure ()
  | some d => throw (IO.userError s!"MISMATCH at {place}: {d}")

def orFail {α : Type} (e : Except String α) : IO α :=
  match e with
  | .ok a => pure a
  | .error s => throw (IO.userError s!"fixture: {s}")

def asNat (v : Json) : Except String ℕ :=
  match v with
  | .num n => if n.exponent == 0 && n.mantissa ≥ 0 then pure n.mantissa.toNat else throw "not a nat"
  | .str s => match s.toNat? with | some n => pure n | none => throw s!"not a nat string: {s}"
  | _ => throw "not a number"

def asBool (v : Json) : Except String Bool :=
  match v with
  | .bool x => pure x
  | .num n => pure (n.mantissa != 0)
  | _ => throw "not a bool"

def asArr (v : Json) : Except String (List Json) := do pure (← v.getArr?).toList

def asNats (v : Json) : Except String (List ℕ) := do (← asArr v).mapM asNat

def asMask (v : Json) : Except String (Finset ℕ) := do pure (← asNats v).toFinset

def field (j : Json) (k : String) : Except String Json := j.getObjVal? k

def nat (j : Json) (k : String) : Except String ℕ := do asNat (← field j k)

def arr (j : Json) (k : String) : Except String (List Json) := do asArr (← field j k)

def load (name : String) : IO Json := do
  let text ← IO.FS.readFile ("fixtures/" ++ name)
  match Json.parse text with
  | .ok j => pure j
  | .error e => throw (IO.userError s!"{name}: {e}")

def maskStr (m : Finset ℕ) : String := toString (m.sort (· ≤ ·))

/-- A counter of checks made. -/
abbrev M := StateT ℕ IO

def tick (n : ℕ := 1) : M Unit := modify (· + n)

def checkCoord (j : Json) (place : String) : M Coord := do
  let b ← orFail (nat j "base")
  let k0 ← orFail (nat j "k0")
  let k1 ← orFail (nat j "k1")
  let q0 ← orFail (nat j "q0")
  let some c := Coord.withDigits b k0 k1 q0
    | throw (IO.userError s!"MISMATCH at {place}: the model refuses the coordinate")
  let want ← orFail ([ "start", "end", "h0", "hn", "quantum", "v_end" ].mapM (nat j ·))
  ensureList [c.lo, c.hi, c.h0, c.H, c.quantum, c.vEnd] want s!"{place} coordinate values"
  tick
  pure c

def outcomeOf (j : Json) : Except String FieldOutcome := do
  pure ⟨← (← arr j "nice").mapM asNat, ← nat j "survivors", ← nat j "checked", ← nat j "slices"⟩

def survOf (v : Json) : Except String (ℕ × ℕ × Bool) := do
  match ← asArr v with
  | [d, n, p] => pure (← asNat d, ← asNat n, ← asBool p)
  | _ => throw "survivor shape"

/-- `whole.json`: every slice of the small bases. -/
def checkWhole : M Unit := do
  let j ← load "whole.json"
  for bj in ← orFail (asArr j) do
    let b ← orFail (nat bj "base")
    let c ← checkCoord bj s!"whole b{b}"
    for p in ← orFail (arr bj "n_of_v") do
      let [v, n] ← orFail (asArr p) | throw (IO.userError "n_of_v shape")
      let v ← orFail (asNat v)
      let want ← match n with | .null => pure none | x => do pure (some (← orFail (asNat x)))
      ensure (c.nOfV v == want) s!"whole b{b} n_of_v {v}: model {c.nOfV v}, Rust {want}"
      match want with
      | some n => ensure (c.vOfN n == v) s!"whole b{b} v_of_n {n}"
      | none => pure ()
      tick
    for sj in ← orFail (arr bj "shapes") do
      let sh : Shape := ⟨← orFail (nat sj "f0"), ← orFail (nat sj "k")⟩
      let place := s!"whole b{b} ({c.k0}, {c.k1}, {c.q0}) shape ({sh.f0}, {sh.k})"
      let slices ← orFail (arr sj "slices")
      -- the slice list of the whole base, in order
      let wantTp ← orFail (slices.mapM fun s => do pure (← nat s "t", ← nat s "pip"))
      let modelTp := (c.fieldTs c.lo (c.vEnd - c.lo)).flatMap fun t =>
        (sh.slicesOf c t).map fun p => (t, p)
      ensureList modelTp wantTp s!"{place} slice list"
      tick
      for s in slices do
        let pip ← orFail (nat s "pip")
        let wantC ← orFail ((← orFail (arr s "counts")).mapM asNat)
        let wantS ← orFail ((← orFail (arr s "surv")).mapM survOf)
        let run := sliceRun c.b c.lo c.hi sh pip
        ensureList run.counts.toList wantC s!"{place} slice {pip} counters"
        ensureList run.surv wantS s!"{place} slice {pip} survivors (in order)"
        -- the definition: the same survivors as a set (sorted by n)
        let defn := (sliceSurvivors c.b c.lo c.hi sh pip).map fun x =>
          (x.1, x.2.1, midPrefilter c.b sh.k x.2.1 x.2.2)
        let srt := fun (l : List (ℕ × ℕ × Bool)) => l.mergeSort fun x y => x.2.1 ≤ y.2.1
        ensureList (srt defn) (srt wantS) s!"{place} slice {pip} survivors of the definition"
        tick 3
      for (key, vs, vz) in [("field_all", c.lo, c.vEnd - c.lo), ("field_first", c.lo, c.quantum)] do
        let want ← orFail (outcomeOf (← orFail (field sj key)))
        match searchField c sh vs vz with
        | none => throw (IO.userError s!"MISMATCH at {place} {key}: the model refuses the field")
        | some o =>
          ensureList o.nice want.nice s!"{place} {key} nice"
          ensure (o.survivors == want.survivors && o.checked == want.checked &&
            o.slices == want.slices)
            s!"{place} {key}: model {o.survivors}/{o.checked}/{o.slices}, Rust {want.survivors}/{want.checked}/{want.slices}"
        tick

/-- `bases.json`: roots and ranges of every base 3-128. -/
def checkBases : M Unit := do
  let j ← load "bases.json"
  for bj in ← orFail (asArr j) do
    let b ← orFail (nat bj "base")
    ensureList (roots b) (← orFail ((← orFail (arr bj "roots")).mapM asNat)) s!"roots b{b}"
    let want ← match ← orFail (field bj "range") with
      | .null => pure none
      | v => do
        match ← orFail (asNats v) with
        | [lo, hi] => pure (some (lo, hi))
        | _ => throw (IO.userError "range shape")
    ensure (baseRangeC b == want) s!"range b{b}: model {baseRangeC b}, Rust {want}"
    tick 2

def parentOf (v : Json) : Except String Parent := do
  match ← asArr v with
  | [r, mk, c2, c3, a2, a3, cls] =>
    pure ⟨← asNat r, ← asMask mk, ← asNat c2, ← asNat c3, ← asNat a2, ← asNat a3, ← asNat cls⟩
  | _ => throw "parent shape"

instance : ToString Parent where
  toString p := s!"(r {p.r}, mask {maskStr p.mask}, {p.c2} {p.c3} {p.a2} {p.a3}, class {p.cls})"

instance : ToString Top where
  toString t := s!"(h {t.h}, mask {maskStr t.mask}, mhi {maskStr t.mhi}, [{t.lo}, {t.hi}])"

/-- A child mask in the fixture: the empty list is "not certified". -/
def childOf (v : Json) : Except String (Option (Finset ℕ)) := do
  let m ← asNats v
  pure (if m.isEmpty then none else some m.toFinset)

/-- A parent of slice `pip`, pointwise: `r`'s digits `[f0, k − 1)` are `pip`
and its low `k − 1` output digits are distinct (the residue the walk keeps). -/
def parentAt (b : ℕ) (sh : Shape) (pip r : ℕ) : Option Parent :=
  if r / b ^ sh.f0 = pip then
    (botCertDirect b r (sh.k - 1)).map fun mk => mkParent b sh.k (r, mk)
  else none

/-- `b64.json`: base-64 (and base-65) pieces. -/
def checkB64 : M Unit := do
  let j ← load "b64.json"
  let mut c64 : Option Coord := none
  for cj in ← orFail (arr j "coords") do
    let c ← checkCoord cj "b64 coords"
    let place := s!"b{c.b} ({c.k0}, {c.k1}, {c.q0})"
    if c.b = 64 ∧ c64.isNone then c64 := some c
    let sh := Shape.forCoord c
    ensureList [sh.f0, sh.k] (← orFail ((← orFail (arr cj "shape")).mapM asNat)) s!"{place} shape"
    for p in ← orFail (arr cj "v_of_n") do
      let [n, v] ← orFail (asNats p) | throw (IO.userError "v_of_n shape")
      ensure (c.vOfN n == v) s!"{place} v_of_n {n}: model {c.vOfN n}, Rust {v}"
      tick
    for p in ← orFail (arr cj "n_of_v") do
      let [v, n] ← orFail (asArr p) | throw (IO.userError "n_of_v shape")
      let v ← orFail (asNat v)
      let want ← match n with | .null => pure none | x => do pure (some (← orFail (asNat x)))
      ensure (c.nOfV v == want) s!"{place} n_of_v {v}: model {c.nOfV v}, Rust {want}"
      tick
    for p in ← orFail (arr cj "fields") do
      let [vs, vz, r] ← orFail (asArr p) | throw (IO.userError "fields shape")
      let vs ← orFail (asNat vs)
      let vz ← orFail (asNat vz)
      let want ← match r with
        | .null => pure none
        | x => do
          let [t0, t1] ← orFail (asNats x) | throw (IO.userError "field digits shape")
          pure (some (t0, t1))
      ensure (c.fieldDigits vs vz == want) s!"{place} field_digits {vs} {vz}"
      tick
    for p in ← orFail (arr cj "slices") do
      let [t, l] ← orFail (asArr p) | throw (IO.userError "slices shape")
      let t ← orFail (asNat t)
      ensureList (sh.slicesOf c t) (← orFail (asNats l)) s!"{place} slices_of {t}"
      tick
  let some c := c64 | throw (IO.userError "no base-64 coordinate")
  let b := c.b
  for p in ← orFail (arr j "certs") do
    let [a, e, kpos, kmid, got] ← orFail (asArr p) | throw (IO.userError "certs shape")
    let (a, e, kpos, kmid) := (← orFail (asNat a), ← orFail (asNat e), ← orFail (asNat kpos),
      ← orFail (asNat kmid))
    let want ← match got with
      | .null => pure none
      | x => do
        let [m, h] ← orFail (asArr x) | throw (IO.userError "cert shape")
        pure (some (← orFail (asMask m), ← orFail (asMask h)))
    ensure (topCertSplit b a e kpos kmid == want) s!"top_cert_split [{a}, {e}] {kpos} {kmid}"
    tick
  for u in ← orFail (arr j "units") do
    let sh : Shape := ⟨← orFail (nat u "f0"), ← orFail (nat u "k")⟩
    let uv ← orFail (nat u "u")
    let tested ← orFail (nat u "tested")
    let want ← orFail ((← orFail (arr u "tops")).mapM fun t => do
      match ← asArr t with
      | [h, m, mh, lo, hi] => pure (⟨← asNat h, ← asMask m, ← asMask mh, ← asNat lo, ← asNat hi⟩ : Top)
      | _ => throw "top shape")
    ensure ((unitLeads b c.lo c.hi sh.f0 sh.k uv).length == tested) s!"unit_tops {uv} tested"
    ensureList (unitTops b c.lo c.hi sh.f0 sh.k uv) want s!"unit_tops {uv}"
    tick 2
  for pl in ← orFail (arr j "parent_lists") do
    let sh : Shape := ⟨← orFail (nat pl "f0"), ← orFail (nat pl "k")⟩
    let pip ← orFail (nat pl "pip")
    let want ← orFail ((← orFail (arr pl "parents")).mapM parentOf)
    let ps := parents b sh pip
    ensureList ps want s!"parents ({sh.f0}, {sh.k}) pip {pip}"
    for ch in ← orFail (arr pl "children") do
      let [i, d, m] ← orFail (asArr ch) | throw (IO.userError "children shape")
      let (i, d) := (← orFail (asNat i), ← orFail (asNat d))
      let some p := ps[i]? | throw (IO.userError "child index")
      ensure (childMask b p d == (← orFail (childOf m))) s!"child_mask pip {pip} parent {i} d {d}"
      tick
    tick
  for ps in ← orFail (arr j "parent_samples") do
    let sh : Shape := ⟨← orFail (nat ps "f0"), ← orFail (nat ps "k")⟩
    let pip ← orFail (nat ps "pip")
    for key in ["first", "last"] do
      let p ← orFail (parentOf (← orFail (field ps key)))
      ensure (parentAt b sh pip p.r == some p) s!"parent sample {pip} {key} {p.r}"
      tick
    for mj in ← orFail (arr ps "members") do
      let [pj, d, m] ← orFail (asArr mj) | throw (IO.userError "members shape")
      let p ← orFail (parentOf pj)
      let d ← orFail (asNat d)
      ensure (parentAt b sh pip p.r == some p) s!"parent sample {pip} r {p.r}"
      ensure (childMask b p d == (← orFail (childOf m))) s!"parent sample {pip} r {p.r} child {d}"
      tick 2
    for pr in ← orFail (arr ps "probes") do
      let [r, is] ← orFail (asArr pr) | throw (IO.userError "probes shape")
      let r ← orFail (asNat r)
      ensure ((parentAt b sh pip r).isSome == (← orFail (asBool is))) s!"parent probe {pip} r {r}"
      tick
  for p in ← orFail (arr j "prefilter") do
    let [n, mhi, v] ← orFail (asArr p) | throw (IO.userError "prefilter shape")
    let n ← orFail (asNat n)
    ensure (midPrefilter b 10 n (← orFail (asMask mhi)) == (← orFail (asBool v))) s!"prefilter {n}"
    tick

end Conformance

namespace Conformance

/-- `check.json`: the final check (`uniqueDigits`, the mirror of `unique_digits`)
against the Rust's count of distinct digits and verdict. -/
def checkCheck : M Unit := do
  let j ← load "check.json"
  for bj in ← orFail (asArr j) do
    let b ← orFail (nat bj "base")
    for r in ← orFail (arr bj "rows") do
      let [n, u, ok] ← orFail (asArr r) | throw (IO.userError "check row shape")
      let n ← orFail (asNat n)
      let want := (← orFail (asNat u), ← orFail (asBool ok))
      let got := uniqueDigits b n
      ensure (got == want) s!"check b{b} n {n}: model {got}, Rust {want}"
      ensure (finalCheck b n == want.2) s!"check b{b} n {n}: final check"
      tick

/-- `wide.json`: whole slices at larger bases, through the run form (counters
and every survivor in order) and the definition (survivors as a set). -/
def checkWide (verbose : Bool := false) : M Unit := do
  let j ← load "wide.json"
  for bj in ← orFail (asArr j) do
    let b ← orFail (nat bj "base")
    let c ← checkCoord bj s!"wide b{b}"
    let sh : Shape := ⟨← orFail (nat bj "f0"), ← orFail (nat bj "k")⟩
    let place := s!"wide b{b} ({c.k0}, {c.k1}, {c.q0}) shape ({sh.f0}, {sh.k})"
    for s in ← orFail (arr bj "slices") do
      let pip ← orFail (nat s "pip")
      let wantC ← orFail ((← orFail (arr s "counts")).mapM asNat)
      let wantS ← orFail ((← orFail (arr s "surv")).mapM survOf)
      let t0 ← IO.monoMsNow
      let run := sliceRun c.b c.lo c.hi sh pip
      ensureList run.counts.toList wantC s!"{place} slice {pip} counters"
      ensureList run.surv wantS s!"{place} slice {pip} survivors (in order)"
      let t1 ← IO.monoMsNow
      let defn := (sliceSurvivors c.b c.lo c.hi sh pip).map fun x =>
        (x.1, x.2.1, midPrefilter c.b sh.k x.2.1 x.2.2)
      let srt := fun (l : List (ℕ × ℕ × Bool)) => l.mergeSort fun x y => x.2.1 ≤ y.2.1
      ensureList (srt defn) (srt wantS) s!"{place} slice {pip} survivors of the definition"
      let t2 ← IO.monoMsNow
      if verbose then
        IO.println s!"{place} slice {pip}: run {t1 - t0} ms, definition {t2 - t1} ms"
        (← IO.getStdout).flush
      tick 3

/-- The survivor checksum of the generator's `surv_hash`. -/
def survHash (l : List (ℕ × ℕ × Bool)) : ℕ :=
  let m := 2 ^ 61 - 1
  l.foldl (fun h x => (h * 1000003 + (x.2.1 * 128 + x.1 * 2 + if x.2.2 then 1 else 0) % m) % m) 0

/-- `slice64.json` (not committed; `lake exe conformance --slice64`): one
base-64 slice of shape (4, 10) through the run form, counters, survivor count
and checksum. -/
def checkSlice64 : M Unit := do
  let j ← load "slice64.json"
  let some c := Coord.withDigits (← orFail (nat j "base")) (← orFail (nat j "k0"))
      (← orFail (nat j "k1")) (← orFail (nat j "q0"))
    | throw (IO.userError "slice64: the model refuses the coordinate")
  let sh : Shape := ⟨← orFail (nat j "f0"), ← orFail (nat j "k")⟩
  let pip ← orFail (nat j "pip")
  let wantC ← orFail ((← orFail (arr j "counts")).mapM asNat)
  let t0 ← IO.monoMsNow
  let run := sliceRun c.b c.lo c.hi sh pip
  ensureList run.counts.toList wantC s!"slice64 {pip} counters"
  let t1 ← IO.monoMsNow
  IO.println s!"slice64: counters equal after {(t1 - t0) / 1000} s"
  (← IO.getStdout).flush
  ensure (run.surv.length == (← orFail (nat j "nsurv"))) "slice64 survivor count"
  ensure (survHash run.surv == (← orFail (nat j "hash"))) "slice64 survivor checksum"
  tick 3

end Conformance

open Conformance in
def main (args : List String) : IO UInt32 := do
  try
    if args.contains "--wide" then
      let ((), n) ← (checkWide true : M Unit).run 0
      IO.println s!"conformance --wide: {n} checks, all equal to the Rust table"
      return 0
    if args.contains "--slice64" then
      let ((), n) ← (checkSlice64 : M Unit).run 0
      IO.println s!"conformance --slice64: {n} checks, all equal to the Rust table"
      return 0
    let ((), n) ← (do checkBases; checkB64; checkWhole; checkCheck; checkWide : M Unit).run 0
    IO.println s!"conformance: {n} checks, all equal to the Rust tables"
    pure 0
  catch e =>
    IO.eprintln s!"conformance: {e}"
    pure 1
