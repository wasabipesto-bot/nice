#!/bin/sh
# cw_micro.sh TAG ARGS...: window 3, task 2 (adapted from CW/box/micro.sh): the phase-3b microbenchmark through
# SPIR-V (mo_width_bench of exp/mo-word-width b3967fb5 = $BIN/cw_bench, no --cuda) on the dumped slices, every
# variant interleaved, the card sampled every 0.1 s (smp.sh in place of nvidia-smi)
. "$(dirname "$(readlink -f "$0")")/env.sh"
TAG=$1; shift
SMP_DT=0.1 sh "$SCRIPTS/smp.sh" "$OUT/cw_$TAG.gpu" & MON=$!
echo "CMD $BIN/cw_bench --dump $W/dump $* (md5 $(md5sum $BIN/cw_bench | cut -c1-8))" > $OUT/cw_$TAG.txt
date -u >> $OUT/cw_$TAG.txt
$BIN/cw_bench --dump $W/dump "$@" >> $OUT/cw_$TAG.txt 2>&1; echo "rc=$?" >> $OUT/cw_$TAG.txt; date -u >> $OUT/cw_$TAG.txt
kill $MON 2>/dev/null
echo "$(date -u +%T) cw_$TAG $(grep -c '^EXACT.*mismatches 0 ' $OUT/cw_$TAG.txt) exact lines, $(grep -c '^EXACT' $OUT/cw_$TAG.txt) in all; $(tail -2 $OUT/cw_$TAG.txt | head -1)"
