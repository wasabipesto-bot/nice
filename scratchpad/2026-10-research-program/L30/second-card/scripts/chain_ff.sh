#!/bin/bash
# Fixed fields, interleaved per round main / #235 / #236 / both; nothing else runs meanwhile.
R=/root/run.sh; L=/root/sc
for r in 1 2 3; do for t in main p235 p236 both; do $R ff_${t}_e17_b62_r$r $t 62 1 1e17; done; done
echo FF_E17_DONE $(date -u +%T) > $L/ffE17.done
for r in 1 2 3; do for t in main p235 p236 both; do $R ff_${t}_e16_b62_r$r $t 62 2 1e16; done; done
for r in 1 2 3; do for t in main p235 p236 both; do $R ff_${t}_e16_b60_r$r $t 60 2 1e16; done; done
for r in 1 2; do for t in main both; do $R ff_${t}_e16_b64_r$r $t 64 2 1e16; done; done
echo CHAIN_FF_DONE $(date -u +%T) > $L/chainFF.done
