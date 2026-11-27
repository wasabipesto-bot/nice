#!/bin/bash
# ab_fx.sh: timing before (fx-base-bench-*: the merge head 73bc0065) and after (fx-fin-bench-*: the final head) the
# independent counts, same session, alternating (round 2 in the other order), RTX 3060: base 65 wide (warm-up
# field 13731, field 77777), base 64 wide (4095, 77777) and base 64 narrow (4095, 77777) through CUDA, two rounds;
# then base 65 wide through Vulkan/SPIR-V, two rounds. No sampled CPU check (the card's time only). run_b65.sh
# samples the card (nvidia-smi 0.5 s) and the host (vmstat 1 s) beside every run.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; RUN=fixes-ab; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; W64="--base 64 --fields 4095,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
c() { n=$1; b=$2; rt=$3; ex=$4; shift 4
  [ -e $R/b65b/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/$ex $rt -- "$@"; }
for r in 1 2; do
  if [ $r = 1 ]; then A=base; B=fin; else A=fin; B=base; fi
  c cu65_${A}_$r fx-$A-bench-cuda cuda midout_wide_bench $W65; c cu65_${B}_$r fx-$B-bench-cuda cuda midout_wide_bench $W65
  c cu64w_${A}_$r fx-$A-bench-cuda cuda midout_wide_bench $W64; c cu64w_${B}_$r fx-$B-bench-cuda cuda midout_wide_bench $W64
  c cu64n_${A}_$r fx-$A-bench-cuda cuda midout_bench $N64; c cu64n_${B}_$r fx-$B-bench-cuda cuda midout_bench $N64
done
for r in 1 2; do
  if [ $r = 1 ]; then A=base; B=fin; else A=fin; B=base; fi
  c vk65_${A}_$r fx-$A-bench-spv vk midout_wide_bench $W65; c vk65_${B}_$r fx-$B-bench-spv vk midout_wide_bench $W65
done
echo done > $O/done
