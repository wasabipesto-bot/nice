#!/bin/bash
# lvp.sh BIN: every wgpu test of cubecl_join (ignored; CUDA ones skipped) on lavapipe -> logs/lvp_BIN.log
W=/root/n21v; B=$1; export NICE_BUILD_SHA=test
echo "START lvp_$B $(date -u +%T) md5=$(md5sum $W/bin/$B | cut -c1-8)" > $W/logs/lvp_$B.log
$W/bin/$B --ignored cubecl_join::tests:: --skip cuda --nocapture --test-threads 1 >> $W/logs/lvp_$B.log 2>&1
echo "END lvp_$B $(date -u +%T) rc=$?" >> $W/logs/lvp_$B.log; tail -1 $W/logs/lvp_$B.log
