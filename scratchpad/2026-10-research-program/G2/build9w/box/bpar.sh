#!/bin/bash
# box: bpar.sh OUT TBOX — the wide path's exactness set on CUDA: slices against the CPU reference n for n and every
# count (b30 100, b40 1234, b50 77777, b64 forced wide 712012851, b65 717171717, 532260419 (the range's start's
# clipped top), 1160290624 (the last slice)); the same with the prefilter off (whole survivor sets) at b40 and b65;
# whole small bases against brute force; the wide fault test. Guarded.
set -u; O=/root/runs/$1; X=$2; mkdir -p $O; rm -f $O/done $O/rc.txt; source /root/guard.sh $O || exit 1
md5sum $X > $O/bins.txt
g() { n=$1; shift; s0=$(date +%s); env MIDOUT_CUDA=1 "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
g small MIDOUT_WIDE_CASES=30:2:5:100,40:3:6:1234,50:4:8:77777 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g b65 MIDOUT_WIDE_CASES=65:4:10:717171717,65:4:10:532260419,65:4:10:1160290624 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g nopf MIDOUT_NOPF=1 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g b64w MIDOUT_WIDE_CASES=64:4:10:712012851 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g brute $X --ignored --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force
g wfaults $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud
echo done > $O/done
