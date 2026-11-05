#!/bin/bash
# chain_h2.sh: variant H2 (= H + the first word of a small batch picked before the walk by a select over its ept words):
# a screen against M, nothing else on the box: the 1e14 set (b57/60/62/64, 3 fields, 2 rounds), NiceMark (2 rounds), b62 and b60 1e16 (1 round);
# order M H2, then H2 M.
until grep -q SCR_H_DONE /root/l40/logs/chain_h.out; do sleep 5; done
L=/root/l40/logs; R=/root/l40/run.sh; BIN=/root/l40/bin
/root/l40/build.sh H2 H2 || exit 1
/root/l40/regs.sh H2 H2 H2 > $L/regs_H2.out 2>&1
grep join_kernel /root/l40/sass/H2/registers.txt; head -1 $L/regs_H2.out
/root/l40/buildclient.sh H2 client_H2 > $L/buildclient_H2.out 2>&1; tail -n 2 $L/buildclient_H2.out
(cd /root/l40/src/H2 && echo "H2 (variant) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
echo SCR_H2_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="H2 M"; else O="M H2"; fi
  for b in 57 60 62 64; do for t in $O; do SRCD=$t $R scrh2_${t}_e14_b${b}_r$r $t $b 3 1e14; done; done
done
echo SCR_H2_E14_DONE $(date -u +%T)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
for r in 1 2; do
  if [ $r = 2 ]; then O="H2 M"; else O="M H2"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmh2_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmh2_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nmh2_${t}_r$r.err
    (cd /root/l40 && $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmh2_${t}_r$r.json 2>> $L/nmh2_${t}_r$r.err)
    echo "END nmh2_${t}_r$r $(date -u +%T) rc=$?" >> $L/nmh2_${t}_r$r.err
    kill $SMI
  done
done
echo SCR_H2_NM_DONE $(date -u +%T)
for f in "62 e16_b62" "60 e16_b60"; do set -- $f; for t in M H2; do SRCD=$t $R scrh2_${t}_$2_r1 $t $1 2 1e16; done; done
echo SCR_H2_DONE $(date -u +%T)
