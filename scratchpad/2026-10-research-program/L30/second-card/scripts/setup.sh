#!/bin/bash
# setup.sh: unpack the four git-archive trees, record the box (GPU, power limit, clocks, CPU quota).
L=/root/sc; mkdir -p $L
cd /root
for t in main p235 p236 both; do rm -rf /root/$t; tar xzf /root/src/$t.tar.gz -C /root; done
md5sum /root/src/*.tar.gz > $L/src_md5.txt
nproc > $L/nproc.txt; cat /sys/fs/cgroup/cpu.max >> $L/nproc.txt; lscpu | grep -E "Model name|^CPU\(s\)" >> $L/nproc.txt
free -g > $L/mem.txt; df -h /root > $L/disk.txt
nvidia-smi > $L/nvidia-smi.txt
nvidia-smi -q -d POWER,CLOCK,TEMPERATURE,PERFORMANCE > $L/power.txt
nvidia-smi --query-gpu=name,driver_version,pcie.link.gen.max,pcie.link.width.max,power.limit,power.default_limit,power.max_limit,clocks.max.sm,clocks.max.mem --format=csv > $L/gpu.csv
echo SETUP_DONE $(date -u +%T)
