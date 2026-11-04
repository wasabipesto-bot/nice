#!/bin/bash
# chain_abl2.sh (rounds 2-3 of chain_abl.sh): join-kernel breakdown by ablation on A (main 6f060a9 + profile + NICE_EXP_JOIN_ABL/TMIN), profile on.
# Sanity (b62 1e14 counts at mode 0), then 3 interleaved rounds: b62 1e17 (1 field) and b60 1e16 (2 fields) per mode;
# the lane-round count runs (mode 6) first.
R=/root/l37/run.sh; L=/root/l37/logs
echo ABL2_START $(date -u +%T)
# H1 screen first (unprofiled): C with NICE_EXP_JOIN_COMPACT 0/1/2 at b62 1e16, 2 fields.
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN
if [ -e /root/l37/bin/C ]; then
  for c in 0 1 2; do NICE_EXP_JOIN_COMPACT=$c SRCD=C $R scr_C${c}_e16_b62 C 62 2 1e16; done
fi
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
export NICE_EXP_GPU_PROFILE=1
unset NICE_EXP_JOIN_TMIN
MODES="c:0: a:1: b:2: p:3: z:4: d:0:1073741824"
unset NICE_EXP_JOIN_TMIN
NICE_EXP_JOIN_ABL=6 $R abl_u_e17_b62 A 62 1 1e17
NICE_EXP_JOIN_ABL=6 $R abl_u_e16_b60 A 60 2 1e16
for r in 2 3; do
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for m in $MODES; do
      IFS=: read tag abl tmin <<< "$m"
      if [ -n "$tmin" ]; then export NICE_EXP_JOIN_TMIN=$tmin; else unset NICE_EXP_JOIN_TMIN; fi
      NICE_EXP_JOIN_ABL=$abl $R abl_${tag}_$4_r$r A $1 $2 $3
    done
  done
  touch $L/abl_r$r.done
done
echo ABL_DONE $(date -u +%T) > $L/abl.done
