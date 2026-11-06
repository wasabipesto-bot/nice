#!/bin/bash
# chain_p.sh NAME REF: tree NAME at the fork's REF, its test binary and client (niced, beside untimed GPU work), its
# host tests, registers/SASS on the 1e14 fields, rustfmt.
L=/root/l41/logs; W=$1
/root/l41/tree.sh $W $2
NICEN=15 J=10 /root/l41/build.sh $W $W > $L/build_$W.out 2>&1 || { cat $L/build_$W.out; exit 1; }
cat $L/build_$W.out
NICEN=15 /root/l41/buildclient.sh $W client_$W > $L/buildclient_$W.out 2>&1; cat $L/buildclient_$W.out
cd /root/l41/src/$W
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/$W fx_ lean_ --nocapture; /root/l41/bin/$W join_plan:: ; /root/l41/bin/$W cubecl_join:: ) > $L/host_$W.log 2>&1
grep -h "test result\|FAILED\|panicked" $L/host_$W.log
( source ~/.cargo/env; cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_$W.log 2>&1; tail -1 $L/fmt_$W.log
/root/l41/regs.sh $W $W $W 2>&1 | tail -30 > $L/regs_$W.out; head -1 $L/regs_$W.out
grep join_kernel /root/l41/sass/$W/registers.txt
python3 /root/l41/walkcount.py /root/l41/sass/$W/join_kernel_b6[024]_1.sass | cut -c1-160
touch $L/p_$W.done
