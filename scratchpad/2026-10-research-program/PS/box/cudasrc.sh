#!/bin/bash
# box: CubeCL's generated CUDA source (CUBECL_DEBUG_LOG) of the ps kernels (one slice, few instances)
mkdir -p /root/raw/cudasrc; cd /root/raw/cudasrc
CUBECL_DEBUG_LOG=/root/raw/cudasrc/micro.log /root/tgt/release/examples/mo_width_bench --cuda --dump /root/dump --pips 712012851 --once --max-inst 64 \
  --variants w64,ps_q4,ps_q2,ps_q1 > micro_run.txt 2>&1; echo "micro rc=$?"
ls -la /root/raw/cudasrc
