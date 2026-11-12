#!/bin/sh
# chain_D.sh (~9 min on the RX 9070 XT): Task D's binary (exp/n14-wgpu-dense-plan, label D) against upstream main
# 5b1d627 (label M) at b62 1e17 and b60 1e16, 3 rounds, order alternating; plain production kernels (mode c, but the
# binaries have no switches, so only NICE_EXP_HOSTACC is set and ignored).
. "${SCRIPTS:-$(dirname "$0")}/lib.sh"
for r in 1 2 3; do
  if [ $r = 2 ]; then T="D M"; else T="M D"; fi
  for t in $T; do PFX=D${t}_ one c b62 $r $t; PFX=D${t}_ one c b60 $r $t; done
done
echo "D_DONE $(date -u +%T)"
