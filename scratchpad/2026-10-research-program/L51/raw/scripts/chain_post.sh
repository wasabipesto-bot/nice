#!/bin/bash
# chain_post.sh: after the screen. (1) The spill variant's tax and a fix, with pinned PTX caches (L45's pin.py): per
# field, S = a process that compiled the 40-register spill variant of join_kernel (E defaults), N = the same cache with
# the join kernel from a spill-free process of the same config, D = S's PTX with '.minnctapersm 5' on join_kernel (the
# occupancy CubeCL's __launch_bounds__(256) does not state). 1e14 checks, then 3 interleaved rounds at b62 1e17 and
# b60 1e16, unprofiled. (2) How often d813aea's own binary B compiles the spill variant: 16 processes at 1e14.
R=/root/l51/run_pin.sh; L=/root/l51/logs; P=/root/l51/ptx; PIN=/root/l51/pin
until [ -e $L/screen.done ] || [ -e $L/stop ]; do sleep 10; done
[ -e $L/stop ] && exit 0
echo POST_START $(date -u +%T)
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_SPILLCNT NICE_EXP_JOIN_EPT NICE_EXP_JOIN_AG NICE_EXP_JOIN_TCAP NICE_EXP_JOIN_FLUSH NICE_EXP_JOIN_STAGE NICE_EXP_FD_WG
mkdir -p $PIN; cd /root/l51
python3 pin.py $PIN/S62 $P/s_base5_e17_b62_r1_spill0 | tee $L/pins.txt
python3 pin.py $PIN/N62 $P/s_base5_e17_b62_r1_spill0 $P/s_base5_e17_b62_r1 | tee -a $L/pins.txt
python3 pin.py --directive '.minnctapersm 5' $PIN/D62 $P/s_base5_e17_b62_r1_spill0 | tee -a $L/pins.txt
python3 pin.py $PIN/S60 $P/m_u_e16_b60_r1 | tee -a $L/pins.txt
python3 pin.py $PIN/N60 $P/m_u_e16_b60_r1 $P/m_u_e16_b60_r3 | tee -a $L/pins.txt
python3 pin.py --directive '.minnctapersm 5' $PIN/D60 $P/m_u_e16_b60_r1 | tee -a $L/pins.txt
nice -n 19 python3 ptxjit.py --only join --sass /root/l51/sass $PIN/S62 $PIN/N62 $PIN/D62 $PIN/S60 $PIN/N60 $PIN/D60 > $L/pin_jit.txt 2>&1
cat $L/pin_jit.txt | cut -c1-150
for v in S N D; do
  PTXFROM=$PIN/${v}62 $R pchk_${v}_b62 E 62 1 1e14
  PTXFROM=$PIN/${v}60 $R pchk_${v}_b60 E 60 1 1e14
  echo "$(date -u +%T) pchk_$v $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pchk_${v}_b62.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pchk_${v}_b60.log | tail -1)"
done
for r in 1 2 3; do
  case $r in 1) O="S N D";; 2) O="D S N";; 3) O="N D S";; esac
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for v in $O; do
      [ -e $L/stop ] && exit 0
      PTXFROM=$PIN/$v$1 $R pn_${v}_$4_r$r E $1 $2 $3
      echo "$(date -u +%T) pn_${v}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/pn_${v}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pn_${v}_$4_r$r.log | tail -1)"
    done
  done
done
nice -n 19 python3 ptxjit.py --only join $(ls -d $P/pn_*) > $L/pn_jit.txt 2>&1
echo PINS_DONE $(date -u +%T)
for i in $(seq 1 16); do
  [ -e $L/stop ] && exit 0
  /root/l51/run.sh bfreq_$i B 62,60 1 1e14
  nice -n 19 python3 ptxjit.py --only join $P/bfreq_$i > $L/bfreq_${i}_jit.txt 2>&1
  echo "$(date -u +%T) bfreq_$i $(grep -o 'regs=[0-9]* local=[0-9]*' $L/bfreq_${i}_jit.txt | tr '\n' ' ')"
done
echo POST_DONE $(date -u +%T) | tee $L/post.done
