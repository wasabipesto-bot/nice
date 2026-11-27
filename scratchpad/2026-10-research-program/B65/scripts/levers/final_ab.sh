#!/bin/bash
# final_ab.sh: timing, same session, alternating per round: baseline 0b6e22e1 (l-base-*), step 1 (c2-bench-cuda:
# whole field, CUDA), steps 1+2 (fin-bench-*: 7d73c07) and steps 1+2 with the tops fast path (c4-bench-*), base 65
# (warm-up 13731, field 77777): stop 1 (tops), stop 2 (+ parents) and the whole field (6); two rounds through CUDA,
# then two through Vulkan/SPIR-V; then base 64 forced wide once (CUDA, baseline and c4). run_b65.sh samples the
# card (nvidia-smi 0.5 s) and the host (vmstat 1 s) beside every run.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; RUN=levers-final-ab; O=$R/runs/$RUN; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; W64="--base 64 --fields 4095,77777 --group 16"
c() { n=$1; b=$2; rt=$3; st=$4; shift 4; E=""; [ "$st" != 6 ] && E="MIDOUT_STOP=$st"
  [ -e $R/b65l/stop ] && { echo stopped >> $O/rc.txt; exit 0; }
  bash $S/run_b65.sh $RUN $n $b/midout_wide_bench $rt $E -- "$@"; }
for r in 1 2; do
  c cu_base_s1_$r l-base-cuda cuda 1 $W65; c cu_fin_s1_$r fin-bench-cuda cuda 1 $W65; c cu_c4_s1_$r c4-bench-cuda cuda 1 $W65
  c cu_base_s2_$r l-base-cuda cuda 2 $W65; c cu_c4_s2_$r c4-bench-cuda cuda 2 $W65
  c cu_base_f_$r l-base-cuda cuda 6 $W65; c cu_c2_f_$r c2-bench-cuda cuda 6 $W65
  c cu_fin_f_$r fin-bench-cuda cuda 6 $W65; c cu_c4_f_$r c4-bench-cuda cuda 6 $W65
done
for r in 1 2; do
  c vk_base_s1_$r l-base-spv vk 1 $W65; c vk_fin_s1_$r fin-bench-spv vk 1 $W65; c vk_c4_s1_$r c4-bench-spv vk 1 $W65
  c vk_base_s2_$r l-base-spv vk 2 $W65; c vk_c4_s2_$r c4-bench-spv vk 2 $W65
  c vk_base_f_$r l-base-spv vk 6 $W65; c vk_fin_f_$r fin-bench-spv vk 6 $W65; c vk_c4_f_$r c4-bench-spv vk 6 $W65
done
c cu64_base_f l-base-cuda cuda 6 $W64; c cu64_c4_f c4-bench-cuda cuda 6 $W64
echo done > $O/done
