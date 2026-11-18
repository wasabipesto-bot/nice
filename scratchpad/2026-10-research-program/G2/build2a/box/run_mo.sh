#!/bin/bash
# on box: the middle-out join's 10 b64 fields (0.05..0.95 of the base, as day one), one binary, with nvidia-smi
# usage: run_mo.sh BIN TAG
BIN=$1; TAG=$2; cd /root/mo/b2
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -l 5 > smi_${TAG}.csv &
MP=$!
echo "$(date -u +%FT%TZ) start $TAG $(md5sum $BIN)" >> runs2a.log
$BIN --cuda --group 16 --fields 13107,39321,65536,91750,117964,144179,170393,196607,222822,249036 > ${TAG}.log 2>&1
kill $MP
echo "$(date -u +%FT%TZ) end $TAG" >> runs2a.log
