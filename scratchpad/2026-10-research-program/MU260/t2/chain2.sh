#!/bin/bash
# chain2.sh: builds, then timing (3 real b62 1e17 fields, main 0711b163 vs v3.4.7 8bd154bc, one client process per
# (build, field), alternated per field, order reversed in round 2), then NiceMark nice-only GPU 2 rounds each
# (API base = closed local port 9; --benchmark-secs 150), with nvidia-smi sampled every 2 s.
cd /root/mu/t2
M=0711b163; R=8bd154bc
( bash build2.sh 0711b1634b91f156d478e5da447f97693236a48e ) & ( bash build2.sh 8bd154bcc5c0dc1e1384bf5f31838ce58fce1147 ) & wait
[ -x bin/nice-$M ] && [ -x bin/nice-$R ] || { echo BUILDS_FAILED; exit 1; }
strings bin/nice-$M | grep -o '[a-z.]*nicenumbers\.net' | sort -u > hosts_in_bins.txt; strings bin/nice-$R | grep -o '[a-z.]*nicenumbers\.net' | sort -u >> hosts_in_bins.txt
nvidia-smi --query-gpu=timestamp,power.draw,power.limit,power.default_limit,clocks.sm,temperature.gpu,utilization.gpu --format=csv,noheader -l 2 > gpu.csv 2>&1 &
SMI=$!
python3 - <<'P'
import json
q=json.load(open('/root/mu/t2/queue_timing.json'))
pick=[f for f in q if f['field_id'] in (207072517, 207072868, 207072999)]
for i,f in enumerate(pick): json.dump([f], open(f'/root/mu/t2/tq{i}.json','w'))
print(len(pick))
P
round() {
  r=$1
  for i in 0 1 2; do
    if [ $(( (i + r) % 2 )) -eq 0 ]; then o="$M $R"; else o="$R $M"; fi
    for b in $o; do ./run_queue.sh $b tq$i.json 8200 T${r}_${b}_f$i --threads 8; done
  done
}
round 1
round 2
echo "$(date -u +%FT%TZ) $(date +%s.%N) timing done" >> runs.log
for r in 1 2; do
  if (( r % 2 == 1 )); then ORDER="$M $R"; else ORDER="$R $M"; fi
  for b in $ORDER; do
    echo "$(date -u +%FT%TZ) $(date +%s.%N) start NM r$r $b" >> runs.log
    NICE_API_BASE=http://127.0.0.1:9 timeout 900 bin/nice-$b niceonly --api-base http://127.0.0.1:9 --gpu --benchmark --benchmark-secs 150 --benchmark-json > nm-r$r-$b.json 2> nm-r$r-$b.stderr
    echo "$(date -u +%FT%TZ) $(date +%s.%N) end NM r$r $b exit $?" >> runs.log
  done
done
kill $SMI
echo "$(date -u +%FT%TZ) chain done" >> runs.log
