#!/bin/bash
while [ ! -e /root/w3/port2/build_done ] || [ ! -e /root/w3/port1/chain_done ]; do sleep 5; done
cd /root/w3/port2 && cp $(cat testbin.txt) tbin && cp /root/t/mp/release/examples/midout_wide_bench bench_wide
/root/w3/chain_port2.sh /root/w3/port2 port2 /root/mp
