#!/bin/bash
# box: q6batch.sh — after the wide pass: base 65, two slices, the q6 variant list (all jobs), raw /w/raw/s_65_<pip>.txt
until [ -f /w/raw/wide.done ]; do sleep 20; done
cd /w
for P in 767142814 364171716; do
  bash /w/box/runslice.sh 65 $P 18 q6
done
echo Q6DONE > /w/raw/q6.done
