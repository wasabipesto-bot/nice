#!/bin/bash
# after2.sh: 1e14 counts, main against pr (2 fields per base at the A/B starts, 2 rounds).
while ! grep -q AFTER_DONE /root/logs/after.log; do sleep 10; done
cd /root
for r in 1 2; do
  for t in main pr; do
    echo "== $(date -u +%T) e14 round=$r tree=$t"
    ./run.sh $t e14_${t}_r$r 1e14 2 58,60,62,64
  done
done
echo AFTER2_DONE $(date -u +%T)
