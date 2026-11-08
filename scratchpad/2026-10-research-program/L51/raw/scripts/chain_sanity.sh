#!/bin/bash
# chain_sanity.sh: every config once at 1e14 (b62 then b60 in one process); counts must equal base's (and B's).
source /root/l51/cfg.sh
R=/root/l51/run.sh; L=/root/l51/logs
echo SANITY_START $(date -u +%T)
for cf in base c a b p z d ept1 ept3 tm128 tm256 tm512 ag2 ag8 tc128 tc512 fd128 fd512 stg1 fl256 fl768 spc B; do
  if [ $cf = B ]; then until [ -e /root/l51/build_B.done ]; do sleep 5; done; fi
  [ -e $L/stop ] && { echo STOPPED; exit 0; }
  setcfg $cf || continue
  $R san_$cf $BIN 62,60 1 1e14
  echo "$(date -u +%T) san_$cf $(grep -o 'base=[0-9]* fields.*survivors=[0-9]* checked=[0-9]*' $L/san_$cf.log | sed 's/fields=.*survivors/survivors/' | tr '\n' ' ') $(grep -c 'test result: ok' $L/san_$cf.log)"
done
echo SANITY_DONE $(date -u +%T) | tee $L/sanity.done
