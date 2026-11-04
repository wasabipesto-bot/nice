#!/bin/bash
# chain_screen.sh: after the test builds: client_M, then the S-vs-V screen against main (M), nothing else on the box:
# b62 1e16 and b60 1e16 (2 fields each, 2 rounds), b62 1e17 (1 field, 1 round); order M S V in every round.
R=/root/l38/run.sh; L=/root/l38/logs
until [ -e $L/build.done ]; do sleep 10; done
/root/l38/buildclient.sh M client_M > $L/buildclient_M.out 2>&1
echo SCREEN_START $(date -u +%T)
for r in 1 2; do
  for t in M S V; do SRCD=$t $R scr_${t}_e16_b62_r$r $t 62 2 1e16; done
  for t in M S V; do SRCD=$t $R scr_${t}_e16_b60_r$r $t 60 2 1e16; done
done
for t in M S V; do SRCD=$t $R scr_${t}_e17_b62_r1 $t 62 1 1e17; done
echo SCREEN_DONE $(date -u +%T) > $L/screen.done
