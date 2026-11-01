#!/bin/bash
# A/B, interleaved per round: A (e9cdac4), B with ER=2 (compaction), ER=4 (trim), ER=6 (both). Nothing else runs.
R=/root/l33/scripts/runv.sh; L=/root/l33/logs
for r in 1 2 3; do
  $R ab_A_e17_b62_r$r A "" 62 1 1e17
  $R ab_c_e17_b62_r$r B 2 62 1 1e17
  $R ab_t_e17_b62_r$r B 4 62 1 1e17
  $R ab_ct_e17_b62_r$r B 6 62 1 1e17
done
for r in 1 2 3; do
  $R ab_A_e16_b62_r$r A "" 62 2 1e16
  $R ab_s_e16_b62_r$r B 1 62 2 1e16
  $R ab_c_e16_b62_r$r B 2 62 2 1e16
  $R ab_t_e16_b62_r$r B 4 62 2 1e16
  $R ab_ct_e16_b62_r$r B 6 62 2 1e16
done
for r in 1 2 3; do
  $R ab_A_e16_b60_r$r A "" 60 2 1e16
  $R ab_c_e16_b60_r$r B 2 60 2 1e16
  $R ab_t_e16_b60_r$r B 4 60 2 1e16
  $R ab_ct_e16_b60_r$r B 6 60 2 1e16
done
echo CHAIN_AB_DONE $(date -u +%T) > $L/chainAB.done
