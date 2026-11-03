#!/bin/bash
# chain_q.sh: after lavapipe, the quiet ablation rounds (2 rounds, every config, both fields; plus the production
# binary S's own timing test per round), then release the A/B (go_ab).
L=/root/l36/logs; T=/root/l36/test.sh
until [ -e $L/lvp.done ]; do sleep 10; done
echo Q_START $(date -u +%T) > $L/q.start
for r in 2 3; do
  TAG=q /root/l36/chain_abl.sh 1 0 1 2 4 8 16 32 3 6 36 38 54 9 10 12 24 40 63
  for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
    b=${F%%:*}
    SRCD=S $T qS_b${b}_r$r S cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F
  done
  for f in $L/q_b*_r1.log; do mv $f ${f%_r1.log}_r$r.log; done
done
echo Q_DONE $(date -u +%T) > $L/q.done
touch $L/go_ab
