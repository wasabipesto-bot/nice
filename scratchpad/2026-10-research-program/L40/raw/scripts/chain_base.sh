#!/bin/bash
# chain_base.sh: the base's test binary (M = af21136), its registers and 1e14 counts, then client_M.
L=/root/l40/logs
/root/l40/build.sh M M || exit 1
/root/l40/regs.sh M M M > $L/regs_M.out 2>&1
/root/l40/buildclient.sh M client_M > $L/buildclient_M.out 2>&1
echo CHAIN_BASE_DONE $(date -u +%T) > $L/base.done
