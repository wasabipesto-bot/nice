#!/bin/bash
T=/root/tfast/release/deps/nice_common-3897133ca1aa3ced
O=/root/runs/fd
while [ ! -f $O/exact5.done ]; do sleep 5; done
$T cubecl_cuda_matches_cpu_detailed --ignored --nocapture --test-threads 1 > $O/parity_existing.log 2>&1
$T --test-threads 8 > $O/libtests.log 2>&1
echo done > $O/run7.done
