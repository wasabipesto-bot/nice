#!/bin/sh
# go_mo.sh: window 2, the library path of the middle-out join on the RX 9070 XT (production client stopped by the
# user). END_AT (epoch): no step starts after it; `touch $W/stop` ends it before the next step. Order: exactness
# at W 64 first (a failure stops everything but the report), then whole fields against main's two bracket fields
# in the same session, the stage profile, the sampled check's cost, spares. See G2/WINDOW-PLAN-2.md.
. "$(dirname "$(readlink -f "$0")")/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T) dev=$DEV t_mo=$(md5sum $BIN/t_mo | cut -c1-8) mo_bench=$(md5sum $BIN/mo_bench | cut -c1-8)"
vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverInfo|apiVersion' | head -6 > "$OUT/device.txt"; cat "$OUT/device.txt"
ok() { [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }; [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT"; exit 0; }; }
pass() { grep -q 'test result: ok. 1 passed' "$OUT/$1.log"; }
G=midout::gpu::tests::gpu_slices_equal_cpu
WT=midout::gpu_wide::tests::wide_slices_equal_cpu
# 1. exactness at W 64 (~4 min): six slices in three processes and the wide path, in parallel (their CPU references
#    are the long part; the device parts are seconds), then the fault test
ok
if [ "${PAR:-1}" = 1 ]; then
  sh $S/run_t.sh x_g1 $G MIDOUT_GPU_SLICES=$XS1 MIDOUT_CLASSES=$MOCLS & P1=$!
  sh $S/run_t.sh x_g2 $G MIDOUT_GPU_SLICES=$XS2 MIDOUT_CLASSES=$MOCLS & P2=$!
  sh $S/run_t.sh x_g3 $G MIDOUT_GPU_SLICES=$XS3 MIDOUT_CLASSES=$MOCLS & P3=$!
  sh $S/run_t.sh x_w $WT MIDOUT_WIDE_CASES=$XWIDE ${XWCLS:+MIDOUT_CLASSES=$XWCLS} & P4=$!
  wait $P1 $P2 $P3 $P4
else  # PAR=0 (the dry run on a 4-core machine): one after another
  sh $S/run_t.sh x_g1 $G MIDOUT_GPU_SLICES=$XS1 MIDOUT_CLASSES=$MOCLS
  sh $S/run_t.sh x_g2 $G MIDOUT_GPU_SLICES=$XS2 MIDOUT_CLASSES=$MOCLS
  sh $S/run_t.sh x_g3 $G MIDOUT_GPU_SLICES=$XS3 MIDOUT_CLASSES=$MOCLS
  sh $S/run_t.sh x_w $WT MIDOUT_WIDE_CASES=$XWIDE ${XWCLS:+MIDOUT_CLASSES=$XWCLS}
fi
NS=$(grep -c 'busy=' $OUT/x_g1.gpu 2>/dev/null); echo "SAMPLER: $NS samples with busy= in x_g1.gpu; last: $(tail -1 $OUT/x_g1.gpu)"
[ "$DEV" = card ] && [ "${NS:-0}" -eq 0 ] && echo "SAMPLER EMPTY on the card: timing runs will carry no clock; fix smp.sh's sysfs paths if there is time"
WD=$(grep -h -o ' W [0-9]*' $OUT/x_g1.log | head -1 | tr -dc 0-9); echo "PLANE WIDTH: the device path ran at W ${WD:-?}"
[ "$DEV" = card ] && [ "${WD:-0}" != 64 ] && echo "NOT W 64: the device reports plane width ${WD:-?}; everything below tests that width, not 64 (report it)"
XG=1; for x in x_g1 x_g2 x_g3; do pass $x || XG=0; done; pass x_w && XW=1 || XW=0
if [ $XG = 0 ]; then
  echo "NARROW NOT EXACT AT W 64: $(grep -h -m2 'panicked\|errors' $OUT/x_g*.log | cut -c1-200)"
  # a plane error means RADV ran planes other than the 64 the device reports: is the W 32 path exact on the card?
  grep -q 'plane [1-9]' $OUT/x_g*.log && { ok; sh $S/run_t.sh x_g1_w32 $G MIDOUT_GPU_SLICES=712012851 MIDOUT_CLASSES=$MOCLS MIDOUT_FORCE_W=32; }
  echo "STOP: report the logs (WINDOW-PLAN-2.md, outcome E1)"; exit 1
fi
ok; sh $S/run_t.sh x_f midout::gpu::audit::accounts_faults_are_loud AUDIT_SLICES=$XFAULT AUDIT_AGAIN=0 MIDOUT_CLASSES=$MOCLS
pass x_f && XF=1 || XF=0
echo "EXACT narrow=$XG wide=$XW faults=$XF"
[ $XF = 1 ] || { echo "STOP: a fault was silent at W 64 (outcome E2)"; exit 1; }
# 2. whole fields (pipelined: groups of 16 slices, one sync per group, device tops; no sampled check), two rounds
#    around main's bracket fields 2 and 6 (~8 min)
ok; sh $S/run_b.sh b_r1 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f2 $F2
ok; sh $S/run_b.sh b_r2 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f6 $F6
# 3. the stage profile (cumulative stops: 1 tops, 2 + parents, 3 + main kernel, 5 + expansion; 6 = b_r* field
#    77777 below), one process each (~3 min)
for st in 1 2 3 5; do ok; sh $S/run_b.sh s_$st MIDOUT_STOP=$st -- --fields $STAGEF --group 16; done
ok; sh $S/run_b.sh s_6 -- --fields $STAGEF --group 16 --no-cpu-check
# 4. the sampled CPU check's cost on this host (one field with it on: the host waits if the CPU slice is slower)
ok; sh $S/run_b.sh b_cc -- --fields $STAGEF --group 16
echo "SPARE_START $(date -u +%T)"
# 5. spares, in order: a third round; the wide path at b65 (one warm-up and one field, if exact); a re-run of an
#    off-point main field is the director's call
ok; sh $S/run_b.sh b_r3 -- --fields $MOFIELDS --group 16 --no-cpu-check
[ $XW = 1 ] && [ "$DEV" = card ] && { ok; sh $S/run_bw.sh w_65 -- --base 65 --fields 13731,77777 --group 16; }
echo "GO_DONE $(date -u +%T)"
