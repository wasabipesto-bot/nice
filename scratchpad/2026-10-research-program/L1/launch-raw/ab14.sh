#!/bin/bash
# 1e14 A/B: 20 fields per base, main (control) and pr interleaved, under the
# 10 GB card's budget (B10) and this card's own (B20), 3 rounds.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
B10=NICE_TEST_JOIN_MAX_BUFFER=2684354560
for r in 1 2 3; do
  for bud in B10 B20; do
    for t in main pr; do
      if [ $bud = B10 ]; then e=$B10; else e=NICE_TEST_JOIN_NOTHING=1; fi
      echo "== $(date -u +%T) e14 round=$r budget=$bud tree=$t"
      /root/run.sh /root/bin/$t e14_${bud}_${t}_r$r 1e14 20 $e
      /root/summ.sh /root/logs/e14_${bud}_${t}_r$r.log
    done
  done
done
echo AB14_DONE $(date -u +%T)
