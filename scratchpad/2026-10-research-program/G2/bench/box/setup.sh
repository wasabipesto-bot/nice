#!/bin/bash
# on box, first thing: block production hosts and prove it; record the card
mkdir -p /root/g2 && cd /root/g2
sh /root/g2/hosts_block.sh > /root/g2/proof_hosts_block.txt 2>&1
cat /root/g2/proof_hosts_block.txt
nvidia-smi > /root/g2/nvidia_smi.txt; nvcc --version >> /root/g2/nvidia_smi.txt 2>&1; nproc >> /root/g2/nvidia_smi.txt
