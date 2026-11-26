#!/bin/bash
# runs_load.sh: the coordinator's added measurement (06:15 UTC): host CPU load against the wide (b65) and narrow
# (b64) paths, CUDA on the RTX 3060, sampled check off, warm-up then field 77777. Busy threads are plain shell loops
# started here, their PIDs recorded in $O/busy.pids and killed by PID right after each run.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; O=$R/runs/b65-load; mkdir -p $O
W65="--base 65 --fields 13731,77777 --group 16"; N64="--fields 4095,77777 --group 16 --no-cpu-check"
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $O/rc.txt; exit 0; }; }
busy() {  # busy N NICE: start N loops at nice NICE
  P=""; for i in $(seq 1 $1); do nice -n $2 sh -c 'while :; do :; done' & P="$P $!"; done
  echo "$(date -u +%T) busy $1 nice $2 pids$P" >> $O/busy.pids; sleep 2
}
unbusy() { for p in $P; do kill $p; done; wait $P 2>/dev/null; echo "$(date -u +%T) killed$P" >> $O/busy.pids; P=""; }
cell() {  # cell NAME NBUSY NICE EXE ARGS...
  n=$1; k=$2; ni=$3; e=$4; shift 4; stop
  [ "$k" -gt 0 ] && busy $k $ni
  bash $S/run_b65.sh b65-load $n $e cuda -- "$@"
  [ "$k" -gt 0 ] && unbusy
}
cell w65_q   0 0  mo-mode/midout_wide_bench $W65
cell w65_b3  3 0  mo-mode/midout_wide_bench $W65
cell w65_b6  6 0  mo-mode/midout_wide_bench $W65
cell n64_q   0 0  mo-mode/midout_bench --threads 5 $N64
cell n64_b3  3 0  mo-mode/midout_bench --threads 5 $N64
cell n64_b6  6 0  mo-mode/midout_bench --threads 5 $N64
# part 3: busy loops at nice 19; the narrow bench's host threads at 2 and 5 under 6 busy loops (the wide bench has
# no --threads: its host work runs on the calling thread)
cell w65_b6n19 6 19 mo-mode/midout_wide_bench $W65
cell n64_b6_t2 6 0  mo-mode/midout_bench --threads 2 $N64
cell n64_b6n19 6 19 mo-mode/midout_bench --threads 5 $N64
echo done > $O/done
