#!/bin/bash
# Exactness on CUDA: the certificate test and join parity with each switch setting of B.
T=/root/l33/scripts/test.sh; L=/root/l33/logs
CERT=cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu
PAR=cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference
for er in 1 4 5; do $T x_cert_er$er B $CERT NICE_EXP_TOP_ER=$er; done
for er in 2 6; do $T x_par_er$er B $PAR NICE_EXP_TOP_ER=$er; done
echo CHAIN_X_DONE $(date -u +%T) > $L/chainX.done
