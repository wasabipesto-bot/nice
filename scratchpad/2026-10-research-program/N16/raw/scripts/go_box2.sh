#!/bin/sh
# go_box2.sh (the RTX 3080, CUDA, after go_box.sh): the branch head's binary (N16b, with the stage switch) through
# the window's geometry chain (round 2, PFX0=b2.), the b62 geometry chain, the dense compare of the stage modes,
# and Task D's chain (M against D; both take the denser plan on CUDA, so this is an A/A of the script).
export DEV=cuda NB=N16b
S=${SCRIPTS:-/root/n16/scripts}
{
echo "BOX2_START $(date -u +%T)"
PFX0=b2. ROUND=2 sh $S/chain_geo.sh
PFX0=b2. ROUND=1 sh $S/chain_geo62.sh
XPFX=xcu60 NX=8 XFIELD=60:1447429612114824200908:1e16 sh $S/chain_x.sh "sc512 sc256 tcsc"
XPFX=xcu62 NX=4 XFIELD=62:7520566762397899821056:1e17 sh $S/chain_x.sh "sc512 sc256 tcsc"
PFX0=b2. sh $S/chain_D.sh
echo "BOX2_DONE $(date -u +%T)"
} > ${OUT:-/root/n16/out}/go_box2.out 2>&1
