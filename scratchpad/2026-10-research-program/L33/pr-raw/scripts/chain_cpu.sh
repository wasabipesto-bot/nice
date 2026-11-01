#!/bin/bash
# Builds, in priority order: B and A CUDA test binaries, the two clients, then the lavapipe binaries.
L=/root/l33p/logs; S=/root/l33p
$S/build.sh B B gpu || exit 1
echo B_DONE $(date -u +%T) > $L/b.done
$S/build.sh A A gpu || exit 1
echo A_DONE $(date -u +%T) > $L/a.done
$S/buildclient.sh B client_B || exit 1
$S/buildclient.sh A client_A || exit 1
echo CLIENTS_DONE $(date -u +%T) > $L/clients.done
J=10 $S/build.sh B B_naga cubecl || exit 1
J=10 $S/build.sh B B_spv cubecl-spirv || exit 1
echo BLVP_DONE $(date -u +%T) > $L/blvp.done
J=10 $S/build.sh A A_spv cubecl-spirv || exit 1
echo LVPBUILDS_DONE $(date -u +%T) > $L/lvpbuilds.done
