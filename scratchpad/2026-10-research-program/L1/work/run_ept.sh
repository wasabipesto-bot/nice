#!/bin/bash
# EPT sweep at b62/b64, 1e16 fields, 1 field per base; unprofiled rounds 4,5,6,6,5,4 then profiled 5 and 6.
set -u
for e in 4 5 6 6 5 4; do
  NICE_EXP_JOIN_EPT=$e /root/run_join.sh ept${e}_r$(date +%H%M%S) 62,64 1 1e16 0
done
for e in 5 6; do
  NICE_EXP_JOIN_EPT=$e /root/run_join.sh ept${e}_prof 62,64 1 1e16 1
done
echo "# all done $(date -u +%FT%TZ)"
