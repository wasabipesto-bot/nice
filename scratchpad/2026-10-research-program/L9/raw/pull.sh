#!/bin/bash
# pull.sh: copy /root/l9/ from both boxes into L9/raw/<card>/
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/L9/raw
for p in "27692 ssh5 h100" "36822 ssh4 l40s"; do set -- $p
  mkdir -p $D/$3
  timeout 60 rsync -a -e "ssh -o StrictHostKeyChecking=no -o BatchMode=yes -p $1" root@$2.vast.ai:/root/l9/ $D/$3/ 2>&1 | grep -v "Welcome\|Have fun"
  echo "$3: $(ls $D/$3 | wc -l) files"
done
