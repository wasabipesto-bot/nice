#!/bin/bash
# Restart of chain_prab.sh's wait: also wait for clippy on the head (clippy_head.done).
L=/root/l35/logs
until [ -e $L/clippy_head.done ]; do sleep 10; done
exec /root/l35/chain_prab.sh
