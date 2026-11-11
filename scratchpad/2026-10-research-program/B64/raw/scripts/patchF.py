#!/usr/bin/env python3
"""B64: the FD top kernel at power-of-two bases on an environment switch (NICE_EXP_FD_POW2 set = on; unset = today's
rule, off at b64). python3 patchF.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
old = "top_fd_fits(fs) && (TOP_FD_AT_POW2_BASES || !fs.b.is_power_of_two())"
assert s.count(old) == 1
s = s.replace(old, "top_fd_fits(fs)\n        && (TOP_FD_AT_POW2_BASES\n            || std::env::var(\"NICE_EXP_FD_POW2\").is_ok()\n            || !fs.b.is_power_of_two())")
open(p, 'w').write(s); print('patched F', p)
