#!/bin/bash
# regs.sh: extract the JoinKernel CUDA source from the CUBECL_DEBUG_LOG dumps (off, tail) and report ptxas resource usage for sm_86.
L=/root/pad
for t in off tail; do
  python3 - $L/cuda_$t.log $L/join_$t.cu <<'PY'
import sys
src, out = sys.argv[1], sys.argv[2]
lines = open(src, errors='replace').read().split('\n')
i = 0; found = None
while i < len(lines):
    if lines[i].startswith('name: ') and 'JoinKernel' in lines[i]:
        j = i
        while not lines[j].strip() == '```cpp': j += 1
        k = j + 1
        while not lines[k].strip() == '```': k += 1
        found = lines[j+1:k]; break
    i += 1
open(out, 'w').write('\n'.join(found) + '\n')
print(out, len(found), 'lines')
PY
  /usr/local/cuda/bin/nvcc -arch=sm_86 -cubin -O3 --resource-usage -o $L/join_$t.cubin $L/join_$t.cu > $L/regs_$t.txt 2>&1
  cat $L/regs_$t.txt
done
