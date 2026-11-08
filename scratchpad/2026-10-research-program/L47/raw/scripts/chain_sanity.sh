#!/bin/bash
# chain_sanity.sh W: first look at W (tree W): 1e14 b62/b60/b64 (1 field each, profile on), the check kernel's registers,
# spills and SASS from the runtime path (ptxjit), then the count/probe device test.
R=/root/l47/scripts/run.sh; T=/root/l47/scripts/test.sh; L=/root/l47/logs; W=$1
echo SAN_START $W $(date -u +%T)
NICE_EXP_GPU_PROFILE=1 SRCD=$W $R san_${W}_e14 $W 62,60,64 1 1e14
grep -h "GPU_PROFILE" $L/san_${W}_e14.log | grep -o "base=[0-9]* \|check=[0-9.]*\|checked=[0-9]*\|hits=[0-9]*" | tr '\n' ' '; echo
grep -h "test result\|panicked" $L/san_${W}_e14.log
python3 /root/l47/scripts/ptxjit.py --only check_kernel --sass $L/sass_${W} /root/l47/ptx/san_${W}_e14 > $L/san_${W}_jit.txt 2>&1
cat $L/san_${W}_jit.txt
SRCD=$W $T x_${W}_counts $W cubecl_join::tests::cubecl_cuda_check_counts_match_the_cpu X=1
grep -h "test result\|panicked\|agree on" $L/x_${W}_counts.log | head -5
echo SAN_DONE $W $(date -u +%T)
