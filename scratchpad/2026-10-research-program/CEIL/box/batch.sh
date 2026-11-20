#!/bin/bash
# box: batch.sh — every slice of the study, one at a time (18 study threads + slice_join's own thread)
cd /w
for a in "64 712012851 greedy" "64 502136830 greedy" "64 4977728 greedy" "64 0" "64 1073741823" \
         "64 952265258" "64 830186330" "64 630629006" "64 457254635" "64 298641742" \
         "65 767142814" "65 364171716"; do
  set -- $a
  bash /w/box/runslice.sh $1 $2 18 $3
done
echo BATCHDONE > /w/raw/batch.done
