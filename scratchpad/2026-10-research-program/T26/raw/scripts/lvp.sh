#!/bin/bash
# lvp.sh NAME BIN [FILTER]: every wgpu test of cubecl_join (ignored; CUDA ones skipped) on lavapipe -> logs/NAME.log
W=/root/t26; NAME=$1; B=$2; FLT=${3:-cubecl_join::tests::}; export NICE_BUILD_SHA=test
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
echo "START $NAME $(date -u +%T) bin=$B md5=$(md5sum $W/bin/$B | cut -c1-8) filter=$FLT" > $W/logs/$NAME.log
timeout ${TMO:-5400} $W/bin/$B --ignored $FLT --skip cuda --nocapture --test-threads 1 >> $W/logs/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $W/logs/$NAME.log; tail -1 $W/logs/$NAME.log
