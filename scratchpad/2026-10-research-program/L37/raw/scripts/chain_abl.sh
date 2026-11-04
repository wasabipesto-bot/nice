#!/bin/bash
# chain_abl.sh: join-kernel breakdown by ablation on A (main 6f060a9 + profile + NICE_EXP_JOIN_ABL/TMIN), profile on.
# Sanity (b62 1e14 counts at mode 0), then 3 interleaved rounds: b62 1e17 (1 field) and b60 1e16 (2 fields) per mode;
# then one lane-round count run (mode 6) per field.
R=/root/l37/run.sh; L=/root/l37/logs
until [ -e $L/A.built ] && [ -e /root/l37/bin/A ]; do sleep 10; done
echo ABL_START $(date -u +%T)
export NICE_EXP_GPU_PROFILE=1
unset NICE_EXP_JOIN_TMIN
NICE_EXP_JOIN_ABL=0 $R abl_sanity_e14 A 62,60 1 1e14
MODES="c:0: a:1: b:2: p:3: z:4: d:0:1073741824"
for r in 1 2 3; do
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
unset NICE_EXP_JOIN_TMIN
NICE_EXP_JOIN_ABL=6 $R abl_u_e17_b62 A 62 1 1e17
NICE_EXP_JOIN_ABL=6 $R abl_u_e16_b60 A 60 2 1e16
echo ABL_DONE $(date -u +%T) > $L/abl.done
