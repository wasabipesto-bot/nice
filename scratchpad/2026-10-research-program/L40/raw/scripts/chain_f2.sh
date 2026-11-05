#!/bin/bash
# chain_f2.sh: experimental F2 (= the PR's kernel, but a small batch's two words walked by their own one-walk-per-lane
# loop, no word pick; a second round body): test binary and client in their own target dir (niced, beside the final
# chains), registers; then, once the final chains are done and nothing else runs, a screen against M: the 1e14 set
# (2 rounds), NiceMark (3 rounds), b62 and b60 1e16 (1 round); order alternating.
L=/root/l40/logs; R=/root/l40/run.sh; BIN=/root/l40/bin
NICEN=10 J=8 /root/l40/build.sh F2 F2 gpu /root/tgt_f2 || exit 1
source ~/.cargo/env
cd /root/l40/src/F2 && CARGO_TARGET_DIR=/root/tgt_f2 NICE_BUILD_SHA=test nice -n 10 cargo build --release -j 8 -p nice_client --features gpu > $L/build_client_F2.log 2>&1 && cp /root/tgt_f2/release/nice_client $BIN/client_F2 && echo "client_F2 $(md5sum $BIN/client_F2)"
(cd /root/l40/src/F2 && echo "F2 (experimental) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> $L/trees.txt
until [ -e $L/final.done ] && [ -e $L/cpu_q.done ]; do sleep 10; done
while pgrep -f "cargo|rustc|l40/bin/" > /dev/null; do sleep 5; done
/root/l40/regs.sh F2 F2 F2 > $L/regs_F2.out 2>&1
grep join_kernel /root/l40/sass/F2/registers.txt; head -1 $L/regs_F2.out
echo SCR_F2_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="F2 M"; else O="M F2"; fi
  for b in 57 60 62 64; do for t in $O; do SRCD=$t $R scrf2_${t}_e14_b${b}_r$r $t $b 3 1e14; done; done
done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
for r in 1 2 3; do
  if [ $r = 2 ]; then O="F2 M"; else O="M F2"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nmf2_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nmf2_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nmf2_${t}_r$r.err
    (cd /root/l40 && $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nmf2_${t}_r$r.json 2>> $L/nmf2_${t}_r$r.err)
    echo "END nmf2_${t}_r$r $(date -u +%T) rc=$?" >> $L/nmf2_${t}_r$r.err
    kill $SMI
  done
done
echo SCR_F2_NM_DONE $(date -u +%T)
for f in "62 e16_b62" "60 e16_b60"; do set -- $f; for t in M F2; do SRCD=$t $R scrf2_${t}_$2_r1 $t $1 2 1e16; done; done
echo SCR_F2_DONE $(date -u +%T) > $L/f2.done
