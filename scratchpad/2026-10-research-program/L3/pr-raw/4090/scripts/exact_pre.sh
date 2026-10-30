#!/bin/bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
O=/root/runs/exact_pre; mkdir -p $O
RB=/root/t_rb/release/deps/nice_common-c0034331d0049e16
EX=/root/t_exp/release/deps/nice_common-0eda1b7a3c812e0f
$RB --list --ignored 2>/dev/null | grep -iE "cuda|near_miss" > $O/rb_ignored_list.txt
$EX --list --ignored 2>/dev/null | grep -iE "fd" > $O/exp_fd_list.txt
$RB cubecl_cuda_reads_back_every_near_miss --ignored --exact --nocapture --test-threads 1 > $O/rb_readback.log 2>&1
$RB cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed --ignored --exact --nocapture --test-threads 1 > $O/rb_parity.log 2>&1
$EX cubecl_backend::tests::cubecl_cuda_fd_matches_cpu_detailed --ignored --exact --nocapture --test-threads 1 > $O/exp_fd_exact.log 2>&1
echo done > $O/done
