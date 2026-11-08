#!/bin/bash
# after the screen and P's build: CUDA exactness of P; lavapipe builds and lint of P beside it (niced, CPU only)
until [ -e /root/l47/logs/x_go ] && grep -q "BUILD_DONE P\|BUILD FAILED" /root/l47/logs/build_P.out; do sleep 10; done
SRCD=P /root/l47/scripts/chain_x.sh P > /root/l47/logs/x_P.out 2>&1 &
XP=$!
until grep -q "BUILD_DONE client_P\|BUILD FAILED" /root/l47/logs/build_P.out; do sleep 10; done
SRCD=P /root/l47/scripts/chain_lvp.sh P > /root/l47/logs/lvp_P.out 2>&1 &
SRCD=P /root/l47/scripts/chain_lint.sh P > /root/l47/logs/lint_P.out 2>&1
wait $XP
echo QX_DONE $(date -u +%T)
