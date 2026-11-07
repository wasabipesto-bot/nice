#!/bin/bash
# chain_post.sh W: after W's test binary is built: CUDA exactness (chain_x.sh) beside the clients' and lavapipe builds
# (CPU, niced); then the A/B B vs W with nothing else on the box; then lavapipe tests and the lint.
L=/root/l46/logs; S=/root/l46/scripts; W=$1
echo POST_START $(date -u +%T)
SRCD=$W $S/chain_x.sh $W > /root/l46/chain_x_$W.out 2>&1 &
XP=$!
( [ -e /root/l46/bin/client_B ] || NICEN=10 J=6 $S/buildclient.sh B client_B; NICEN=10 J=6 $S/buildclient.sh $W client_$W ) >> /root/l46/buildclient.out 2>&1
SRCD=$W $S/chain_lvp.sh $W > /root/l46/chain_lvp_$W.out 2>&1 &
until [ -e $L/lvp_${W}.built ]; do sleep 10; done
wait $XP
echo AB_GO $(date -u +%T); touch $L/ab_go
$S/chain_ab.sh $W > /root/l46/chain_ab.out 2>&1
touch $L/lvp_go
until [ -e $L/lvp_${W}.done ]; do sleep 10; done
SRCD=$W $S/chain_lint.sh $W > /root/l46/chain_lint_$W.out 2>&1
echo POST_DONE $(date -u +%T) > $L/post.done
