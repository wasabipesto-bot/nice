#!/bin/bash
# box: dump the slices' phase-3b inputs (mo_width_dump), raw log per slice in /root/raw
mkdir -p /root/dump /root/raw
/root/tgt/release/examples/mo_width_dump --field-slices 77777 4 > /root/raw/field77777_first_slices.txt
for p in "$@"; do
  echo "CMD /root/tgt/release/examples/mo_width_dump $p /root/dump 10 (exp/mo-word-width $(cd /root/nice && git rev-parse --short HEAD))" > /root/raw/dump_$p.txt
  date -u >> /root/raw/dump_$p.txt
  /root/tgt/release/examples/mo_width_dump $p /root/dump 10 >> /root/raw/dump_$p.txt 2>&1; echo "rc=$?" >> /root/raw/dump_$p.txt; date -u >> /root/raw/dump_$p.txt
done
touch /root/raw/dump.done
