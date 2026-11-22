#!/bin/bash
# box: build the dump, then counts + bench files for the three slices, one at a time (15 GB box)
cd /root; bash build_dump.sh > build_dump.log 2>&1
for p in 712012851 4977728 4977729; do
  bash count.sh $p freq,c32,q4 freq,c32,q2 freq,c32,17 freq,c16x2,q4 freq,c16x2,17
done
touch /root/raw/counts_all.done
