#!/bin/bash
# box: cudapar.sh TAG OUT — the base-64 parity and fault tests on the RTX 3080 (CUDA) with test binary t_sc of TAG:
# two whole slices n for n against the CPU reference, the check's rebuild of one class, and every fault loud.
X=/root/bin/$1/t_sc; O=/root/runs/$2; mkdir -p $O; rm -f $O/done
run() { local n=$1; shift; s0=$(date +%s); env MIDOUT_CUDA=1 "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
run slices env MIDOUT_GPU_SLICES=712012851,502136830 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
run rebuild $X --ignored --exact midout::gpu::tests::gpu_check_rebuilds_the_survivors
run faults $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
echo done > $O/done
