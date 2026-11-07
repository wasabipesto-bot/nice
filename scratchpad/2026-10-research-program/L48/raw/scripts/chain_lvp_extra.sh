#!/bin/bash
# chain_lvp_extra.sh: after the A/B (lvp_P_go): CI's WGSL lint on P_naga; TopFdKernel's SPIR-V blocks of P_spv and of
# X_spv at level 0 (= f3fb390's kernel), from #240's FD test on lavapipe with CUBECL_DEBUG_LOG.
L=/root/l48/logs; BIN=/root/l48/bin
until [ -e $L/lvp_P_go ]; do sleep 15; done
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/l48/src/P
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_P.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_P.log timeout 900 $BIN/P_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_P.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_P.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_P.log 2>&1
gzip -f $L/wgsl_P.log
P=cubecl_join::tests::top_fd_matches_the_top_kernel
for spec in "P P 0" "X_spv X 0"; do
  set -- $spec
  B=$1; S=$2; LV=$3; [ $B = P ] && B=P_spv
  cd /root/l48/src/$S
  rm -f $L/spvdump_${B}_l$LV.log
  ( date -u; NICE_EXP_TOPFD=$LV CUBECL_DEBUG_LOG=$L/spvdump_${B}_l$LV.log timeout 2400 $BIN/$B --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvpfd_${B}_l$LV.log 2>&1
  python3 /root/l48/blocks.py $L/spvdump_${B}_l$LV.log --top 40 > $L/blocks_${B}_l$LV.txt 2>&1
  gzip -f $L/spvdump_${B}_l$LV.log
done
echo "EXTRA: lint $(tail -1 $L/wgsl_lint_P.log); P_spv FD $(grep -h 'test result' $L/lvpfd_P_spv_l0.log); X_spv l0 FD $(grep -h 'test result' $L/lvpfd_X_spv_l0.log) $(date -u +%T)"
touch $L/lvp_extra.done
