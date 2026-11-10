#!/bin/bash
# tile.sh NAME BIN: the N1 tile harness (n1_tile::tests::n1_tile_harness) with NICE_N1_* from the environment;
# logs NAME.{log,smi}; PTX cache per process (ptxjit.py replays the tile kernels: registers / spills per variant).
set -u
NAME=$1; BIN=$2
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
OUT=/root/n1/logs
RUND=/root/n1/run/$NAME; PTXD=/root/n1/ptx/$NAME
rm -rf $RUND $PTXD; mkdir -p $RUND $PTXD
printf '[compilation]\ncache = { file = "%s" }\n' $PTXD > $RUND/cubecl.toml
cd $RUND
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 2; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) env=[$(env | grep '^NICE_N1_' | sort | tr '\n' ' ')] bin=$BIN md5=$(md5sum /root/n1/bin/$BIN | cut -c1-8)" > $OUT/$NAME.log
/root/n1/bin/$BIN --ignored --exact n1_tile::tests::n1_tile_harness --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
python3 /root/n1/ptxjit.py --only tile $PTXD > $OUT/${NAME}_jit.txt 2>&1
