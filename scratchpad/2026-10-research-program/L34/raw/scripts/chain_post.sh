#!/bin/bash
# After the A/B and NiceMark: build FP = F + the profile commits, then profile it (NICE_EXP_GPU_PROFILE=1):
# b62 1e17 (1 field) and b60 1e16 (2 fields), switch off and on (G=4).
L=/root/l34/logs; S=/root/l34; R=$S/run.sh
until [ -e $L/chainNM.done ]; do sleep 20; done
mkdir -p /root/l34/src/FP && tar xzf /root/l34/FP.tgz -C /root/l34/src/FP
$S/build.sh FP FP gpu > $L/build_FP.out 2>&1 || exit 1
export NICE_EXP_GPU_PROFILE=1
$R fprof_off_b62_e17 FP 62 1 1e17
NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 $R fprof_on_b62_e17 FP 62 1 1e17
$R fprof_off_b60_e16 FP 60 2 1e16
NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=4 $R fprof_on_b60_e16 FP 60 2 1e16
echo POST_DONE $(date -u +%T) > $L/post.done
