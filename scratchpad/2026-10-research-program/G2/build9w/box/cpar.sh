#!/bin/bash
# box: cpar.sh OUT TBOX — the probe-digit packing's exactness set on CUDA (maxpop 18 at base 65, 17 at base 64 forced
# wide): base-65 slices 717171717 and 532260419 and base-64 slice 712012851 forced wide against the CPU reference n
# for n and every count, and the wide fault test at base 65; holds /root/gpu.lock (one GPU job at a time). Guarded.
set -u; O=/root/runs/$1; X=$2; mkdir -p $O; rm -f $O/done $O/rc.txt
until mkdir /root/gpu.lockd 2>/dev/null; do sleep 10; done; trap 'rmdir /root/gpu.lockd' EXIT
source /root/guard.sh $O || exit 1
md5sum $X > $O/bins.txt
g() { n=$1; shift; s0=$(date +%s); env MIDOUT_CUDA=1 "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
g b65 MIDOUT_WIDE_CASES=65:4:10:717171717,65:4:10:532260419 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g b64w MIDOUT_WIDE_CASES=64:4:10:712012851 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g wfaults $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud
echo done > $O/done
