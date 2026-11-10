#!/bin/bash
# chain_cal.sh: calibration at today's shape on the brief's b62 1e17 field (start 7226266762397899821056 =
# 3226266762397899821056 + 40000e17), 3 interleaved rounds. Modes on E (L51's profile + ablations; profiled):
# c full, a AND only (dense phase), z no AND (base), b walk without prefilter/stage, p walk + prefilter (no stage);
# T = upstream main c0c357a (+ the test-only harness), unprofiled. Order rotates by 2 each round.
R=/root/n1/run.sh; L=/root/n1/logs
echo CAL_START $(date -u +%T)
MODES=(c a z T b p)
for r in 1 2 3; do
  for i in 0 1 2 3 4 5; do
    m=${MODES[$(( (i + 2 * (r - 1)) % 6 ))]}
    [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
    unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL; BIN=E
    case $m in
      c) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0;;
      a) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=1;;
      b) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=2;;
      p) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=3;;
      z) export NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=4;;
      T) BIN=T;;
    esac
    $R cal_${m}_r$r $BIN 62 1 1e17
    echo "$(date -u +%T) cal_${m}_r$r $(grep -o 'join=[0-9.]*' $L/cal_${m}_r$r.log | tail -1) $(grep -o 'device=[0-9.]*s' $L/cal_${m}_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/cal_${m}_r$r.log | tail -1) $(grep -o 'regs=[0-9]*' $L/cal_${m}_r${r}_jit.txt | head -1)"
  done
done
echo CAL_DONE $(date -u +%T) | tee $L/cal.done
