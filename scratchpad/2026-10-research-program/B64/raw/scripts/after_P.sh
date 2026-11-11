#!/bin/bash
cd /root/b64
until grep -q P_DONE logs/chain_P.out 2>/dev/null; do sleep 15; done
[ -e logs/stop ] || { grep -q BUILD_DONE logs/build_EF.out && bash scripts/chain_PF.sh > logs/chain_PF.out 2>&1; }
