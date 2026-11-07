#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L48/raw).
python3 scripts/ab.py box scr l0 l1 l2 l3 l4 > scr_table.md
python3 scripts/ab.py box s6 l4 l6 l7 > s6_table.md
python3 scripts/topt48.py box topt > topt_table.md
python3 scripts/topt48.py box t6 > t6_table.md
python3 scripts/topt48.py box tp2 > tp2_table.md
python3 scripts/ab.py box ab B P > ab_table.md
python3 scripts/nm_table.py box nm B P > nm_table.md
python3 scripts/ab.py box ab2 B P2 > ab2_table.md
python3 scripts/nm_table.py box nm2 B P2 > nm2_table.md
python3 scripts/xsum.py box X_l1 X_l2 X_l3 X_l4 P P2 > xsum_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
(cat box/regs.out box/regs_P.out box/regs_X7.out | grep -v "^l[0-9]*: base") > registers.txt
