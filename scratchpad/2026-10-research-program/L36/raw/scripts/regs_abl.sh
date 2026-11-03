#!/bin/bash
# regs_abl.sh BIN TAG CONFIGS...: CubeCL CUDA source of top_fd_kernel (b62 and b60 1e14 fields) per NICE_EXP_TOP_FD_ABL
# config, compiled offline (nvcc -cubin -arch=sm_86 -O3 -Xptxas -v): registers and static SASS instruction count.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
export PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; shift 2; L=/root/l36/sass/$TAG; mkdir -p $L
cd /root/l36/src/${SRCD:-X}
for A in "$@"; do
  rm -f $L/cubecl_a$A.log
  NICE_EXP_TOP_FD_ABL=$A CUBECL_DEBUG_LOG=$L/cubecl_a$A.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62,60 \
    /root/l36/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run_a$A.log 2>&1
  python3 - $L/cubecl_a$A.log $L a$A <<'PY'
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
PY
  gzip -f $L/cubecl_a$A.log
done
cd $L
for f in top_fd_kernel_a*_b*.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -o "Used [0-9]* registers.*")
  cuobjdump -sass /tmp/k_$TAG.cubin > ${f%.cu}.sass
  n=$(grep -cE "^\s+/\*[0-9a-f]{4,}\*/" ${f%.cu}.sass)
  echo "$f $r sass=$n"
done | tee registers.txt
echo REGS_DONE
