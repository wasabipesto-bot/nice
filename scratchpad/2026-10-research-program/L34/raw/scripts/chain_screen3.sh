#!/bin/bash
# Attempt 3 (T3 = unrolled build): registers, then b62 1e16 (2 fields): off, G=4, G=16 (build only), G=2, G=8, off, G=4.
L=/root/l34/logs; S=/root/l34; R=$S/run.sh
mkdir -p /root/l34/src/T3 && tar xzf /root/l34/T3.tgz -C /root/l34/src/T3
$S/build.sh T3 T3 gpu > $L/build_T3.out 2>&1 || exit 1
cfg() { case $1 in off) echo "";; g*) echo "NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$(echo $1 | tr -dc 0-9)";; esac; }
for c in off g4 g2 g8 g16; do $S/regs.sh T3 t3$c $(cfg $c); done
for c in off g4 g16 g2 g8 off g4; do
  n=s3_${c}_r1; [ -e $L/$n.log ] && n=s3_${c}_r2
  env $(cfg $c) $R $n T3 62 2 1e16
done
echo SCREEN3_DONE $(date -u +%T) > $L/screen3.done
