#!/bin/bash
# Order on the GPU: exactness (chain_x, started separately) -> profile 1 -> A/B -> NiceMark -> profile 2. Lints after.
L=/root/pad
w() { until [ -e "$1" ]; do sleep 10; done; }
w $L/chainX.done; w $L/prof.done
echo "PROF1 start $(date -u +%T)"; /root/chain_prof1.sh > $L/chain_prof1.out 2>&1 < /dev/null
w $L/builds.done
echo "AB start $(date -u +%T)"; /root/chain_ab.sh > $L/chain_ab.out 2>&1 < /dev/null
echo "NM start $(date -u +%T)"; /root/chain_nm.sh > $L/chain_nm.out 2>&1 < /dev/null
echo "PROF2 start $(date -u +%T)"; /root/chain_prof2.sh > $L/chain_prof2.out 2>&1 < /dev/null
echo "ALL DONE $(date -u +%T)"
