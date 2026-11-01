#!/bin/bash
# benchlvp.sh <secs> <label>...: NiceMark detailed on lavapipe (wgpu, naga WGSL).
SECS=$1; shift
B=/root/logs/benchlvp; mkdir -p $B
export NICE_API_BASE=http://127.0.0.1:9 VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
i=$(ls $B/*.json 2>/dev/null | wc -l)
for label in "$@"; do
  i=$((i+1)); tag=$(printf "%02d" $i)-$label
  s=$(date +%s); uptime > $B/$tag.load
  /root/bin/$label-client detailed --benchmark --benchmark-secs $SECS --benchmark-json \
      --gpu --gpu-backend cubecl > $B/$tag.json 2> $B/$tag.err
  echo "$tag rc=$? secs=$(( $(date +%s) - s )) $(date -u +%T)" >> $B/runs.txt; uptime >> $B/$tag.load
done
echo "BENCH_DONE $*" >> $B/runs.txt
