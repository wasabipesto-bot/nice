#!/bin/bash
# box: card.sh OUT — the card tier on the RTX 3080 (CUDA) with /root/bin/fin/t_box, then the client's --help (M7);
# sources guard.sh first (production hosts mapped and unreachable, or nothing runs)
set -u; O=/root/runs/$1; mkdir -p $O; rm -f $O/done; source /root/guard.sh $O || exit 1
X=/root/bin/fin/t_box; md5sum $X > $O/bins.txt
g() { n=$1; shift; s0=$(date +%s); env MIDOUT_CUDA=1 "$@" --nocapture --test-threads 1 > $O/$n.txt 2>&1; echo "$n rc=$? $(( $(date +%s) - s0 )) s" >> $O/rc.txt; }
g tier_b $X --ignored cubecl_midout
g slices MIDOUT_GPU_SLICES=712012851,502136830 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g slices_pf32 MIDOUT_GPU_SLICES=4977728 MIDOUT_PREFILTER=32 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g slices_pf24 MIDOUT_GPU_SLICES=4977728 MIDOUT_PREFILTER=24 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu
g faults $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
g share_faults $X --ignored --exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud
g wide_slices $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g wide_faults $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud
/root/bin/fin/nice_client --help > $O/client_help.txt 2>&1; echo "client --help rc=$? midout lines: $(grep -ci midout $O/client_help.txt)" >> $O/rc.txt
/root/bin/fin/nice_client --midout-coordinator http://127.0.0.1:9 niceonly > $O/client_flag.txt 2>&1; echo "client --midout-coordinator (no CubeCL build) rc=$?" >> $O/rc.txt
echo done > $O/done
