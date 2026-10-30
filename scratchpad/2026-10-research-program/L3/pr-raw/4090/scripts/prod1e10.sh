#!/bin/bash
# Production-path 1e10 detailed field via a local mock API.
# usage: prod1e10.sh TREE BIN BASE OUTDIR NFIELDS
# Runs nice_client --repeat against the mock, waits for NFIELDS submissions,
# then stops the client by PID. Field 1 includes kernel JIT.
TREE=$1; BIN=$2; BASE=$3; O=$4; N=${5:-4}
SIZE=10000000000
case $BASE in
  40) START=1916284264916 ;;
  50) START=26507984537059635 ;;
esac
PORT=$((18000 + RANDOM % 1000))
D=$O/${TREE}_b$BASE
rm -rf $D; mkdir -p $D
python3 /root/mock_api.py $PORT $BASE $START $SIZE $D > $D/mock.log 2>&1 &
MP=$!
sleep 1
NICE_API_BASE=http://127.0.0.1:$PORT $BIN detailed --gpu --repeat --no-progress -l info < /dev/null > $D/client.log 2>&1 &
CP=$!
SECONDS=0
while [ "$(ls $D/submit_*.json 2>/dev/null | wc -l)" -lt $N ]; do
  sleep 0.2
  if ! kill -0 $CP 2>/dev/null; then echo "client exited early" >> $D/client.log; break; fi
  if [ $SECONDS -gt 600 ]; then echo "timeout" >> $D/client.log; break; fi
done
kill $CP 2>/dev/null; wait $CP 2>/dev/null
kill $MP 2>/dev/null; wait $MP 2>/dev/null
echo "# $TREE b$BASE done $(date -u +%FT%TZ)" >> $D/client.log
