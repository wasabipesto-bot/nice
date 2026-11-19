#!/bin/bash
# box: wg2.sh TAG OUT KIND — CI-sized device tests on lavapipe, test binary t_KIND of TAG (wg = WGSL via naga,
# sc = CubeCL's SPIR-V compiler); the env-driven tests of the trunk at small sizes
X=/root/bin/$1/t_$3; O=/root/runs/$2; mkdir -p $O; rm -f $O/done; export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
run() { local n=$1; shift; s0=$(date +%s); env "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
run rebuild $X --ignored --exact midout::gpu::tests::gpu_check_rebuilds_the_survivors
run faults MIDOUT_CLASSES=4 AUDIT_SLICES=502136830 AUDIT_AGAIN=0 $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
run wide40 MIDOUT_WIDE_CASES=40:3:6:1234 $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
run widefaults40 MIDOUT_WIDE_FAULT_CASE=40:1234 MIDOUT_WIDE_FAULT_SHAPE=3:6 AUDIT_AGAIN=0 $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud
echo done > $O/done
