#!/bin/bash
# L30 round 5: is the instrumented binary's xm=0 kernel at main's speed? bddf20f's binary (base) against l30 xm=0, interleaved.
R=/root/l30run.sh
cd /root
for r in 1 2; do BIN=/root/l30/base $R base_e16_b62_r$r 62 2 1e16 0; BIN=/root/l30/l30 $R c0_e16_b62_r$((r+3)) 62 2 1e16 0 0; done
echo CHAIN5_DONE $(date -u +%T) > /root/l30/chain5.done
