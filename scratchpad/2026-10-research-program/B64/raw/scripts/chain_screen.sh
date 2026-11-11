#!/bin/bash
# chain_screen.sh: retune screen at b64 on tree E (unprofiled, every knob value its own comptime kernel), 2 rounds;
# fields 0.35 + 0.55 of b64 1e16 in one process; the base (today's constants) at the start and middle of each block;
# round 2 runs the list reversed. After every run its join kernel is replayed through the driver's JIT; a run that
# compiled a spill variant (local>0) is kept as *_spill<k> and re-run, up to twice.
source /root/b64/scripts/cfg.sh; source /root/b64/scripts/lists.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
IFS=, read -ra A <<< "$L64"
export NICE_TEST_JOIN_LIST=${A[3]},${A[5]}
V1=(base ept1 ept3 tm128 tm256 ag2 base2 ag8 tc128 tc512 fl256 fl768 stg1 base3)
# Round 4 of the base means first (round 1's M 1e16 ran its first five fields under a 260 W cap / disturbed card).
ROUNDS=4 B62ROUNDS="" FULL=0 bash /root/b64/scripts/chain_base.sh > $L/chain_base4.out 2>&1
# The 1e16 tiles of two 1e17 fields (0.05 and 0.55: twenty 1e16 fields, the same n as the 1e17 fields), S then M.
TILES=39667831862957161709568,39667841862957161709568,39667851862957161709568,39667861862957161709568,39667871862957161709568,39667881862957161709568,39667891862957161709568,39667901862957161709568,39667911862957161709568,39667921862957161709568,58557331862957161709568,58557341862957161709568,58557351862957161709568,58557361862957161709568,58557371862957161709568,58557381862957161709568,58557391862957161709568,58557401862957161709568,58557411862957161709568,58557421862957161709568
for t in S M; do
  [ -e $L/stop ] && exit 0
  export NICE_TEST_JOIN_LIST=$TILES; n=t_${t}_b64_tile_r1
  $R $n $t 64 20 1e16; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1)"
done
source /root/b64/scripts/cfg.sh
export NICE_TEST_JOIN_LIST=${A[3]},${A[5]}
echo SCREEN_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 1 ]; then V=("${V1[@]}"); else V=(); for ((i=${#V1[@]}-1; i>=0; i--)); do V+=("${V1[$i]}"); done; fi
  for v in "${V[@]}"; do
    [ -e $L/stop ] && exit 0
    setcfg $v || continue
    for try in 0 1 2; do
      n=s_${v}_r$r; $R $n $BIN 64 2 1e16; bash /root/b64/scripts/jit.sh $n
      sp=$(grep -c "join_kernel.*local=[1-9]" $L/${n}_jit.txt)
      echo "$(date -u +%T) $n try=$try $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/$n.log | tail -1) $(grep -o 'join_kernel.*regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1 | grep -o 'regs.*')"
      if [ "$sp" -gt 0 ] && [ $try -lt 2 ]; then for e in log smi _jit.txt; do s=$e; [ $e = _jit.txt ] || s=.$e; mv $L/$n$s $L/${n}_spill$try$s; done; else break; fi
    done
  done
done
echo SCREEN_DONE $(date -u +%T)
