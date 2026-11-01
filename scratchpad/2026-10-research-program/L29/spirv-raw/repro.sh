#!/bin/bash
# Reproduce the CI abort and locate it. Tree = $1 (pr|fix|main), tag = $2.
T=${1:-pr}; TAG=${2:-$T}
cd /root/src/$T
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
export RUST_BACKTRACE=1 NICE_BUILD_SHA=test
BIN=$(ls -t target/release/deps/nice_common-* | grep -v '\.d$' | head -1)
echo "bin $BIN $(md5sum < $BIN)" > /root/logs/${TAG}_bin.txt
L=/root/logs
# 1. the CI step as CI runs it
( date -u; timeout 2400 $BIN --ignored --nocapture cubecl_; echo "exit $?"; date -u ) > $L/${TAG}_ci_spirv.log 2>&1
# 2. the certificate test alone, default stack
( date -u; timeout 1200 $BIN --ignored --nocapture --exact cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu; echo "exit $?"; date -u ) > $L/${TAG}_cert_alone.log 2>&1
touch $L/${TAG}_repro.done
