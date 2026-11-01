#!/bin/bash
# The CI step "Run device parity tests (CubeCL direct SPIR-V compiler)", with a pinned binary.
TAG=$1; BIN=$2; TREE=$3
cd /root/src/$TREE
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
export RUST_BACKTRACE=1 NICE_BUILD_SHA=test
( date -u; md5sum $BIN; timeout 3000 $BIN --ignored --nocapture cubecl_; echo "exit $?"; date -u ) > /root/logs/${TAG}_ci_spirv.log 2>&1
touch /root/logs/${TAG}_ci_spirv.done
