#!/bin/bash
# Builds (CPU) | lint (CPU, niced) | CUDA exactness once B is built | lavapipe once its binaries are built;
# then the A/B on a quiet box; then the whole-field check.
L=/root/l33p/logs; S=/root/l33p
w() { until [ -e "$1" ]; do sleep 10; done; }
echo "MASTER start $(date -u +%T)" >> $L/master.log
nohup $S/chain_cpu.sh > $L/chain_cpu.out 2>&1 < /dev/null &
w $L/b.done
nohup $S/chain_lint.sh > $L/chain_lint.out 2>&1 < /dev/null &
nohup $S/chain_x.sh > $L/chain_x.out 2>&1 < /dev/null &
nohup $S/chain_lvp.sh > $L/chain_lvp.out 2>&1 < /dev/null &
w $L/clients.done; w $L/lvpbuilds.done; w $L/x.done; w $L/lvp.done; w $L/lint.done
echo "AB start $(date -u +%T)" >> $L/master.log
$S/chain_ab.sh > $L/chain_ab.out 2>&1 < /dev/null
echo "AB done $(date -u +%T)" >> $L/master.log
echo "ALL DONE $(date -u +%T)" >> $L/master.log
