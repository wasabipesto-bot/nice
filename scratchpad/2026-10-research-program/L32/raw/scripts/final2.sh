#!/bin/bash
# After final.sh and the pad2 build: registers of tail mode 2, then b62 1e17 base / tail 1 / tail 2 (pad2) x2 rounds, b60 1e16 one round, then fmt+clippy on padsrc2.
L=/root/pad
until [ -e $L/final.done ] && [ -e $L/pad2.done ]; do sleep 15; done
echo "FINAL2 start $(date -u +%T)"
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
cd /root/padsrc2
for t in 1 2; do
  rm -f $L/cuda2_t$t.log
  env NICE_EXP_JOIN_TAIL=$t CUBECL_DEBUG_LOG=$L/cuda2_t$t.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62 \
    $L/pad2 --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/cuda2dump_t$t.out 2>&1
  python3 - $L/cuda2_t$t.log $L/join2_t$t.cu <<'PY'
import sys
lines = open(sys.argv[1], errors='replace').read().split('\n')
for i, l in enumerate(lines):
    if l.startswith('name: ') and 'JoinKernel' in l:
        j = i
        while lines[j].strip() != '```cpp': j += 1
        k = j + 1
        while lines[k].strip() != '```': k += 1
        open(sys.argv[2], 'w').write('\n'.join(lines[j+1:k]) + '\n'); break
PY
  /usr/local/cuda/bin/nvcc -arch=sm_86 -cubin -O3 --resource-usage -o $L/join2_t$t.cubin $L/join2_t$t.cu > $L/regs2_t$t.txt 2>&1
  grep "Used" $L/regs2_t$t.txt
done
R=/root/run.sh
$R ab2_base_e17_b62_r1 base 62 1 1e17 0
$R ab2_t1_e17_b62_r1 pad2 62 1 1e17 0 NICE_EXP_JOIN_TAIL=1
$R ab2_t2_e17_b62_r1 pad2 62 1 1e17 0 NICE_EXP_JOIN_TAIL=2
$R ab2_t2_e17_b62_r2 pad2 62 1 1e17 0 NICE_EXP_JOIN_TAIL=2
$R ab2_t1_e17_b62_r2 pad2 62 1 1e17 0 NICE_EXP_JOIN_TAIL=1
$R ab2_base_e17_b62_r2 base 62 1 1e17 0
$R ab2_t2_e16_b60_r1 pad2 60 2 1e16 0 NICE_EXP_JOIN_TAIL=2
echo "FINAL2 AB DONE $(date -u +%T)"
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt-clippy
( cargo fmt --all --check && echo FMT_OK ) > $L/lint2_fmt.log 2>&1; tail -1 $L/lint2_fmt.log
( cargo clippy -j 9 -p "*" --all-targets --features nice_client/gpu -- -D warnings && echo CLIPPY_GPU_OK ) > $L/lint2_clippy_gpu.log 2>&1; tail -1 $L/lint2_clippy_gpu.log
( cargo clippy -j 9 -p "*" --all-targets -- -D warnings && echo CLIPPY_DEFAULT_OK ) > $L/lint2_clippy_default.log 2>&1; tail -1 $L/lint2_clippy_default.log
echo "FINAL2 DONE $(date -u +%T)" > $L/final2.done
