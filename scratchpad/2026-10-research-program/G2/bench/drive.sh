#!/bin/bash
# ivory side. Needs ssh to Vast 61025183. Steps, in order:
#   ./drive.sh push | setup | build_main | bench TAG | main TAG | pull
SSH="ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=20 -o ServerAliveInterval=30 -o LogLevel=ERROR -p 28528 root@ssh4.vast.ai"
SCP="scp -o StrictHostKeyChecking=accept-new -P 28528"
D=/home/claude/projects/nice/scratchpad/2026-10-research-program/G2/bench
case $1 in
  push) $SSH 'mkdir -p /root/g2' < /dev/null; $SCP -r $D/box/* $D/g2bench.cu $D/su64_712012851 root@ssh4.vast.ai:/root/g2/ ;;
  setup) $SSH 'test -f /root/READY && sh /root/g2/setup.sh' < /dev/null ;;
  build_main) $SSH 'nohup /root/g2/build_main.sh > /root/g2/build_main.out 2>&1 &' < /dev/null ;;
  bench) $SSH "/root/g2/run_bench.sh $2 ${3:-5}" < /dev/null ;;
  main) $SSH "/root/g2/run_main.sh $2 && python3 /root/g2/summarize_main.py /root/g2/out_$2.jsonl" < /dev/null ;;
  pull) mkdir -p $D/box_out; $SCP "root@ssh4.vast.ai:/root/g2/*.{log,txt,csv,jsonl}" $D/box_out/ ;;
esac
