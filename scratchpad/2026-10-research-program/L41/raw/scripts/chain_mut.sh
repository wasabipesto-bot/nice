#!/bin/bash
# chain_mut.sh: after P, the RC mutant test binary X4 (tree X with NICE_EXP_JOIN_RCV=2 = no range test), niced.
L=/root/l41/logs
until [ -e $L/p_P.done ]; do sleep 10; done
NICEN=15 J=10 /root/l41/build.sh X X4 > $L/build_X4.out 2>&1; cat $L/build_X4.out
touch $L/mut_built.done
