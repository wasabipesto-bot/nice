#!/bin/bash
# box: gate.sh TAG — every tier on /root/mc as it stands: `just lint` and the middle-out clippy sets (lint8.sh),
# production's CI test commands (suite.sh, on a copy at /root/mc's HEAD: run only on a committed tree), tiers (a)
# and (b) on lavapipe through WGSL and SPIR-V (tiers.sh), the card-tier binary (bbox.sh, no benches) and the card
# tier (card9.sh). Output /root/runs/{lint_,suite_,,card_}TAG.
T=$1
bash /root/lint8.sh lint_$T
[ -n "${NOSUITE:-}" ] || { bash /root/suite.sh; rm -rf /root/runs/suite_$T; cp -r /root/runs/suite_head /root/runs/suite_$T; }
bash /root/tiers.sh $T
NOBENCH=1 bash /root/bbox.sh g_$T
bash /root/card9.sh card_$T /root/bin/g_$T/t_box
echo done > /root/runs/gate_$T.done
