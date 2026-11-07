#!/bin/bash
# regsample.sh N VARIANTS...: N processes per variant (1e14 at b60/b62/b64, 1 field each, fresh PTX cache), then the
# driver JIT's registers/spills of every join_kernel each process compiled (ptxjit.py). Variant tag = binary = tree.
N=$1; shift
cd /root/l46
for i in $(seq 1 $N); do for V in "$@"; do
  SRCD=$V bash scripts/run.sh rs_${V}_$i $V 60,62,64 1 1e14 > /dev/null 2>&1
  python3 scripts/ptxjit.py --only join_kernel ptx/rs_${V}_$i 2>&1 | sed "s/ptx=[0-9a-f]* //; s/ key=.*//; s/image=ptx //" | awk -v v=$V -v i=$i '{print v, i, $0}'
done; done | tee -a logs/regsample.txt
