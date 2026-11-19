#!/bin/bash
# box: g2claim.sh — the same client and stub as g2run.sh, but the rows served as nice-only claims (one field each,
# no --repeat): the CPU, --gpu (auto: CUDA) and --gpu --gpu-backend cubecl on lavapipe, base-42 control first;
# then the fixed client (/root/bin/sfx/nice_client) on the CPU if it exists. Guarded. Output /root/runs/g2k.
O=/root/runs/g2k; mkdir -p $O; rm -f $O/done $O/rc.txt; source /root/guard.sh $O || exit 1
X=/root/bin/upc/nice_client; md5sum $X /root/bin/sfx/nice_client > $O/bin.txt 2>&1
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
python3 /root/stub_validate.py 8651 /root/rows43.json $O/cur $O/stub.jsonl & SP=$!; sleep 1
run() { n=$1; id=$2; shift 2; echo $id > $O/cur; echo "{\"run\":\"$n\"}" >> $O/stub.jsonl; s0=$(date +%s)
  env NICE_API_BASE=http://127.0.0.1:8651 NICE_API_MAX_RETRIES=0 RUST_BACKTRACE=1 timeout 900 "$@" --no-progress > $O/$n.txt 2>&1
  echo "$n field $id rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
for id in ${IDS:-25000 30000 40000 49999}; do
  run cpu_$id $id $X niceonly
  run cuda_$id $id $X niceonly --gpu
  run wgpu_$id $id env VK_ICD_FILENAMES=$LVP $X niceonly --gpu --gpu-backend cubecl
  [ -x /root/bin/sfx/nice_client ] && run fixed_cpu_$id $id /root/bin/sfx/nice_client niceonly
done
kill $SP; echo done > $O/done
