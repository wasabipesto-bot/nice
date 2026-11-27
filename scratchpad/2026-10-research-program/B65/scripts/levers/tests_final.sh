#!/bin/bash
# tests_final.sh: the final series' tests on the RTX 3060: wide (tier, slices, faults, parent sharing) through CUDA
# and Vulkan/SPIR-V; the narrow tests once (CUDA).
. "$HOME/research/scripts/env.sh"
until [ -f $R/b65l/builds_final.tests ]; do sleep 10; done
L=$R/b65l/scripts; SH=midout::gpu_wide::tests::wide_field_parent_sharing_is_exact_and_loud
bash $L/tests.sh levers-final-tests fin-t-cuda cuda $SH
bash $L/tests.sh levers-final-tests fin-t-spv vk $SH
echo tests-done > $R/runs/levers-final-tests/wide.done
