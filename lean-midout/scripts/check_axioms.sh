#!/usr/bin/env bash
# Every theorem of NiceMidOut (listed by the Lean environment itself)
# depends on no axiom beyond propext, Classical.choice and Quot.sound:
# no sorryAx, no Lean.ofReduceBool (native_decide), nothing added.
# Run from lean-midout/ after `lake build`.
set -euo pipefail
out=$(lake env lean scripts/Axioms.lean 2>&1)
echo "$out"
n=$(grep -c "depends on axioms\|does not depend on any axioms" <<<"$out" || true)
[ "$n" -gt 0 ] || { echo "no theorems checked"; exit 1; }
if grep -E "sorryAx|ofReduceBool|ofReduceNat" <<<"$out"; then echo "forbidden axiom"; exit 1; fi
bad=$(grep "depends on axioms" <<<"$out" | sed 's/.*depends on axioms: \[\(.*\)\]/\1/' | tr ',' '\n' \
  | sed 's/ //g' | grep -vxE "propext|Classical.choice|Quot.sound" || true)
[ -z "$bad" ] || { echo "unexpected axioms: $bad"; exit 1; }
echo "axioms: $n theorems checked, standard axioms only"
