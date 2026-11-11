#!/bin/bash
# chain_prof.sh: tree E profiled (L51's modes: c full, a AND only, z no AND, b walk w/o prefilter+stage, p walk+prefilter).
# b64 1e16: fields at 0.05, 0.35, 0.55 in one process, modes c a z b p, 2 rounds (order rotated);
# b64 1e17: c on 0.55 + 0.05, then a and z on 0.55.
source /root/b64/scripts/cfg.sh
R=/root/b64/scripts/run.sh; L=/root/b64/logs
F16=39667831862957161709568,51001531862957161709568,58557331862957161709568
F17C=58557331862957161709568,39667831862957161709568
F17=58557331862957161709568
echo PROF_START $(date -u +%T)
MODES=(c a z b p)
for r in 1 2; do
  for i in 0 1 2 3 4; do
    m=${MODES[$(( (i + 2 * (r - 1)) % 5 ))]}
    [ -e $L/stop ] && exit 0
    setcfg $m; export NICE_TEST_JOIN_LIST=$F16
    n=p_${m}_e16_r$r; $R $n E 64 3 1e16; bash /root/b64/scripts/jit.sh $n
    echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1)"
  done
done
for m in c a z; do
  [ -e $L/stop ] && exit 0
  setcfg $m; if [ $m = c ]; then export NICE_TEST_JOIN_LIST=$F17C; else export NICE_TEST_JOIN_LIST=$F17; fi
  n=p_${m}_e17_r1; $R $n E 64 1 1e17; bash /root/b64/scripts/jit.sh $n
  echo "$(date -u +%T) $n $(grep -o 'secs=[0-9.]* per_field=[0-9.]*' $L/$n.log | tail -1) $(grep -o 'regs=[0-9]* local=[0-9]*' $L/${n}_jit.txt | head -1)"
done
echo PROF_DONE $(date -u +%T)
