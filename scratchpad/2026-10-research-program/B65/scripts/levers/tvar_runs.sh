#!/bin/bash
# tvar_runs.sh: wtops2 variants (scratch MIDOUT_TVAR: 0 as built, 1 permuted order, 2 no atomic (slot = entry),
# 3 atomic but slot = entry) at the cumulative sub-stops 3 (through wscan) and 4 (+ wtops2), grid cap MIDOUT_TCAP.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; RUN=levers-tvar; BIN=l-tvar/midout_wide_bench
W65="--base 65 --fields 13731,77777 --group 16"
for c in 0:0:3 0:0:4 0:2:4 0:3:4 1024:0:3 1024:0:4 1024:1:4; do
  cap=${c%%:*}; rest=${c#*:}; v=${rest%:*}; ts=${rest#*:}
  bash $S/run_b65.sh $RUN cuda_c${cap}_v${v}_t$ts $BIN cuda MIDOUT_STOP=1 MIDOUT_TSTOP=$ts MIDOUT_TCAP=$cap MIDOUT_TVAR=$v -- $W65
done
echo done > $R/runs/$RUN/done
