#!/bin/bash
# dense1.sh BIN MODES...: the dense compares against the CPU join on CUDA, b60 1e16 (48 partitions), b62 1e17 (32),
# b64 1e17 (32), for each NICE_EXP_N21 mode.
B=$1; shift
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568
for m in "$@"; do
  bash /root/n21/scripts/dense.sh x_${B}_${m}_b60 $B $m 60 $F60 1e16 48
  bash /root/n21/scripts/dense.sh x_${B}_${m}_b62 $B $m 62 $F62 1e17 32
  bash /root/n21/scripts/dense.sh x_${B}_${m}_b64 $B $m 64 $F64 1e17 32
done
echo DENSE_DONE $B $(date -u +%T)
