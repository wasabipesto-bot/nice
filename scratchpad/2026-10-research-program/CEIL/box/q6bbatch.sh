#!/bin/bash
# box: q6bbatch.sh — after q6batch.sh: base 65 again, the q6b list (hybrids j = 4-6, L order at 32 and 128), raw /w/raw/q6b_65_<pip>.txt
until [ -f /w/raw/q6.done ]; do sleep 20; done
for P in 767142814 364171716; do
  O=/w/raw/q6b_65_$P.txt
  echo "CMD /w/tceil/release/examples/mo_ceiling 65 $P 18 q6b" > $O
  date -u >> $O
  /w/tceil/release/examples/mo_ceiling 65 $P 18 q6b >> $O 2> /w/raw/q6b_65_$P.err
  echo "rc=$?" >> $O; date -u >> $O
done
echo Q6BDONE > /w/raw/q6b.done
