#!/bin/bash
# After the planned chain: bottoms (CPU), X1 (prune + EPT override on new main vs main), X2 (old pair on this card:
# base 2d740d3 vs the ept tree at its default EPT 4 = 4670ffe's prune).
until grep -q CHAIN_DONE /root/ab/chain.log; do sleep 5; done
echo "EXTRAS_START $(date -u +%T)"
/root/bottoms.sh > /root/ab/bottoms.log 2>&1; echo "bottoms $(date -u +%T)"
VARIANTS=${VARIANTS:-"main prept:2"} /root/x1.sh > /root/ab/x1.log 2>&1; echo "x1 $(date -u +%T)"
/root/ab.sh base ept 58,60,62,64 old > /root/ab/ab_old.log 2>&1; echo "old $(date -u +%T)"
echo "EXTRAS_DONE $(date -u +%T)"
