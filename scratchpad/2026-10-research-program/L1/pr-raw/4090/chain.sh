#!/bin/bash
# Order by the coordinator's priority: A/B at b60/b62, then b58/b64, then the EPT matrix, then NiceMark;
# then exactness (compare) on the prune tree and EPT at 1e14.
cd /root
echo "CHAIN_START $(date -u +%T)"
/root/ab.sh main prune 60,62 b6062 > /root/ab/ab_b6062.log 2>&1; echo "ab b6062 $(date -u +%T)"
/root/ab.sh main prune 58,64 b5864 > /root/ab/ab_b5864.log 2>&1; echo "ab b5864 $(date -u +%T)"
/root/ept.sh > /root/ab/ept.log 2>&1; echo "ept $(date -u +%T)"
/root/nicemark.sh main prune > /root/ab/nm.log 2>&1; echo "nm $(date -u +%T)"
/root/compare.sh prune > /root/ab/compare_summary.log 2>&1; echo "compare $(date -u +%T)"
N=20 EPTS="2 4" /root/ept14.sh > /root/ab/ept14.log 2>&1; echo "ept14 $(date -u +%T)"
echo "CHAIN_DONE $(date -u +%T)"
