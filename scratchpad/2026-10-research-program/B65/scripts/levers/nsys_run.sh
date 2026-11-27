#!/bin/bash
# nsys_run.sh NAME BINTAG STOP [ARGS...]: one CUDA bench process on the RTX 3060 under nsys (CUDA trace only),
# then the kernel summary and the per-kernel trace as CSV. Output: $R/runs/levers-nsys/NAME.*
. "$HOME/research/scripts/env.sh"
NAME=$1; B=$2; ST=$3; shift 3
O=$R/runs/levers-nsys; mkdir -p $O
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=1 MIDOUT_CUDA=1
E=""; [ "$ST" != 6 ] && E="MIDOUT_STOP=$ST"
echo "START $NAME $(date -u +%FT%T) exe=$B md5=$(md5sum $R/bin/$B | cut -c1-8) stop=$ST args=[$*]" > $O/$NAME.log
env $E nsys profile --trace=cuda --sample=none --cpuctxsw=none -o $O/$NAME -f true $R/bin/$B --cuda "$@" >> $O/$NAME.log 2>&1
echo "END rc=$? $(date -u +%FT%T)" >> $O/$NAME.log
nsys stats --report cuda_gpu_kern_sum --format csv -o $O/$NAME $O/$NAME.nsys-rep >> $O/$NAME.log 2>&1
nsys stats --report cuda_gpu_trace --format csv -o $O/$NAME $O/$NAME.nsys-rep >> $O/$NAME.log 2>&1
nsys stats --report cuda_api_sum --format csv -o $O/$NAME $O/$NAME.nsys-rep >> $O/$NAME.log 2>&1
echo "STATS done $(date -u +%FT%T)" >> $O/$NAME.log
