#!/bin/bash
# chain_cpu_q.sh: after Q's test binary: lint (fmt, clippy x3) and lavapipe (builds, WGSL lint, every wgpu test of
# cubecl_join with naga and direct SPIR-V) on Q, CPU only.
L=/root/l40/logs
until [ -e $L/Q.built ]; do sleep 10; done
/root/l40/chain_lint.sh Q
/root/l40/chain_lvp.sh Q
echo CHAIN_CPU_Q_DONE $(date -u +%T) > $L/cpu_q.done
