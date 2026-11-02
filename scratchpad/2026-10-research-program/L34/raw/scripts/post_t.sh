#!/bin/bash
# Replaces the tail of chain_base2.sh (killed after it started T's build, so A is not rebuilt: the A binary
# from chain_base.sh's build, installed 06:06, is kept). Waits for T's build.sh to exit, then marks T and A done.
L=/root/l34/logs
while pgrep -f "build.sh T T gpu" > /dev/null; do sleep 5; done
if [ -e /root/l34/bin/T ]; then echo T_DONE $(date -u +%T) > $L/t.done; echo A_DONE kept-06:06 > $L/a.done; else echo "T BUILD FAILED" >> $L/chain_base2.out; fi
