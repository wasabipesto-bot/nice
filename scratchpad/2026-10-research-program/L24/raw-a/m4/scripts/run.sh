#!/bin/sh
# usage: run.sh <name> <script> [args]; records its PID, logs, exit status
D="$HOME/claude-exp-2026-10-31-seed"
echo $$ >> "$D/pids"
name=$1; shift
echo "START $(date +%s) pid $$" > "$D/logs/$name.status"
sh "$@" > "$D/logs/$name.log" 2>&1 < /dev/null
echo "EXIT $? $(date +%s)" >> "$D/logs/$name.status"
sed -i '' "/^$$\$/d" "$D/pids"
