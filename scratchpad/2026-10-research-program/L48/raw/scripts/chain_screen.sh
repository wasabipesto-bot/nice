#!/bin/bash
# chain_screen.sh: levels 0-4 of binary X (NICE_EXP_TOPFD), 2 interleaved rounds (order rotating): b62 1e17 (1 field),
# b60 1e16 (2 fields); then #240's kernel-alone timing test per level at both fields, 2 rounds. Waits for screen_go.
R=/root/l48/run.sh; T=/root/l48/test.sh; L=/root/l48/logs; export SRCD=X
until [ -e $L/screen_go ]; do sleep 10; done
echo SCREEN_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 1 ]; then O="0 1 2 3 4"; else O="4 3 2 1 0"; fi
  for lv in $O; do
    [ -e $L/stop ] && exit 0
    NICE_EXP_TOPFD=$lv $R scr_l${lv}_e17_b62_r$r X 62 1 1e17
    NICE_EXP_TOPFD=$lv $R scr_l${lv}_e16_b60_r$r X 60 2 1e16
    echo "$(date -u +%T) r$r l$lv $(grep -o 'device=[0-9.]*s' $L/scr_l${lv}_e17_b62_r$r.log | tail -1) $(grep -o 'device=[0-9.]*s' $L/scr_l${lv}_e16_b60_r$r.log | tail -1)"
  done
done
echo SCREEN_FIELDS_DONE $(date -u +%T)
for r in 1 2; do
  if [ $r = 1 ]; then O="0 1 2 3 4"; else O="4 3 2 1 0"; fi
  for lv in $O; do
    [ -e $L/stop ] && exit 0
    NICE_EXP_TOPFD=$lv $T topt_l${lv}_e17_b62_r$r X cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=62:7997740455941656911841:1e17
    NICE_EXP_TOPFD=$lv $T topt_l${lv}_e16_b60_r$r X cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=60:1366406074057412100454:1e16
  done
done
echo SCREEN_DONE $(date -u +%T) | tee $L/screen.done
