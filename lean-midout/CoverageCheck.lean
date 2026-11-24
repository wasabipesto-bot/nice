/-
`lake exe coverage BASE K0 K1 Q0 FILE`: the coverage certificate of a searched
base. FILE (`-` for standard input) lists the searched fields, one per line:
`range_start range_size nice_count`, the field `[range_start, range_start +
range_size)` in the coordinate's values `v` and the number of nice numbers its
search reported (`scripts/coverage_fields.py` writes it from a coordinator's
`submissions.jsonl`). Blank lines and lines starting with `#` are skipped.

The decision (exit code 0) is `certOk BASE K0 K1 Q0 records`, the function
of `NiceMidOut.Coverage` about which `no_nice_of_certOk` is proved; the other
lines of the output are diagnostics computed here, not proved.
Exit codes: 0 yes, 1 no, 2 bad arguments or input.
-/
import NiceMidOut.Coverage

open NiceMidOut

namespace CoverageCheck

def usage : String :=
  "usage: coverage BASE K0 K1 Q0 FILE   (FILE: lines `range_start range_size nice_count`, - for stdin)"

/-- One line of the file: `none` for a blank or comment line. -/
def parseLine (line : String) : Except String (Option (ℕ × ℕ × ℕ)) :=
  let ws := (line.splitOn " ").filter (· ≠ "")
  let ws := ws.map fun w => w.replace "\r" "" |>.replace "\t" ""
  let ws := ws.filter (· ≠ "")
  match ws with
  | [] => .ok none
  | w :: _ =>
    if w.startsWith "#" then .ok none
    else match ws.map String.toNat? with
      | [some s, some z, some k] => .ok (some (s, z, k))
      | _ => .error s!"not `range_start range_size nice_count`: {line}"

def parseAll (lines : List String) : Except String (List (ℕ × ℕ × ℕ)) := do
  let mut out : Array (ℕ × ℕ × ℕ) := #[]
  let mut i := 0
  for l in lines do
    i := i + 1
    match parseLine l with
    | .ok none => pure ()
    | .ok (some r) => out := out.push r
    | .error e => throw s!"line {i}: {e}"
  return out.toList

/-- Diagnostics (not proved): the first gap of the sorted fields in
`[lo, vEnd)`, as `(from, to)`, and the number of fields overlapping the
values already reached. -/
def gapsAndOverlaps (lo e : ℕ) (fs : List (ℕ × ℕ)) : Option (ℕ × ℕ) × ℕ := Id.run do
  let mut cur := lo
  let mut gap : Option (ℕ × ℕ) := none
  let mut overlaps := 0
  for f in sortFields fs do
    if f.1 > cur then
      if gap.isNone && cur < e then gap := some (cur, min f.1 e)
      cur := f.1 + f.2
    else
      if f.1 < cur && f.2 > 0 then overlaps := overlaps + 1
      cur := max cur (f.1 + f.2)
  if gap.isNone && cur < e then gap := some (cur, e)
  return (gap, overlaps)

def run (args : List String) : IO UInt32 := do
  let [bS, k0S, k1S, q0S, file] := args
    | IO.eprintln usage; return 2
  let some b := bS.toNat? | IO.eprintln usage; return 2
  let some k0 := k0S.toNat? | IO.eprintln usage; return 2
  let some k1 := k1S.toNat? | IO.eprintln usage; return 2
  let some q0 := q0S.toNat? | IO.eprintln usage; return 2
  let text ← if file == "-" then (← IO.getStdin).readToEnd else IO.FS.readFile file
  let recs ← match parseAll (text.splitOn "\n") with
    | .ok r => pure r
    | .error e => IO.eprintln s!"coverage: {file}: {e}"; return 2
  let t0 ← IO.monoMsNow
  let ok := certOk b k0 k1 q0 recs
  let t1 ← IO.monoMsNow
  IO.println s!"base {b}, coordinate digits (k0, k1, q0) = ({k0}, {k1}, {q0}), {recs.length} fields listed"
  match Coord.withDigits b k0 k1 q0 with
  | none =>
    IO.println "coordinate: REFUSED (Coord.withDigits gives none: no range, or not k0 ≤ q0 < k1 ≤ L)"
  | some c =>
    let fs := recs.map fun r => (r.1, r.2.1)
    let q := c.quantum
    IO.println s!"coordinate: accepted; values [lo, vEnd) = [{c.lo}, {c.vEnd}), quantum {q}, {(c.vEnd - c.lo) / q} quanta"
    let notWq := fs.filter fun f => !wqRaw c.lo c.vEnd q f
    match notWq.head? with
    | none => IO.println "whole quanta: every field"
    | some f =>
      IO.println s!"whole quanta: NO, {notWq.length} fields are not (first: start {f.1} size {f.2})"
    let (gap, overlaps) := gapsAndOverlaps c.lo c.vEnd fs
    match gap with
    | none => IO.println s!"gaps: none ({overlaps} fields overlap others; overlaps are allowed)"
    | some (x, y) =>
      IO.println s!"gaps: first uncovered values [{x}, {y}) ({overlaps} fields overlap others)"
    IO.println s!"covers [lo, vEnd) (Coord.coversB): {if c.coversB fs then "yes" else "NO"}"
  let withNice := recs.filter fun r => r.2.2 != 0
  let total := withNice.foldl (fun a r => a + r.2.2) 0
  IO.println s!"fields reporting a nice number: {withNice.length} ({total} nice numbers in all)"
  IO.println s!"check time: {t1 - t0} ms"
  if ok then
    IO.println s!"YES (certOk): if each listed field's search really returned what is recorded, then by \
      no_nice_of_searched_withDigits (through no_nice_of_certOk) base {b} has no nice number. Not checked: \
      that the searches ran, or ran correctly (the Rust or GPU code, the hardware), or that this file \
      matches the coordinator's record."
    return 0
  else
    IO.println s!"NO (certOk is false): this list does not show that base {b} has no nice number \
      (refused coordinate, a field not of whole quanta, a gap, or a reported nice number)."
    return 1

end CoverageCheck

def main (args : List String) : IO UInt32 := do
  try CoverageCheck.run args
  catch e =>
    IO.eprintln s!"coverage: {e}"
    return 2
