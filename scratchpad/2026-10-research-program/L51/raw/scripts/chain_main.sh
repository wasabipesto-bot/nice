#!/bin/bash
# chain_main.sh: 3 interleaved rounds; per round b62 1e17 (1 field) then b60 1e16 (2 fields); modes c a b p z d (profiled),
# u (E unprofiled), B (d813aea unprofiled); the order rotates by 3 each round.
source /root/l51/cfg.sh
R=/root/l51/run.sh; L=/root/l51/logs
until [ -e $L/sanity.done ] || [ -e $L/stop ]; do sleep 10; done
echo MAIN_START $(date -u +%T)
MODES=(c a b p z d u B)
for r in 1 2 3; do
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for i in 0 1 2 3 4 5 6 7; do
      m=${MODES[$(( (i + 3 * (r - 1)) % 8 ))]}
      [ -e $L/stop ] && { echo STOPPED $(date -u +%T); exit 0; }
      setcfg $m
      $R m_${m}_$4_r$r $BIN $1 $2 $3
      echo "$(date -u +%T) m_${m}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/m_${m}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/m_${m}_$4_r$r.log | tail -1)"
    done
  done
  touch $L/main_r$r.done
done
echo MAIN_DONE $(date -u +%T) | tee $L/main.done
