#!/bin/bash
# ident.sh: are the production kernels other than the top kernels identical between main (M) and the fix (F)?
# CUDA: CubeCL's full compilation log of a production run (the dense compare on one partition of b60 1e16, which runs
# launch_batch in hits mode) -> every kernel's CUDA source; WGSL: CI's wgsl_dump_for_lint on lavapipe -> every shader.
# Then kdiff.py per kernel (modulo CubeCL's variable numbering and declaration order). Logs in $W/ident/.
W=/root/t26; export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
mkdir -p $W/ident
for B in ${BINS:-M F}; do
  d=$W/ident/$B; rm -rf $d; mkdir -p $d; cd $d
  printf '[compilation.logger]\nlevel = "full"\nfile = "%s/cuda.log"\n' $d > cubecl.toml
  NICE_TEST_JOIN_DENSE=1 NICE_TEST_JOIN_DENSE_FIELD=60:1447429612114824200908:10000000000000000 \
    $W/bin/$B --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture > run_cuda.out 2>&1
  rm cubecl.toml
  VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) CUBECL_DEBUG_LOG=$d/wgsl.log $W/bin/$B --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > run_wgsl.out 2>&1
  echo "$B md5 $(md5sum $W/bin/$B | cut -c1-8): cuda $(grep -c '__global__' $d/cuda.log) kernels, $(grep -c 'test result: ok' run_cuda.out) ok; wgsl $(wc -c < $d/wgsl.log) bytes, $(grep -c 'test result: ok' run_wgsl.out) ok"
done
python3 $W/scripts/kdiff.py $W/ident/M/cuda.log $W/ident/F/cuda.log
python3 - <<'PY'
import re
W='/root/t26/ident'
def wgsl(p):
    t=open(p).read()
    return re.findall(r'@compute.*?\n}\n', t, re.S)
wo, wn = wgsl(f'{W}/M/wgsl.log'), wgsl(f'{W}/F/wgsl.log')
print('wgsl shaders', len(wo), len(wn), 'IDENTICAL' if sorted(wo)==sorted(wn) else f'DIFFER ({len(set(wo)-set(wn))} only in M, {len(set(wn)-set(wo))} only in F)')
for s in sorted(set(wo)^set(wn)):
    m = re.search(r'fn (\w+)\(', s); print('  differs:', 'M' if s in wo else 'F', m.group(1) if m else '?', len(s), 'bytes', 'top_fd' if 'top' in s[:4000] else '')
PY
