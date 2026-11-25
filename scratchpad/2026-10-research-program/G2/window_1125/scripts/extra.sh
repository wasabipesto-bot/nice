#!/bin/sh
# extra.sh: window 3, after tasks 1-5 (time left): two more rounds around a second main bracket (task 1's ratio
# moved between rounds: 1.030 / 1.004 / 1.107), then the wide bench at base 64 with --narrow (wide and narrow path
# alternating in one process) to see whether the wide path's low clock at base 65 (task 3) follows the path or the base
. "$(dirname "$(readlink -f "$0")")/env.sh"
S=$SCRIPTS; : "${END_AT:?set END_AT}"
ok() { [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT"; exit 0; }; }
echo "EXTRA_START $(date -u +%T)"
ok; sh $S/run_b.sh b_r4 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f2b $F2
ok; sh $S/run_b.sh b_r5 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f6b $F6
ok; sh $S/run_bw.sh w64_wn -- --base 64 --fields 4095,77777 --group 16 --narrow
echo "EXTRA_DONE $(date -u +%T)"
