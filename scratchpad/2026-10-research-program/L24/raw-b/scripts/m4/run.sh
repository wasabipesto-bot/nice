#!/bin/sh
# usage: run.sh <name> <cmd> [args]; records its PID, logs, exit status
D="$HOME/claude-exp-2026-11-01-webfd"
. "$D/scripts/env.sh"
echo $$ >> "$D/pids"
name=$1; shift
echo "START $(date -u +%FT%TZ) $(date +%s) pid $$" > "$D/logs/$name.status"
"$@" > "$D/logs/$name.log" 2>&1 < /dev/null
echo "EXIT $? $(date -u +%FT%TZ) $(date +%s)" >> "$D/logs/$name.status"
sed -i '' "/^$$\$/d" "$D/pids"
