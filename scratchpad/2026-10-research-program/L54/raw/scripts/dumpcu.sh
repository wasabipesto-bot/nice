#!/bin/bash
# dumpcu.sh BIN TAG: CubeCL's CUDA source of every kernel of a 1e14 run at b62 and b60 (CUBECL_DEBUG_LOG), the PTX cache
# of that process, and the driver-JIT SASS of its join kernels (ptxjit.py) -> /root/l54/cu/TAG. Also nvcc-offline SASS.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test PATH=/usr/local/cuda/bin:$PATH
BIN=$1; TAG=$2; D=/root/l54/cu/$TAG; rm -rf $D; mkdir -p $D/run $D/ptx
printf '[compilation]\ncache = { file = "%s" }\n' $D/ptx > $D/run/cubecl.toml
cd $D/run
CUBECL_DEBUG_LOG=$D/cubecl.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=${BASES:-62,60} \
  NICE_TEST_JOIN_STARTS=60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
  /root/l54/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $D/run.log 2>&1
echo "$TAG: $(grep -o 'base=[0-9]* fields.*found=[0-9]*' $D/run.log | sed 's/rate.*survivors/survivors/' | tr '\n' ' ')"
python3 - $D/cubecl.log $D <<'PY'
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
gzip -f $D/cubecl.log
python3 /root/l54/ptxjit.py --only join_kernel --sass $D/jit $D/ptx > $D/jit.txt 2>&1
cat $D/jit.txt | sed 's/key=.*//'
