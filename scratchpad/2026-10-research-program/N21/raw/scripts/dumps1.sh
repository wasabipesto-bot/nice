#!/bin/bash
# dumps1.sh: ACO counts of the N21 switch combinations at b62, b60, b64 (binary Xd).
cd /root/n21
for x in "62 9 11 13 15" "60 0 1 2 8 9 11 15" "64 0 1 2 8 9 11 15"; do
  set -- $x; B=$1; shift
  for m in "$@"; do TMO=30 bash scripts/spvdump.sh b${B}_$m $m $B; done
done
echo DUMPS1_DONE $(date -u +%T)
