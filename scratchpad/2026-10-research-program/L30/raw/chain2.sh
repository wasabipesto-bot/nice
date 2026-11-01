#!/bin/bash
# L30 round 2: b62 1e17 A/B (2 rounds), b60 1e16 A/B (3 rounds), kernel source dumps. Waits for chain1.
while [ ! -f /root/l30/chain1.done ]; do sleep 10; done
R=/root/l30run.sh
export BIN=/root/l30/l30
cd /root
$R c0_e17_b62_r1 62 1 1e17 0 0
$R pf_e17_b62_r1 62 1 1e17 0 256
for r in 1 2 3; do $R c0_e16_b60_r$r 60 2 1e16 0 0; $R pf_e16_b60_r$r 60 2 1e16 0 256; done
$R pf_e17_b62_r2 62 1 1e17 0 256
$R c0_e17_b62_r2 62 1 1e17 0 0
# kernel sources (CUDA C++ as CubeCL emits it), one 1e14 field each
for xm in 0 256; do CUBECL_DEBUG_LOG=/root/l30/cubecl_xm$xm.txt $R dump_$xm 62 1 1e14 0 $xm; done
echo CHAIN2_DONE $(date -u +%T) > /root/l30/chain2.done
