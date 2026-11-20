#!/bin/bash
# box: q1.sh — after the first builds: the reference wide bench, the A tree benches, then the CPU-slice table
source ~/.cargo/env
until [ -f /root/logs/pre/done ] && [ -f /root/logs/a1/done ] && [ -f /root/logs/xd/done ]; do sleep 10; done
(cd /root/base && CARGO_TARGET_DIR=/root/t/base cargo build --release -p nice_common --features cubecl-cuda,midout-bench --example midout_wide_bench > /root/logs/pre/b_wbench.log 2>&1; echo "wbench rc=$?" >> /root/logs/pre/rc.txt; cp /root/t/base/release/examples/midout_wide_bench /root/bin/base/; md5sum /root/bin/base/* >> /root/logs/pre/rc.txt)
bash /root/bbox.sh a1b
bash /root/cpuslice.sh cpu_a1 /root/bin/a1b/t_box
echo done > /root/q1.done
