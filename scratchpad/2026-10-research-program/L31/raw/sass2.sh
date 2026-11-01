#!/bin/bash
# TopKernel's CUDA source per variant -> nvcc sm_86 cubin -> registers/spills and SASS counts.
cd /root/logs/sass
for V in base diff bar both; do
  awk '/^name: .*TopKernel</{f=1} f&&/^```cpp/{g=1;next} g&&/^```/{exit} g{print}' $V.dump > top_$V.cu
  nice /usr/local/cuda/bin/nvcc -arch=sm_86 -cubin -O3 --resource-usage -o top_$V.cubin top_$V.cu > res_$V.txt 2>&1
  /usr/local/cuda/bin/cuobjdump -sass top_$V.cubin > top_$V.sass 2>&1
  echo "== $V: $(wc -l < top_$V.cu) lines of CUDA; $(grep -cE '^\s+/\*[0-9a-f]{4,6}\*/' top_$V.sass) SASS instructions"
  grep -E "registers|spill|stack" res_$V.txt | head -3
  for op in IMAD.HI IMAD.WIDE IMAD IADD3 LOP3 SHF SEL ISETP LDG LDL STL BRA; do printf "%s=%s " $op $(grep -cE "^\s+/\*[0-9a-f]{4,6}\*/\s+(@!?P[0-9] )?$op[ .]" top_$V.sass); done; echo
done
