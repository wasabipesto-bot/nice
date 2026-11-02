#!/bin/bash
# head_x.sh: after post_pr: build the PR head (Cfmt = 88605a9) and run the FD test, the certificate test and the 1e14 compare on it.
L=/root/l35/logs; T=/root/l35/test.sh; R=/root/l35/run2.sh
until [ -e $L/ppost.done ]; do sleep 10; done
cd /root/l35/src/Cfmt && git log --oneline -1 > $L/ph_tree.txt && md5sum common/src/cubecl_join.rs >> $L/ph_tree.txt
/root/l35/build.sh Cfmt PH gpu
export SRCD=Cfmt
$T phx_fd PH cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T phx_cert PH cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$R PH_cmp_e14 PH 57,60,62,64 1 1e14 1
echo PHX_DONE $(date -u +%T) > $L/phx.done
