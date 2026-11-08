#!/bin/bash
# fix_chain.sh REV: the review fixes on box 59687089. Tree F = fork exp/check-d-fixes (or pr/check-d) at REV.
# 1. fmt check; CUDA test binary FX; host tests (+ exhaustive); count/probe/gated test on CUDA; check_all; b62 1e14 COMPARE.
# 2. lavapipe binaries (naga, direct SPIR-V) and the count test on each. 3. clippy x3.
set -u
L=/root/l47/logs; S=/root/l47/scripts; REV=$1
mkdir -p $L /root/l47/bin /root/l47/src /root/l47/run /root/l47/ptx
cd /root/nice && git fetch -q origin exp/check-d-fixes pr/check-d 2>/dev/null
if [ -d /root/l47/src/F ]; then cd /root/l47/src/F && git checkout -q -f --detach $REV; else git worktree add -q --detach /root/l47/src/F $REV; fi
cd /root/l47/src/F && git log --oneline -1 > $L/fix_tree_$REV.txt
( nproc; cat /sys/fs/cgroup/cpu.max; nvidia-smi --query-gpu=name,driver_version,power.limit --format=csv; /usr/local/cuda/bin/nvcc --version | tail -2 ) > $L/box-info.txt 2>&1
source ~/.cargo/env
echo FIX_START $REV $(date -u +%T)
( cd /root/l47/src/F && cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_$REV.log 2>&1
tail -1 $L/fmt_$REV.log
J=6 $S/build.sh F FX_$REV gpu /root/tgt || exit 1
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( cd /root/l47/src/F && /root/l47/bin/FX_$REV join_check:: ; NICE_TEST_CHECK_EXHAUSTIVE=1 /root/l47/bin/FX_$REV --ignored --exact join_check::tests::magic_quotients_are_exact_everywhere --nocapture ) > $L/fx_unit_$REV.log 2>&1 &
UNIT=$!
SRCD=F $S/test.sh fx_counts_$REV FX_$REV cubecl_join::tests::cubecl_cuda_check_counts_match_the_cpu X=1
SRCD=F $S/test.sh fx_ref_$REV FX_$REV cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
NICE_TEST_JOIN_COMPARE=1 SRCD=F $S/run.sh fx_cmp_$REV FX_$REV 62 1 1e14
wait $UNIT
echo CUDA_DONE $(date -u +%T)
NICEN=5 J=6 $S/build.sh F FN_$REV cubecl /root/tgt_lvp && NICEN=5 J=6 $S/build.sh F FS_$REV cubecl-spirv /root/tgt_lvp
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) RUST_BACKTRACE=1
for c in FN FS; do
  ( date -u; cd /root/l47/src/F && timeout 3000 /root/l47/bin/${c}_$REV --ignored --exact cubecl_join::tests::cubecl_check_counts_match_the_cpu --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_${c}_$REV.log 2>&1 &
done
wait
echo LVP_DONE $(date -u +%T)
cd /root/l47/src/F
export CARGO_TARGET_DIR=/root/tgt_clippy
( nice -n 5 cargo clippy -j 6 -p "*" --all-targets -- -D warnings; echo "clippy default rc=$?" ) > $L/clippy_default_$REV.log 2>&1
( nice -n 5 cargo clippy -j 6 -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy gpu rc=$?" ) > $L/clippy_gpu_$REV.log 2>&1
( nice -n 5 cargo clippy -j 6 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings; echo "clippy gpu+spirv rc=$?" ) > $L/clippy_gpuspv_$REV.log 2>&1
echo FIX_DONE $REV $(date -u +%T) | tee $L/fix_$REV.done
