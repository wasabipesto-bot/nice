#!/bin/bash
# Dump CubeCL CUDA source of the join and bucket kernels (b62, b60) for main and pr2; ptxas -v registers.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export PATH=/usr/local/cuda/bin:$PATH
L=/root/l30pr; mkdir -p $L/sass
cd /root/src-main
for B in main pr2; do
  rm -f $L/sass/cubecl_$B.log
  CUBECL_DEBUG_LOG=$L/sass/cubecl_$B.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62 \
    $L/$B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/sass/run_$B.log 2>&1
  python3 - $L/sass/cubecl_$B.log $L/sass $B <<'PY'
import sys,re
log,out,tag=sys.argv[1:4]
txt=open(log,errors='replace').read()
for blk in txt.split('[START_KERNEL_COMPILATION]')[1:]:
    blk=blk.split('[END_KERNEL_COMPILATION]')[0]
    m=re.search(r'name: nice_common::cubecl_join::kernels::(\w+)::', blk)
    if not m or m.group(1) not in ('join_kernel','bucket_kernel'): continue
    base=re.search(r'base: (\d+)', blk).group(1)
    src=blk.split('```cpp',1)[1].split('```',1)[0]
    open(f'{out}/{m.group(1)}_{tag}_b{base}.cu','w').write(src)
    print('wrote', m.group(1), tag, base)
PY
done
cd $L/sass
for f in *_b62.cu; do
  r=$(nvcc -cubin -arch=sm_86 -O3 -Xptxas -v -o /tmp/k.cubin $f 2>&1 | grep -o "Used [0-9]* registers.*")
  n=$(cuobjdump -sass /tmp/k.cubin | grep -cE "^\s+/\*[0-9a-f]{4}\*/")
  echo "$f $r sass=$n"
done | tee registers.txt
nvcc --version | tail -2 >> registers.txt
echo REGS_DONE
