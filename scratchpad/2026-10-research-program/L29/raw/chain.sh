#!/bin/bash
while ! grep -q WHOLE_DONE /root/logs/whole.log; do sleep 5; done
while ! grep -q "built pprof" /root/logs/buildt_pprof.log; do sleep 5; done
echo "== $(date -u +%T) start ab"
/root/ab.sh
