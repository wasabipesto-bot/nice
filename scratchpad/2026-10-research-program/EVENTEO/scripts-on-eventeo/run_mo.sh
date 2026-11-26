#!/bin/bash
# run_mo.sh TAG GPU RUN PHASES: the middle-out join on one of eventeo's cards through CUDA.
#   TAG     binaries in $R/bin/TAG (build_mo.sh)        GPU   nvidia-smi index (0 = GTX 1060 3GB, 1 = RTX 3060 12GB)
#   RUN     output directory name under $R/runs         PHASES any of: a (exactness: the card tier), b (timing:
#           whole base-64 fields and production's join on the same fields' bracket), c (the real client in midout
#           mode against the development server on 127.0.0.1), m (memory: one field, to see what a small card does)
# Every process sees only the chosen card (CUDA_VISIBLE_DEVICES with PCI order). Nothing reaches the production API.
. "$(dirname "$(readlink -f "$0")")/env.sh"
TAG=$1; GPU=$2; RUN=$3; PH=${4:-abc}; BIN=$R/bin/$TAG; O=$R/runs/$RUN; mkdir -p "$O"; rm -f "$O/done"
export CUDA_VISIBLE_DEVICES=$GPU MIDOUT_CUDA=1 NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn}
X=$BIN/t_box; HT=${HTHREADS:-5}
md5sum "$BIN"/* > "$O/bins.txt"; echo "START $(date -u +%FT%T) tag=$TAG gpu=$GPU phases=$PH $(nvidia-smi -i "$GPU" --query-gpu=name,memory.total --format=csv,noheader)" >> "$O/rc.txt"
smp() { nvidia-smi -i "$GPU" --query-gpu=timestamp,utilization.gpu,power.draw,temperature.gpu,memory.used,clocks.gr --format=csv,noheader,nounits -lms 1000 > "$O/$1.gpu" 2>&1 & echo $!; }
g() { n=$1; shift; M=$(smp "$n"); s0=$(date +%s); env "$@" > "$O/$n.txt" 2>&1; rc=$?; kill "$M" 2>/dev/null
      echo "$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' "$O/$n.txt" | tail -1)" >> "$O/rc.txt"; }
T="--nocapture --test-threads 1"
case $PH in *a*)
  g tier_b       $X --ignored cubecl_midout $T
  g slices       MIDOUT_GPU_SLICES=712012851,502136830 $X --ignored --exact midout::gpu::tests::gpu_slices_equal_cpu $T
  g faults       $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud $T
  g share_faults $X --ignored --exact midout::gpu::tests::field_parent_sharing_is_exact_and_loud $T
  g wide_slices  $X --ignored --exact midout::gpu_wide::tests::wide_slices_equal_cpu $T
  g wide_faults  $X --ignored --exact midout::gpu_wide::tests::wide_faults_are_loud $T
;; esac
F2=43445731862957161709568; F6=58557331862957161709568; H=cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields
MOF=${MOFIELDS:-4095,13107,131072,249036,65536,196608}
case $PH in *b*)
  g b_r1    "$BIN/midout_bench" --cuda --threads "$HT" --fields "$MOF" --group 16
  g main_f2 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e17 NICE_TEST_JOIN_BASES=64 NICE_TEST_JOIN_STARTS=64:$F2 $X --ignored --exact $H $T
  g b_r2    "$BIN/midout_bench" --cuda --threads "$HT" --fields "$MOF" --group 16
  g main_f6 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e17 NICE_TEST_JOIN_BASES=64 NICE_TEST_JOIN_STARTS=64:$F6 $X --ignored --exact $H $T
  g b_nc    "$BIN/midout_bench" --cuda --threads "$HT" --fields "$MOF" --group 16 --no-cpu-check
;; esac
case $PH in *m*)
  g mem_one "$BIN/midout_bench" --cuda --threads "$HT" --fields 77777 --group 16
;; esac
case $PH in *c*)
  C=$O/route; mkdir -p "$C/state"; PORT=${PORT:-8471}; NF=${NFIELDS:-6}
  "$BIN/midout_fields" --base 64 --spread "$NF" > "$C/w64.json" 2> "$C/fields.err" || echo "midout_fields failed" >> "$O/rc.txt"
  python3 "$BIN/midout_coordinator.py" --worklist "$C/w64.json" --state "$C/state" --port "$PORT" > "$C/server.log" 2>&1 &
  CO=$!; echo $CO > "$C/server.pid"; sleep 2
  M=$(smp route_client); s0=$(date +%s)
  "$BIN/nice_client" midout --api-base "http://127.0.0.1:$PORT" --repeat --username eventeo-test --threads "$HT" > "$C/client.log" 2>&1 &
  CL=$!; echo $CL > "$C/client.pid"
  while kill -0 $CL 2>/dev/null; do
    S=$(python3 -c "import urllib.request,json;print(json.load(urllib.request.urlopen('http://127.0.0.1:$PORT/status',timeout=5)).get('searched',0))" 2>/dev/null)
    [ "${S:-0}" -ge "$NF" ] && break
    [ $(( $(date +%s) - s0 )) -ge ${ROUTE_MAX:-1800} ] && { echo "route: time limit before the list was done" >> "$O/rc.txt"; break; }
    sleep 5
  done
  sleep 3; kill -TERM $CL 2>/dev/null; wait $CL; crc=$?; kill "$M" 2>/dev/null
  python3 -c "import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:$PORT/status',timeout=5).read().decode())" > "$C/status.json" 2>&1
  python3 "$BIN/midout_audit.py" --worklist "$C/w64.json" --state "$C/state" > "$C/audit.txt" 2>&1; arc=$?
  kill -TERM $CO 2>/dev/null; wait $CO 2>/dev/null
  echo "route client rc=$crc (SIGTERM by pid after the list) $(( $(date +%s) - s0 )) s; audit rc=$arc; status $(cat "$C/status.json")" >> "$O/rc.txt"
;; esac
echo "END $(date -u +%FT%T)" >> "$O/rc.txt"; echo done > "$O/done"
