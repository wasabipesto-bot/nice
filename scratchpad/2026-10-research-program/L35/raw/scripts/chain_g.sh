#!/bin/bash
# chain_g.sh: after extra.sh: build G (slot groups + no FD at power-of-two bases), fmt, FD test, parity (FD=2),
# timings over MIN_UNITS on the small fields, NiceMark A/B x3 with G's client, then one round of each A/B field on G.
L=/root/l35/logs; BIN=/root/l35/bin; T=/root/l35/test.sh; R=/root/l35/run2.sh
until [ -e $L/extra.done ]; do sleep 10; done
source ~/.cargo/env
cd /root/l35/src/B && git checkout -q -- . && git fetch -q origin exp/top-fd && git checkout -q --detach FETCH_HEAD && git log --oneline -1 > $L/g_tree.txt && md5sum common/src/cubecl_join.rs >> $L/g_tree.txt
( cargo fmt --all --check > $L/fmt_g.log 2>&1; echo "fmt rc=$?" >> $L/fmt_g.log )
/root/l35/build.sh B G gpu
/root/l35/buildclient.sh B client_G &
$T xg_fd G cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T xg_ref2 G cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_TOP_FD=2
wait
cd /root/l35/src/B
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
for F in 58:104400216587923470200:1e15 62:7997740455941656911841:1e14 57:28151599893042801193:1e14 62:7997740455941656911841:1e17; do
  for MU in 0 65536 131072 262144 524288; do
    NICE_EXP_TOP_FD_MIN_UNITS=$MU NICE_TEST_TOPFD_TIMING=$F $BIN/G --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 2>&1 | grep TOPFD | sed "s/^/MU=$MU /" >> $L/tg_groups.log
  done
done
echo G_TIMING_DONE $(date -u +%T) > $L/gtiming.done
export NICE_API_BASE=http://127.0.0.1:9
cd /root/l35
for r in 1 2 3; do
  for s in A B; do
    if [ $s = A ]; then FD=0; else FD=2; fi
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmg_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmg_${s}_r$r $(date -u +%T) md5=$(md5sum $BIN/client_G | cut -c1-8) NICE_EXP_TOP_FD=$FD" > $L/nmg_${s}_r$r.err
    NICE_EXP_TOP_FD=$FD $BIN/client_G niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmg_${s}_r$r.json 2>> $L/nmg_${s}_r$r.err
    echo "END nmg_${s}_r$r $(date -u +%T) rc=$?" >> $L/nmg_${s}_r$r.err
    kill $SMI
  done
done
echo G_NM_DONE $(date -u +%T) > $L/gnm.done
for f in "62 1 1e17 e17_b62" "62 2 1e16 e16_b62" "60 2 1e16 e16_b60" "64 2 1e16 e16_b64"; do
  set -- $f
  NICE_EXP_TOP_FD=0 $R abg_A_$4_r1 G $1 $2 $3; NICE_EXP_TOP_FD=2 $R abg_B_$4_r1 G $1 $2 $3
done
echo G_AB_DONE $(date -u +%T) > $L/gab.done
