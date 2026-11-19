#!/bin/bash
# box: dumpcu.sh TAG — CubeCL's CUDA source of every narrow kernel from /root/bin/TAG/t_box (the card-tier test binary) (compile-only path of
# gpu_slices_equal_cpu at W 32 on the RTX 3080, CUBECL_DEBUG_LOG; one slice, one class, one batch), normalised by
# cudanorm.py (locals renamed in order of first use, shared-array offsets dropped, declarations sorted) into cu/,
# one md5 per kernel in cu_sums.txt. Guarded (hosts proof).
T=$1; O=/root/dump/$T; rm -rf $O; mkdir -p $O; source /root/guard.sh $O || exit 1; X=/root/bin/$T/t_box
env MIDOUT_GPU_SLICES=712012851 MIDOUT_CLASSES=1 MIDOUT_BATCHES=1 MIDOUT_FORCE_W=32 MIDOUT_CUDA=1 CUBECL_DEBUG_LOG=$O/cuda32.log \
  $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu --nocapture --test-threads 1 > $O/run_cuda32.txt 2>&1
echo "cuda32 rc=$?" >> $O/rc.txt
python3 /root/cudanorm.py $O/cuda32.log $O/cu > $O/cu_sums.txt
md5sum $X >> $O/rc.txt; echo done > $O/done
