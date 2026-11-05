#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L40/raw).
python3 scripts/ab.py box scr2 M G G2 > scr2_table.md
python3 scripts/ab.py box ab M P > ab_table.md
python3 scripts/nm_table.py box nm M P > nm_table.md
python3 scripts/ab.py box ab2 M F > ab2_table.md
python3 scripts/nm_table.py box nm2 M F > nm2_table.md
python3 scripts/ab.py box ab3 M H2 > ab3_table.md
python3 scripts/nm_table.py box nm3 M H2 > nm3_table.md
python3 scripts/nm_pool.py box M H2 nm3 nm4 > nm34_pool.md
python3 scripts/nm_pool.py box M H2 nmh2 nm3 nm4 > nm_h2_all_pool.md
python3 scripts/ab.py box scrh M H > scrh_table.md
python3 scripts/nm_table.py box nmh M H > nmh_table.md
python3 scripts/ab.py box scrh2 M H2 > scrh2_table.md
python3 scripts/nm_table.py box nmh2 M H2 > nmh2_table.md
python3 scripts/ab.py box scrf2 M F2 > scrf2_table.md 2>/dev/null
python3 scripts/ab.py box ab5 M F2 > ab5_table.md
python3 scripts/nm_table.py box nm5 M F2 > nm5_table.md
python3 scripts/nm_pool.py box M F2 nm5 nm6 > nm56_pool.md
python3 scripts/nm_pool.py box M F2 nmf2 nm5 nm6 > nm_f2_all_pool.md
python3 scripts/nm_table.py box nmf2 M F2 > nmf2_table.md 2>/dev/null
python3 scripts/ctr.py box > ctr_table.md
python3 scripts/ctr14.py box > ctr14_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
for t in M M2 G G2 P F H H2 Q Q2 F2; do echo "== $t"; grep -v "bucket\|fill\|scan" box/sass/$t/registers.txt | sed 's/0 bytes spill stores, 0 bytes spill loads Used \([0-9]*\) registers.*sass=\([0-9]*\)/regs=\1 sass=\2/'; done > registers.txt 2>/dev/null
for t in M P F H H2 Q F2; do for b in 60 62 64; do [ -e box/sass/$t/join_kernel_b${b}_1.sass ] && python3 scripts/walkloop.py box/sass/$t/join_kernel_b${b}_1.sass; done; done > walkloops.txt
