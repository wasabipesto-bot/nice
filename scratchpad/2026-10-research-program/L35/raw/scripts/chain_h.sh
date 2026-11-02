#!/bin/bash
# chain_h.sh: after chain_g: build H (G + warm the clipped-block kernel), FD test, parity FD=2, NiceMark A/B x3, one round per field.
L=/root/l35/logs; BIN=/root/l35/bin; T=/root/l35/test.sh; R=/root/l35/run2.sh
until [ -e $L/gab.done ]; do sleep 10; done
source ~/.cargo/env
cd /root/l35/src/B && git checkout -q -- . && git fetch -q origin exp/top-fd && git checkout -q --detach FETCH_HEAD && git log --oneline -1 > $L/h_tree.txt && md5sum common/src/cubecl_join.rs >> $L/h_tree.txt
( cargo fmt --all --check > $L/fmt_h.log 2>&1; echo "fmt rc=$?" >> $L/fmt_h.log )
/root/l35/build.sh B H gpu
/root/l35/buildclient.sh B client_H
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_API_BASE=http://127.0.0.1:9
cd /root/l35
for r in 1 2 3; do
  for s in A B; do
    if [ $s = A ]; then FD=0; else FD=2; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmh_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmh_${s}_r$r $(date -u +%T) md5=$(md5sum $BIN/client_H | cut -c1-8) NICE_EXP_TOP_FD=$FD" > $L/nmh_${s}_r$r.err
    NICE_EXP_TOP_FD=$FD $BIN/client_H niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmh_${s}_r$r.json 2>> $L/nmh_${s}_r$r.err
    echo "END nmh_${s}_r$r $(date -u +%T) rc=$?" >> $L/nmh_${s}_r$r.err
    kill $SMI
  done
done
echo H_NM_DONE $(date -u +%T) > $L/hnm.done
$T xh_fd H cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T xh_ref2 H cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_TOP_FD=2
for f in "62 1 1e17 e17_b62" "62 2 1e16 e16_b62" "60 2 1e16 e16_b60" "64 2 1e16 e16_b64"; do
  set -- $f
  NICE_EXP_TOP_FD=0 $R abh_A_$4_r1 H $1 $2 $3; NICE_EXP_TOP_FD=2 $R abh_B_$4_r1 H $1 $2 $3
done
echo H_DONE $(date -u +%T) > $L/h.done
