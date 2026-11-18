#!/bin/sh
# copy the worktree's changed files to the box's clone (iteration only; commits move by bundle)
cd /home/claude/projects/nice/.worktrees/midout-wide
for f in $(git status --short | awk '{print $2}'); do
  scp -q -P 28120 "$f" root@ssh6.vast.ai:/root/mo/nice/"$f" 2>&1 | grep -v -e Welcome -e "Have fun"
done
echo pushed $(git status --short | wc -l) files
