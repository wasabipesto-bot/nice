#!/bin/bash
# go2.sh (07:05): wait for E2's build, then the extras (E2's slice-setup split, spill counts), then the restarted screen.
cd /root/l51
until grep -q -E "BUILD_DONE|FAILED" build_E2.out 2>/dev/null; do sleep 5; done
L=/root/l51/logs
for p in s_tm512_e17_b62_r1:s_base4_e17_b62_r1 s_tm512_e17_b62_r1_spill0:s_base4_e17_b62_r1_spill0 s_ag2_e17_b62_r1:s_base3_e17_b62_r1; do
  a=${p%%:*}; b=${p##*:}
  for x in log smi; do mv $L/$a.$x $L/$b.$x; done; mv $L/${a}_jit.txt $L/${b}_jit.txt; mv /root/l51/ptx/$a /root/l51/ptx/$b
done
rm -f $L/stop
bash chain_extra.sh > chain_extra.out 2>&1
bash chain_screen2.sh > chain_screen2.out 2>&1
