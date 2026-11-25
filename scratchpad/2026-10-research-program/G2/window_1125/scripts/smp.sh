#!/bin/sh
# smp.sh FILE: sample the card every 0.5 s until killed (busy %, shader clock MHz, power W, temperature): AMD sysfs;
# on lavapipe only the load. Window 3: SMP_DT (default 0.5 s) sets the interval (0.1 for the word-width bench).
F=$1
D=$(ls -d /sys/class/drm/card*/device 2>/dev/null | while read d; do [ -e $d/gpu_busy_percent ] && echo $d; done | head -1)
HW=$(ls -d $D/hwmon/hwmon* 2>/dev/null | head -1)
while true; do
  if [ -n "$D" ]; then
    P=$(cat $HW/power1_average 2>/dev/null || cat $HW/power1_input 2>/dev/null || echo 0)
    echo "$(date -u +%T.%N | cut -c1-12) busy=$(cat $D/gpu_busy_percent) sclk=$(grep '\*' $D/pp_dpm_sclk | sed 's/.*: *//; s/[^0-9]//g') pw=$((P / 1000000)) temp=$(( $(cat $HW/temp1_input 2>/dev/null || echo 0) / 1000 )) load=$(cut -d' ' -f1 /proc/loadavg)"
  else
    echo "$(date -u +%T.%N | cut -c1-12) load=$(cut -d' ' -f1 /proc/loadavg)"
  fi
  sleep ${SMP_DT:-0.5}
done > "$F" 2>&1
