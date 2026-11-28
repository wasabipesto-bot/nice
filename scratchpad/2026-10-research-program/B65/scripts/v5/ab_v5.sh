#!/bin/bash
# ab_v5.sh: B65.9 timing. V5 (v5-bench-*: a4fb3543, digit-major slices and four chunks per lane in both main kernels)
# against its base (fx-fin-bench-*: f503a13c), RTX 3060, alternating, two rounds (round 2 in the other order):
# base 64 narrow and base 65 wide through Vulkan/SPIR-V, then through CUDA. Same arguments as fixes/ab_fx.sh.
# The benches print each field's survivor and check counts: V5's must equal the base's.
. "$HOME/research/scripts/env.sh"
S=$R/v5/scripts; RUN=v5-ab; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
c() { n=$1; b=$2; rt=$3; ex=$4; shift 4
  [ -e $R/v5/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/$ex $rt -- "$@"; }
for rt in vk cuda; do
  sfx=cuda; [ $rt = vk ] && sfx=spv
  for r in 1 2; do
    if [ $r = 1 ]; then A=fx-fin; B=v5; else A=v5; B=fx-fin; fi
    c ${rt}64n_${A}_$r $A-bench-$sfx $rt midout_bench $N64; c ${rt}64n_${B}_$r $B-bench-$sfx $rt midout_bench $N64
    c ${rt}65_${A}_$r $A-bench-$sfx $rt midout_wide_bench $W65; c ${rt}65_${B}_$r $B-bench-$sfx $rt midout_wide_bench $W65
  done
done
echo done > $O/done
