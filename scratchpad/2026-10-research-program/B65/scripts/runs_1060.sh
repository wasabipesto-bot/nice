#!/bin/bash
# runs_1060.sh CUDATAG: B65.10's check on the GTX 1060 3 GB (nvidia-smi index 0) through CUDA, the runtime on which a
# base-64 field fits that card (OWN.1): one field t 77777 at group 16 and one at group 256, card memory sampled.
# (Through Vulkan the bench's allocation fails at start on this card at any group size: runs/b65-group2/g1060_*.log.)
. "$HOME/research/scripts/env.sh"
T=${1:?CUDATAG}; O=$R/runs/b65-group2; mkdir -p $O
for g in 16 256; do n=g1060c_n64_g$g
  nvidia-smi -i 0 --query-gpu=timestamp,utilization.gpu,power.draw,memory.used --format=csv,noheader,nounits -lms 500 > $O/$n.gpu 2>&1 & MON=$!
  CUDA_VISIBLE_DEVICES=0 MIDOUT_CUDA=1 NICE_BUILD_SHA=test RUST_LOG=warn $R/bin/$T/midout_bench --cuda --threads 5 --fields 77777 --group $g --no-cpu-check > $O/$n.log 2>&1; rc=$?
  kill $MON 2>/dev/null; wait $MON 2>/dev/null
  echo "$(date -u +%T) $n rc=$rc $(grep -h 'fs per admissible' $O/$n.log | tail -1 | cut -c1-110) memmax $(cut -d, -f4 $O/$n.gpu | sort -n | tail -1) MiB" >> $O/rc.txt
done
echo done > $O/done1060
