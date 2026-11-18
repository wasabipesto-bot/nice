#!/bin/bash
# on box: the measurement session of step 2A, nothing else running: cumulative stops before/after on field 77777,
# the 10 middle-out fields at the head, then main's 10 fields (run_main.sh, real client, local stub only)
cd /root/mo/b2
./stops.sh /root/mo/mo_bench_7ba before2 > stops_final.log 2>&1
./stops.sh /root/mo/mo_bench_0309 after2 >> stops_final.log 2>&1
./run_mo.sh /root/mo/mo_bench_0309 mo2a
/root/mo/run_main.sh m2 > /root/mo/b2/run_main_m2.out 2>&1
python3 /root/mo/summarize_main.py /root/mo/out_m2.jsonl > /root/mo/b2/main_m2_summary.txt 2>&1
echo done > /root/mo/b2/final_done
