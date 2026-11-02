#!/bin/bash
# chain_prab.sh M: A/B of #236's head (B236, fb05597) vs the PR head (P$M), interleaved per round, nothing else on
# the box: b62 1e17 x2, b62/b60/b64 1e16 x3, the 1e14 set x2 (with a third side, P${M}t: the PR with survivors'
# top ids read from the list instead of shared memory, a diagnostic for the 1e14 cost), then NiceMark x2
# (client_B236 / client_P$M).
M=$1; P=P$M
L=/root/l34/logs; R=/root/l34/run.sh; BIN=/root/l34/bin
until [ -e $L/prx_$M.done ]; do sleep 10; done
until [ -e $L/p${M}t.done ]; do sleep 10; done
echo PRAB_START $(date -u +%T) > $L/prab.start
for r in 1 2; do $R pab_base_e17_b62_r$r B236 62 1 1e17; $R pab_pr_e17_b62_r$r $P 62 1 1e17; done
for r in 1 2 3; do $R pab_base_e16_b62_r$r B236 62 2 1e16; $R pab_pr_e16_b62_r$r $P 62 2 1e16; done
for r in 1 2 3; do $R pab_base_e16_b60_r$r B236 60 2 1e16; $R pab_pr_e16_b60_r$r $P 60 2 1e16; done
for r in 1 2 3; do $R pab_base_e16_b64_r$r B236 64 2 1e16; $R pab_pr_e16_b64_r$r $P 64 2 1e16; done
for r in 1 2 3; do $R pab_base_e14_r$r B236 60,62,64 3 1e14; $R pab_pr_e14_r$r $P 60,62,64 3 1e14; $R pab_prt_e14_r$r ${P}t 60,62,64 3 1e14; done
echo PRAB_TP_DONE $(date -u +%T) > $L/prab_tp.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_API_BASE=http://127.0.0.1:9
cd /root/l34
for r in 1 2; do
  for s in base pr; do
    c=client_B236; [ $s = pr ] && c=client_$P
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/pnm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START pnm_${s}_r$r $(date -u +%T) md5=$(md5sum $BIN/$c | cut -c1-8)" > $L/pnm_${s}_r$r.err
    $BIN/$c niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/pnm_${s}_r$r.json 2>> $L/pnm_${s}_r$r.err
    echo "END pnm_${s}_r$r $(date -u +%T) rc=$?" >> $L/pnm_${s}_r$r.err
    kill $SMI
  done
done
echo PRAB_DONE $(date -u +%T) > $L/prab.done
