#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L43/raw).
python3 scripts/ab.py box scr wb0 wb1 wb17 wb2 wb4 wb8 wb15 wb31 > scr_table.md
python3 scripts/ab.py box scr2 wb0 wb19 > scr2_table.md
python3 scripts/ab.py box scr3 wb0 wb17 wb2 wb19 > b64_table.md
python3 scripts/ab.py box ab B W > ab_table.md
python3 scripts/nm_table.py box nm B W > nm_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
python3 scripts/sass_stats.py box/sass B W2_wb0 W2_wb1 W2_wb17 W2_wb2 W2_wb4 W2_wb8 W2_wb15 W2_wb31 W3_wb0 W3_wb1 W3_wb17 W3_wb2 W3_wb4 W3_wb8 W3_wb15 W3_wb19 W3_wb31 > registers.md
( echo "== W (first build) WB=4: AU unrolled at comptime"; python3 scripts/sass_stats.py box/sass B W_wb4 W_wb1 W_wb15 ) >> registers.md
for t in B W_wb4 W2_wb1 W2_wb17 W2_wb4 W3_wb4 W3_wb15 W3_wb19 W3_wb31; do echo "== $t"; python3 scripts/loops.py box/sass/$t/join_kernel_b62_1.sass 4; done > loops.txt
for v in 0 31; do echo "== WB=$v"; python3 scripts/blocks.py box/spvdump_wb$v.log.gz --top 40; done > spv_blocks.txt
