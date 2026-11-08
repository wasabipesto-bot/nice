#!/bin/bash
L=/root/l47/logs
until [ -e $L/lint_F.done ]; do sleep 10; done
rm -f $L/lint_F.done
cd /root/nice && git fetch -q origin exp/check-d-pr && cd /root/l47/src/F && git checkout -q -f --detach acba8033 && git log --oneline -1 > $L/lintF_tree.txt
SRCD=F /root/l47/scripts/chain_lint.sh F > $L/lint_F.out 2>&1
