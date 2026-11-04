#!/bin/bash
# regs.sh BIN TAG SRCD VAR VALUES...: CubeCL CUDA source of join_kernel (b62 and b60 1e14 fields) per value of env VAR,
# compiled offline (nvcc -cubin -arch=sm_86 -O3 -Xptxas -v): registers, spills and static SASS instruction count.
# Also checks the b62/b60 1e14 counts (logged in run_*.log).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
export PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; SRCD=$3; VAR=$4; shift 4; L=/root/l37/sass/$TAG; mkdir -p $L
cd /root/l37/src/$SRCD
for A in "$@"; do
  rm -f $L/cubecl_$A.log
  env $VAR=$A CUBECL_DEBUG_LOG=$L/cubecl_$A.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62,60 \
    /root/l37/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run_$A.log 2>&1
  echo "$VAR=$A: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/run_$A.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
  python3 - $L/cubecl_$A.log $L $A <<'PY'
import sys,re
log,out,tag=sys.argv[1:4]
txt=open(log,errors='replace').read()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1)!='join_kernel': continue
    base=re.search(r'base: (\d+)', blk).group(1)
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    open(f'{out}/join_kernel_{tag}_b{base}.cu','w').write(src)
PY
  gzip -f $L/cubecl_$A.log
done
cd $L
for f in join_kernel_*_b*.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -o "Used [0-9]* registers.*\|[0-9]* bytes spill.*" | tr '\n' ' ')
  cuobjdump -sass /tmp/k_$TAG.cubin > ${f%.cu}.sass
  n=$(grep -cE "^\s+/\*[0-9a-f]{4,}\*/" ${f%.cu}.sass)
  echo "$f $r sass=$n"
done | tee registers.txt
echo REGS_DONE
