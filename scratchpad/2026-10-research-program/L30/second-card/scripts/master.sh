#!/bin/bash
# setup -> builds (exactness starts once both's test binary exists) -> quiet box: fixed fields, then NiceMark.
L=/root/sc
w() { until [ -e "$1" ]; do sleep 10; done; }
/root/setup.sh
echo "BUILD start $(date -u +%T)"
nohup /root/chain_x.sh > $L/chain_x.out 2>&1 < /dev/null &
/root/chain_build.sh > $L/chain_build.out 2>&1 < /dev/null
test -e $L/builds.done || { echo "BUILDS FAILED $(date -u +%T)"; exit 1; }
w $L/chainX.done
echo "FF start $(date -u +%T)"
/root/chain_ff.sh > $L/chain_ff.out 2>&1 < /dev/null
echo "NM start $(date -u +%T)"
/root/chain_nm.sh > $L/chain_nm.out 2>&1 < /dev/null
echo "ALL DONE $(date -u +%T)"
