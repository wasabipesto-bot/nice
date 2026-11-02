#!/bin/bash
# regs.sh BIN TAG [env...]: dump CubeCL's CUDA source of join_kernel (b62, one 1e14 field) and count registers
# with ptxas (-arch=sm_86 -O3 -Xptxas -v), as L30's regs.sh. Output in /root/l34/logs/sass/.
BIN=$1; TAG=$2; shift 2
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} PATH=/usr/local/cuda/bin:$PATH NICE_BUILD_SHA=test
L=/root/l34/logs/sass; mkdir -p $L
cd /root/l34/src/A
rm -f $L/cubecl_$TAG.log
env "$@" CUBECL_DEBUG_LOG=$L/cubecl_$TAG.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62 \
  /root/l34/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run_$TAG.log 2>&1
python3 - $L/cubecl_$TAG.log $L $TAG <<'PY'
import sys,re
log,out,tag=sys.argv[1:4]
txt=open(log,errors='replace').read()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1) != 'join_kernel': continue
    base=re.search(r'base: (\d+)', blk).group(1)
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    open(f'{out}/join_kernel_{tag}_b{base}.cu','w').write(src)
    print('wrote', tag, base)
PY
cd $L
for f in join_kernel_${TAG}_b62.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -oE "Used [0-9]+ registers.*|[0-9]+ bytes spill.*" | tr '\n' ' ')
  n=$(cuobjdump -sass /tmp/k_$TAG.cubin | grep -cE "^\s+/\*[0-9a-f]{4}\*/")
  echo "$f $r sass=$n"
done | tee -a registers.txt
gzip -f $L/cubecl_$TAG.log
