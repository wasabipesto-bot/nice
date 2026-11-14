#!/bin/bash
# cuda.sh: the fix's CUDA build (FG, gpu features) on the box's RTX 3080 (host, not the chroot): every CUDA test of
# cubecl_backend, each in its own process, and the CUDA source of niceonly_kernel (compilation log).
B=/srv/r26/root/bin/FG; O=/root/w/out/cuda.out; mkdir -p /root/w/logs /root/w/cudadump; : > $O
export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
for t in $($B --list --ignored 2>/dev/null | grep -o 'cubecl_backend::tests::cubecl_cuda_[a-z0-9_]*'); do
  n=${t##*::}; ( [ "$n" = cubecl_cuda_queues_check_every_survivor_on_partly_filled_warps ] && export NICE_TEST_QUEUE_SCAN=1; timeout 1200 $B --ignored --exact $t --nocapture --test-threads=1 > /root/w/logs/FG_$n.log 2>&1; echo "$n rc=$? $(grep -h 'runs,\|test result' /root/w/logs/FG_$n.log | tr '\n' ' ')" >> $O )
done
cd /root/w/cudadump; printf '[compilation.logger]\nlevel = "full"\nfile = "/root/w/cudadump/cuda.log"\n' > cubecl.toml
timeout 600 $B --ignored --exact cubecl_backend::tests::cubecl_cuda_queue_faults_fail_the_field --nocapture > run.out 2>&1; rm cubecl.toml
echo "CUDA DONE $(date -u +%T)" >> $O
