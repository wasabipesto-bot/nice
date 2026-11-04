#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L38/raw).
python3 scripts/ab.py box scr M S V > scr_table.md
python3 scripts/ab.py box ab M P > ab_table.md
python3 scripts/nm_table.py box nm M P > nm_table.md
python3 scripts/topt.py box > topt_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
for t in M M2 S P P2 V; do echo "== $t"; grep -v "bucket\|fill\|scan" box/sass/$t/registers.txt | sed 's/0 bytes spill stores, 0 bytes spill loads Used \([0-9]*\) registers.*sass=\([0-9]*\)/regs=\1 sass=\2/'; done > registers.txt
