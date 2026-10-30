#!/bin/sh
# usage: watchdog.sh <seconds>; at the deadline kill every PID in pids
# (parent before children) and remove the experiment directory.
D="$HOME/claude-exp-2026-10-30-fd"
sleep "$1"
desc() { for c in $(pgrep -P "$1"); do echo "$c"; desc "$c"; done; }
if [ -f "$D/pids" ]; then
  for p in $(cat "$D/pids"); do
    kids=$(desc "$p")
    kill -9 "$p" 2>/dev/null
    for k in $kids; do kill -9 "$k" 2>/dev/null; done
  done
fi
cd "$HOME" && rm -rf "$D"
