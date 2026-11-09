#!/usr/bin/env python3
"""region.py SASS LO HI [LO HI ...]: print the instructions of a SASS dump in the given address ranges (hex)."""
import re, sys
f = sys.argv[1]; rs = [(int(a, 16), int(b, 16)) for a, b in zip(sys.argv[2::2], sys.argv[3::2])]
for line in open(f):
    m = re.match(r'\s+/\*([0-9a-f]{4,})\*/\s+(.*?)\s*;', line)
    if m and any(lo <= int(m.group(1), 16) <= hi for lo, hi in rs): print(f'{m.group(1)} {m.group(2)}')
