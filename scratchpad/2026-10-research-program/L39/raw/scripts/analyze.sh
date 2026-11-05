#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L39/raw).
python3 scripts/ab.py box scr B E F > scr_table.md
python3 scripts/ab.py box ab B P > ab_table.md
python3 scripts/nm_table.py box nm B P > nm_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
grep -h "ENTRY SECTORS" box/sectors.log > sectors.txt
for t in B B2 E F P P2; do [ -e box/sass/$t/registers.txt ] || continue; echo "== $t"; grep -v "fill\|scan" box/sass/$t/registers.txt | sed 's/0 bytes spill stores, 0 bytes spill loads Used \([0-9]*\) registers.*sass=\([0-9]*\)/regs=\1 sass=\2/'; done > registers.txt
