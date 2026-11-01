#!/bin/bash
# Extra (not in the requested protocol): b64 1e16 (2 fields), four-way main / #235 / #236 / both, 2 rounds,
# so the b64 compounding check uses single-PR numbers from this card too.
R=/root/run.sh; L=/root/sc
for r in 1 2; do for t in main p235 p236 both; do $R x4_${t}_e16_b64_r$r $t 64 2 1e16; done; done
nvidia-smi -q -d POWER,CLOCK,TEMPERATURE,PERFORMANCE > $L/power_after.txt
echo CHAIN_EXTRA_DONE $(date -u +%T) > $L/chainExtra.done
