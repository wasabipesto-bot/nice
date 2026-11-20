#!/bin/bash
# box: widebatch.sh — after batch.sh: the wide-only pass (chunk widths 128/256, Q4 at those widths), raw to /w/raw/w_<base>_<pip>.txt
until [ -f /w/raw/batch.done ]; do sleep 20; done
for P in 712012851 502136830 4977728 0 1073741823 952265258; do
  O=/w/raw/w_64_$P.txt
  echo "CMD /w/tceil/release/examples/mo_ceiling 64 $P 18 wide  (exp/mo-ceiling source as of the wide pass; see git log)" > $O
  date -u >> $O
  /w/tceil/release/examples/mo_ceiling 64 $P 18 wide >> $O 2> /w/raw/w_64_$P.err
  echo "rc=$?" >> $O; date -u >> $O
done
echo WIDEDONE > /w/raw/wide.done
