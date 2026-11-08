#!/bin/bash
until [ -e /root/l47/logs/scr.done ]; do sleep 5; done
cd /root/l47; export NICE_EXP_GPU_PROFILE=1
NICE_EXP_CHECK_K=1 SRCD=D scripts/run.sh p2_k1_e17_b62 D 62 1 1e17
NICE_EXP_CHECK_K=2 SRCD=D scripts/run.sh p2_k2_e17_b62 D 62 1 1e17
NICE_EXP_CHECK_K=1 SRCD=D scripts/run.sh p2_k1_e16_b60 D 60 2 1e16
echo P2_DONE
