#!/bin/bash
# Chain: wait for both builds, then fix tests + dumps, main dumps, lint/host, main baseline tests.
FIX=$1
while ! grep -q BUILD_DONE /root/logs/build.log 2>/dev/null; do sleep 10; done
echo "start $(date -u +%T)"
/root/tests.sh fix all
/root/tests.sh main dump
/root/lint.sh $FIX
/root/tests.sh main cuda
/root/tests.sh main lvp
echo "PIPELINE_DONE $(date -u +%T)" >> /root/logs/tests.status
