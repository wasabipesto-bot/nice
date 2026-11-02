#!/bin/bash
# Diagnostic build: P192t = the PR with survivors' top ids from the list (exp/join-transpose-and-tid), nice 19.
L=/root/l34/logs; S=/root/l34
rm -rf /root/l34/src/P192t; mkdir -p /root/l34/src/P192t; tar xzf /root/l34/PR192T.tgz -C /root/l34/src/P192t
J=6 nice -n 19 $S/build.sh P192t P192t gpu || exit 1
$S/regs.sh P192t pr192t 2>&1 | grep join_kernel
echo P192T_DONE $(date -u +%T) > $L/p192t.done
