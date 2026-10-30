#!/bin/bash
# 1e14 A/B again, main against the PR with the 64 cap (/root/bin/pr64): 20
# fields per base, both budgets, 3 rounds interleaved.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
for r in 1 2 3; do
  for bud in B10 B20; do
    for t in main pr64; do
      if [ $bud = B10 ]; then e=NICE_TEST_JOIN_MAX_BUFFER=2684354560; else e=NICE_TEST_JOIN_NOTHING=1; fi
      echo "== $(date -u +%T) e14b round=$r budget=$bud tree=$t"
      /root/run.sh /root/bin/$t f14_${bud}_${t}_r$r 1e14 20 $e
      /root/summ.sh /root/logs/f14_${bud}_${t}_r$r.log
    done
  done
done
echo AB14B_DONE $(date -u +%T)
