#!/bin/bash
# chain_final.sh G: the final tree src/F. Build F (CUDA test binary) -> CUDA exactness (chain_x) on the GPU, beside the
# CPU builds of client_F, F_naga, F_spv and the fmt check -> lavapipe (chain_lvp) -> A/B + NiceMark (chain_ab) on a
# quiet box.
G=${1:-4}
L=/root/l34/logs; S=/root/l34
w() { until [ -e "$1" ]; do sleep 10; done; }
echo "FINAL start $(date -u +%T) G=$G" >> $L/final.log
$S/build.sh F F gpu || exit 1
echo F_DONE $(date -u +%T) > $L/f.done
nohup $S/chain_x.sh $G > $L/chain_x.out 2>&1 < /dev/null &
$S/buildclient.sh F client_F || exit 1
$S/build.sh F F_naga cubecl || exit 1
$S/build.sh F F_spv cubecl-spirv || exit 1
echo LVPBUILDS_DONE $(date -u +%T) > $L/lvpbuilds.done
( cd /root/l34/src/F && source ~/.cargo/env && cargo fmt --all --check; echo "fmt rc=$?" ) > $L/lint_fmt.log 2>&1
$S/chain_lvp.sh $G > $L/chain_lvp.out 2>&1
w $L/x_g$G.done
echo "AB start $(date -u +%T)" >> $L/final.log
$S/chain_ab.sh $G > $L/chain_ab.out 2>&1 < /dev/null
echo "ALL DONE $(date -u +%T)" >> $L/final.log
