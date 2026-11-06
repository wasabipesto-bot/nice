#!/bin/bash
# regs.sh BIN TAG SRCD: CubeCL's CUDA source of every kernel compiled on the b62, b60 and b64 1e14 fields (join, top,
# top FD, check, ...), compiled offline (nvcc -cubin -arch=sm_86 -O3 -Xptxas -v): registers, spills, SASS instruction
# count. Also logs the three 1e14 counts (run.log).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
export PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; SRCD=$3; L=/root/l41/sass/$TAG; mkdir -p $L
cd /root/l41/src/$SRCD
rm -f $L/cubecl.log $L/*.cu $L/*.sass
CUBECL_DEBUG_LOG=$L/cubecl.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62,60,64 \
  /root/l41/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/run.log 2>&1
echo "$TAG: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/run.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
python3 - $L/cubecl.log $L <<'PY'
import sys,re,collections
log,out=sys.argv[1:3]
txt=open(log,errors='replace').read()
seen=collections.Counter()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m: continue
    kn=m.group(1)
    b=re.search(r'base: (\d+)', blk)
    base=b.group(1) if b else 'x'
    if '```cpp' not in blk: continue
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    key=f'{kn}_b{base}'
    seen[key]+=1
    open(f'{out}/{key}_{seen[key]}.cu','w').write(src)
PY
gzip -f $L/cubecl.log
cd $L
for f in *.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k_$TAG.cubin $f 2>&1 | grep -o "Used [0-9]* registers.*\|[0-9]* bytes spill.*" | tr '\n' ' ')
  cuobjdump -sass /tmp/k_$TAG.cubin > ${f%.cu}.sass
  n=$(grep -cE "^\s+/\*[0-9a-f]{4,}\*/" ${f%.cu}.sass)
  echo "$f $r sass=$n"
done | tee registers.txt
echo REGS_DONE $TAG
