#!/bin/bash
# chain_build.sh: every binary, one build at a time (shared target dir, `cargo clean -p nice_common` before each).
B=/root/l36/build.sh; BC=/root/l36/buildclient.sh; L=/root/l36/logs
echo BUILD_START $(date -u +%T)
$B S S gpu; touch $L/S.built
$B M M gpu; touch $L/M.built
$B X X gpu; touch $L/X.built
$BC S client_S
$BC M client_M; touch $L/clients.built
$B PR PR gpu; touch $L/PR.built
CARGO_TARGET_DIR=/root/tgt_lvp $B S S_naga cubecl /root/tgt_lvp
CARGO_TARGET_DIR=/root/tgt_lvp $B S S_spv cubecl-spirv /root/tgt_lvp; touch $L/lvp.built
echo BUILDS_DONE $(date -u +%T) > $L/builds.done
