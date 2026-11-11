#!/bin/bash
# chain_P.sh: the entry-wave hoist (v6, stg 6) without its spill: pinned PTX images on tree E3 (pin.py, L45/L51's).
# P0 = today's kernel (v0) as a spill-free process compiled it; P6r48 = v6's PTX + '.maxnreg 48'; P6r56 = v6's PTX +
# '.maxnreg 56' (4 cubes per SM). 3 interleaved rounds, b64 1e16 at 0.35 + 0.55 and b62 1e17 (L30's field).
source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs; P=/root/b64/ptx; PIN=/root/b64/pin
IFS=, read -ra A <<< "$L64"
mkdir -p $PIN; cd /root/b64/scripts
echo P_START $(date -u +%T)
for b in 64 62; do
  if [ $b = 64 ]; then s0=b_v0_b64_1e16_r1; s6=b_v6_b64_1e16_r1; else s0=b_v0_b62_1e17_r2; s6=b_v6_b62_1e17_r1; fi
  grep -q "local=0" $L/${s0}_jit.txt || { for r in r1 r2 r3; do grep -q "join_kernel.*local=0" $L/b_v0_b${b}_*_${r}_jit.txt 2>/dev/null && s0=$(basename $(ls $L/b_v0_b${b}_*_${r}_jit.txt) _jit.txt) && break; done; }
  rm -rf $PIN/P0_$b $PIN/P6r48_$b $PIN/P6r56_$b
  cp -a $P/$s0 $PIN/P0_$b
  python3 pin.py --directive '.maxnreg 48' $PIN/P6r48_$b $P/$s6
  python3 pin.py --directive '.maxnreg 56' $PIN/P6r56_$b $P/$s6
  echo "pins b$b: P0 from $s0, P6 from $s6"
done
IM=(P0 P6r48 P6r56)
for r in 1 2 3; do
  for f in "64 2 1e16" "62 1 1e17"; do
    set -- $f
    for i in 0 1 2; do
      im=${IM[$(( (i + r - 1) % 3 ))]}
      [ -e $L/stop ] && exit 0
      unset NICE_TEST_JOIN_LIST; [ $1 = 64 ] && export NICE_TEST_JOIN_LIST=${A[3]},${A[5]}
      if [ $im = P0 ]; then export NICE_EXP_JOIN_STAGE=0; else export NICE_EXP_JOIN_STAGE=6; fi
      n=pp_${im}_b$1_r$r; PTXFROM=$PIN/${im}_$1 $R $n E3 $1 $2 $3; bash /root/b64/scripts/jit.sh $n
      echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'join_kernel.*regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1 | grep -o 'regs.*')"
    done
  done
done
echo P_DONE $(date -u +%T)
