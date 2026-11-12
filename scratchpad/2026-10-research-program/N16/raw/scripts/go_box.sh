#!/bin/sh
# go_box.sh (the RTX 3080, CUDA): the window's chains in the window's order as the NVIDIA column, plus the removal
# modes at b62 unprofiled and profiled (clock check). Logs in $OUT; progress in $OUT/go_box.out.
export DEV=cuda
S=${SCRIPTS:-/root/n16/scripts}
{
ROUND=1 sh $S/chain_must.sh
ROUND=1 sh $S/chain_surv.sh
ROUND=1 sh $S/chain_geo.sh
ROUND=2 sh $S/chain_must.sh
. $S/lib.sh
for m in r_z r_a r_p prof_c c4; do one $m b62 1; done
echo GO_BOX_DONE $(date -u +%T)
} > ${OUT:-/root/n16/out}/go_box.out 2>&1
