#!/bin/sh
# bg.sh NAME CMD...: CMD detached in its own session; its process-group id in $W/NAME.pgid; output in $W/out_b/NAME.bgout
W=/home/justin/claude-exp-2026-11-18-g2
N=$1; shift
mkdir -p $W/out_b
setsid nohup "$@" > $W/out_b/$N.bgout 2>&1 < /dev/null &
echo $! > $W/$N.pgid
