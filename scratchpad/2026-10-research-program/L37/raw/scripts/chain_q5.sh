#!/bin/bash
# chain_q5.sh: after chain_q4: the last split of the base (A4, profiled): modes 11 and 12 interleaved, b62 1e17 2 rounds,
# b60 1e16 1 round.
R=/root/l37/run.sh; L=/root/l37/logs
until [ -e $L/q4.done ] && [ -e $L/A4.built ]; do sleep 10; done
echo Q5_START $(date -u +%T)
unset NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
export NICE_EXP_GPU_PROFILE=1
for r in 1 2; do for m in 11 12; do NICE_EXP_JOIN_ABL=$m SRCD=A4 $R base4_m${m}_e17_b62_r$r A4 62 1 1e17; done; done
for m in 11 12; do NICE_EXP_JOIN_ABL=$m SRCD=A4 $R base4_m${m}_e16_b60_r1 A4 60 2 1e16; done
echo Q5_DONE $(date -u +%T) > $L/q5.done
