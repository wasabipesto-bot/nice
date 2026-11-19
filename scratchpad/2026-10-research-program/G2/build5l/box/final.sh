#!/bin/bash
# box: the head's verification: builds, fmt, clippy, suites, GPU tests, one route field; $1 = log dir (tree /root/m5w fast-forwarded to the head)
set -u
L=$1; mkdir -p $L; source /root/mo/guard.sh $L || exit 1
source ~/.cargo/env; cd /root/m5w; export CARGO_TARGET_DIR=/root/t/m5w
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
s() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; "$@" > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
s fmt cargo fmt --all --check
s b_tests cargo test --release -p nice_common --features cubecl-cuda,cubecl-spirv --lib --no-run
X=$(grep -o "/root/t/m5w/release/[^)]*nice_common-[0-9a-f]*" $L/b_tests.log | tail -1); mkdir -p /root/m5wbin/final; cp $X /root/m5wbin/final/tests; T=/root/m5wbin/final/tests
s b_client cargo build --release -p nice_client --features cubecl-cuda
cp /root/t/m5w/release/nice_client /root/m5wbin/final/nice_mo
s b_fields cargo build --release -p nice_common --example midout_fields
cp /root/t/m5w/release/examples/midout_fields /root/m5wbin/final/
md5sum /root/m5wbin/final/* > $L/bins.txt
g() { n=$1; shift; echo "$(date -u +%FT%TZ) start $n" >> $L/runs.log; env "$@" RUST_LOG=warn timeout 3000 $T --ignored --exact --nocapture $TEST > $L/$n.log 2>&1; rc=$?; echo "$(date -u +%FT%TZ) end $n rc=$rc" >> $L/runs.log; }
TEST=midout::gpu::tests::field_parent_sharing_is_exact_and_loud g share_faults MIDOUT_CUDA=1
TEST=midout::gpu::tests::field_485_equals_496_slice_by_slice g field485 MIDOUT_CUDA=1
TEST=midout::gpu::audit::accounts_faults_are_loud g faults MIDOUT_CUDA=1
TEST=midout::gpu::tests::gpu_slices_equal_cpu g parity MIDOUT_CUDA=1 MIDOUT_GPU_SLICES=712012851,4977728
TEST=midout::gpu::audit::audit_stop_env_is_loud g stop_env MIDOUT_CUDA=1
TEST=midout::gpu::audit::audit_oom_is_loud g oom MIDOUT_CUDA=1 AUDIT_FILL_MB=9216
# one route field, (4,8,5) t 77777 (expect survivors 48216914309, checked 1384731444)
R=$L/e2e; mkdir -p $R
/root/m5wbin/final/midout_fields --base 64 --t 77777 > $R/work.json
python3 /root/m5w/scripts/midout_coordinator.py --worklist $R/work.json --state $R/state --port 8476 2> $R/coord.log & CP=$!
sleep 1; /root/m5wbin/final/nice_mo niceonly --midout-coordinator http://127.0.0.1:8476 --repeat --username mo-e2e-local > $R/client.log 2>&1; echo "client rc=$?" > $R/run.log
kill $CP
s suite cargo test --release -p nice_common --lib
s client_def cargo test --release -p nice_client
s client_cuda cargo test --release -p nice_client --features cubecl-cuda
s clippy_def cargo clippy -p nice_common -p nice_client --all-targets -- -D warnings
s clippy_gpu cargo clippy -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings
s clippy_cl cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings
s clippy_clf cargo clippy -p nice_common -p nice_client --all-targets --features nice_client/cubecl-cuda,nice_client/midout-fault -- -D warnings
echo done > $L/done
