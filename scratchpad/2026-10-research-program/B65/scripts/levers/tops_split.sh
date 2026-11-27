#!/bin/bash
# tops_split.sh: the tops stage (MIDOUT_STOP=1) split by the scratch sub-stop MIDOUT_TSTOP (0 no top kernel, 1 wtops5,
# 2 +wtops1, 3 +wscan, 4 +wtops2, 5 all = the stage), base 65 wide, CUDA, RTX 3060; one cold process each.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; RUN=${RUN:-levers-tops}; BIN=${BIN:-l-tstop-cuda/midout_wide_bench}; RT=${RT:-cuda}
W65="--base 65 --fields 13731,77777 --group 16"
for ts in ${TSTOPS:-5 0 1 2 3 4 5}; do
  bash $S/run_b65.sh $RUN ${RT}_t$ts $BIN $RT MIDOUT_STOP=1 MIDOUT_TSTOP=$ts -- $W65
done
echo done > $R/runs/$RUN/done
