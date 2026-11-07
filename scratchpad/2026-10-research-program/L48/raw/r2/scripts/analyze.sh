#!/bin/bash
# analyze.sh (round 2): regenerate the tables from raw/r2/box (run from L48/raw/r2).
python3 scripts/ab.py box ab S C > ab_table.md
python3 scripts/nm_table.py box nm S C > nm_table.md
python3 scripts/topt48.py box topt > topt_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
(cat box/regs_S.out box/regs_C.out box/regs_F.out | grep -v "^l[0-9]*: base") > registers.txt
