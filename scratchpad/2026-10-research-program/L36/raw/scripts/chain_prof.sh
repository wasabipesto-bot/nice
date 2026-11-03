#!/bin/bash
# chain_prof.sh: NICE_EXP_GPU_PROFILE=1 on all5 + profile commits (PR): b62 1e17 (1 field), b60 1e16 (2 fields);
# then (if built) main + 2ab1694 (MPR) on the same fields.
R=/root/l36/run.sh; L=/root/l36/logs
until [ -e $L/ab.done ] && [ -e $L/PR.built ] && [ -e $L/go_prof ]; do sleep 10; done
export NICE_EXP_GPU_PROFILE=1
SRCD=PR $R prof_S_e17_b62 PR 62 1 1e17
SRCD=PR $R prof_S_e16_b60 PR 60 2 1e16
if [ -e /root/l36/bin/MPR ]; then
  SRCD=MP $R prof_M_e17_b62 MPR 62 1 1e17
  SRCD=MP $R prof_M_e16_b60 MPR 60 2 1e16
fi
echo PROF_DONE $(date -u +%T) > $L/prof.done
