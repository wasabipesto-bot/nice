#!/bin/bash
# step 3W verification for the tree at $3 (built by build.sh into log dir $1); $2 = label
L=$1; TREE=$3
cd $TREE/common; source ~/.cargo/env
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing" > $L/ABORT; exit 1; }
grep -E "nicenumbers" /etc/hosts > $L/hosts_block.txt
T0=$(cat $L/testbin.txt); cp $T0 $L/tbin; T=$L/tbin
run() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture ${TEST} > $L/$n.log 2>&1; echo "$(date -u +%FT%TZ) end $n rc=$?" >> $L/runs.log; }
A=midout::gpu::audit; G=midout::gpu::tests; W=midout::gpu_wide::tests
TEST=$W::wide_faults_are_loud run wfaults_b65 MIDOUT_CUDA=1
TEST=$W::wide_faults_are_loud run wfaults_b64 MIDOUT_CUDA=1 MIDOUT_WIDE_FAULT_CASE=64:712012851,0
TEST=$W::wide_stop_is_loud run wstop MIDOUT_CUDA=1
TEST=$W::wide_oom_is_loud run woom_8192 MIDOUT_CUDA=1 AUDIT_FILL_MB=8192
TEST=$W::wide_whole_small_bases_vs_brute_force run wide_brute MIDOUT_CUDA=1
TEST=$W::wide_slices_equal_cpu run wide_slices MIDOUT_CUDA=1 MIDOUT_WIDE_CASES=30:2:5:100,40:3:6:1234,50:4:8:77777,64:4:10:712012851,65:4:10:717171717,65:4:10:532260419,65:4:10:1160290624
TEST=$A::accounts_faults_are_loud run faults_cuda MIDOUT_CUDA=1
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json
TEST=$W::wide_faults_are_loud run lvp_wfaults MIDOUT_CLASSES=2 MIDOUT_WIDE_FAULT_CASE=40:1234 MIDOUT_WIDE_FAULT_SHAPE=3:6 AUDIT_AGAIN=0
TEST=$W::wide_slices_equal_cpu run lvp_wide MIDOUT_CLASSES=2 MIDOUT_WIDE_CASES=40:3:6:1234,65:4:10:717171717
unset VK_ICD_FILENAMES
echo done > $L/chain_done
