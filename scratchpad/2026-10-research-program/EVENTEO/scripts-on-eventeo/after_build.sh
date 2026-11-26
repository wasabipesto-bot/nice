#!/bin/bash
# after_build.sh: wait for build_mo.sh mo-mode, then the RTX 3060 run (exactness, timing, the client mode) and a
# memory probe on the GTX 1060.
. "$(dirname "$(readlink -f "$0")")/env.sh"
until [ -f $R/logs/mo-mode/done ]; do sleep 10; done
grep -q "rc=[1-9]" $R/logs/mo-mode/rc.txt && { echo "build failed" > $R/runs/r1_blocked; exit 1; }
bash $R/scripts/run_mo.sh mo-mode 1 r1-3060 abc
bash $R/scripts/run_mo.sh mo-mode 0 r1-1060 m
