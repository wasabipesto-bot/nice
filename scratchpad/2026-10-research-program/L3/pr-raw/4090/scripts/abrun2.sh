#!/bin/bash
# final: main / rb / fd interleaved
P=/root/runs/ab_final
mkdir -p $P
/root/ab_win.sh $P/win 2000000000 3 3 main rb fd
/root/ab_win.sh $P/win25 2000000000 25 3 main rb fd
/root/ab_prod.sh $P/prod 8 3 main rb fd
/root/ab_nicemark.sh $P/nm 150 3 main rb fd
echo done > $P/done
