#!/bin/bash
# box: rebuild (g variants: the plan read from global memory, shared size as w3b's), their SPIR-V, the BLOCKS lines
# of the q plans on one slice, and a timing pass of the g variants
cd /root
bash build_dump.sh > build_dump3.log 2>&1; bash build_bench.sh > build_bench3.log 2>&1
SPV=/root/spv3 SPVV=w64,ps_q4g,ps_q2g,ps_q1g,ps_u1g,ps_t4g bash spv.sh > spv3.log 2>&1
bash write_ps.sh 712012851 freq,c32,q4 freq,c32,q2 freq,c32,17 freq,c16x2,q4
bash micro.sh h --pips 712012851,4977728,4977729 --reps 15 --launches 20 --variants w64,ps_q4g,ps_q2g,ps_q1g,ps_u1g,ps_t4g
touch /root/raw/stage3.done
