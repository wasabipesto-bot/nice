#!/bin/bash
# chain_post2.sh: P2 = the PR form with slices cut as before (SLICE_SURV_PER_PREFIX 2) and batches planned at
# SURV_PER_PREFIX 1. After chain_post (X exactness) and with nothing else running: the A/B of B against P2 (PFX=ab2,
# 3 rounds of fields, the 1e14 set, NiceMark 6 rounds); then P2's CUDA exactness list beside P2's lavapipe builds,
# lavapipe tests and lint; then the kernel-alone timing test, B against P2, 2 rounds per field.
L=/root/l48/logs; cd /root/l48
until [ -e $L/post.done ] && grep -q "BUILD_DONE client_P2" build_P2.out; do sleep 15; done
while pgrep -f "bin/X_naga|bin/X_spv|bin/P_naga|bin/P_spv|cargo |rustc" > /dev/null; do sleep 15; done
echo AB2_GO $(date -u +%T)
PFX=ab2 ./chain_ab.sh P2 0 P2 > chain_ab2.out 2>&1
echo AB2_DONE $(date -u +%T)
( NICEN=15 J=10 ./build.sh P2 P2_naga cubecl /root/tgt_lvp && NICEN=15 J=10 ./build.sh P2 P2_spv cubecl-spirv /root/tgt_lvp && GO=ab2.done ./chain_lvp.sh P2 P2 "" 6 ) > chain_lvp_P2.out 2>&1 &
( sed 's/until \[ -e $L\/ab.done \]/until [ -e $L\/ab2.done ]/' chain_lint.sh > chain_lint2.sh; chmod +x chain_lint2.sh; ./chain_lint2.sh P2 ) > chain_lint_P2.out 2>&1 &
SRCD=P2 ./chain_x.sh P2 0 P2 > chain_x_P2.out 2>&1
echo X_P2_DONE $(date -u +%T)
wait
T=/root/l48/test.sh
for r in 1 2; do
  if [ $r = 1 ]; then O="B P2"; else O="P2 B"; fi
  for t in $O; do
    lv=0; [ $t = P2 ] && lv=6
    SRCD=$t $T tp2_l${lv}_e17_b62_r$r $t cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=62:7997740455941656911841:1e17
    SRCD=$t $T tp2_l${lv}_e16_b60_r$r $t cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=60:1366406074057412100454:1e16
  done
done
echo POST2_DONE $(date -u +%T) | tee $L/post2.done
