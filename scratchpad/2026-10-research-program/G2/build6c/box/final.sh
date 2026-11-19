#!/bin/bash
# box: final.sh — the head's verification in one session, one thing at a time: the final binaries (finbuild.sh),
# `just lint`'s commands and the middle-out feature sets (lint.sh), tiers (a) and (b) on lavapipe with both
# compilers (tiers.sh), the card tier on CUDA (card.sh), then the ten-field timing against the trunk alone (ten.sh)
bash /root/finbuild.sh
bash /root/lint.sh lint_head
bash /root/tiers.sh head
bash /root/card.sh card_head
bash /root/ten.sh ten_head
echo done > /root/runs/final.done
