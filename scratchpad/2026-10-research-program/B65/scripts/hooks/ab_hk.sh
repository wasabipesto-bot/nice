#!/bin/bash
# ab_hk.sh NEW [RUN]: timing of three builds in one session on the RTX 3060, alternating, two rounds (round 2 in the
# reverse order): fx-base-bench-* (73bc0065, before the per-lane counts and the hooks), fx-fin-bench-* (f503a13c,
# with the hooks) and NEW-bench-* (the hooks compiled out). Base 65 wide (warm-up field 13731, field 77777) and
# base 64 narrow (4095, 77777), CUDA then Vulkan/SPIR-V. No sampled CPU check. run_b65.sh samples card and host.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; NEW=$1; RUN=${2:-hooks-ab}; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
c() { n=$1; b=$2; rt=$3; ex=$4; shift 4
  [ -e $R/b65h/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/$ex $rt -- "$@"; }
for rt in cuda vk; do
  [ $rt = cuda ] && sfx=cuda || sfx=spv
  for r in 1 2; do
    if [ $r = 1 ]; then L="fx-base fx-fin $NEW"; else L="$NEW fx-fin fx-base"; fi
    for t in $L; do c ${rt}65_${t}_$r $t-bench-$sfx $rt midout_wide_bench $W65; done
    for t in $L; do c ${rt}64n_${t}_$r $t-bench-$sfx $rt midout_bench $N64; done
  done
done
echo done > $O/done
