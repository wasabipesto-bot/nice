#!/bin/bash
# chain_main.sh: tree W3 (exp/join-wave-base with AU's empty-slot skip), its test binary and register passes (WB 0, 4,
# 15, 31; the other values compile the same kernels as W2's), then the lavapipe builds and client_W3 (niced) beside
# the CUDA exactness, then the screen (chain_xs.sh).
L=/root/l43/logs
WBS="0 4 15 31" /root/l43/chain_w.sh exp/join-wave-base W3 > $L/chain_w_W3.out 2>&1 || exit 1
test -e /root/l43/bin/W3 || exit 1
(setsid nohup /root/l43/chain_lvpbuild.sh W3 > $L/chain_lvpbuild.out 2>&1 < /dev/null &)
/root/l43/chain_xs.sh > $L/chain_xs.out 2>&1
