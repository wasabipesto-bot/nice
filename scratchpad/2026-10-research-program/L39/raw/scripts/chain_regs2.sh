#!/bin/bash
# chain_regs2.sh: after the A/B, a second regs.sh pass of B and P (CubeCL's CUDA source is not the same from process to
# process, so ptxas's counts can move by a few registers on the same binary).
L=/root/l39/logs
until [ -e $L/ab.done ]; do sleep 10; done
/root/l39/regs.sh B B2 B > $L/regs_B2.out 2>&1
/root/l39/regs.sh P P2 P > $L/regs_P2.out 2>&1
echo REGS2_DONE $(date -u +%T) > $L/regs2.done
