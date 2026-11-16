#!/bin/bash
# builds.sh: the merge's three test binaries (one target dir), then CI's host tests on the merge.
W=/root/mu
bash $W/build.sh m G gpu
bash $W/build.sh m W cubecl
bash $W/build.sh m S cubecl-spirv
. /root/.cargo/env; cd $W/m && CARGO_TARGET_DIR=$W/target-m NICE_BUILD_SHA=test cargo test --release -j 24 -p nice_common --features gpu --lib > $W/logs/G_host_tests.log 2>&1; echo "HOST rc=$? $(date -u +%T) $(grep -a 'test result' $W/logs/G_host_tests.log)"
echo BUILDS_DONE $(date -u +%T)
