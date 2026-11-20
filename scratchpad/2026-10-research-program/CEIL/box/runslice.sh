#!/bin/bash
# box: runslice.sh <base> <pip> <threads> [greedy] — one slice through mo_ceiling, raw to /w/raw/s_<base>_<pip>.txt
B=$1; P=$2; T=$3; G=$4
O=/w/raw/s_${B}_${P}.txt
echo "CMD /w/tceil/release/examples/mo_ceiling $B $P $T $G  (exp/mo-ceiling $(cd /w/ceil && git rev-parse --short HEAD) + working tree)" > $O
date -u >> $O
/w/tceil/release/examples/mo_ceiling $B $P $T $G >> $O 2> /w/raw/s_${B}_${P}.err
echo "rc=$?" >> $O; date -u >> $O
