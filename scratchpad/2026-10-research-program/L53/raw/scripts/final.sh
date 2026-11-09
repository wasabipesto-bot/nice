#!/bin/bash
# final.sh: the final tree C (80a103e): build; lint (fmt, clippy x3) beside the CUDA exactness chain (after B's
# FD-vs-top test); lavapipe builds after the lint, lavapipe tests after the CUDA chain; the rebased branches after.
cd /root/l53; L=/root/l53/logs
J=8 bash build.sh C C | tail -2
( SRCD=C bash chain_lint.sh C > chain_lint_C.out 2>&1; SRCD=C bash chain_lvp.sh C > chain_lvp_C.out 2>&1 ) &
until [ -e $L/x_B_topfd.done ]; do sleep 10; done
bash chain_x.sh C > chain_x_C.out 2>&1
touch $L/lvp_go
bash chain_rebased.sh > chain_rebased.out 2>&1
wait
echo FINAL_DONE $(date -u +%T) | tee $L/final.done
