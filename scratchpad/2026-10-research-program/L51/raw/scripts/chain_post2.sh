#!/bin/bash
# chain_post2.sh: one more pinned image, M = S's PTX with '.maxnreg 48' on join_kernel (a register cap at the
# spill-free allocation instead of an occupancy floor); its registers, then 2 interleaved rounds N / M at both fields.
R=/root/l51/run_pin.sh; L=/root/l51/logs; P=/root/l51/ptx; PIN=/root/l51/pin
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN NICE_EXP_JOIN_SPILLCNT NICE_EXP_JOIN_EPT NICE_EXP_JOIN_AG NICE_EXP_JOIN_TCAP NICE_EXP_JOIN_FLUSH NICE_EXP_JOIN_STAGE NICE_EXP_FD_WG
cd /root/l51
echo POST2_START $(date -u +%T)
python3 pin.py --directive '.maxnreg 48' $PIN/M62 $P/s_base5_e17_b62_r1_spill0 | tee -a $L/pins.txt
python3 pin.py --directive '.maxnreg 48' $PIN/M60 $P/m_u_e16_b60_r1 | tee -a $L/pins.txt
nice -n 19 python3 ptxjit.py --only join --sass /root/l51/sass $PIN/M62 $PIN/M60 > $L/pin2_jit.txt 2>&1
cut -c1-150 $L/pin2_jit.txt
PTXFROM=$PIN/M62 $R pchk_M_b62 E 62 1 1e14
PTXFROM=$PIN/M60 $R pchk_M_b60 E 60 1 1e14
echo "$(date -u +%T) pchk_M $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pchk_M_b62.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pchk_M_b60.log | tail -1)"
for r in 4 5; do
  if [ $r = 4 ]; then O="M N"; else O="N M"; fi
  for f in "62 1 1e17 e17_b62" "60 2 1e16 e16_b60"; do
    set -- $f
    for v in $O; do
      [ -e $L/stop ] && exit 0
      PTXFROM=$PIN/$v$1 $R pn_${v}_$4_r$r E $1 $2 $3
      echo "$(date -u +%T) pn_${v}_$4_r$r $(grep -o 'device=[0-9.]*s' $L/pn_${v}_$4_r$r.log | tail -1) $(grep -o 'survivors=[0-9]* checked=[0-9]*' $L/pn_${v}_$4_r$r.log | tail -1)"
    done
  done
done
nice -n 19 python3 ptxjit.py --only join $(ls -d $P/pn_*_r4 $P/pn_*_r5) > $L/pn2_jit.txt 2>&1
echo POST2_DONE $(date -u +%T) | tee $L/post2.done
