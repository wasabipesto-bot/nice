#!/bin/sh
# copy the box's outputs to ivory (T28/raw/box/), real-field submissions only (padding claim_id 1 dropped)
cd "$(dirname "$0")"; mkdir -p box
timeout 120 ssh -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR -p 29364 root@ssh3.vast.ai \
  'cd /root/t28; mkdir -p /root/t28x; for f in out_*.jsonl; do grep -v "\"claim_id\": 1," $f > /root/t28x/$f; done; for f in client_*.log; do grep -v "Base 10\|5.30e1 numbers" $f > /root/t28x/$f; done; cp runs.log gpu.csv chain.out /root/t28x/' </dev/null
timeout 180 scp -q -o StrictHostKeyChecking=accept-new -o LogLevel=ERROR -P 29364 "root@ssh3.vast.ai:/root/t28x/*" box/ </dev/null
