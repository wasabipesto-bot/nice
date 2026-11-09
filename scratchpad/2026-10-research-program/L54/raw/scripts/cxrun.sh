#!/bin/bash
# cxrun.sh LAYOUTS VARIANTS: for each dumped layout (B0..; its join_kernel_b62_1.cu) and each variant (mkvar.py), the
# NVRTC + driver-JIT registers/spill and the AND digit loop's instructions per digit -> one line each.
cd /root/l54/cx
for L in $1; do
  for v in $2; do
    d=/root/l54/cx/$L; mkdir -p $d
    python3 /root/l54/mkvar.py /root/l54/cu/$L/join_kernel_b${B:-62}_1.cu $v $d/v_$v.cu > /dev/null || { echo "$L $v MKVAR FAIL"; continue; }
    r=$(bash /root/l54/cuexp.sh $d/v_$v.cu 2>&1)
    regs=$(echo "$r" | grep -o "'regs': [0-9]*" | grep -o '[0-9]*'); loc=$(echo "$r" | grep -o "'local': [0-9]*" | grep -o '[0-9]*')
    sass=$(echo "$r" | grep -o 'sass=[0-9]*'); and=$(python3 /root/l54/andloops.py --and $d/v_$v.sass | grep -o '[0-9]* instr' | tr '\n' ' ')
    echo "$L b${B:-62} $v regs=$regs local=$loc $sass and=[$and]"
  done
done
