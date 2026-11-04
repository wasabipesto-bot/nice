#!/bin/bash
# chain_q3.sh: after chain_q1b: (1) the base split (A3, profiled: modes 4, 9, 10, 11; b62 1e17 2 rounds, b60 1e16 1 round);
# (2) exactness of H1 (C, COMPACT=1) with lavapipe beside it; (3) exactness of H2 (S, SHFL=1);
# (4) H2 confirmation at b62 1e17 / b60 1e16: full (unprofiled) and AND-only (profiled), SHFL 0/1, 1 round.
R=/root/l37/run.sh; L=/root/l37/logs
until [ -e $L/q1.done ] && [ -e $L/A3.built ]; do sleep 10; done
echo Q3_START $(date -u +%T)
unset NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
export NICE_EXP_GPU_PROFILE=1
for r in 1 2; do for m in 4 9 10 11; do NICE_EXP_JOIN_ABL=$m SRCD=A3 $R base_m${m}_e17_b62_r$r A3 62 1 1e17; done; done
for m in 4 9 10 11; do NICE_EXP_JOIN_ABL=$m SRCD=A3 $R base_m${m}_e16_b60_r1 A3 60 2 1e16; done
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL
echo BASE_DONE $(date -u +%T) > $L/base.done
touch $L/lvp_go
/root/l37/chain_x.sh C C NICE_EXP_JOIN_COMPACT 1 C1 > $L/chain_x_C1.out 2>&1
/root/l37/chain_x.sh S S NICE_EXP_JOIN_SHFL 1 S1 > $L/chain_x_S1.out 2>&1
unset NICE_EXP_JOIN_COMPACT NICE_EXP_JOIN_SHFL
until [ -e $L/lvp_C.done ]; do sleep 10; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R ab2_S${s}_e17_b62_r1 S 62 1 1e17; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R ab2_S${s}_e16_b60_r1 S 60 2 1e16; done
export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=1
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R andabl_S${s}_e17_b62_r1 S 62 1 1e17; done
for s in 0 1; do NICE_EXP_JOIN_SHFL=$s SRCD=S $R andabl_S${s}_e16_b60_r1 S 60 2 1e16; done
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL
echo Q3_DONE $(date -u +%T) > $L/q3.done
