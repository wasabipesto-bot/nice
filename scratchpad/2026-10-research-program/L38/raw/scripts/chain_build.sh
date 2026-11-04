#!/bin/bash
# chain_build.sh: setup, the three test binaries (M, S, V) one at a time in the shared target dir, then each one's
# registers and 1e14 counts (regs.sh) as soon as it is built.
L=/root/l38/logs
/root/l38/setup.sh > $L/setup.out 2>&1
for t in M S V; do
  /root/l38/build.sh $t $t || exit 1
  /root/l38/regs.sh $t $t $t > $L/regs_$t.out 2>&1 &
done
wait
echo CHAIN_BUILD_DONE $(date -u +%T) > $L/build.done
