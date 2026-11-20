#!/bin/bash
# box: cpuslice.sh OUT BIN — the sampled check's CPU slice (threaded_slice_join_real_slices) at bases 65 and 64 on
# 1, 2, 3, 4, 5 and 16 threads (this box: 16 visible, a ~5-CPU quota), each equal to the 1-thread run in every count
# and in the survivors' order. Nothing else running.
set -u; O=/root/runs/$1; X=$2; mkdir -p $O; rm -f $O/done; md5sum $X > $O/bins.txt; nproc > $O/nproc.txt; cat /sys/fs/cgroup/cpu.max >> $O/nproc.txt
s0=$(date +%s); MIDOUT_CPU_THREADS=${TH:-1,2,3,4,5,16} MIDOUT_CPU_SLICES=${SL:-65:717171717,64:712012851} $X --ignored --exact midout::cpu::tests::threaded_slice_join_real_slices --nocapture --test-threads 1 > $O/run.txt 2>&1
echo "rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; echo done > $O/done
