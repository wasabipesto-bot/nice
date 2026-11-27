#!/bin/bash
# ab.sh RUN BASE NEW RT "STOPS" ROUNDS: alternating baseline and change (bench tags under bin/, midout_wide_bench),
# base 65 (warm-up 13731, field 77777), for each stop in STOPS (6 = the whole field), ROUNDS rounds; RTX 3060.
. "$HOME/research/scripts/env.sh"
RUN=$1; BASE=$2; NEW=$3; RT=$4; STOPS=$5; ROUNDS=${6:-2}
S=$R/b65/scripts; W65="--base 65 --fields 13731,77777 --group 16"
for r in $(seq 1 $ROUNDS); do
  for st in $STOPS; do
    E=""; [ "$st" != 6 ] && E="MIDOUT_STOP=$st"
    bash $S/run_b65.sh $RUN ${RT}_base_s${st}_$r $BASE/midout_wide_bench $RT $E -- $W65
    bash $S/run_b65.sh $RUN ${RT}_new_s${st}_$r $NEW/midout_wide_bench $RT $E -- $W65
  done
done
echo done > $R/runs/$RUN/done
