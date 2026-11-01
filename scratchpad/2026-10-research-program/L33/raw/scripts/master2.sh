#!/bin/bash
# Replaces master.sh after chain_ab: B2 exactness (parity with ER 10/26/30), the second A/B, NiceMark, then
# writes "MASTER done" (which chain_lvp.sh waits for).
L=/root/l33/logs; T=/root/l33/scripts/test.sh; R=/root/l33/scripts/runv.sh
while [ ! -f $L/chainAB.done ] || ! grep -q BUILD_DONE $L/buildB2.out 2>/dev/null; do sleep 10; done
echo "MASTER2 start X2 $(date -u +%T)" >> $L/master.log
PAR=cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference
CERT=cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu
for er in 10 26 30; do $T x2_par_er$er B2 $PAR NICE_EXP_TOP_ER=$er; done
$T x2_cert_er31 B2 $CERT NICE_EXP_TOP_ER=31
echo "MASTER2 start AB2 $(date -u +%T)" >> $L/master.log
for r in 1 2 3; do
  $R ab2_A_e17_b62_r$r A "" 62 1 1e17
  $R ab2_t_e17_b62_r$r B2 4 62 1 1e17
  $R ab2_cp_e17_b62_r$r B2 26 62 1 1e17
  $R ab2_cpt_e17_b62_r$r B2 30 62 1 1e17
done
for r in 1 2 3; do
  $R ab2_A_e16_b62_r$r A "" 62 2 1e16
  $R ab2_t_e16_b62_r$r B2 4 62 2 1e16
  $R ab2_cp_e16_b62_r$r B2 26 62 2 1e16
  $R ab2_cpt_e16_b62_r$r B2 30 62 2 1e16
done
echo "MASTER2 start NM $(date -u +%T)" >> $L/master.log
cp /root/l33/bin/B2 /root/l33/bin/B2.test
/root/l33/scripts/chain_nm.sh 4 >> $L/master.log 2>&1
echo "MASTER done $(date -u +%T)" >> $L/master.log
