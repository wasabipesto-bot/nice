#!/bin/bash
# dense.sh NAME BIN N21 BASE START SIZE PARTS: the dense compare against the CPU join on CUDA with NICE_EXP_N21=N21.
W=/root/n21; L=$W/logs/t; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
mkdir -p $W/run/$1; cd $W/run/$1
echo "START $1 $(date -u +%T) bin=$2 md5=$(md5sum $W/bin/$2 | cut -c1-8) n21=$3 $4:$5:$6 parts=$7" > $L/$1.log
NICE_EXP_N21=$3 NICE_TEST_JOIN_DENSE=$7 NICE_TEST_JOIN_DENSE_FIELD=$4:$5:$6 $W/bin/$2 --ignored --exact \
  cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 >> $L/$1.log 2>&1
echo "END $1 $(date -u +%T) rc=$?" >> $L/$1.log
echo "$1: $(grep -o 'survivors [0-9]* checked [0-9]*' $L/$1.log | tail -1) $(grep -o 'test result: [a-z]*' $L/$1.log)"
