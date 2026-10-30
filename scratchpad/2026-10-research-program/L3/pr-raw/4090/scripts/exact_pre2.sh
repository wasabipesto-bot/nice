#!/bin/bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
O=/root/runs/exact_pre
while [ ! -f $O/done ]; do sleep 5; done
RB=/root/t_rb/release/deps/nice_common-c0034331d0049e16
$RB cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss --ignored --exact --nocapture --test-threads 1 > $O/rb_readback.log 2>&1
$RB client_process_cuda::tests::gpu_reads_back_every_near_miss --ignored --exact --nocapture --test-threads 1 > $O/rb_readback_handcuda.log 2>&1
echo done > $O/done2
