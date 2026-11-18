#!/bin/sh
# window_1118b measurement stretch (2026-11-18, build g2z): main f2 first; four rounds of A and D by the window's
# protocol (t_ with the GPU prep, o_ without records; --reps 400, the window's flags) and by the pipelined protocol
# (pp_: K = 3000 super-units queued, one sync, buffers reused, 5 s warm-up, then each component queued K times);
# one run each of the window's protocol with a warm-up and 2000 reps (wp_); main f6 after round 2, f2 and f6 again
# at the end. touch $W/stop ends it before the next run.
W=/home/justin/claude-exp-2026-11-18-g2; cd $W
export OUT=$W/out_b/m W=$W G2BIN=$W/bin/g2z
mkdir -p $OUT
S=$W/scripts; S1=$W/data/su64_712012851
F2=43445731862957161709568; F6=58557331862957161709568
VA="--xpose 1 --ept 2"; VD="--xpose 1 --ept 2 --tdig 1"
ok() { [ -e "$W/stop" ] && { echo "stopped by $W/stop"; exit 0; }; [ "$(date -u +%H%M)" -ge 1555 ] && { echo "stopped at 15:55"; exit 0; }; }
g2r() { # round variant
  eval V=\$V$2
  ok; sh $S/run_g2.sh t_$2_r$1 $S1 --gpu-prep --no-sets --reps 400 $V
  ok; sh $S/run_g2.sh o_$2_r$1 $S1 --no-sets --noout --modes 0,1,2 --reps 400 $V
  ok; sh $S/run_g2.sh pp_$2_r$1 $S1 --gpu-prep --no-sets --modes 0 --reps 20 $V --warm 5 --pipe 3000 --pipe-parts
}
echo "MEAS_START $(date -u +%T) g2=$(md5sum $G2BIN | cut -c1-8) main=$(md5sum $W/bin/main | cut -c1-8)"
ok; sh $S/run_main.sh main_f2 $F2
g2r 1 A; g2r 1 D
g2r 2 D; g2r 2 A
ok; sh $S/run_main.sh main_f6 $F6
g2r 3 A; g2r 3 D
g2r 4 D; g2r 4 A
ok; sh $S/run_g2.sh wp_A_r1 $S1 --gpu-prep --no-sets --reps 2000 $VA --warm 5 --warm-mode 3
ok; sh $S/run_g2.sh wp_D_r1 $S1 --gpu-prep --no-sets --reps 2000 $VD --warm 5 --warm-mode 3
ok; sh $S/run_main.sh main_f2b $F2
ok; sh $S/run_main.sh main_f6b $F6
echo "MEAS_DONE $(date -u +%T)"
