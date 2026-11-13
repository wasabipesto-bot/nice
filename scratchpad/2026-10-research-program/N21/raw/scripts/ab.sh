#!/bin/bash
# ab.sh: the timed A/B on CUDA, one binary ($BIN, default X2), NICE_EXP_N21 modes $MODES (default first). Rounds
# $ROUNDS; per round each field runs every mode back to back, the order rotated by one each round. Every run starts at
# <= 60 C (run.sh). Nothing else runs on the box meanwhile. A file $W/stop ends it before the next run.
W=/root/n21; R=$W/scripts/run.sh; BIN=${BIN:-X4}
F60=1447429612114824200908; F62=7520566762397899821056; F64=58557331862957161709568
MODES=(${MODES:-0 9 1 8 4 11})
echo AB_START $(date -u +%T) bin=$BIN modes="${MODES[*]}"
for r in ${ROUNDS:-1 2 3}; do
  n=${#MODES[@]}; O=()
  for i in $(seq 0 $((n - 1))); do O+=(${MODES[$(( (i + r - 1) % n ))]}); done
  # (until 07:56 the default below was one quoted word, so the first A/B ran b62 only)
  for f in ${FIELDS:-b62:62:1:1e17:$F62 b60:60:1:1e16:$F60 b64:64:1:1e17:$F64}; do
    IFS=: read tag base nf size start <<< "$f"
    for m in "${O[@]}"; do
      [ -e $W/stop ] && { echo stopped; exit 0; }
      bash $R ab_m${m}_${tag}_r$r $BIN $m $base $nf $size $start
    done
  done
done
echo AB_DONE $(date -u +%T)
