#!/bin/bash
# chain_screen.sh W: D's knobs, profile on, 2 rounds (order reversed in round 2): the gate's n³ digits g in {8, 10, 12}
# (K = 4) at b62 1e16 and b60 1e16 (2 fields each), the entries per lane K in {1, 8} (g = 10) at b62 1e16, and the
# old kernel (S0, 1024 cubes) beside them; then ptxjit of each variant's check kernel.
R=/root/l47/scripts/run.sh; L=/root/l47/logs; W=$1
export NICE_EXP_GPU_PROFILE=1
echo SCR_START $(date -u +%T)
for r in 1 2; do
  M="g8 g10 g12 k1 k8 old"; [ $r = 2 ] && M="old k8 k1 g12 g10 g8"
  for m in $M; do
    unset NICE_EXP_CHECK_G NICE_EXP_CHECK_K NICE_EXP_CHECK_CUBES NICE_EXP_CHECK
    BIN=$W; FL="62:e16_b62 60:e16_b60"
    case $m in
      g*) export NICE_EXP_CHECK_G=${m:1};;
      k*) export NICE_EXP_CHECK_K=${m:1}; FL="62:e16_b62";;
      old) BIN=S0; export NICE_EXP_CHECK_CUBES=1024;;
    esac
    for f in $FL; do SRCD=$BIN $R scr_${m}_${f#*:}_r$r $BIN ${f%%:*} 2 1e16; done
  done
done
for m in g8 g10 g12 k1 k8; do python3 /root/l47/scripts/ptxjit.py --only check_kernel --sass $L/sass_scr_$m /root/l47/ptx/scr_${m}_e16_b62_r1 2>&1 | sed "s/^/$m /"; for f in $L/sass_scr_$m/*.sass; do echo "$m $(python3 /root/l47/scripts/sasscount.py $f | tail -1)"; done; done > $L/scr_jit.txt 2>&1
echo SCR_DONE $(date -u +%T) > $L/scr.done
