#!/bin/bash
# box: t4/t2 files for the other slices, the SPIR-V modules of the new variants, lavapipe exactness, then timing pass g
cd /root
bash write_ps.sh 4977728 freq,c32,t4 freq,c32,t2
bash write_ps.sh 4977729 freq,c32,t4 freq,c32,t2
SPV=/root/spv2 SPVV=w64,ps_t4,ps_t4n,ps_t2,ps_q17n,ps_q8n bash spv.sh > spv2.log 2>&1
LVPTAG=_2 bash lvp_exact.sh > lvp2.log 2>&1
bash micro.sh g --pips 712012851,4977728,4977729 --reps 15 --launches 20 --variants w64,ps_q17n,ps_q8n,ps_t4,ps_t4n,ps_t2
touch /root/raw/stage2.done
