#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L40/raw).
python3 scripts/ab.py box scr M G > scr_table.md
python3 scripts/ab.py box scr2 M G G2 > scr2_table.md
python3 scripts/ab.py box ab M P > ab_table.md
python3 scripts/nm_table.py box nm M P > nm_table.md
python3 scripts/ctr.py box > ctr_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
for t in M G G2 P; do echo "== $t"; grep -v "bucket\|fill\|scan" box/sass/$t/registers.txt | sed 's/0 bytes spill stores, 0 bytes spill loads Used \([0-9]*\) registers.*sass=\([0-9]*\)/regs=\1 sass=\2/'; done > registers.txt
