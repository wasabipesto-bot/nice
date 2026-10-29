#!/bin/bash
# Replaces extras.sh's tail: after X1, the 1e14 A/B on new main, then the old pair on this card, then EPT 1/3/6 at 1e14.
until grep -q X1_DONE /root/ab/x1.log; do sleep 5; done
echo "EXTRAS2_START $(date -u +%T)"
/root/x14.sh > /root/ab/x14.log 2>&1; echo "x14 $(date -u +%T)"
/root/ab.sh base ept 58,60,62,64 old > /root/ab/ab_old.log 2>&1; echo "old $(date -u +%T)"
N=20 EPTS="1 3 6" /root/ept14.sh > /root/ab/ept14b.log 2>&1; echo "ept14b $(date -u +%T)"
echo "EXTRAS2_DONE $(date -u +%T)"
