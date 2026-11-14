#!/bin/bash
# t.sh NAME BIN DUMP|- [ARGS...]: run /root/r2bin/BIN in the 26.04 chroot on lavapipe (Mesa 26.0.8); DUMP = CubeCL full compilation log name or -
NAME=$1; B=$2; DUMP=$3; shift 3
W=/srv/r26/rv_$NAME; mkdir -p $W
if [ "$DUMP" != - ]; then printf "[compilation.logger]\nlevel = \"full\"\nfile = \"/rv_$NAME/$DUMP\"\n" > $W/cubecl.toml; fi
echo "START $NAME $(date -u +%T) bin=$B md5=$(md5sum /srv/r26/root/r2bin/$B | cut -c1-8) args=[$*]" > /root/r2/logs/$NAME.log
chroot /srv/r26 /bin/sh -c "cd /rv_$NAME && exec /usr/bin/env -i PATH=/usr/bin:/bin HOME=/root NICE_BUILD_SHA=test $XENV VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json timeout ${TMO:-1800} /root/r2bin/$B $*" >> /root/r2/logs/$NAME.log 2>&1
RC=$?; echo "END $NAME $(date -u +%T) rc=$RC" >> /root/r2/logs/$NAME.log
[ "$DUMP" != - ] && cp $W/$DUMP /root/r2/dump/ 2>/dev/null
echo "$NAME rc=$RC"
