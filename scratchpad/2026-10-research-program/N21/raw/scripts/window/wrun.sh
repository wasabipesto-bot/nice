#!/bin/sh
# wrun.sh NAME N21 BASE SIZE START: one process of the throughput harness (one untimed 1e14 warm-up field, then one
# field of SIZE at START) with NICE_EXP_N21=N21. Logs $OUT/NAME.log and $OUT/NAME.gpu (every 2 s: busy %, shader
# clock, power, temperature; AMD sysfs, nvidia-smi, or the load only on lavapipe). (N16's wrun.sh with the switch.)
. "${SCRIPTS:-$(dirname "$0")}/env.sh"
NAME=$1; N21=$2; BASE=$3; SIZE=$4; START=$5
smp() {
  if [ "$DEV" = cuda ]; then
    while true; do
      nvidia-smi --query-gpu=utilization.gpu,clocks.sm,power.draw,power.limit,temperature.gpu --format=csv,noheader,nounits |
        { IFS=', ' read u c p l t; echo "$(date -u +%T) busy=$u sclk=$c pw=$p cap=$l temp=$t load=$(cut -d' ' -f1 /proc/loadavg)"; }
      sleep 2
    done
  else
    D=$(ls -d ${DRM:-/sys/class/drm}/card*/device 2>/dev/null | while read d; do [ -e $d/gpu_busy_percent ] && echo $d; done | head -1)
    HW=$(ls -d $D/hwmon/hwmon* 2>/dev/null | head -1)
    while true; do
      if [ -n "$D" ]; then
        P=$(cat $HW/power1_average 2>/dev/null || cat $HW/power1_input 2>/dev/null)
        echo "$(date -u +%T) busy=$(cat $D/gpu_busy_percent) sclk=$(grep '\*' $D/pp_dpm_sclk | sed 's/.*: *//; s/[^0-9]//g') pw=$((P / 1000000)) cap=$(( $(cat $HW/power1_cap 2>/dev/null || echo 0) / 1000000)) temp=$(cat $HW/temp1_input 2>/dev/null) load=$(cut -d' ' -f1 /proc/loadavg)"
      else
        echo "$(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg)"
      fi
      sleep 2
    done
  fi
}
smp > "$OUT/$NAME.gpu" 2>&1 &
MON=$!
echo "START $NAME $(date -u +%T) dev=$DEV n21=$N21 base=$BASE size=$SIZE start=$START md5=$(md5sum "$BIN/E" | cut -c1-8)" > "$OUT/$NAME.log"
NICE_EXP_N21=$N21 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASE NICE_TEST_JOIN_STARTS=$BASE:$START \
  "$BIN/E" --ignored --exact $HARNESS --nocapture --test-threads 1 >> "$OUT/$NAME.log" 2>&1
RC=$?
echo "END $NAME $(date -u +%T) rc=$RC" >> "$OUT/$NAME.log"
kill $MON 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -h 'JOIN THROUGHPUT' "$OUT/$NAME.log" | grep -o 'secs=[0-9.]*\|survivors=[0-9]*\|checked=[0-9]*' | tr '\n' ' ')"
