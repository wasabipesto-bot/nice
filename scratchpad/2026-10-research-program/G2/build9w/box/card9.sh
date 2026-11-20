#!/bin/bash
# box: card9.sh OUT TBOX — the card tier on the RTX 3080 (CUDA) with the given card-tier test binary: tier (b) on
# CUDA, slice parity at base 64 (two whole slices; one slice with each prefilter form), the narrow fault test, parent
# sharing, slice parity at base 65 and the wide fault test. Guarded (hosts proof).
# one GPU job at a time: wait for the lock, then hold it (mkdir is atomic)
until mkdir /root/gpu.lockd 2>/dev/null; do sleep 10; done; trap 'rmdir /root/gpu.lockd' EXIT
set -u; O=/root/runs/$1; X=$2; mkdir -p $O; rm -f $O/done $O/rc.txt; source /root/guard.sh $O || exit 1
md5sum $X > $O/bins.txt
g() { n=$1; shift; s0=$(date +%s); env MIDOUT_CUDA=1 "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
g tier_b $X --ignored cubecl_midout
g slices MIDOUT_GPU_SLICES=712012851,502136830 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g slices_pf32 MIDOUT_GPU_SLICES=4977728 MIDOUT_PREFILTER=32 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g slices_pf24 MIDOUT_GPU_SLICES=4977728 MIDOUT_PREFILTER=24 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g faults $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
g share_faults $X --ignored --exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud
g wide_slices $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g wide_faults $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud
echo done > $O/done
