#!/bin/bash
# t.sh NAME BIN FILTER [lvp]: run one ignored test, log to logs/NAME.log
B=$2; F=$3; export NICE_BUILD_SHA=test
[ "$4" = lvp ] && export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
echo "START $1 $(date -u +%T) $(md5sum /root/rv/bin/$B|cut -c1-8) $F" > /root/rv/logs/$1.log
timeout ${TMO:-3000} /root/rv/bin/$B --ignored --exact $F --nocapture --test-threads 1 >> /root/rv/logs/$1.log 2>&1
echo "END rc=$? $(date -u +%T)" >> /root/rv/logs/$1.log
