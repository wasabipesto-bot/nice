#!/bin/bash
# runs_vk2.sh: follow-up of the Vulkan load cells (07:17 UTC: b65 wide 6.34 -> 14.6 fs under 6 busy loops, the card
# at 24 % busy; b64 narrow +5 %). Which host work starves the card: MIDOUT_STOP=5 (every kernel but the check, and
# finish_group returns after the sync with no reads) quiet and under 6 loops; 6 loops at nice 19; 3 loops; group 64.
# Waits for chain1.sh (the CUDA stage profile) to finish.
. "$HOME/research/scripts/env.sh"
until [ -f $R/b65/chain1.done ]; do sleep 10; done
S=$R/b65/scripts; O=$R/runs/b65-loadvk; mkdir -p $O
W65="--base 65 --fields 13731,77777"
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $O/rc.txt; exit 0; }; }
busy() { P=""; for i in $(seq 1 $1); do nice -n $2 sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 nice $2 pids$P" >> $O/busy.pids; sleep 2; }
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() { n=$1; k=$2; ni=$3; e=$4; shift 4; stop; [ "$k" -gt 0 ] && busy $k $ni
  bash $S/run_b65.sh b65-loadvk $n $e vk "$@"; [ "$k" -gt 0 ] && unbusy; }
cell vw65_s5_q   0 0  head-spv/midout_wide_bench MIDOUT_STOP=5 -- $W65 --group 16
cell vw65_s5_b6  6 0  head-spv/midout_wide_bench MIDOUT_STOP=5 -- $W65 --group 16
cell vw65_b6n19  6 19 head-spv/midout_wide_bench -- $W65 --group 16
cell vw65_b3     3 0  head-spv/midout_wide_bench -- $W65 --group 16
cell vw65_b6g64  6 0  head-spv/midout_wide_bench -- $W65 --group 64
echo done > $O/done2
