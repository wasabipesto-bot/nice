#!/bin/bash
# on box: one timing round of the G2 kernels (no builds here; binaries prebuilt), card idle first, nvidia-smi at 100 ms
# usage: round.sh R
R=$1; cd /root/g2
idle() { for i in $(seq 1 120); do u=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits); if [ "$u" -eq 0 ] && ! pgrep -x nice-main >/dev/null; then sleep 2; return 0; fi; sleep 1; done; echo "card not idle"; return 1; }
for b in v1staged:20 v10:200 v10o:200; do
  n=${b%%:*}; reps=${b##*:}
  idle || exit 1
  nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,clocks.mem,utilization.gpu,temperature.gpu --format=csv,noheader -lms 100 > smi_r${R}_$n.csv &
  MP=$!
  echo "$(date -u +%FT%TZ) round $R $n start" >> runs.log
  SKIPCPU=1 ./g2b_$n su64_712012851 $reps > round${R}_$n.log 2>&1; rc=$?
  kill $MP; echo "$(date -u +%FT%TZ) round $R $n end rc=$rc" >> runs.log
  grep -E "PREP:|MODE|VERIFY|RESULT" round${R}_$n.log
  python3 - smi_r${R}_$n.csv <<'PY'
import sys
rows=[l.strip().split(', ') for l in open(sys.argv[1]) if l.strip()]
busy=[r for r in rows if float(r[4].split()[0])>50]
if busy:
    p=[float(r[1].split()[0]) for r in busy]; c=[float(r[2].split()[0]) for r in busy]
    print(f"smi busy samples {len(busy)}: mean {sum(p)/len(p):.0f} W (max {max(p):.0f}), SM {sum(c)/len(c):.0f} MHz (min {min(c):.0f}), max temp {max(int(r[5]) for r in rows)} C")
PY
done
