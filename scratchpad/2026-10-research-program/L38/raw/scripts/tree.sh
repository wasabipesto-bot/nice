#!/bin/bash
# tree.sh NAME REF: (re)create /root/l38/src/NAME at the fork's REF (fetching it first); log trees.txt.
cd /root/nice && git fetch -q origin "$2" && git worktree remove --force /root/l38/src/$1 2>/dev/null
git worktree add -q --detach /root/l38/src/$1 FETCH_HEAD && (cd /root/l38/src/$1 && echo "$1 $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs) $(date -u +%T)") >> /root/l38/logs/trees.txt
tail -1 /root/l38/logs/trees.txt
