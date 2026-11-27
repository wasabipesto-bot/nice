#!/bin/bash
# split_1060.sh: on the GTX 1060 3GB (CUDA index 0) after post_b.sh: base 65 field 77777 after the warm-up 13731,
# stop 1 and stop 2, baseline vs head, and the head's stop 2 without sharing; peak card memory per run.
. "$HOME/research/scripts/env.sh"
until [ -f $R/runs/levers-1060/post_b.done ]; do sleep 10; done
O=$R/runs/levers-1060; export NICE_BUILD_SHA=test RUST_LOG=warn
r() { n=$1; b=$2; st=$3; shift 3
  nvidia-smi -i 0 --query-gpu=timestamp,utilization.gpu,power.draw,memory.used,memory.total --format=csv,noheader,nounits -lms 500 > $O/$n.gpu 2>&1 & M=$!
  CUDA_VISIBLE_DEVICES=0 MIDOUT_STOP=$st $R/bin/$b/midout_wide_bench --cuda --base 65 --fields 13731,77777 --group 16 "$@" > $O/$n.log 2>&1; echo "rc=$?" >> $O/$n.log
  kill $M; wait $M 2>/dev/null
  echo "$n $(grep -h 't 77777' $O/$n.log | cut -c1-90) peak $(cut -d, -f4 $O/$n.gpu | sort -n | tail -1) MiB" >> $O/rc.txt; }
r g0_base_s1 l-base-cuda 1; r g0_fin_s1 fin-bench-cuda 1
r g0_base_s2 l-base-cuda 2; r g0_fin_s2 fin-bench-cuda 2; r g0_fin_s2_noshare fin-bench-cuda 2 --no-share-parents
echo done > $O/split.done
