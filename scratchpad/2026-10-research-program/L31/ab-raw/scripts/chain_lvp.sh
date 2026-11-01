#!/bin/bash
# Lavapipe: build B naga + spirv and A spirv test binaries; then CI's lint dump (naga: lint; spirv: blocks at b57),
# the certificate test on naga and spirv (B), and the join parity test on spirv with a dump (blocks per base, A and B).
L=/root/l31b/logs; BIN=/root/l31b/bin
dpkg -s mesa-vulkan-drivers > /dev/null 2>&1 || apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools > $L/apt_lvp.log 2>&1
J=8 nice -n 5 /root/l31b/build.sh B B_naga cubecl || exit 1
J=8 nice -n 5 /root/l31b/build.sh B B_spv cubecl-spirv || exit 1
J=8 nice -n 5 /root/l31b/build.sh A A_spv cubecl-spirv || exit 1
echo LVP_BUILDS_DONE $(date -u +%T) > $L/lvpbuilds.done
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
cd /root/l31b/src/B
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
# CI's lint step on B (naga)
rm -f $L/wgsl_B.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_B.log timeout 900 $BIN/B_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_B.log 2>&1
( python3 /root/l31b/src/B/scripts/wgsl-lint.py $L/wgsl_B.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_B.log 2>&1
gzip -f $L/wgsl_B.log
# the same dump on the direct SPIR-V compiler: TopKernel b57 blocks, A and B
for V in A B; do
  rm -f $L/spvdump_$V.log
  ( date -u; CUBECL_DEBUG_LOG=$L/spvdump_$V.log timeout 900 $BIN/${V}_spv --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/spv_dump_$V.log 2>&1
  python3 /root/l31b/blocks.py $L/spvdump_$V.log --top 20 > $L/blocks_lint_$V.txt 2>&1
  gzip -f $L/spvdump_$V.log
done
echo LVP_LINT_DONE $(date -u +%T) > $L/lvplint.done
T=cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu
( date -u; timeout 1800 $BIN/B_naga --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_cert_naga.log 2>&1
rm -f $L/certdump_spv.log
( date -u; CUBECL_DEBUG_LOG=$L/certdump_spv.log timeout 1800 $BIN/B_spv --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_cert_spv.log 2>&1
python3 /root/l31b/blocks.py $L/certdump_spv.log --top 12 > $L/blocks_cert_B.txt 2>&1
gzip -f $L/certdump_spv.log
for V in B A; do
  rm -f $L/pardump_$V.log
  ( date -u; CUBECL_DEBUG_LOG=$L/pardump_$V.log timeout 900 $BIN/${V}_spv --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv_$V.log 2>&1
  python3 /root/l31b/blocks.py $L/pardump_$V.log --name TopKernel --top 40 > $L/blocks_par_$V.txt 2>&1
  gzip -f $L/pardump_$V.log
done
echo LVP_DONE $(date -u +%T) > $L/lvp.done
