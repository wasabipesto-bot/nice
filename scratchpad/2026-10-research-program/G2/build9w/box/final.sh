#!/bin/bash
# box: final.sh — the head's verification in one session, one thing at a time: binaries (finbuild.sh), lint and the
# middle-out feature sets (quick.sh's first part via lint8.sh), production's CI suite (suite.sh), tiers (a) and (b)
# (tiers.sh), the card tier on CUDA (card.sh), the kernel sources of both heads (dumpcu.sh), the five-field timing
# (five.sh)
bash /root/finbuild.sh
bash /root/lint8.sh lint_head
bash /root/suite.sh
bash /root/tiers.sh head
bash /root/card.sh card_head
bash /root/dumpcu.sh base5a; bash /root/dumpcu.sh fin
diff /root/dump/base5a/cu_sums.txt /root/dump/fin/cu_sums.txt > /root/runs/cu_sums.diff; echo "cu_sums diff rc=$?" >> /root/runs/cu_sums.diff
bash /root/five.sh five_head
echo done > /root/runs/final.done
