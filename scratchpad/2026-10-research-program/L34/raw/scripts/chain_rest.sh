#!/bin/bash
# Replaces chain_final.sh (killed at 07:02, to hold the A/B for a hybrid screen). client_F and F_naga were built by
# chain_final.sh; waits for its F_spv build, then fmt and lavapipe. The A/B is started separately.
L=/root/l34/logs; S=/root/l34
while pgrep -f "^/bin/bash /root/l34/build.sh F F_spv" > /dev/null; do sleep 5; done
[ -e /root/l34/bin/F_spv ] || { echo "F_spv missing"; exit 1; }
echo LVPBUILDS_DONE $(date -u +%T) > $L/lvpbuilds.done
( cd /root/l34/src/F && source ~/.cargo/env && cargo fmt --all --check; echo "fmt rc=$?" ) > $L/lint_fmt.log 2>&1
$S/chain_lvp.sh 4 > $L/chain_lvp.out 2>&1
echo REST_DONE $(date -u +%T) > $L/rest.done
