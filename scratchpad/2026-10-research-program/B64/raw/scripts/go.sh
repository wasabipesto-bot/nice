#!/bin/bash
# go.sh: wait for the builds and the sanity run, then: base-mean round 1 (all three jobs), E profiles, 1e16 rounds 2-3.
L=/root/b64/logs; S=/root/b64/scripts
until grep -q "BUILD_DONE E\|FAILED" $L/build_all.out; do sleep 5; done
until grep -q "^END" $L/san_M_b64_1e16.log; do sleep 5; done
until grep -q "^END" $L/x_M_e17.log 2>/dev/null; do sleep 5; done
ROUNDS=1 B62ROUNDS=1 FULL=1 bash $S/chain_base.sh > $L/chain_base1.out 2>&1
[ -e $L/stop ] && exit 0
[ -e $S/chain_prof.sh ] && bash $S/chain_prof.sh > $L/chain_prof.out 2>&1
ROUNDS="2 3" B62ROUNDS="" FULL=0 bash $S/chain_base.sh > $L/chain_base23.out 2>&1
[ -e $S/chain_screen.sh ] && bash $S/chain_screen.sh > $L/chain_screen.out 2>&1
echo GO_DONE $(date -u +%T) > $L/go.done
