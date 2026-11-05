#!/bin/bash
# chain_build.sh: setup, the three test binaries (B, E, F) one at a time in the shared target dir, each one's registers
# and 1e14 counts (regs.sh) as soon as it is built, then client_B (NiceMark's base).
L=/root/l39/logs
/root/l39/setup.sh > $L/setup.out 2>&1
for t in B E F; do
  /root/l39/build.sh $t $t || exit 1
  /root/l39/regs.sh $t $t $t > $L/regs_$t.out 2>&1 &
done
wait
echo CHAIN_BUILD_DONE $(date -u +%T) > $L/build.done
