#!/bin/bash
# regs48.sh BIN TAG LEVELS...: top_fd_kernel per NICE_EXP_TOPFD level on the b62 and b60 1e14 fields: (1) CubeCL's CUDA
# source (CUBECL_DEBUG_LOG) compiled offline (nvcc -cubin -arch=sm_86 -O3 -Xptxas -v: registers, spills, static SASS);
# (2) the runtime's own path: NVRTC's PTX from CubeCL's PTX cache, JIT-loaded by the driver (ptxjit.py: registers, spill
# bytes, static SASS of the driver's cubin). Also logs the 1e14 counts per level.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
export PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; shift 2; L=/root/l48/sass/$TAG; mkdir -p $L
for A in "$@"; do
  RUND=/root/l48/run/regs_${TAG}_l$A; PTXD=/root/l48/ptx/regs_${TAG}_l$A
  rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
  printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
  cd $RUND
  rm -f $L/cubecl_l$A.log
  NICE_EXP_TOPFD=$A CUBECL_DEBUG_LOG=$L/cubecl_l$A.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62,60 \
    /root/l48/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run_l$A.log 2>&1
  echo "l$A: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/run_l$A.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
  python3 - $L/cubecl_l$A.log $L l$A <<'PY'
import sys,re
log,out,tag=sys.argv[1:4]
txt=open(log,errors='replace').read()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1) not in ('top_kernel','top_fd_kernel'): continue
    base=re.search(r'base: (\d+)', blk).group(1)
    if '```cpp' not in blk: continue
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    open(f'{out}/{m.group(1)}_{tag}_b{base}.cu','w').write(src)
PY
  gzip -f $L/cubecl_l$A.log
  python3 /root/l48/ptxjit.py --only top_fd --sass $L/jit $PTXD > $L/jit_l$A.txt 2>&1
  sed "s/^/l$A /" $L/jit_l$A.txt
done
cd $L
for f in top_fd_kernel_l*_b*.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -o "Used [0-9]* registers\|[0-9]* bytes spill stores" | tr '\n' ' ')
  cuobjdump -sass /tmp/k_$TAG.cubin > ${f%.cu}.sass
  n=$(grep -cE "^\s+/\*[0-9a-f]{4,}\*/" ${f%.cu}.sass)
  echo "$f nvcc: $r sass=$n"
done | tee registers.txt
echo REGS_DONE $TAG $(date -u +%T)
