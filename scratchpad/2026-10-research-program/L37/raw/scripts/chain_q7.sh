#!/bin/bash
# chain_q7.sh: after chain_q6: build A5 (modes 13, 14), then the split of the top loads (profiled): modes 11, 13, 14, 12
# interleaved, b62 1e17 2 rounds, b60 1e16 1 round.
R=/root/l37/run.sh; L=/root/l37/logs
until [ -e $L/q6.done ]; do sleep 10; done
cd /root/l37 && NICEN=15 J=16 ./build.sh A5 A5 gpu > $L/build_A5.out 2>&1 && touch $L/A5.built
[ -e $L/A5.built ] || { echo BUILD_FAILED; exit 1; }
echo Q7_START $(date -u +%T)
unset NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
export NICE_EXP_GPU_PROFILE=1
for r in 1 2; do for m in 11 13 14 12; do NICE_EXP_JOIN_ABL=$m SRCD=A5 $R base5_m${m}_e17_b62_r$r A5 62 1 1e17; done; done
for m in 11 13 14 12; do NICE_EXP_JOIN_ABL=$m SRCD=A5 $R base5_m${m}_e16_b60_r1 A5 60 2 1e16; done
echo Q7_DONE $(date -u +%T) > $L/q7.done
