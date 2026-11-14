#!/usr/bin/env python3
"""union_changelog.py FILE: resolve every conflict hunk by keeping both sides, ours first (the PR merged earlier)."""
import re, sys
p = sys.argv[1]; s = open(p).read()
s2, n = re.subn(r'<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n', lambda m: m.group(1) + m.group(2), s, flags=re.S)
open(p, 'w').write(s2); print(f'{p}: {n} hunks resolved as union')
