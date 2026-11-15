#!/bin/sh
# wait until PATTERN appears in the box's runs.log or UTC time passes DEADLINE (HHMM); pull every 5 min
P="$1"; D="$2"
while true; do
  ./pull.sh >/dev/null 2>&1
  grep -q "$P" box/runs.log 2>/dev/null && { echo "found $P"; break; }
  [ "$(date -u +%H%M)" -ge "$D" ] && { echo "deadline $D"; break; }
  sleep 120
done
tail -n 3 box/runs.log; date -u
