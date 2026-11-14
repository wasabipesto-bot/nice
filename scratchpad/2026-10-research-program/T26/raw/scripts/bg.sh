#!/bin/bash
# bg.sh LOG CMD...: run CMD detached (setsid, under the box lock), output to $W/out/LOG
W=/root/t26; LOG=$1; shift
setsid nohup bash /root/t26/scripts/q.sh bash -c "$*" > $W/out/$LOG 2>&1 < /dev/null &
echo "queued $LOG"
