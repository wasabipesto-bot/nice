#!/bin/bash
# bench.sh <secs> <label>...: NiceMark detailed, GPU on CubeCL's CUDA runtime,
# one run per label in the order given; JSON and stderr to /root/logs/bench/.
SECS=$1; shift
B=/root/logs/bench; mkdir -p $B
export NICE_API_BASE=http://127.0.0.1:9
i=$(ls $B/*.json 2>/dev/null | wc -l)
for label in "$@"; do
  i=$((i+1)); tag=$(printf "%02d" $i)-$label
  nvidia-smi --query-gpu=temperature.gpu,clocks.sm,power.draw,utilization.gpu --format=csv,noheader > $B/$tag.smi-before
  s=$(date +%s)
  /root/bin/$label-client detailed --benchmark --benchmark-secs $SECS --benchmark-json \
      --gpu --gpu-backend cubecl-cuda > $B/$tag.json 2> $B/$tag.err
  echo "$tag rc=$? secs=$(( $(date +%s) - s )) $(date -u +%T)" >> $B/runs.txt
  nvidia-smi --query-gpu=temperature.gpu,clocks.sm,power.draw,utilization.gpu --format=csv,noheader > $B/$tag.smi-after
done
echo "BENCH_DONE $*" >> $B/runs.txt
