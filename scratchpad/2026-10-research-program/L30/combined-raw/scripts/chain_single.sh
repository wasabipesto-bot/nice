#!/bin/bash
# Extra: each PR alone at b62 1e17, interleaved #235 #236 per round, right after the main/both A/B (same box, same cap).
R=/root/run.sh; L=/root/cmb
for r in 1 2 3; do $R ab_a_e17_b62_r$r p235 62 1 1e17; $R ab_b_e17_b62_r$r p236 62 1 1e17; done
echo CHAIN_SINGLE_DONE $(date -u +%T) > $L/chainSingle.done
