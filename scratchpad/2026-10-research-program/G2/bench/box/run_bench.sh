#!/bin/bash
# on box: build and run the G2 kernel on the super-unit; nvidia-smi samples alongside
# usage: run_bench.sh TAG [reps]
set -u
TAG=$1; REPS=${2:-5}; cd /root/g2
[ -x g2bench ] || nvcc -O3 -arch=sm_86 -std=c++17 -lineinfo -Xptxas -v -o g2bench g2bench.cu > build_bench.log 2>&1 || { cat build_bench.log; exit 1; }
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -lms 500 > smi_bench_${TAG}.csv &
MP=$!
echo "$(date -u +%FT%TZ) bench start $TAG" >> runs.log
./g2bench /root/g2/su64_712012851 $REPS > bench_${TAG}.log 2>&1; RC=$?
kill $MP; echo "$(date -u +%FT%TZ) bench end $TAG rc=$RC" >> runs.log
cat bench_${TAG}.log
