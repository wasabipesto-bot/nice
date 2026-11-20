#!/bin/bash
# box: q6cbatch.sh — after q6bbatch.sh: the q6c list (code, lex, L order, hybrid 3, each with Q4's sharing), raw /w/raw/q6c_<base>_<pip>.txt
until [ -f /w/raw/q6b.done ]; do sleep 20; done
for a in "64 712012851" "64 952265258" "65 767142814" "65 364171716"; do
  set -- $a
  O=/w/raw/q6c_$1_$2.txt
  echo "CMD /w/tceil/release/examples/mo_ceiling $1 $2 18 q6c" > $O
  date -u >> $O
  /w/tceil/release/examples/mo_ceiling $1 $2 18 q6c >> $O 2> /w/raw/q6c_$1_$2.err
  echo "rc=$?" >> $O; date -u >> $O
done
echo Q6CDONE > /w/raw/q6c.done
