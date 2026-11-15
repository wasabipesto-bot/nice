#!/bin/bash
# T2.8 box chain: timing round 1 (6 fields, main and v3.4.7 alternated per field, ABBA), the main sample queue,
# timing round 2 (order reversed). One client process per (build, field) in the timing runs.
cd /root/t28
M=54d0aac4; R=8bd154bc
python3 - <<'P'
import json
q=json.load(open('/root/t28/queue_timing.json'))
for i,f in enumerate(q): json.dump([f], open(f'/root/t28/tq{i}.json','w'))
P
round() {
  r=$1
  for i in 0 1 2 3 4 5; do
    if [ $(( (i + r) % 2 )) -eq 0 ]; then o="$M $R"; else o="$R $M"; fi
    for b in $o; do ./run_queue.sh $b tq$i.json 8200 T${r}_${b}_f$i --threads 8; done
  done
}
round 1
./run_queue.sh $M queue_main_sample.json 8300 S_main --threads 8
round 2
echo "$(date -u +%FT%TZ) chain done" >> runs.log
