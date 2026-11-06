#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L41/raw).
python3 scripts/ab.py box scr L0 L1 L2 L3 L4 > scr_table.md
python3 scripts/ctr41.py box > ctr_table.md
[ -e box/ab.done ] && python3 scripts/ab.py box ab B P > ab_table.md
ls box/nm_B_r*.json > /dev/null 2>&1 && python3 scripts/nm_table.py box nm B P > nm_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
for t in XL0 XL1 XL2 XL3 XL4 X2L1 X2L2m0 X2L2m1 X2L3m1 X2L4m1 X3L2c X3L3c X3L4a X3L4b X3L4c X3L4d X3L4e X3L4f P1 P B; do
  [ -d box/sass/$t ] || continue
  echo "== $t"; grep -v "bucket\|fill\|scan" box/sass/$t/registers.txt | sed 's/ bytes spill stores, / spill-st /; s/ bytes spill loads Used / spill-ld regs=/; s/ registers.*sass=/ sass=/'
  python3 scripts/walkcount.py box/sass/$t/join_kernel_b6[024]_1.sass | sed 's/; ops:.*//'
done > registers.txt
