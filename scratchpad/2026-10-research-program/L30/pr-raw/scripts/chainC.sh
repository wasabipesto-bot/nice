#!/bin/bash
# A/B, interleaved A B A B A B per scenario (A = main, B = pr2). Nothing else runs meanwhile.
R=/root/run.sh
for r in 1 2 3; do $R ab_m_e16_b62_r$r main 62 2 1e16; $R ab_p_e16_b62_r$r pr2 62 2 1e16; done
for r in 1 2 3; do $R ab_m_e16_b60_r$r main 60 2 1e16; $R ab_p_e16_b60_r$r pr2 60 2 1e16; done
for r in 1 2 3; do $R ab_m_e16_b64_r$r main 64 2 1e16; $R ab_p_e16_b64_r$r pr2 64 2 1e16; done
for r in 1 2 3; do $R ab_m_e17_b62_r$r main 62 1 1e17; $R ab_p_e17_b62_r$r pr2 62 1 1e17; done
echo CHAIN_C_DONE $(date -u +%T) > /root/l30pr/chainC.done
