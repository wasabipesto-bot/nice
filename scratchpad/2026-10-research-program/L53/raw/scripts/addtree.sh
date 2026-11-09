#!/bin/bash
# addtree.sh NAME REF: worktree /root/l53/src/NAME at REF (fetched from the fork).
cd /root/nice
git fetch -q origin "+refs/heads/$3:refs/remotes/origin/$3" 2>/dev/null
git fetch -q origin
git worktree add -q --detach /root/l53/src/$1 $2 || { cd /root/l53/src/$1 && git checkout -q --detach $2; }
(cd /root/l53/src/$1 && echo "$1 $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") >> /root/l53/logs/trees.txt
