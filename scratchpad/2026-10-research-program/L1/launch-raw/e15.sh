#!/bin/bash
# 1e15 fields (NiceMark's b58 scenarios are 1e15 at the A/B start), main and
# pr interleaved, 2 fields per base, both budgets, 3 rounds. Replaces the
# third 1e16 round under the card's own budget (ab16r3.sh).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
until grep -q RACE3_DONE /root/logs/race3.out 2>/dev/null; do sleep 15; done
for r in 1 2 3; do
  for bud in B10 B20; do
    for t in main pr; do
      if [ $bud = B10 ]; then e=NICE_TEST_JOIN_MAX_BUFFER=2684354560; else e=NICE_TEST_JOIN_NOTHING=1; fi
      echo "== $(date -u +%T) e15 round=$r budget=$bud tree=$t"
      /root/run.sh /root/bin/$t e15_${bud}_${t}_r$r 1e15 2 $e
      /root/summ.sh /root/logs/e15_${bud}_${t}_r$r.log
    done
  done
done
echo "AB16R3_DONE (replaced by e15.sh) $(date -u +%T)" >> /root/logs/ab16r3.out
echo E15_DONE $(date -u +%T)
