#!/bin/bash
# verification after the pad-row and clipped-survivor fixes (CUDA), then session 4 timings
cd /root/mo/nice/common
T=/root/mo/t-wide/release/build/nice_common/c29ae11497f8b508/out/nice_common-c29ae11497f8b508
B=/root/mo/t-wide/release/examples/midout_wide_bench
L=/root/mo/logs/v2
mkdir -p $L
md5sum $T $B > $L/bin_md5.txt
r() { echo "$(date -u +%FT%TZ) start $1" >> $L/runs.log; shift; "$@"; echo "$(date -u +%FT%TZ) end rc=$?" >> $L/runs.log; }
r brute sh -c "MIDOUT_CUDA=1 $T --ignored --nocapture midout::gpu_wide::tests::wide_whole_small > $L/brute.log 2>&1"
r slices sh -c "MIDOUT_CUDA=1 MIDOUT_WIDE_CASES=30:2:5:100,30:1:5:5000,40:3:6:1234,40:2:6:7,50:4:8:77777,64:4:10:712012851,65:4:10:717171717,65:4:10:532260419,65:4:10:0 $T --ignored --nocapture midout::gpu_wide::tests::wide_slices_equal_cpu > $L/slices.log 2>&1"
r staged sh -c "MIDOUT_CUDA=1 MIDOUT_SU_DIR=/root/mo/staged/su65_717171717 $T --ignored --nocapture midout::gpu_wide::tests::wide_slice_vs_staged > $L/staged.log 2>&1"
cd /root/mo
M=/root/mo/logs/m4
mkdir -p $M
md5sum $B > $M/bin_md5.txt
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,power.limit --format=csv -l 1 > $M/smi.csv 2>&1 &
SMI=$!
echo "$(date -u +%FT%TZ) start b64 warm" >> $M/runs.log
$B --cuda --base 64 --narrow --fields 4095,13107,131072,249036,65536,196608 > $M/b64_warm.log 2>&1
echo "$(date -u +%FT%TZ) b64 done rc=$?" >> $M/runs.log
$B --cuda --base 65 --fields 4095,13731,77777,137312,200000,260893 > $M/b65_warm.log 2>&1
echo "$(date -u +%FT%TZ) b65 done rc=$?" >> $M/runs.log
kill $SMI
echo "$(date -u +%FT%TZ) end" >> $M/runs.log
