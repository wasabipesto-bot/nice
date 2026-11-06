#!/bin/bash
# chain_main.sh: 3 interleaved rounds; per round b62 1e17 (1 field), then b60 1e16 (2 fields); per field the modes
#   c full (#246) | a AND only | b walk, no prefilter, no stage | p walk + prefilter, no stage | z no AND |
#   d full, per-top AND (TMIN 2^30) | s7, s8 stage every 4 / 8 chunks | s15 stage once per top batch   (profile on)
#   u full, profile OFF (part A's unprofiled total)
#   (the spill / no-spill pinned runs S, N follow in chain_sn.sh)
# Every process has its own PTX cache (fresh unless pinned), so each one's join variant is recorded afterwards.
R=/root/l45/run.sh; L=/root/l45/logs
echo MAIN_START $(date -u +%T)
MODES="c:0:: a:1:: b:2:: p:3:: z:4:: d:0:1073741824: s7:7:: s8:8:: s15:15:: u:0::noprof"
for r in 1 2 3; do
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for m in $MODES; do
      IFS=: read tag abl tmin extra <<< "$m"
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      if [ -n "$tmin" ]; then export NICE_EXP_JOIN_TMIN=$tmin; else unset NICE_EXP_JOIN_TMIN; fi
      if [ "$extra" = noprof ]; then unset NICE_EXP_GPU_PROFILE; else export NICE_EXP_GPU_PROFILE=1; fi
      unset PTXFROM
      if [ "$extra" = pinS ]; then export PTXFROM=/root/l45/pin/S$1; fi
      if [ "$extra" = pinN ]; then export PTXFROM=/root/l45/pin/N$1; fi
      if [ -n "${PTXFROM:-}" ] && [ ! -d "$PTXFROM" ]; then echo "skip $tag (no $PTXFROM)"; continue; fi
      NICE_EXP_JOIN_ABL=$abl $R m_${tag}_$4_r$r E2 $1 $2 $3
      echo "$(date -u +%T) m_${tag}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/m_${tag}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/m_${tag}_$4_r$r.log | tail -1)"
    done
  done
  touch $L/main_r$r.done
done
echo MAIN_DONE $(date -u +%T) | tee $L/main.done
