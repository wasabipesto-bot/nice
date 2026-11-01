#!/bin/bash
# L30 round 3 (binary l30b = a6a0ffb): profiled ablation round 2 incl. walk-pf alone (768) and 32-bit pf (1280),
# A/B pf32 vs pf, b62 1e17 stats. Waits for chain2 and the l30b build.
while [ ! -f /root/l30/chain2.done ] || ! grep -q SETUP_DONE /root/l30/setup_l30b.out; do sleep 10; done
R=/root/l30run.sh
export BIN=/root/l30/l30b
cd /root
for xm in 0 2 4 8 16 32 256 768 1280; do $R ab${xm}_e16_b62_p2 62 2 1e16 1 $xm; done
for r in 1 2; do $R pf32_e16_b62_r$r 62 2 1e16 0 1280; $R pfb_e16_b62_r$r 62 2 1e16 0 256; done
$R st_e17_b62 62 1 1e17 0 1
echo CHAIN3_DONE $(date -u +%T) > /root/l30/chain3.done
