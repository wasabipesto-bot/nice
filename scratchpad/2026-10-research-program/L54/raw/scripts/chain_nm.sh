#!/bin/bash
# chain_nm.sh A B ROUNDS: NiceMark nice-only (150 s) of client_A against client_B, ROUNDS rounds, order alternating
# (A B, B A, ...), nothing else on the box; JSON + nvidia-smi per run.
L=/root/l54/logs; BIN=/root/l54/bin; A=$1; B=$2; N=${3:-4}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9 NICE_BUILD_SHA=test
mkdir -p /root/l54/nm && cd /root/l54/nm
echo NM_START $A $B $(date -u +%T)
for r in $(seq 1 $N); do
  if [ $((r % 2)) = 0 ]; then O="$B $A"; else O="$A $B"; fi
  for t in $O; do
    [ -e $L/stop ] && exit 0
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${t}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${t}_r$r $(date -u +%T) md5=$(md5sum $BIN/client_$t | cut -c1-8)" > $L/nm_${t}_r$r.err
    $BIN/client_$t niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${t}_r$r.json 2>> $L/nm_${t}_r$r.err
    echo "END nm_${t}_r$r $(date -u +%T) rc=$?" >> $L/nm_${t}_r$r.err
    kill $SMI
    echo "$(date -u +%T) nm_${t}_r$r $(python3 -c "import json;d=json.load(open('$L/nm_${t}_r$r.json'));print(d.get('score', d.get('nicemark', '?')))" 2>/dev/null)"
  done
done
echo NM_DONE $(date -u +%T) | tee $L/nm.done
