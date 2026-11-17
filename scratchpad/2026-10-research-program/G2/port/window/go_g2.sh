#!/bin/sh
# go_g2.sh: the G2 window on the RX 9070 XT (production client stopped). END_AT (epoch): no run starts after it.
# touch $W/stop ends it before the next run. Order: exactness on the card (both super-units; both transposes), then
# three G2 timing rounds (variants A/B/C rotated) interleaved with main's ten base-64 fields (5 / 5), then a spare.
. "$(dirname "$(readlink -f "$0")")/env.sh"
S=$SCRIPTS
: "${END_AT:?set END_AT}"
echo "GO_START $(date -u +%T) END_AT $(date -u -d @$END_AT +%T) dev=$DEV g2=$(md5sum $BIN/g2 | cut -c1-8) main=$(md5sum $BIN/main | cut -c1-8)"
vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverInfo|apiVersion' | head -6 > "$OUT/device.txt"; cat "$OUT/device.txt"
ok() { [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }; [ "$(date +%s)" -ge "$END_AT" ] && { echo "stopped at END_AT"; exit 0; }; }
# 1. exactness on the card: every unit's survivor set, the counts, the GPU preparation's order (A must pass; B is the
#    fallback transpose if A's does not)
ok; sh $S/run_g2.sh x_A_su1 $SU1 --gpu-prep --xpose 1 --ept 2 --reps 1
# the sampler, checked once by hand: on the card it must have busy/sclk/pw samples
NS=$(grep -c 'busy=' $OUT/x_A_su1.gpu 2>/dev/null); echo "SAMPLER: $NS samples with busy= in x_A_su1.gpu; last: $(tail -1 $OUT/x_A_su1.gpu)"
[ "$DEV" = card ] && [ "${NS:-0}" -eq 0 ] && { echo "SAMPLER EMPTY on the card: stop, fix smp.sh (sysfs paths), re-run"; exit 1; }
ok; sh $S/run_g2.sh x_A_su2 $SU2 --gpu-prep --xpose 1 --ept 2 --reps 1
ok; sh $S/run_g2.sh x_B_su1 $SU1 --gpu-prep --xpose 0 --ept 2 --reps 1
grep -q 'ALL CHECKS PASSED' $OUT/x_A_su1.log && grep -q 'ALL CHECKS PASSED' $OUT/x_A_su2.log && XA=1 || XA=0
grep -q 'ALL CHECKS PASSED' $OUT/x_B_su1.log && XB=1 || XB=0
echo "EXACT A=$XA B=$XB"
[ $XA = 1 ] || [ $XB = 1 ] || { echo "no exact variant on the card: stop (report the logs)"; exit 1; }
# timing variants: A = shuffle transpose, 2 entries per step (the predicted default); B = ballot transpose; C = 1 entry
VA="--xpose 1 --ept 2"; VB="--xpose 0 --ept 2"; VC="--xpose 1 --ept 1"
g2t() { # round variant
  eval V=\$V$2; [ "$2" = A ] && [ $XA = 0 ] && return; [ "$2" = C ] && [ $XA = 0 ] && return; [ "$2" = B ] && [ $XB = 0 ] && return
  ok; sh $S/run_g2.sh t_$2_r$1 $SU1 --gpu-prep --no-sets --reps $REPS $V
  ok; sh $S/run_g2.sh o_$2_r$1 $SU1 --no-sets --noout --modes 0,1,2 --reps $REPS $V
}
# NMAIN (default 5): main fields per block (the dry run uses 1: fields 1 and 6 only)
mainf() { i=0; for f in $F64S; do i=$((i+1)); [ $i -ge $1 ] && [ $i -lt $(( $1 + ${NMAIN:-5} )) ] && [ $i -le $2 ] && { ok; sh $S/run_main.sh main_f$i $f; }; done; }
g2t 1 A; g2t 1 B; g2t 1 C
mainf 1 5
g2t 2 B; g2t 2 C; g2t 2 A
mainf 6 10
g2t 3 C; g2t 3 A; g2t 3 B
# round 4 of A (the CubeCL kernel's timing was bimodal across processes on a 3080: four rounds, median and minimum)
g2t 4 A
echo "SPARE_START $(date -u +%T)"
# spare: re-run once any main field the analysis marks OFF-POINT (the director's call), else round 5 of A
ok; g2t 5 A
echo "GO_DONE $(date -u +%T)"
