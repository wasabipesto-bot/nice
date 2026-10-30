#!/bin/bash
# main vs rb, before the fd branch exists
P=/root/runs/ab_rb
mkdir -p $P
/root/ab_win.sh $P/win 2000000000 3 3 main rb
/root/ab_win.sh $P/win25 2000000000 25 3 main rb
/root/ab_prod.sh $P/prod 8 3 main rb
/root/ab_nicemark.sh $P/nm 150 3 main rb
echo done > $P/done
