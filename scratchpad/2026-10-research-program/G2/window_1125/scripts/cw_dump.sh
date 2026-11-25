#!/bin/sh
# cw_dump.sh PIP...: window 3, task 2 (adapted from CW/box/dump.sh): the slices' phase-3b inputs from the CPU
# reference (mo_width_dump of exp/mo-word-width b3967fb5 = $BIN/cw_dump), raw log per slice in $OUT
. "$(dirname "$(readlink -f "$0")")/env.sh"
mkdir -p $W/dump
for p in "$@"; do
  echo "CMD $BIN/cw_dump $p $W/dump 10 (md5 $(md5sum $BIN/cw_dump | cut -c1-8))" > $OUT/cw_dump_$p.txt
  date -u >> $OUT/cw_dump_$p.txt
  $BIN/cw_dump $p $W/dump 10 >> $OUT/cw_dump_$p.txt 2>&1; echo "rc=$?" >> $OUT/cw_dump_$p.txt; date -u >> $OUT/cw_dump_$p.txt
done
echo "$(date -u +%T) cw_dump done: $(grep -h '^rc=' $OUT/cw_dump_*.txt | tr '\n' ' ')"
