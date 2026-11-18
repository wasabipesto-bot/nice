#!/bin/bash
# on box (Vast 61250912, RTX 3080 at the host's 240 W cap): one timing round, binaries prebuilt, no builds running.
# usage: round3.sh R ORDER   e.g. round3.sh 1 "v10 P A D"   (rotate ORDER between rounds)
# v10 = hand CUDA (g2bench.cu KVER 10), P = port 9ff100e6 (its defaults, --tdig 0), A = port 4170a781 --tdig 0,
# D = port 4170a781 --tdig 1. 200 launches per mode, per-launch medians; GPU prep in every port run.
R=$1; ORDER=$2; cd /root/g2; SU=/root/g2/su64_712012851; mkdir -p out
export NICE_BUILD_SHA=test
idle() { for i in $(seq 1 120); do u=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits); if [ "$u" -eq 0 ] && ! pgrep -x nice-main >/dev/null && ! pgrep -x cargo >/dev/null && ! pgrep -f 'bin/g2_|bin/v10' >/dev/null; then sleep 2; return 0; fi; sleep 1; done; echo "card not idle"; return 1; }
for n in $ORDER; do
  case $n in
    v10) BIN=bin/v10; CMD="env SKIPCPU=1 ./bin/v10 $SU 200";;
    P)   BIN=bin/g2_P; CMD="./bin/g2_P $SU --cuda --gpu-prep --no-sets --reps 200";;
    A)   BIN=bin/g2_T; CMD="./bin/g2_T $SU --cuda --gpu-prep --no-sets --reps 200 --tdig 0";;
    D)   BIN=bin/g2_T; CMD="./bin/g2_T $SU --cuda --gpu-prep --no-sets --reps 200 --tdig 1";;
  esac
  idle || exit 1
  nvidia-smi --query-gpu=timestamp,power.draw,power.limit,clocks.sm,clocks.mem,utilization.gpu,temperature.gpu,clocks_throttle_reasons.active --format=csv,noheader -lms 100 > out/smi_r${R}_$n.csv &
  MP=$!
  echo "$(date -u +%FT%TZ) round $R $n start [$CMD] md5=$(md5sum $BIN | cut -c1-8)" >> out/runs.log
  $CMD > out/r${R}_$n.log 2>&1; rc=$?
  kill $MP; wait $MP 2>/dev/null
  echo "$(date -u +%FT%TZ) round $R $n end rc=$rc" >> out/runs.log
  echo "== r$R $n rc=$rc"; grep -E "^PREP|^MODE|RESULT|FAIL|ALL CHECKS" out/r${R}_$n.log | cut -c1-160
  python3 - out/smi_r${R}_$n.csv <<'PY'
import sys
rows=[l.strip().split(', ') for l in open(sys.argv[1]) if l.strip()]
busy=[r for r in rows if r[5].split()[0].isdigit() and float(r[5].split()[0])>50]
if busy:
    p=[float(r[1].split()[0]) for r in busy]; c=[float(r[3].split()[0]) for r in busy]
    print(f"smi busy samples {len(busy)}: mean {sum(p)/len(p):.0f} W (max {max(p):.0f}, limit {rows[0][2]}), SM {sum(c)/len(c):.0f} MHz (min {min(c):.0f}), max temp {max(int(r[6]) for r in rows)} C")
PY
done
