#!/bin/bash
# chain_lvl.sh W: build tree W's test binary, its host tests (FX/MT/lean, the exhaustive FX test, join_plan:: and
# cubecl_join:: unit tests), then registers/SASS per level 0-4 (NICE_EXP_JOIN_PF) on the b62/b60/b64 1e14 fields.
L=/root/l41/logs; W=$1
until [ -e $L/base.done ]; do sleep 5; done
J=10 /root/l41/build.sh $W $W > $L/build_$W.out 2>&1 || { cat $L/build_$W.out; exit 1; }
cat $L/build_$W.out
cd /root/l41/src/$W
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/$W fx_ mt_ lean_prefilter --nocapture; /root/l41/bin/$W join_plan:: ; /root/l41/bin/$W cubecl_join:: ) > $L/host_$W.log 2>&1
grep -h "test result\|FAILED\|panicked" $L/host_$W.log
for lv in 0 1 2 3 4; do NICE_EXP_JOIN_PF=$lv /root/l41/regs.sh $W ${W}L$lv $W 2>&1 | tail -30 > $L/regs_${W}L$lv.out; grep "join_kernel\|top_kernel_b62\|check_kernel_b62" /root/l41/sass/${W}L$lv/registers.txt; head -1 $L/regs_${W}L$lv.out; done
touch $L/lvl_$W.done
( /root/l41/bin/$W fx_digits_are_exact_everywhere --ignored --nocapture ) > $L/host_exh_$W.log 2>&1
tail -3 $L/host_exh_$W.log
touch $L/exh_$W.done
