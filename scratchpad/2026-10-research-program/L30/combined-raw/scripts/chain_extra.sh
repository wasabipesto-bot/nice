#!/bin/bash
# Extra, after the profile: b64 1e16 (2 fields), four-way interleave main / #235 / #236 / both, 2 rounds,
# because b64 is the one field where the combined speed-up fell short of the product.
R=/root/run.sh; L=/root/cmb
until [ -e $L/chainProf.done ]; do sleep 10; done
for r in 1 2; do
  $R x4_m_e16_b64_r$r main 64 2 1e16
  $R x4_a_e16_b64_r$r p235 64 2 1e16
  $R x4_b_e16_b64_r$r p236 64 2 1e16
  $R x4_p_e16_b64_r$r both 64 2 1e16
done
echo CHAIN_EXTRA_DONE $(date -u +%T) > $L/chainExtra.done
