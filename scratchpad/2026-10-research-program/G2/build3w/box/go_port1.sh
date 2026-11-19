#!/bin/bash
while [ ! -e /root/w3/port1/build_done ] || [ ! -e /root/w3/merge/chain_done ]; do sleep 5; done
/root/w3/chain_port.sh /root/w3/port1 port1 /root/mp
