#!/bin/bash
# box: share counts (MO_SHARE=1) per slice, optionally writing the bench file(s) for the given specs
# usage: count.sh <pip> [spec ...]   (spec = order,assignment,cap — e.g. pos,c16x2,q4)
P=$1; shift; mkdir -p /root/raw /root/dump
O=/root/raw/count_$P.txt
echo "CMD MO_SHARE=1 /root/tgt/release/examples/mo_width_dump $P /root/dump 12 (exp/mo-word-width $(cd /root/nice && git rev-parse --short HEAD) + working tree)" > $O
date -u >> $O
MO_SHARE=1 /root/tgt/release/examples/mo_width_dump $P /root/dump 12 >> $O 2>&1; echo "rc=$?" >> $O
for s in "$@"; do
  t=$(echo $s | cut -d, -f2)_${s##*,}
  echo "CMD MO_SHARE=1 MO_SHARE_WRITE=$s mo_width_dump $P /root/dump 12" >> $O
  MO_SHARE=1 MO_SHARE_ONLYWRITE=1 MO_SHARE_WRITE=$s /root/tgt/release/examples/mo_width_dump $P /root/dump 12 2>&1 | grep -E 'PSWRITE|WROTE|REF|panick' >> $O
  mv /root/dump/s${P}_w64_ps.bin /root/dump/s${P}_w64_ps_$t.bin
done
date -u >> $O; touch /root/raw/count_$P.done
