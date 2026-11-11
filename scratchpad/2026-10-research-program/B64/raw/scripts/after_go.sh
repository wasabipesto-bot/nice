#!/bin/bash
# after_go.sh: after go.sh: chain_F (FD at b64) if SF built, then chain_B (Task B).
cd /root/b64
until [ -e logs/go.done ]; do sleep 10; done
grep -q BUILD_DONE logs/build_SF.out && bash scripts/chain_F.sh > logs/chain_F.out 2>&1
[ -e logs/stop ] || bash scripts/chain_B.sh > logs/chain_B.out 2>&1
