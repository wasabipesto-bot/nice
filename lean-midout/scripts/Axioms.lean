import NiceMidOut
open Lean Elab Command in
/-- `#print axioms` for every theorem declared in a `NiceMidOut` module. -/
elab "#print_midout_axioms" : command => do
  let env ← getEnv
  let mut names : Array Name := #[]
  for (n, ci) in env.constants.toList do
    if let .thmInfo _ := ci then
      if let some m := env.getModuleIdxFor? n then
        if (env.header.moduleNames[m.toNat]!).getRoot == `NiceMidOut && !n.isInternal then
          names := names.push n
  for n in names.qsort (·.toString < ·.toString) do
    elabCommand (← `(#print axioms $(mkIdent n)))
#print_midout_axioms
