#!/bin/bash
# chain_lvpbuild.sh W: lavapipe test binaries (naga, direct SPIR-V) and client_W, niced, own target dir for lavapipe.
L=/root/l43/logs; BIN=/root/l43/bin; W=$1
NICEN=15 J=10 /root/l43/build.sh $W ${W}_naga cubecl /root/tgt_lvp
NICEN=15 J=10 /root/l43/build.sh $W ${W}_spv cubecl-spirv /root/tgt_lvp
NICEN=15 /root/l43/buildclient.sh $W client_$W > $L/buildclient_$W.out 2>&1
touch $L/lvp_${W}.built
