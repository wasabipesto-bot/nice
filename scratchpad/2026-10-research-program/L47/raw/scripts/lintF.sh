#!/bin/bash
# lint the fixed PR head in worktree F after P's lint chain has finished (same target dir, one at a time)
L=/root/l47/logs
until [ -e $L/lint_P.done ]; do sleep 10; done
cd /root/nice && git fetch -q origin exp/check-d-pr && cd /root/l47/src/F && git checkout -q -f --detach $1 && git log --oneline -1 > $L/lintF_tree.txt
SRCD=F /root/l47/scripts/chain_lint.sh F > $L/lint_F.out 2>&1
