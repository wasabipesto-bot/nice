#!/bin/bash
# final_ab2.sh: the rest of the timing after final_ab.sh's first CUDA round, without the tops fast path (c4) except
# one more stop-1 pair: CUDA round 1's missing fin stop 2, CUDA round 2, two Vulkan/SPIR-V rounds, base 64 wide once.
. "$HOME/research/scripts/env.sh"
until ! pgrep -x midout_wide_ben > /dev/null && grep -q stopped $R/runs/levers-final-ab/rc.txt; do sleep 5; done
rm -f $R/b65l/stop
S=$R/b65/scripts; RUN=levers-final-ab; O=$R/runs/$RUN
W65="--base 65 --fields 13731,77777 --group 16"; W64="--base 64 --fields 4095,77777 --group 16"
c() { n=$1; b=$2; rt=$3; st=$4; shift 4; E=""; [ "$st" != 6 ] && E="MIDOUT_STOP=$st"
  [ -e $R/b65l/stop ] && { echo stopped2 >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/midout_wide_bench $rt $E -- "$@"; }
c cu_fin_s2_1 fin-bench-cuda cuda 2 $W65
r=2
c cu_base_s1_$r l-base-cuda cuda 1 $W65; c cu_fin_s1_$r fin-bench-cuda cuda 1 $W65; c cu_c4_s1_$r c4-bench-cuda cuda 1 $W65
c cu_base_s2_$r l-base-cuda cuda 2 $W65; c cu_fin_s2_$r fin-bench-cuda cuda 2 $W65
c cu_base_f_$r l-base-cuda cuda 6 $W65; c cu_c2_f_$r c2-bench-cuda cuda 6 $W65; c cu_fin_f_$r fin-bench-cuda cuda 6 $W65
for r in 1 2; do
  c vk_base_s1_$r l-base-spv vk 1 $W65; c vk_fin_s1_$r fin-bench-spv vk 1 $W65
  c vk_base_s2_$r l-base-spv vk 2 $W65; c vk_fin_s2_$r fin-bench-spv vk 2 $W65
  c vk_base_f_$r l-base-spv vk 6 $W65; c vk_fin_f_$r fin-bench-spv vk 6 $W65
done
c cu64_base_f l-base-cuda cuda 6 $W64; c cu64_fin_f fin-bench-cuda cuda 6 $W64
echo done > $O/done
