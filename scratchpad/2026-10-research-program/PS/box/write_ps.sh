#!/bin/bash
# box: write the bench files (MO_SHARE_ONLYWRITE) for the given specs of one slice; log the PSWRITE/BLOCKS/UNIFORM lines
P=$1; shift; O=/root/raw/write_$P.txt
for s in "$@"; do
  t=$(echo $s | cut -d, -f2)_${s##*,}
  echo "CMD MO_SHARE=1 MO_SHARE_ONLYWRITE=1 MO_SHARE_WRITE=$s mo_width_dump $P /root/dump 12 ($(date -u))" >> $O
  MO_SHARE=1 MO_SHARE_ONLYWRITE=1 MO_SHARE_WRITE=$s /root/tgt/release/examples/mo_width_dump $P /root/dump 12 2>&1 | grep -E 'PSWRITE|WROTE|BLOCKS|UNIFORM|REF|panick' >> $O
  mv /root/dump/s${P}_w64_ps.bin /root/dump/s${P}_w64_ps_$t.bin
done
touch /root/raw/write_$P.done
