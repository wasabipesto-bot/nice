#!/bin/bash
# chain_l5.sh: after the screen: tree X5 (exp/top-fd-round2 with level 5), build X5; #240's device test at level 5;
# then a mini-screen of X5 at levels 4 and 5, 2 interleaved rounds (b62 1e17, b60 1e16), and the kernel-alone timing
# test at levels 4 and 5, 2 rounds. Nothing else on the box.
R=/root/l48/run.sh; T=/root/l48/test.sh; L=/root/l48/logs
until [ -e $L/screen.done ]; do sleep 10; done
echo L5_START $(date -u +%T)
/root/l48/tree.sh X5 exp/top-fd-round2
J=19 /root/l48/build.sh X5 X5 || exit 1
export SRCD=X5
NICE_EXP_TOPFD=5 $T q_topfd_l5 X5 cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
echo "l5 device test: $(grep -h 'test result' $L/q_topfd_l5.log) $(grep -h 'tops' $L/q_topfd_l5.log | tail -1) $(date -u +%T)"
grep -q "test result: ok" $L/q_topfd_l5.log || { echo L5_DEVICE_TEST_FAILED; exit 1; }
for r in 1 2; do
  if [ $r = 1 ]; then O="4 5"; else O="5 4"; fi
  for lv in $O; do
    [ -e $L/stop ] && exit 0
    NICE_EXP_TOPFD=$lv $R s5_l${lv}_e17_b62_r$r X5 62 1 1e17
    NICE_EXP_TOPFD=$lv $R s5_l${lv}_e16_b60_r$r X5 60 2 1e16
    echo "$(date -u +%T) r$r l$lv $(grep -o 'device=[0-9.]*s' $L/s5_l${lv}_e17_b62_r$r.log | tail -1) $(grep -o 'device=[0-9.]*s' $L/s5_l${lv}_e16_b60_r$r.log | tail -1)"
  done
done
for r in 1 2; do
  if [ $r = 1 ]; then O="4 5"; else O="5 4"; fi
  for lv in $O; do
    NICE_EXP_TOPFD=$lv $T t5_l${lv}_e17_b62_r$r X5 cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=62:7997740455941656911841:1e17
    NICE_EXP_TOPFD=$lv $T t5_l${lv}_e16_b60_r$r X5 cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=60:1366406074057412100454:1e16
  done
done
echo L5_DONE $(date -u +%T) | tee $L/l5.done
