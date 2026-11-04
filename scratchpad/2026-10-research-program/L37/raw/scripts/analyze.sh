#!/bin/bash
# analyze.sh: regenerate every table from raw/box (run from L37/raw).
python3 scripts/abl.py box > abl.txt
python3 scripts/abl_table.py box > abl_table.md
python3 scripts/base.py box > base_table.md
python3 scripts/ab.py box ab1 C0 C1 C2 > ab1_table.md
python3 scripts/nm_table.py box nm1 C0 C1 C2 > nm1_table.md
python3 scripts/h2_table.py box > h2_table.md
python3 scripts/clocks.py 'box/*.smi' > clocks.txt
python3 scripts/ab.py box ab1 C0 C2 | grep -E "^\| (field|e14)" | sed '1a |---|---|---|---|---|---|' > ab1_e14_table.md
