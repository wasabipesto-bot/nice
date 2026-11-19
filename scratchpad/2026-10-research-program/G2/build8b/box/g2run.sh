#!/bin/bash
# box: g2run.sh — the real client of upstream main (974d7194, /root/bin/upc/nice_client, --features gpu, release)
# against stub_validate.py on 127.0.0.1:8650: for each validation row, niceonly --validate on the CPU, with --gpu
# (default backend: auto, i.e. CUDA here) and with --gpu --gpu-backend cubecl on lavapipe; then detailed --validate
# on one base-43 row. Guarded (hosts proof first). Output /root/runs/g2c.
O=/root/runs/g2c; mkdir -p $O; rm -f $O/done $O/rc.txt; source /root/guard.sh $O || exit 1
cat /etc/hosts > $O/etc_hosts.txt
X=/root/bin/upc/nice_client; md5sum $X > $O/bin.txt; $X --version >> $O/bin.txt 2>&1
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
python3 /root/stub_validate.py 8650 /root/rows43.json $O/cur $O/stub.jsonl & SP=$!; sleep 1
run() { n=$1; id=$2; shift 2; echo $id > $O/cur; echo "{\"run\":\"$n\"}" >> $O/stub.jsonl; s0=$(date +%s)
  env NICE_API_BASE=http://127.0.0.1:8650 NICE_API_MAX_RETRIES=0 RUST_BACKTRACE=1 timeout 900 "$@" --no-progress > $O/$n.txt 2>&1
  echo "$n field $id rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
for id in 25000 30000 40000 49999; do
  run cpu_$id $id $X niceonly --validate
  run cuda_$id $id $X niceonly --validate --gpu
done
for id in 25000 30000; do run wgpu_$id $id env VK_ICD_FILENAMES=$LVP $X niceonly --validate --gpu --gpu-backend cubecl; done
run detailed_30000 30000 $X detailed --validate
kill $SP; echo done > $O/done
