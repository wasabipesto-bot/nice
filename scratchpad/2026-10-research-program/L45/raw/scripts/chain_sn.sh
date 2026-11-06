#!/bin/bash
# chain_sn.sh: (ii) the spill vs no-spill variants of #246's join kernel, timed separately.
# 1. classify every main-chain process's join kernel (driver JIT of its own PTX cache);
# 2. per field pick one spill and one no-spill process among the abl-0 runs (c, u);
# 3. pin: N = the no-spill process's cache, S = the same cache with the spill process's join PTX (so S and N differ in
#    the join kernel only); if no process compiled a spill variant (the driver JIT gave 47-48 registers and no spill in
#    every sanity compile), S = N with '.minnctapersm 6' in the join kernel's PTX: the 6-cube target L41 suspected
#    offline ptxas of choosing, which the driver JIT meets with 40 registers and spills;
# 4. 3 rounds, S/N alternating, profile on, both fields.
R=/root/l45/run.sh; L=/root/l45/logs; P=/root/l45/ptx
cd /root/l45
echo SN_START $(date -u +%T)
python3 /root/l45/ptxjit.py --only join --sass /root/l45/sass $P/m_* > $L/main_jit.txt 2>&1
for spec in "62 1 1e17 e17_b62 45" "60 1 1e16 e16_b60 30"; do
  set -- $spec
  read sp ns rest <<< "$(python3 pick.py $L/main_jit.txt $4 '^m_(c|u)_' '^hunt_')"
  i=0
  while { [ "$sp" = - ] || [ "$ns" = - ]; } && [ $i -lt ${HUNTS:-0} ]; do
    i=$((i+1))
    HUNT_TIMEOUT=$5 NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R hunt_${4}_$i E2 $1 $2 $3
    python3 /root/l45/ptxjit.py --only join $P/hunt_${4}_$i >> $L/hunt_jit.txt 2>&1
    cat $L/main_jit.txt $L/hunt_jit.txt > $L/all_jit.tmp
    read sp ns rest <<< "$(python3 pick.py $L/all_jit.tmp $4 '^m_(c|u)_' '^hunt_')"
  done
  echo "field $4: spill=$sp nospill=$ns ($rest) after $i hunts" | tee -a $L/pins.txt
  if [ "$ns" != - ]; then
    python3 pin.py /root/l45/pin/N$1 $P/$ns $P/$ns | tee -a $L/pins.txt
    if [ "$sp" != - ]; then
      python3 pin.py /root/l45/pin/S$1 $P/$ns $P/$sp | tee -a $L/pins.txt
    else
      python3 pin.py --directive '.minnctapersm 6' /root/l45/pin/S$1 $P/$ns | tee -a $L/pins.txt
    fi
    python3 /root/l45/ptxjit.py --only join --sass /root/l45/sass /root/l45/pin/N$1 /root/l45/pin/S$1 >> $L/pins.txt 2>&1
  fi
done
for r in 1 2 3; do
  if [ $r = 2 ]; then ORDER="N S"; else ORDER="S N"; fi
  for spec in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $spec
    for v in $ORDER; do
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      [ -d /root/l45/pin/$v$1 ] || continue
      PTXFROM=/root/l45/pin/$v$1 NICE_EXP_GPU_PROFILE=1 NICE_EXP_JOIN_ABL=0 $R sn_${v}_$4_r$r E2 $1 $2 $3
      echo "$(date -u +%T) sn_${v}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/sn_${v}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/sn_${v}_$4_r$r.log | tail -1)"
    done
  done
done
python3 /root/l45/ptxjit.py --only join $P/sn_* $P/hunt_* > $L/sn_jit.txt 2>&1
echo SN_DONE $(date -u +%T) | tee $L/sn.done
