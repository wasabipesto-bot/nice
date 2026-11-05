#!/bin/bash
# chain_h.sh: variant H (= P, but a batch below TRANSPOSE_MIN takes one chunk per pass: no chunk loop, its 2 words
# set directly, nm over them): test binary, registers + 1e14 counts, client; then a screen against M, nothing else
# on the box: the 1e14 set (b57/60/62/64, 3 fields, 2 rounds), NiceMark (2 rounds), b62 and b60 1e16 (1 round);
# order M H, then H M.
L=/root/l40/logs; R=/root/l40/run.sh; BIN=/root/l40/bin
/root/l40/build.sh H H || exit 1
/root/l40/regs.sh H H H > $L/regs_H.out 2>&1
grep join_kernel /root/l40/sass/H/registers.txt; head -1 $L/regs_H.out
/root/l40/buildclient.sh H client_H > $L/buildclient_H.out 2>&1; tail -n 2 $L/buildclient_H.out
(cd /root/l40/src/H && echo "H (variant) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
echo SCR_H_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="H M"; else O="M H"; fi
  for b in 57 60 62 64; do for t in $O; do SRCD=$t $R scrh_${t}_e14_b${b}_r$r $t $b 3 1e14; done; done
done
echo SCR_H_E14_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
for r in 1 2; do
  if [ $r = 2 ]; then O="H M"; else O="M H"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmh_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmh_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nmh_${t}_r$r.err
    (cd /root/l40 && $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmh_${t}_r$r.json 2>> $L/nmh_${t}_r$r.err)
    echo "END nmh_${t}_r$r $(date -u +%T) rc=$?" >> $L/nmh_${t}_r$r.err
    kill $SMI
  done
done
echo SCR_H_NM_DONE $(date -u +%T)
for f in "62 e16_b62" "60 e16_b60"; do set -- $f; for t in M H; do SRCD=$t $R scrh_${t}_$2_r1 $t $1 2 1e16; done; done
echo SCR_H_DONE $(date -u +%T)
