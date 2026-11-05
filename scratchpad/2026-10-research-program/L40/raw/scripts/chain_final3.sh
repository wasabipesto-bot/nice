#!/bin/bash
# chain_final3.sh: after A/B 5 (ab5.done): 4 more NiceMark rounds of M and F2 (nm6_*, order M F2, F2 M, M F2, F2 M),
# nothing else on the box; then, on the CPU, tree Z = fork pr/join-group-walk (F2's code + one reworded comment): its
# test binary (compared with F2's), lint and lavapipe; and on the GPU F2's CUDA exactness list (chain_x.sh F2).
L=/root/l40/logs; BIN=/root/l40/bin
until [ -e $L/ab5.done ]; do sleep 10; done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
echo NM6_START $(date -u +%T)
for r in 1 2 3 4; do
  if [ $((r % 2)) = 0 ]; then O="F2 M"; else O="M F2"; fi
  for t in $O; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm6_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm6_${t}_r$r $(date -u +%T) bin=client_$t md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nm6_${t}_r$r.err
    (cd /root/l40 && $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm6_${t}_r$r.json 2>> $L/nm6_${t}_r$r.err)
    echo "END nm6_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm6_${t}_r$r.err
    kill $SMI
  done
done
echo NM6_DONE $(date -u +%T)
(setsid nohup bash -c "/root/l40/tree.sh Z pr/join-group-walk; /root/l40/build.sh Z Z; cmp /root/l40/bin/Z /root/l40/bin/F2 > $L/cmp_Z_F2.txt 2>&1; echo \"size Z \$(stat -c %s /root/l40/bin/Z) F2 \$(stat -c %s /root/l40/bin/F2) differing bytes \$(cmp -l /root/l40/bin/Z /root/l40/bin/F2 2>/dev/null | wc -l)\" >> $L/cmp_Z_F2.txt; diff <(strings -n 8 /root/l40/bin/Z | sort -u) <(strings -n 8 /root/l40/bin/F2 | sort -u) | head -20 >> $L/cmp_Z_F2.txt; /root/l40/chain_lint.sh Z; /root/l40/chain_lvp.sh Z; echo CPU_Z_DONE \$(date -u +%T) > $L/cpu_z.done" > $L/chain_cpu_z.out 2>&1 < /dev/null &)
/root/l40/chain_x.sh F2
echo CHAIN_FINAL3_DONE $(date -u +%T) > $L/final3.done
