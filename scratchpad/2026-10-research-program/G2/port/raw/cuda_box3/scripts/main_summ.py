#!/usr/bin/env python3
"""main_summ.py CLIENT_LOG: BENCH.md's corrected method: sum of the client's 'Processed 1.00e17' times (10 fields)."""
import re, sys
t = [float(m.group(1)) for m in re.finditer(r"Processed 1\.00e17 numbers in ([0-9.]+)s", open(sys.argv[1]).read())]
adm = len(t) * 1e17 * 8 / 63
print(f"{len(t)} fields of 1e17, sum of client 'Processed' times {sum(t):.2f} s = {sum(t) / adm * 1e15:.3f} fs per admissible n; "
      f"empties (<3 s): {sum(x < 3 for x in t)}; fields s: {' '.join(f'{x:.1f}' for x in t)}")
