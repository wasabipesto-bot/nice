#!/bin/bash
# The third 1e16 round under this card's own budget (chain5 ran two), after race3.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
until grep -q RACE3_DONE /root/logs/race3.out 2>/dev/null; do sleep 15; done
for t in main pr; do
  echo "== $(date -u +%T) e16 round=3 budget=B20 tree=$t"
  /root/run.sh /root/bin/$t e16_B20_${t}_r3 1e16 2 NICE_TEST_JOIN_NOTHING=1
  /root/summ.sh /root/logs/e16_B20_${t}_r3.log
done
echo AB16R3_DONE $(date -u +%T)
