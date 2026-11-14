#!/bin/bash
# t.sh NAME BIN [ARGS...]: run the test binary BIN inside the 26.04 chroot on lavapipe; log /root/w/logs/NAME.log
NAME=$1; B=$2; shift 2; mkdir -p /root/w/logs
echo "START $NAME $(date -u +%T) bin=$B md5=$(md5sum /srv/r26/root/bin/$B | cut -c1-8) args=[$*]" > /root/w/logs/$NAME.log
chroot /srv/r26 /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test ${XENV:-} \
  VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout ${TMO:-1800} /root/bin/$B "$@" >> /root/w/logs/$NAME.log 2>&1
RC=$?; echo "END $NAME $(date -u +%T) rc=$RC" >> /root/w/logs/$NAME.log
echo "$(date -u +%T) $NAME rc=$RC $(grep -h 'runs,\|test result' /root/w/logs/$NAME.log | tr '\n' ' ' | cut -c1-200)"
