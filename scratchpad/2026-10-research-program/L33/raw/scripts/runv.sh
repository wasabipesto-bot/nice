#!/bin/bash
# runv.sh NAME BIN ER BASES FIELDS SIZE: run.sh with NICE_EXP_TOP_ER=ER (empty = unset)
NAME=$1; BIN=$2; ER=$3; shift 3
if [ -n "$ER" ]; then export NICE_EXP_TOP_ER=$ER; else unset NICE_EXP_TOP_ER; fi
unset NICE_EXP_TOP_HIST
/root/l33/scripts/run.sh $NAME $BIN "$@"
