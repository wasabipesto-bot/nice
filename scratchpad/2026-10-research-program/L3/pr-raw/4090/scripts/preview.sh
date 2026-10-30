#!/bin/bash
P=/root/runs/preview
mkdir -p $P
/root/ab_win.sh $P/win 2000000000 3 1 main exp
/root/ab_prod.sh $P/prod 6 1 main exp
/root/ab_nicemark.sh $P/nm 150 1 main exp
echo done > $P/done
