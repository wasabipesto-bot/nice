#!/bin/bash
# Replaces chain_base.sh after P's cargo build started (order changed: P, then T, then A).
# Waits for P's cargo to exit, installs the P binary as build.sh would, then builds T and A.
L=/root/l34/logs; S=/root/l34; B=/root/l34/bin
while pgrep -f "cargo test --release" > /dev/null; do sleep 5; done
bin=$(grep -o "/root/tgt/release/deps/nice_common-[0-9a-f]*" $L/build_P.log | head -1)
if [ -z "$bin" ]; then echo "P BUILD FAILED"; tail -40 $L/build_P.log; exit 1; fi
cp $bin $B/P; md5sum $B/P; echo BUILD_DONE P $(date -u +%T)
echo P_DONE $(date -u +%T) > $L/p.done
$S/build.sh T T gpu || exit 1
echo T_DONE $(date -u +%T) > $L/t.done
$S/build.sh A A gpu || exit 1
echo A_DONE $(date -u +%T) > $L/a.done
