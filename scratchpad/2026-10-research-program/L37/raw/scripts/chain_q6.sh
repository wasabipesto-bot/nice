#!/bin/bash
# chain_q6.sh: after chain_q5: a second H2 confirmation round (S, SHFL 0/1 interleaved): b62 1e17 and b60 1e16 full
# (unprofiled) and AND-only (profiled), and b62 1e16 full.
R=/root/l37/run.sh; L=/root/l37/logs
until [ -e $L/q5.done ]; do sleep 10; done
echo Q6_START $(date -u +%T)
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R ab2_S${s}_e17_b62_r2 S 62 1 1e17; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R ab2_S${s}_e16_b60_r2 S 60 2 1e16; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R ab2_S${s}_e16_b62_r1 S 62 2 1e16; done
export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=1
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R andabl_S${s}_e17_b62_r2 S 62 1 1e17; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R andabl_S${s}_e16_b60_r2 S 60 2 1e16; done
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL
echo Q6_DONE $(date -u +%T) > $L/q6.done
