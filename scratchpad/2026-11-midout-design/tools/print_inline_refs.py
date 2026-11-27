#!/usr/bin/env python3
"""Print the target line of every inline `file.rs:N` / `:N` / `file.rs:N–M` reference in a text file, so each can be
read against its claim (refs are into the dev/mo-mode worktree). Usage: print_inline_refs.py FILE"""
import re, sys, os
WT = os.path.expanduser('~/projects/nice/.worktrees/mo-mode')
FILES = {'gpu.rs': 'common/src/midout/gpu.rs', 'gpu_wide.rs': 'common/src/midout/gpu_wide.rs', 'cpu.rs': 'common/src/midout/cpu.rs',
         'coord.rs': 'common/src/midout/coord.rs', 'route.rs': 'common/src/midout/route.rs', 'mod.rs': 'common/src/midout/mod.rs',
         'wire.rs': 'common/src/midout/wire.rs', 'midout_route.rs': 'client/src/midout_route.rs'}
txt = open(sys.argv[1]).read()
cur = None
for m in re.finditer(r"(?:\b([A-Za-z_]+\.rs)|(?<=[`(]))(?::|`:)?:?(\d{1,5})(?:[–-](\d{1,5}))?(?:,\s*(\d{1,5}))*" if False else r"(?:\b([A-Za-z_]+\.rs)|(?<=[`(]))(:\d{1,5}(?:[–-]\d{1,5})?(?:,\s*\d{1,5})*)", txt):
    f = m.group(1); spec = m.group(2)
    a, b = re.match(r":(\d+)(?:[–-](\d+))?", spec).groups()
    if f:
        cur = f if f in FILES else None
    if not cur:
        continue
    L = open(os.path.join(WT, FILES[cur])).read().split('\n')
    nums = [int(a)] + ([int(b)] if b else []) + [int(x) for x in re.findall(r",\s*(\d{1,5})", spec)]
    for n in nums:
        print(f"{cur}:{n:<5} | {L[n-1].strip()[:110] if 0 < n <= len(L) else 'OUT OF RANGE'}")
