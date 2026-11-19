#!/bin/bash
# box: side request — the coordinator's branch pr/queue-test-plane-width in its own clone /root/qtest, own target
# dir /root/t/qtest: `just lint`'s three commands, then the two stride tests on lavapipe with WGSL and SPIR-V
source ~/.cargo/env; O=/root/runs/qtest; mkdir -p $O; rm -f $O/done
rm -rf /root/qtest; git clone -q /root/mc /root/qtest && cd /root/qtest
git fetch -q https://github.com/wasabipesto-bot/nice.git pr/queue-test-plane-width && git checkout -q FETCH_HEAD
git log --oneline -2 > $O/head.txt; git status --short >> $O/head.txt
export CARGO_TARGET_DIR=/root/t/qtest
cargo fmt --all --check > $O/fmt.txt 2>&1; echo "fmt rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets -- -D warnings > $O/clippy1.txt 2>&1; echo "clippy default rc=$?" >> $O/rc.txt
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > $O/clippy2.txt 2>&1; echo "clippy gpu,cubecl-spirv rc=$?" >> $O/rc.txt
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
for f in cubecl cubecl-spirv; do
  cargo test --release -p nice_common --features $f -- --ignored --nocapture cubecl_queues_check_every_survivor_on_partly_filled_planes cubecl_dropped_launches_fail_the_field > $O/test_$f.txt 2>&1; echo "test $f rc=$?" >> $O/rc.txt
done
echo done > $O/done
