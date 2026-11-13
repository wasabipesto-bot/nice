#!/bin/bash
# dumps2.sh: ACO counts with Xd4 (switches U, B, D): b62 and b64; then marks dumps2.done (gate_ab waits for it).
cd /root/n21
until grep -q "built Xd4\|FAILED" out/builds3.out; do sleep 5; done
for x in "62 0 9 128 137 169" "64 0 9 73 137 201"; do
  set -- $x; B=$1; shift
  for m in "$@"; do DB=Xd4 TMO=30 bash scripts/spvdump.sh d${B}_$m $m $B; done
done
touch out/dumps2.done; echo DUMPS2_DONE $(date -u +%T)
