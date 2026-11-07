#!/bin/bash
# chain_rider.sh: the optional rider R = W + the survivor stage checked once per top batch (fork
# exp/join-static-buckets-s15). After the main A/B (ab.done): tree R, its test binary and client (CPU, beside the
# lavapipe tests and the lint); CUDA exactness (1e14 compare, CPU-reference parity, both dense fields); after the lint
# (post.done): the A/B W vs R, interleaved, 3 rounds of b62 1e17, b62/b60/b64 1e16 (2 fields), NiceMark 2 rounds.
L=/root/l46/logs; S=/root/l46/scripts; R=$S/run.sh; T=$S/test.sh; BIN=/root/l46/bin; W=${1:-S5}
until [ -e $L/ab.done ]; do sleep 10; done
echo RIDER_START $(date -u +%T)
cd /root/nice && git fetch -q origin exp/join-static-buckets-s15 && git worktree add -q --detach /root/l46/src/R origin/exp/join-static-buckets-s15
(cd /root/l46/src/R && echo "R $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") >> $L/trees.txt
NICEN=5 J=12 $S/build.sh R R || exit 1
NICEN=10 J=8 $S/buildclient.sh R client_R >> /root/l46/buildclient.out 2>&1
export SRCD=R
NICE_TEST_JOIN_COMPARE=1 $R cmp_R_e14 R 57,60,62,64 1 1e14
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_R_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'test result' $L/cmp_R_e14.log
$T x_R_ref R cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_R_dense58 R cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_R_dense62 R cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
for f in ref dense58 dense62; do echo "$f: $(grep -h 'test result' $L/x_R_$f.log | head -1) $(grep -h '^END' $L/x_R_$f.log)"; done
unset SRCD
until [ -e $L/post.done ]; do sleep 10; done
echo RIDER_AB_START $(date -u +%T)
for r in 1 2 3; do
  if [ $r = 2 ]; then O="R $W"; else O="$W R"; fi
  for t in $O; do SRCD=$t $R rd_${t}_e17_b62_r$r $t 62 1 1e17; done
  for f in "62 e16_b62" "60 e16_b60" "64 e16_b64"; do
    set -- $f
    for t in $O; do SRCD=$t $R rd_${t}_$2_r$r $t $1 2 1e16; done
  done
done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
cd /root/l46
for r in 1 2; do
  if [ $r = 2 ]; then O="R $W"; else O="$W R"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmr_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmr_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nmr_${t}_r$r.err
    $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmr_${t}_r$r.json 2>> $L/nmr_${t}_r$r.err
    echo "END nmr_${t}_r$r $(date -u +%T) rc=$?" >> $L/nmr_${t}_r$r.err
    kill $SMI
  done
done
echo RIDER_DONE $(date -u +%T) > $L/rider.done
