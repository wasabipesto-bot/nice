#!/bin/bash
# ab_s2.sh NEW [RUN]: step 2's timing: hk1-bench-* (step 1's head) against NEW-bench-*, same session, alternating,
# three rounds (the order reversed each round): base 65 wide (warm-up field 13731, field 77777) through CUDA and
# through Vulkan/SPIR-V, then base 64 narrow once each (step 2 does not touch it: a control); then the CUDA
# timing stops 3 and 5 of each. No sampled check.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; NEW=$1; RUN=${2:-hooks-s2}; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
c() { n=$1; b=$2; rt=$3; ex=$4; shift 4
  [ -e $R/b65h/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/$ex $rt -- "$@"; }
for rt in cuda vk; do
  [ $rt = cuda ] && sfx=cuda || sfx=spv
  for r in 1 2 3; do
    if [ $((r % 2)) = 1 ]; then L="hk1 $NEW"; else L="$NEW hk1"; fi
    for t in $L; do c ${rt}65_${t}_$r $t-bench-$sfx $rt midout_wide_bench $W65; done
  done
  for t in hk1 $NEW; do c ${rt}64n_${t}_1 $t-bench-$sfx $rt midout_bench $N64; done
done
# where it sits (CUDA, cumulative timing stops: 3 = up to the main kernel, 5 = + the expansion)
for st in 3 5; do for t in hk1 $NEW; do
  [ -e $R/b65h/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN cuda65s${st}_$t $t-bench-cuda/midout_wide_bench cuda MIDOUT_STOP=$st -- $W65
done; done
# step 1's base-64 narrow check, again: fx-base (73bc0065) against hk1, alternating, 2 rounds per runtime
for rt in cuda vk; do
  [ $rt = cuda ] && sfx=cuda || sfx=spv
  for r in 3 4; do
    if [ $r = 3 ]; then L="hk1 fx-base"; else L="fx-base hk1"; fi
    for t in $L; do c ${rt}64n_${t}_$r $t-bench-$sfx $rt midout_bench $N64; done
  done
done
echo done > $O/done
