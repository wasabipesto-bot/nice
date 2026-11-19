#!/bin/bash
# verification chain for a tree built by build.sh; $1 = log dir (holds testbin.txt); $2 = "merge" or "port"
cd /root/midout/common; source ~/.cargo/env
L=$1; MODE=$2
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing" > $L/ABORT; exit 1; }
grep -E "nicenumbers" /etc/hosts > $L/hosts_block.txt
T=$(cat $L/testbin.txt)
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture ${TEST} > $L/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $L/runs.log; }
A=midout::gpu::audit; G=midout::gpu::tests; W=midout::gpu_wide::tests
TEST=$A::accounts_faults_are_loud run faults_cuda MIDOUT_CUDA=1
TEST=$G::gpu_slices_equal_cpu run parity_cuda MIDOUT_CUDA=1 MIDOUT_GPU_SLICES=712012851,1073741823
TEST=$A::audit_stop_env_is_loud run stop_env MIDOUT_CUDA=1
TEST=$A::audit_oom_is_loud run oom_inproc_9216 MIDOUT_CUDA=1 AUDIT_FILL_MB=9216
TEST=$W::wide_whole_small_bases_vs_brute_force run wide_brute MIDOUT_CUDA=1
TEST=$W::wide_slices_equal_cpu run wide_slices MIDOUT_CUDA=1 MIDOUT_WIDE_CASES=30:2:5:100,40:3:6:1234,50:4:8:77777,64:4:10:712012851,65:4:10:717171717,65:4:10:532260419
if [ "$MODE" = port ]; then
  for t in $EXTRA; do TEST=$W::$t run $t MIDOUT_CUDA=1; done
fi
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
TEST=$G::gpu_slices_equal_cpu run lvp_parity MIDOUT_CLASSES=4 MIDOUT_GPU_SLICES=712012851
TEST=$W::wide_slices_equal_cpu run lvp_wide MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717
unset VK_ICD_FILENAMES
echo done > $L/chain_done
