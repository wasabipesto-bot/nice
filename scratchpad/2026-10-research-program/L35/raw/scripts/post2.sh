#!/bin/bash
# post2.sh: after post.sh: the base binary's top kernel registers (b62).
L=/root/l35/logs
until [ -e $L/post.done ]; do sleep 10; done
SRCD=A BASES=62 /root/l35/regs.sh A A_b62 > $L/regs_A_b62.log 2>&1
echo POST2_DONE $(date -u +%T) > $L/post2.done
