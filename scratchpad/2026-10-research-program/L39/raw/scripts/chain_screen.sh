#!/bin/bash
# chain_screen.sh: after the builds, the screen of B against E and F: one round of b62 1e17 (order B E F), two rounds of
# b62 and b60 1e16 (2 fields each; order B E F, then F E B); nothing else on the box. Then client_B.
R=/root/l39/run.sh; L=/root/l39/logs
until [ -e $L/build.done ]; do sleep 10; done
echo SCREEN_START $(date -u +%T)
for t in B E F; do SRCD=$t $R scr_${t}_e17_b62_r1 $t 62 1 1e17; done
for r in 1 2; do
  if [ $r = 2 ]; then O="F E B"; else O="B E F"; fi
  for t in $O; do SRCD=$t $R scr_${t}_e16_b62_r$r $t 62 2 1e16; done
  for t in $O; do SRCD=$t $R scr_${t}_e16_b60_r$r $t 60 2 1e16; done
done
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
/root/l39/buildclient.sh B client_B > $L/buildclient_B.out 2>&1
