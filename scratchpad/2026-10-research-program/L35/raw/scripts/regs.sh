#!/bin/bash
# regs.sh BIN TAG: CubeCL CUDA source of top_kernel / top_fd_kernel (b62 1e14 field, FD off and on), ptxas -v.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
export PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; L=/root/l35/sass/$TAG; mkdir -p $L
cd /root/l35/src/${SRCD:-B}
for FD in 0 1 2; do
  rm -f $L/cubecl_fd$FD.log
  NICE_EXP_TOP_FD=$FD CUBECL_DEBUG_LOG=$L/cubecl_fd$FD.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=${BASES:-62} \
    /root/l35/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run_fd$FD.log 2>&1
  python3 - $L/cubecl_fd$FD.log $L fd$FD <<'PY'
import sys,re
log,out,tag=sys.argv[1:4]
txt=open(log,errors='replace').read()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1) not in ('top_kernel','top_fd_kernel'): continue
    base=re.search(r'base: (\d+)', blk).group(1)
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    open(f'{out}/{m.group(1)}_{tag}_b{base}.cu','w').write(src)
    print('wrote', m.group(1), tag, base)
PY
done
cd $L
for f in top_*_b*.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -o "Used [0-9]* registers.*")
  n=$(cuobjdump -sass /tmp/k_$TAG.cubin | grep -cE "^\s+/\*[0-9a-f]{4,}\*/")
  echo "$f $r sass=$n"
done | tee registers.txt
echo REGS_DONE
