#!/bin/bash
# ir.sh <dir>: naga WGSL->MSL, then MSL as C++ through clang -O2 to LLVM IR, then scan.
cd $1
for f in *.wgsl; do
  b=${f%.wgsl}
  sed -i "/^\`\`\`/d" "$f"
  [ -f $b.metal ] || /root/nagacli/bin/naga "$f" "$b.metal" > "$b.naga.txt" 2>&1
  { echo '#include "/root/ir/msl_shim.h"'; grep -v '^#include' $b.metal; } > $b.cpp
  clang++ -std=c++17 -O2 -w -S -emit-llvm $b.cpp -o $b.ll 2> $b.clang.txt || echo "CLANG FAIL $b"
done
python3 /root/ir/ir_scan.py *.ll
