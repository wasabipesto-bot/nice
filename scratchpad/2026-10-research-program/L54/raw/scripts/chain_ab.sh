#!/bin/bash
# chain_ab.sh SIDES [SIDES2]: interleaved A/B, nothing else on the box. Sides: B = d813aea's binary (no env), F<n> = binary X1 with
# NICE_EXP_AND_FORM=<n>. Rounds 1-3: b62 1e17 (1 field) and b60 1e16 (2 fields); rounds 1-2: b62 1e16 and b64 1e16
# (2 fields each; sides SIDES2, default SIDES). Side order per round: a Latin square over the sides. Every process's join kernel is replayed through
# the driver's JIT (ptxjit.py); a process that compiled a spill variant (STL/LDL/local bytes) is kept as *_spill<k> and
# re-run, up to twice.
source /root/l54/cfg.sh
R=/root/l54/run.sh; L=/root/l54/logs
SIDES=(${1:-B F2 F3}); n=${#SIDES[@]}; SIDES2=(${2:-${SIDES[*]}}); n2=${#SIDES2[@]}
one() { # side name bases fields size
  local t=$1 nm=$2; shift 2
  for try in 0 1 2; do
    [ -e $L/stop ] && exit 0
    setside $t
    $R $nm $BIN "$@"
    nice -n 19 python3 /root/l54/ptxjit.py --only join /root/l54/ptx/$nm > $L/${nm}_jit.txt 2>&1
    echo "$(date -u +%T) $nm try$try $(grep -o 'per_field=[0-9.]*' $L/$nm.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$nm.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${nm}_jit.txt | tr '\n' ' ')"
    if grep -q 'variant=SPILL' $L/${nm}_jit.txt && [ $try -lt 2 ]; then
      for x in log smi; do mv $L/$nm.$x $L/${nm}_spill$try.$x; done
      mv $L/${nm}_jit.txt $L/${nm}_spill${try}_jit.txt; rm -rf /root/l54/ptx/${nm}_spill$try; mv /root/l54/ptx/$nm /root/l54/ptx/${nm}_spill$try
    else
      break
    fi
  done
}
echo AB_START "${SIDES[@]}" $(date -u +%T)
for r in 1 2 3; do
  O=(); for i in $(seq 0 $((n - 1))); do O+=(${SIDES[$(( (i + (r - 1) * (n - 1)) % n ))]}); done
  echo "round $r order ${O[*]}"
  for t in "${O[@]}"; do one $t ab_${t}_e17_b62_r$r 62 1 1e17; done
  for t in "${O[@]}"; do one $t ab_${t}_e16_b60_r$r 60 2 1e16; done
  if [ $r -le 2 ]; then
    O2=(); for i in $(seq 0 $((n2 - 1))); do O2+=(${SIDES2[$(( (i + (r - 1) * (n2 - 1)) % n2 ))]}); done
    for t in "${O2[@]}"; do one $t ab_${t}_e16_b62_r$r 62 2 1e16; done
    for t in "${O2[@]}"; do one $t ab_${t}_e16_b64_r$r 64 2 1e16; done
  fi
  echo "AB round $r done $(date -u +%T)"
done
echo AB_DONE $(date -u +%T) | tee $L/ab.done
