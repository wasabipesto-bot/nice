#!/bin/bash
# chain_x.sh BIN SRCD VAR VALUE TAG: CUDA exactness of one prototype setting (env VAR=VALUE): CPU-reference join parity
# (incl. b50/b54), both dense fields, the whole b42 field, the 1e14 compare at b57/60/62/64.
T=/root/l37/test.sh; R=/root/l37/run.sh; L=/root/l37/logs
BIN=$1; export SRCD=$2; VAR=$3; VAL=$4; TAG=$5
export $VAR=$VAL
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_ABL NICE_EXP_JOIN_TMIN
echo X_START $TAG $VAR=$VAL $(date -u +%T)
$T x_${TAG}_ref $BIN cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_${TAG}_dense58 $BIN cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${TAG}_dense62 $BIN cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${TAG}_whole $BIN cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$R cmp_${TAG}_e14 $BIN 57,60,62,64 1 1e14 1
for f in ref dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${TAG}_$f.log | head -1) $(grep -h '^END' $L/x_${TAG}_$f.log)"; done
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${TAG}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|test result' $L/cmp_${TAG}_e14.log
echo X_DONE $TAG $(date -u +%T)
touch $L/x_${TAG}.done
