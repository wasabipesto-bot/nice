#!/bin/bash
# ident.sh: are the production kernels byte-identical between O (8d11e0be) and N (this head)?
# CUDA: CubeCL's full compilation log of a production run (the dense compare on one partition of b60 1e16, which runs
# launch_batch in the hits mode) -> every kernel's CUDA source; WGSL: CI's wgsl_dump_for_lint on lavapipe -> every
# shader. Then diff per binary. Logs in $W/ident/.
W=/root/ckf3; export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
mkdir -p $W/ident
for B in O N; do
  d=$W/ident/$B; rm -rf $d; mkdir -p $d; cd $d
  printf '[compilation.logger]\nlevel = "full"\nfile = "%s/cuda.log"\n' $d > cubecl.toml
  NICE_TEST_JOIN_DENSE=1 NICE_TEST_JOIN_DENSE_FIELD=60:1447429612114824200908:10000000000000000 \
    $W/bin/$B --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture > run_cuda.out 2>&1
  rm cubecl.toml
  CUBECL_DEBUG_LOG=$d/wgsl.log $W/bin/$B --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > run_wgsl.out 2>&1
  echo "$B: cuda $(grep -c '__global__' $d/cuda.log) kernels, $(grep -c 'test result: ok' run_cuda.out) ok; wgsl $(wc -c < $d/wgsl.log) bytes, $(grep -c 'test result: ok' run_wgsl.out) ok"
done
python3 - <<'PY'
import re
W='/root/ckf3/ident'
def cuda(p):
    t=open(p).read(); ks={}
    for m in re.finditer(r'extern "C" __global__ void (?:__launch_bounds__\(\d+\))?(\w+) \(.*?\n}\n', t, re.S):
        ks.setdefault(m.group(1), set()).add(m.group(0))
    return ks
def wgsl(p):
    t=open(p).read()
    return set(re.findall(r'@compute.*?\n}\n', t, re.S)), t
co, cn = cuda(f'{W}/O/cuda.log'), cuda(f'{W}/N/cuda.log')
for k in sorted(set(co)|set(cn)):
    print('cuda', k, len(co.get(k,())), len(cn.get(k,())), 'IDENTICAL' if co.get(k)==cn.get(k) else 'DIFFER')
wo, to = wgsl(f'{W}/O/wgsl.log'); wn, tn = wgsl(f'{W}/N/wgsl.log')
print('wgsl shaders', len(wo), len(wn), 'IDENTICAL' if wo==wn else f'DIFFER ({len(wo-wn)} only in O, {len(wn-wo)} only in N)')
PY
