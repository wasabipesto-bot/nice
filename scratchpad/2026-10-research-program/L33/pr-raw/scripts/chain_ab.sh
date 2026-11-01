#!/bin/bash
# A/B, interleaved A B per round (A = #235 6e7475e, B = the branch). Nothing else runs meanwhile. Then NiceMark A B x3.
R=/root/l33p/run.sh; L=/root/l33p/logs; BIN=/root/l33p/bin
until [ -e $L/b2.done ]; do sleep 10; done
# B2 (the pushed tree; B plus a whitespace-only rustfmt fix) exactness before timing: the certificate test.
T=/root/l33p/test.sh
$T x2_cert B2 cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
echo AB_START $(date -u +%T) > $L/ab.start
for r in 1 2 3; do $R ab_A_e17_b62_r$r A 62 1 1e17; $R ab_B_e17_b62_r$r B2 62 1 1e17; done
for r in 1 2 3; do $R ab_A_e16_b62_r$r A 62 2 1e16; $R ab_B_e16_b62_r$r B2 62 2 1e16; done
for r in 1 2 3; do $R ab_A_e16_b60_r$r A 60 2 1e16; $R ab_B_e16_b60_r$r B2 60 2 1e16; done
for r in 1 2; do $R ab_A_e16_b64_r$r A 64 2 1e16; $R ab_B_e16_b64_r$r B2 64 2 1e16; done
echo CHAIN_AB_DONE $(date -u +%T) > $L/chainAB.done
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
cd /root/l33p
for r in 1 2 3; do
  for s in A B; do
    ( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $L/nm_${s}_r$r.smi 2>&1 &
    SMI=$!
    echo "START nm_${s}_r$r $(date -u +%T) md5=$(md5sum $BIN/client_$s | cut -c1-8)" > $L/nm_${s}_r$r.err
    $BIN/client_$s niceonly --gpu --benchmark --benchmark-secs 150 --benchmark-json < /dev/null > $L/nm_${s}_r$r.json 2>> $L/nm_${s}_r$r.err
    echo "END nm_${s}_r$r $(date -u +%T) rc=$?" >> $L/nm_${s}_r$r.err
    kill $SMI
  done
done
echo CHAIN_NM_DONE $(date -u +%T) > $L/chainNM.done
