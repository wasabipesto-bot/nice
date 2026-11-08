#!/bin/bash
# after P's exactness chain, its lint and its lavapipe builds: the A/B (nothing else on the box), then the lavapipe tests
L=/root/l47/logs
until [ -e $L/x_P.done ] && [ -e $L/lint_P.done ] && [ -e $L/lint_F.done ] && [ -e $L/lvp_P.built ]; do sleep 15; done
echo ORCH_AB_GO $(date -u +%T)
touch $L/ab_go
/root/l47/scripts/chain_ab.sh P > $L/ab_P.out 2>&1
echo ORCH_AB_DONE $(date -u +%T)
touch $L/lvp_go
until [ -e $L/lvp_P.done ]; do sleep 15; done
echo ORCH_DONE $(date -u +%T)
