#!/bin/bash
# B's CUDA test binary first (compile check), then A's, then the two clients.
L=/root/l31b/logs
/root/l31b/build.sh B B gpu || exit 1
echo B_DONE $(date -u +%T) > $L/b.done
/root/l31b/build.sh A A gpu || exit 1
echo TESTBINS_DONE $(date -u +%T) > $L/testbins.done
/root/l31b/buildclient.sh B client_B || exit 1
/root/l31b/buildclient.sh A client_A || exit 1
echo BUILDS_DONE $(date -u +%T) > $L/builds.done
