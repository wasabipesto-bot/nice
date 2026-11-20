#!/bin/bash
# box: dumpwide.sh TAG — CubeCL's CUDA source of the wide path's kernels from /root/bin/TAG/t_box (the card-tier
# wide parity test, base 65 slice 717171717, CUBECL_DEBUG_LOG), normalised by cudanorm.py into wcu/, one md5 per
# kernel in wcu_sums.txt. Guarded (hosts proof).
T=$1; O=/root/dump/w_$T; rm -rf $O; mkdir -p $O; source /root/guard.sh $O || exit 1; X=/root/bin/$T/t_box
env MIDOUT_CUDA=1 CUBECL_DEBUG_LOG=$O/cudaw.log $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu --nocapture --test-threads 1 > $O/run.txt 2>&1
echo "wide rc=$?" >> $O/rc.txt
python3 /root/cudanorm.py $O/cudaw.log $O/wcu > $O/wcu_sums.txt
echo done > $O/done
