#!/bin/bash
# lvp.sh NAME BIN DUMP|- [ARGS...]: run /root/bin/BIN inside the 26.04 chroot on lavapipe (Mesa 26.0.8, as CI);
# DUMP = name of CubeCL's full compilation log (copied to /root/mu/dump), or -.
NAME=$1; B=$2; DUMP=$3; shift 3
W=/srv/r26/rv_$NAME; mkdir -p $W
if [ "$DUMP" != - ]; then printf "[compilation.logger]\nlevel = \"full\"\nfile = \"/rv_$NAME/$DUMP\"\n" > $W/cubecl.toml; fi
echo "START $NAME $(date -u +%T) bin=$B md5=$(md5sum /srv/r26/root/bin/$B | cut -c1-8) args=[$*]" > /root/mu/logs/$NAME.log
chroot /srv/r26 /bin/sh -c "cd /rv_$NAME && exec /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test VK_ICD_FILENAMES=\$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) timeout ${TMO:-5400} /root/bin/$B $*" >> /root/mu/logs/$NAME.log 2>&1
RC=$?; echo "END $NAME $(date -u +%T) rc=$RC" >> /root/mu/logs/$NAME.log
[ "$DUMP" != - ] && cp $W/$DUMP /root/mu/dump/ 2>/dev/null
echo "$(date -u +%T) $NAME rc=$RC $(grep -a 'test result' /root/mu/logs/$NAME.log | tail -1)"
