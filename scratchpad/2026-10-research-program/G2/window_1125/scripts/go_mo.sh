#!/bin/sh
# go_mo.sh: window 3 (2026-11-25, adapted from window 2's build4s/window/go_mo.sh): the cleaned branch dev/mo-clean
# 66305ada on the RX 9070 XT. PHASE=1 (default): exactness at W 64 (+ the parent-sharing test, the wide fault test,
# one (4, 8, 5) field with the sampled check), then whole fields around main's bracket (task 1); PHASE=3: base 65
# through the wide path with and without the sampled check (task 3); PHASE=4: the stage profile and the sampled
# check's cost (task 4). Window 2's header follows.
# (window 2: the library path of the middle-out join on the RX 9070 XT, production client stopped by the
# user). END_AT (epoch): no step starts after it; `touch $W/stop` ends it before the next step. Order: exactness
# at W 64 first (a failure stops everything but the report), then whole fields against main's two bracket fields
# in the same session, the stage profile, the sampled check's cost, spares. See G2/WINDOW-PLAN-2.md.
. "$(dirname "$(readlink -f "$0")")/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T) dev=$DEV t_mo=$(md5sum $BIN/t_mo | cut -c1-8) mo_bench=$(md5sum $BIN/mo_bench | cut -c1-8) mo_wide_bench=$(md5sum $BIN/mo_wide_bench | cut -c1-8) phase=${PHASE:-1}"
vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverInfo|apiVersion' | head -6 > "$OUT/device.txt"; cat "$OUT/device.txt"
ok() { [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }; [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT"; exit 0; }; }
pass() { grep -q 'test result: ok. 1 passed' "$OUT/$1.log"; }
G=midout::gpu::tests::gpu_slices_equal_cpu
: "${PHASE:=1}"
if [ "$PHASE" = 3 ]; then
  # task 3: base 65, wide kernel (12-wave shared memory, 10ddbf17 in this branch); W65F's first field is the warm-up
  ok; sh $S/run_bw.sh w65_cc -- --base 65 --fields $W65F --group 16 --cpu-check
  ok; sh $S/run_bw.sh w65_nc -- --base 65 --fields $W65F --group 16
  echo "PHASE3_DONE $(date -u +%T)"; exit 0
fi
if [ "$PHASE" = 4 ]; then
  # task 4: the cumulative stops (the bench reads MIDOUT_STOP; it has no stage-isolating mode that keeps the card
  # loaded), then the sampled check's cost
  for st in 1 2 3 5; do ok; sh $S/run_b.sh s_$st MIDOUT_STOP=$st -- --fields $STAGEF --group 16; done
  ok; sh $S/run_b.sh s_6 -- --fields $STAGEF --group 16 --no-cpu-check
  ok; sh $S/run_b.sh b_cc -- --fields $STAGEF --group 16
  echo "PHASE4_DONE $(date -u +%T)"; exit 0
fi
WT=midout::gpu_wide::tests::wide_slices_equal_cpu
# 0. (optional) PR #270's two tests, their own binary (~2 min on the card): reported, never a stop
if [ -x "$BIN/t_pr270" ]; then
  ok; sh $S/run_pr.sh p_pr270
fi
# 1. exactness at W 64 (~5 min): seven slices in three processes (four of them through the shared depth-8 lists),
#    the wide path after them, the fault test, one (4, 9, 6) field
ok
if [ "${PAR:-1}" = 1 ]; then
  # three narrow processes together (each ~1.7 GB of buffers, ~3.4 GB with the pool's slack), the wide one after
  # them alone (b65: ~3-4.3 GB, up to ~8.6 GB with slack): four at once could pass 16 GB
  sh $S/run_t.sh x_g1 $G MIDOUT_GPU_SLICES=$XS1 MIDOUT_CLASSES=$MOCLS MIDOUT_SHARE8=1 & P1=$!
  sh $S/run_t.sh x_g2 $G MIDOUT_GPU_SLICES=$XS2 MIDOUT_CLASSES=$MOCLS MIDOUT_SHARE8=1 & P2=$!
  sh $S/run_t.sh x_g3 $G MIDOUT_GPU_SLICES=$XS3 MIDOUT_CLASSES=$MOCLS & P3=$!
  wait $P1 $P2 $P3
  sh $S/run_t.sh x_w $WT MIDOUT_WIDE_CASES=$XWIDE ${XWCLS:+MIDOUT_CLASSES=$XWCLS}
else  # PAR=0 (the dry run on a 4-core machine): one after another
  sh $S/run_t.sh x_g1 $G MIDOUT_GPU_SLICES=$XS1 MIDOUT_CLASSES=$MOCLS MIDOUT_SHARE8=1
  sh $S/run_t.sh x_g2 $G MIDOUT_GPU_SLICES=$XS2 MIDOUT_CLASSES=$MOCLS MIDOUT_SHARE8=1
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
[ $XF = 1 ] || { echo "STOP: a fault was silent at W 64 (outcome E2)"; exit 1; }
# window 3: the parent-sharing test (shared = unshared slice by slice, faults loud) and the wide fault test (b65)
ok; sh $S/run_t.sh x_sh midout::gpu::tests::field_parent_sharing_is_exact_and_loud MIDOUT_CLASSES=$MOCLS
pass x_sh && XSH=1 || XSH=0
[ $XSH = 1 ] || { echo "STOP: parent sharing not exact or a fault silent (outcome E2)"; exit 1; }
ok; sh $S/run_t.sh x_wf midout::gpu_wide::tests::wide_faults_are_loud MIDOUT_WIDE_FAULT_CASE=$XWFAULT ${XWCLS:+MIDOUT_CLASSES=$XWCLS}
pass x_wf && XWF=1 || XWF=0
# window 3: one whole field under the default (4, 8, 5), sampled CPU check on
ok; sh $S/run_b.sh x_485 -- --fields $X485 --group 16
grep -q '^SAMPLE .*equal' $OUT/x_485.log && grep -q 'END x_485 .* rc=0' $OUT/x_485.log && X485OK=1 || X485OK=0
[ $X485OK = 1 ] || { echo "STOP: the (4, 8, 5) field with the sampled check failed (outcome E3)"; exit 1; }
# the old coordinate (4, 9, 6): one whole field, sampled CPU check on (a dry run: its first MOPART slices)
ok; sh $S/run_b.sh x_496 -- --digits 4,9,6 --fields $X496 --group 16
grep -q '^SAMPLE .*equal' $OUT/x_496.log && grep -q 'END x_496 .* rc=0' $OUT/x_496.log && X496OK=1 || X496OK=0
echo "EXACT narrow=$XG wide=$XW faults=$XF sharing=$XSH wide-faults=$XWF field485=$X485OK old-coordinate=$X496OK"
[ $X496OK = 1 ] || echo "the (4, 9, 6) field failed: report it (outcome E3); the (4, 8, 5) steps continue"
# 2. whole fields (pipelined: groups of 16 slices, one sync per group, device tops; no sampled check), two rounds
#    around main's bracket fields 2 and 6 (~8 min)
ok; sh $S/run_b.sh b_r1 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f2 $F2
ok; sh $S/run_b.sh b_r2 -- --fields $MOFIELDS --group 16 --no-cpu-check
ok; sh $S/run_main.sh main_f6 $F6
# (window 3: the stage profile and the sampled check's cost are PHASE=4, base 65 is PHASE=3; a third round here)
ok; sh $S/run_b.sh b_r3 -- --fields $MOFIELDS --group 16 --no-cpu-check
echo "GO_DONE $(date -u +%T)"
