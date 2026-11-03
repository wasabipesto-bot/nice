#!/bin/bash
# chain_x4lvp.sh: the prototype on lavapipe: X4 (47c1b36) built for naga (cubecl) and the direct SPIR-V compiler
# (cubecl-spirv); #240's light FD test with NICE_EXP_TOP_FD_ABL = 3584 (all three prototype switches) on both, and the
# SPIR-V basic-block count of TopFdKernel with and without them.
L=/root/l36/logs; BIN=/root/l36/bin
CARGO_TARGET_DIR=/root/tgt_lvp /root/l36/build.sh X4 X4_naga cubecl /root/tgt_lvp
CARGO_TARGET_DIR=/root/tgt_lvp /root/l36/build.sh X4 X4_spv cubecl-spirv /root/tgt_lvp
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/l36/src/X4
P=cubecl_join::tests::top_fd_matches_the_top_kernel
( date -u; NICE_EXP_TOP_FD_ABL=3584 timeout 2400 $BIN/X4_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/x4lvp_fd_naga.log 2>&1
for A in 3584 0; do
  rm -f $L/x4dump_spv_a$A.log
  ( date -u; NICE_EXP_TOP_FD_ABL=$A CUBECL_DEBUG_LOG=$L/x4dump_spv_a$A.log timeout 2400 $BIN/X4_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/x4lvp_fd_spv_a$A.log 2>&1
  python3 /root/l36/blocks.py $L/x4dump_spv_a$A.log --top 30 > $L/x4blocks_spv_a$A.txt 2>&1
  gzip -f $L/x4dump_spv_a$A.log
done
echo X4LVP_DONE $(date -u +%T) > $L/x4lvp.done
