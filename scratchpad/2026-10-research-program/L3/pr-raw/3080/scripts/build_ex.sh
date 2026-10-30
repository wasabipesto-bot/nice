#!/bin/bash
source /root/.cargo/env
cd /root/$1
{ date -u; cargo build --release -p nice_common --features gpu --example fdbench && echo EX_OK; date -u; } > /root/logs/build_ex_$1.log 2>&1
