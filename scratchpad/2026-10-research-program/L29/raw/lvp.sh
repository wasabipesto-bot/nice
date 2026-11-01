#!/bin/bash
# lvp.sh TREE: the new certificate test and the WGSL dump on lavapipe, then the lint.
T=${1:-pr}
B=/root/bin/$T/nice_common_test
export VK_ICD_FILENAMES="$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
cd /root/src/$T
echo "== $(date -u +%T) cert on lavapipe ($VK_ICD_FILENAMES)"
$B --ignored --exact cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture > /root/logs/l_${T}_cert.log 2>&1
echo "exit $? $(date -u +%T)"
rm -f /root/logs/wgsl_$T.log
CUBECL_DEBUG_LOG=/root/logs/wgsl_$T.log $B --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > /root/logs/l_${T}_dump.log 2>&1
echo "dump exit $? $(date -u +%T)"
python3 scripts/wgsl-lint.py /root/logs/wgsl_$T.log \
  --require DetailedKernelU32@80 --require DetailedFdKernelU32@40 \
  --require DetailedFdKernelU32@50 \
  --require DetailedFdKernel@23 --require DetailedFdKernel@40 \
  --require DetailedFdKernel@50 --require DetailedFdKernel@62 \
  --require DetailedKernel@80 --require NiceonlyKernel@40 \
  --require BucketKernel@57 --require JoinKernel@57 \
  --require TopKernel@57 --require CheckKernel@57 > /root/logs/l_${T}_lint.log 2>&1
echo "lint exit $? $(date -u +%T)"
echo LVP_DONE $(date -u +%T)
