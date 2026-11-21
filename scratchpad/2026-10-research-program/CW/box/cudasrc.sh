#!/bin/bash
# box: CubeCL's generated CUDA source (CUBECL_DEBUG_LOG) of the microbenchmark's kernels and of the real g2_kernel
# (one slice of field 77777 through the bench at stop 3), for the W 64 structure comparison
mkdir -p /root/raw/cudasrc; cd /root/raw/cudasrc
CUBECL_DEBUG_LOG=/root/raw/cudasrc/micro.log /root/tgt/release/examples/mo_width_bench --cuda --dump /root/dump --pips 4977728 --once --max-inst 64 > micro_run.txt 2>&1; echo "micro rc=$?"
CUBECL_DEBUG_LOG=/root/raw/cudasrc/g2.log MIDOUT_STOP=3 /root/tgt/release/examples/midout_bench --cuda --fields 77777 --slices 1 --no-cpu-check > g2_run.txt 2>&1; echo "g2 rc=$?"
ls -la /root/raw/cudasrc
