#!/bin/bash
# chain_base.sh: setup, the base test binary B and client_B, B's registers.
L=/root/l43/logs
/root/l43/setup.sh > $L/setup.out 2>&1
/root/l43/build.sh B B || exit 1
/root/l43/buildclient.sh B client_B > $L/buildclient_B.out 2>&1
/root/l43/regs.sh B B B > $L/regs_B.out 2>&1
echo CHAIN_BASE_DONE $(date -u +%T) > $L/base.done
