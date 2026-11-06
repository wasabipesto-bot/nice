#!/bin/bash
# chain_lvl2.sh SRC BIN "TAG:PF:MT[:FXM[:RCV]] ...": build tree SRC's test binary as BIN, its host tests, then
# registers/SASS for each TAG (NICE_EXP_JOIN_PF/MT/FXM/RCV) on the b62/b60/b64 1e14 fields, with the walk-loop counts.
L=/root/l41/logs; S=$1; W=$2
J=10 /root/l41/build.sh $S $W > $L/build_$W.out 2>&1 || { cat $L/build_$W.out; exit 1; }
cat $L/build_$W.out
cd /root/l41/src/$S
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( /root/l41/bin/$W fx_ mt_ lean_prefilter --nocapture; /root/l41/bin/$W join_plan:: ; /root/l41/bin/$W cubecl_join:: ) > $L/host_$W.log 2>&1
grep -h "test result\|FAILED\|panicked" $L/host_$W.log
for spec in $3; do
  IFS=: read tag pf mt fxm rcv <<< "$spec"
  NICE_EXP_JOIN_PF=$pf NICE_EXP_JOIN_MT=$mt NICE_EXP_JOIN_FXM=${fxm:-0} NICE_EXP_JOIN_RCV=${rcv:-1} /root/l41/regs.sh $W $tag $S 2>&1 | tail -30 > $L/regs_$tag.out
  head -1 $L/regs_$tag.out
  grep join_kernel /root/l41/sass/$tag/registers.txt | sed 's/ bytes spill stores, / /; s/ bytes spill loads Used / /; s/ registers.*sass=/ regs sass=/'
  python3 /root/l41/walkcount.py /root/l41/sass/$tag/join_kernel_b6[024]_1.sass | grep loop1 | cut -c1-150
done
touch $L/lvl2_$W.done
