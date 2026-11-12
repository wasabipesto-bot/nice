#!/bin/sh
# replacement box: build only what the base-60 queues need, in queue order
cd /root/nice
for s in c0c357ae 8c088a28 c72e2c6f 18cba8bc cb38b917 6f060a94 9a4f7406; do /root/box_build.sh $(git rev-parse $s); done
