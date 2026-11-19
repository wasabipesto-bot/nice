#!/bin/bash
while [ ! -e /root/w3/merge/build_done ]; do sleep 5; done
/root/w3/lint.sh /root/w3/merge/lint > /dev/null 2>&1 &
/root/w3/chain.sh /root/w3/merge merge
