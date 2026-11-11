#!/bin/bash
cd /root/b64
until grep -q F2_DONE logs/chain_F2.out 2>/dev/null; do sleep 15; done
[ -e logs/stop ] || bash scripts/chain_P.sh > logs/chain_P.out 2>&1
