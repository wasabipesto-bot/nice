#!/bin/bash
# Replaces chain_p192t.sh (killed: its cargo clean raced P192_spv's install, so the SPIR-V parity did not run).
# Waits for P192t's build, counts its registers, rebuilds P192_spv alone, runs the SPIR-V parity test with a dump,
# then releases the A/B (p192t.done).
L=/root/l34/logs; S=/root/l34; BIN=/root/l34/bin
while pgrep -f "build.sh P192t" > /dev/null; do sleep 5; done
$S/regs.sh P192t pr192t 2>&1 | grep join_kernel
J=10 $S/build.sh P192 P192_spv cubecl-spirv || exit 1
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/l34/src/P192
PT=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
rm -f $L/pardump_pr192.log
( date -u; CUBECL_DEBUG_LOG=$L/pardump_pr192.log timeout 1800 $BIN/P192_spv --ignored --exact $PT --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/pr192_lvp_par_spv.log 2>&1
python3 /root/l34/blocks.py $L/pardump_pr192.log --name JoinKernel --top 40 > $L/pr192_blocks.txt 2>&1
gzip -f $L/pardump_pr192.log
echo P192T_DONE_FIX $(date -u +%T) > $L/p192t.done
