#!/bin/bash
# tree.sh NAME REF: worktree /root/l48/src/NAME at origin REF (fetched first).
L=/root/l48/logs; NAME=$1; REF=$2
cd /root/nice
git fetch -q origin "$REF" || exit 1
rm -rf /root/l48/src/$NAME; git worktree prune
git worktree add -q --detach /root/l48/src/$NAME FETCH_HEAD || exit 1
(cd /root/l48/src/$NAME && echo "$NAME $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs common/src/join_plan.rs | cut -c1-8 | tr '\n' ' ')") | tee -a $L/trees.txt
