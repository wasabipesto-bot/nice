#!/bin/bash
# box: the SPIR-V build at lavapipe's native plane width (8): exactness of the ps variants on the first 48 instances
source ~/.cargo/env
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=8 timeout 1800 /root/tgt_spv/release/examples/mo_width_bench \
  --dump /root/dump --pips 712012851 --once --max-inst 48 --variants w64,w64o_q4,ps_q4n,ps_q4,ps_q2,ps_q1n,ps_q1,ps16_q4,ps16_q1,ps_u1,ps_t4,ps_t4n,ps_t2,ps_q17n,ps_q8n > /root/raw/lvp_exact_w8${LVPTAG}.txt 2>&1
echo "rc=$?" >> /root/raw/lvp_exact_w8${LVPTAG}.txt
