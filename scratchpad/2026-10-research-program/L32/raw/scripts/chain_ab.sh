#!/bin/bash
# A/B interleaved: A = base (e9cdac4, the combined tree), B = pad with NICE_EXP_JOIN_TAIL=1; order A B / B A / A B.
# EPT 1 (pad, NICE_EXP_JOIN_EPT=1) as a third arm; EPT1+tail and EPT4+tail once at 1e16.
R=/root/run.sh; L=/root/pad; TL=NICE_EXP_JOIN_TAIL=1
ab() { # ab TAG BASES N SIZE ROUND
  if [ $5 = 2 ]; then
    $R ab_tail_$1_r$5 pad $2 $3 $4 0 $TL; $R ab_base_$1_r$5 base $2 $3 $4 0
  else
    $R ab_base_$1_r$5 base $2 $3 $4 0; $R ab_tail_$1_r$5 pad $2 $3 $4 0 $TL
  fi
}
for r in 1 2 3; do ab e17_b62 62 1 1e17 $r; [ $r = 1 ] && $R ab_ept1_e17_b62_r1 pad 62 1 1e17 0 NICE_EXP_JOIN_EPT=1; done
for r in 1 2 3; do ab e16_b62 62 2 1e16 $r; $R ab_ept1_e16_b62_r$r pad 62 2 1e16 0 NICE_EXP_JOIN_EPT=1; done
for r in 1 2 3; do ab e16_b60 60 2 1e16 $r; $R ab_ept1_e16_b60_r$r pad 60 2 1e16 0 NICE_EXP_JOIN_EPT=1; done
$R ab_ept1tail_e16_b62_r1 pad 62 2 1e16 0 NICE_EXP_JOIN_EPT=1 $TL
$R ab_ept4tail_e16_b62_r1 pad 62 2 1e16 0 NICE_EXP_JOIN_EPT=4 $TL
$R ab_off_e16_b62_r1 pad 62 2 1e16 0
echo CHAIN_AB_DONE $(date -u +%T) > $L/chainAB.done
