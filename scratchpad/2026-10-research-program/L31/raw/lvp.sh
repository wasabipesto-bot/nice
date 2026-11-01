#!/bin/bash
# Lavapipe (exp2 binaries): per variant, the CI lint dump on naga (lint with CI's require list)
# and the same dump on the direct SPIR-V compiler (TopKernel blocks at b57); the certificate
# test on naga and SPIR-V; the join parity test on SPIR-V with everything on (blocks to b64).
L=/root/logs/lvp; mkdir -p $L
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
NB=/root/bin/exp2/nice_common_cubecl; SB=/root/bin/exp2/nice_common_cubecl-spirv
md5sum $NB $SB > $L/md5.txt
flags() { case $1 in base) echo "";; diff) echo "NICE_EXP_TOP_DIFF=1";; bar) echo "NICE_EXP_TOP_BARRETT=1";; ndig) echo "NICE_EXP_TOP_NDIG=1";;
  both) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; dn) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";; all) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac; }
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
for V in all dn base; do
  for K in spv naga; do
    [ $V = base ] && [ $K = naga ] && continue
    BIN=$NB; [ $K = spv ] && BIN=$SB
    rm -f $L/dump_${V}_$K.log
    ( date -u; env $(flags $V) CUBECL_DEBUG_LOG=$L/dump_${V}_$K.log timeout 900 $BIN --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/run_dump_${V}_$K.log 2>&1
  done
  [ -f $L/dump_${V}_naga.log ] && { python3 /root/src/exp2/scripts/wgsl-lint.py $L/dump_${V}_naga.log $REQ > $L/lint_$V.txt 2>&1; echo "exit $?" >> $L/lint_$V.txt; }
  python3 /root/blocks.py $L/dump_${V}_spv.log --top 20 > $L/blocks_$V.txt 2>&1
  gzip -f $L/dump_${V}_naga.log $L/dump_${V}_spv.log 2>/dev/null
done
touch /root/logs/lvp1.done
T=cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu
( date -u; env $(flags all) timeout 1500 $NB --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/cert_naga_all.log 2>&1
( date -u; env $(flags all) timeout 1500 $SB --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/cert_spv_all.log 2>&1
( date -u; env $(flags dn) timeout 1500 $NB --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/cert_naga_dn.log 2>&1
touch /root/logs/lvp2.done
rm -f $L/par_all_spv.dump
( date -u; env $(flags all) CUBECL_DEBUG_LOG=$L/par_all_spv.dump timeout 420 $SB --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/par_all_spv.log 2>&1
python3 /root/blocks.py $L/par_all_spv.dump --name TopKernel --top 40 > $L/blocks_par_all.txt 2>&1
gzip -f $L/par_all_spv.dump
touch /root/logs/lvp.done
