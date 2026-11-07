#!/bin/bash
# chain_topt.sh (round 2): after final.done: #240's kernel-alone timing, S against F, 2 rounds per side and field.
L=/root/l48/logs; cd /root/l48; T=/root/l48/test.sh
until [ -e $L/final.done ]; do sleep 15; done
for r in 1 2; do
  if [ $r = 1 ]; then O="S F"; else O="F S"; fi
  for t in $O; do
    lv=0; [ $t = F ] && lv=6
    SRCD=$t $T topt_l${lv}_e17_b62_r$r $t cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=62:7997740455941656911841:1e17
    SRCD=$t $T topt_l${lv}_e16_b60_r$r $t cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=60:1366406074057412100454:1e16
  done
done
echo TOPT_DONE $(date -u +%T) | tee $L/topt.done
