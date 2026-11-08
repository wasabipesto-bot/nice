#!/bin/bash
# tables.sh: the A/B tables from the box's logs (ab.py, nm_table.py) and the A/B processes' check-kernel registers
L=/root/l47/logs; S=/root/l47/scripts
python3 $S/ab.py $L ab B P > $L/ab_table.md 2>&1
python3 $S/nm_table.py $L nm B P > $L/nm_table.md 2>&1
[ -e $L/ab_P_jit.txt ] && awk '{for(i=1;i<=NF;i++) if($i ~ /^regs=|^variant=/) printf "%s ", $i; print ""}' $L/ab_P_jit.txt | sort | uniq -c > $L/ab_P_regs.txt
cat $L/ab_table.md $L/nm_table.md $L/ab_P_regs.txt 2>/dev/null
