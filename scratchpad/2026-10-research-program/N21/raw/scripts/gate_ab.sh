#!/bin/bash
# gate_ab.sh: start the timed A/B (ab.sh, binary X3) only when every build and every untimed test has finished.
W=/root/n21
until grep -q BUILDS3_DONE $W/out/builds3.out && grep -q DENSE_DONE $W/out/dense1_X.out; do sleep 15; done
sleep 20; echo "GATE $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg) $(pgrep -c cargo) cargo, $(pgrep -c rustc) rustc"
BIN=X3 MODES="0 9 1 8 4 11 41 73" bash $W/scripts/ab.sh
