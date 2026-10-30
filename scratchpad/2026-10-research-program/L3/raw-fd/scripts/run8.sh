#!/bin/bash
O=/root/runs/fd
/root/tbuild.sh > $O/tbuild_final.log 2>&1
T=$(ls -t /root/tfast/release/deps/nice_common-* | grep -v '\.d$' | head -1)
echo "binary $T" > $O/exact_final.log
$T cubecl_cuda_fd_matches_cpu_detailed --ignored --nocapture --test-threads 1 >> $O/exact_final.log 2>&1
$T cubecl_cuda_matches_cpu_detailed --ignored --nocapture --test-threads 1 >> $O/exact_final.log 2>&1
cd /root/fd && git diff --stat >> $O/exact_final.log; md5sum common/src/cubecl_backend.rs >> $O/exact_final.log
echo done > $O/final.done
