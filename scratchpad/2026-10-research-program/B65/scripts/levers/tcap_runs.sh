#!/bin/bash
# tcap_runs.sh: the tops stage (MIDOUT_STOP=1) with the top kernels' grids capped (scratch MIDOUT_TCAP; 0 = old
# grids), split by MIDOUT_TSTOP; base 65 wide, CUDA, RTX 3060; one cold process each.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; RUN=${RUN:-levers-tcap}; BIN=${BIN:-l-tcap-cuda/midout_wide_bench}; RT=${RT:-cuda}
W65="--base 65 --fields 13731,77777 --group 16"
for c in ${CELLS:-0:5 1024:5 256:5 4096:5 1024:2 1024:4 0:4}; do
  cap=${c%:*}; ts=${c#*:}
  bash $S/run_b65.sh $RUN ${RT}_c${cap}_t$ts $BIN $RT MIDOUT_STOP=1 MIDOUT_TSTOP=$ts MIDOUT_TCAP=$cap -- $W65
done
echo done > $R/runs/$RUN/done
