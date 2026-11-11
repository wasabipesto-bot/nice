#!/bin/bash
# pr_build.sh: CUDA test binaries P (the branch), N (branch + harness list), R (ee303030 + harness), MF (main + harness +
# NICE_EXP_FD_POW2 switch); then the wgpu test binaries of P: P_naga (--features cubecl), P_spv (--features cubecl-spirv).
cd /root/b64
for t in P N R MF; do J=22 bash scripts/build.sh $t $t gpu,cubecl-cuda; done
J=22 bash scripts/build.sh P P_naga cubecl /root/tgtw
J=22 bash scripts/build.sh P P_spv cubecl-spirv /root/tgtw
echo PR_BUILD_DONE $(date -u +%T)
