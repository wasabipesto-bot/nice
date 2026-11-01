#!/bin/bash
# L30 round 4 (binary l30c = 655f953): occupancy separation (X_OCC4) and kernel-source dumps of every variant.
while [ ! -f /root/l30/chain3.done ] || ! grep -q SETUP_DONE /root/l30/setup_l30c.out; do sleep 10; done
R=/root/l30run.sh
export BIN=/root/l30/l30c
cd /root
for r in 1 2; do
  $R occ_c0_e16_b62_r$r 62 2 1e16 0 0
  $R occ_c0x_e16_b62_r$r 62 2 1e16 0 2048
  $R occ_pf_e16_b62_r$r 62 2 1e16 0 256
  $R occ_pfx_e16_b62_r$r 62 2 1e16 0 2304
done
for xm in 2 4 8 16 32 64 768 1280 2048 2304; do CUBECL_DEBUG_LOG=/root/l30/cubecl_xm$xm.txt $R dump_$xm 62 1 1e14 0 $xm; done
echo CHAIN4_DONE $(date -u +%T) > /root/l30/chain4.done
