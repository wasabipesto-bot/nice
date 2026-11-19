#!/usr/bin/env python3
"""remap.py OLD NEW MAP DESIGN [--write]: move every middle-out file:line reference in the map's N array and in
DESIGN.md's inline refs from commit OLD to commit NEW of dev/mo-clean, through git's line mapping (diff -U0).
Prints, per ref, old line text and new line text; a ref whose old line was itself changed is flagged CHANGED."""
import re, subprocess, sys, os
OLD, NEW, MAP, DES = sys.argv[1:5]; WRITE = '--write' in sys.argv
WT = os.path.expanduser('~/projects/nice/.worktrees/midout-clean')
def git(*a): return subprocess.run(['git', '-C', WT, *a], capture_output=True, text=True, check=True).stdout
maps, texts = {}, {}
def lines(rev, path):
    k = (rev, path)
    if k not in texts: texts[k] = git('show', f'{rev}:{path}').split('\n')
    return texts[k]
def mapper(path):
    if path in maps: return maps[path]
    hunks = []
    for m in re.finditer(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@', git('diff', '-U0', OLD, NEW, '--', path), re.M):
        a, al, b, bl = int(m[1]), int(m[2] or 1), int(m[3]), int(m[4] or 1)
        hunks.append((a, al, b, bl))
    def f(n):
        shift = 0
        for a, al, b, bl in hunks:
            start = a if al else a + 1   # al == 0: pure insertion after line a
            if al and a <= n < a + al: return None
            if n >= start:
                if not al: shift = (b + bl - 1) - a
                elif not bl: shift = (b + 1) - (a + al)
                else: shift = (b + bl) - (a + al)
        return n + shift
    maps[path] = f; return f
out = []
def report(path, n, m):
    o = lines(OLD, path)[n-1].strip()[:80] if 0 < n <= len(lines(OLD, path)) else '?'
    t = lines(NEW, path)[m-1].strip()[:80] if m and 0 < m <= len(lines(NEW, path)) else '?'
    flag = 'CHANGED' if m is None else ('same' if o == t else 'DIFF')
    out.append(f"{flag:7} {path}:{n}->{m} | {o} || {t}")
# the map
html = open(MAP).read()
consts = dict(re.findall(r"\b([A-Z]{1,2})='([^']+)'", html.split('const X1')[0]))
pat = re.compile(r"\[((?:[A-Z]{1,2})|'[^']+'),(\d+),('(?:[^'\\]|\\.)*')(,'main')?\]")
def sub_map(m):
    c, ln, ident, main = m.groups()
    if main: return m[0]
    path = consts[c] if not c.startswith("'") else c.strip("'")
    n = int(ln); new = mapper(path)(n); report(path, n, new)
    return f"[{c},{new if new else n},{ident}]"
html2 = pat.sub(sub_map, html)
# DESIGN.md
FILES = {'gpu.rs': 'common/src/midout/gpu.rs', 'gpu_wide.rs': 'common/src/midout/gpu_wide.rs', 'cpu.rs': 'common/src/midout/cpu.rs',
         'coord.rs': 'common/src/midout/coord.rs', 'route.rs': 'common/src/midout/route.rs', 'mod.rs': 'common/src/midout/mod.rs',
         'wire.rs': 'common/src/midout/wire.rs', 'midout_route.rs': 'client/src/midout_route.rs'}
txt = open(DES).read(); cur = [None]
def sub_des(m):
    f, spec = m.group(1), m.group(2)
    if f: cur[0] = f if f in FILES else None
    if not cur[0]: return m[0]
    path = FILES[cur[0]]; mp = mapper(path)
    def one(x):
        n = int(x[0]); new = mp(n); report(path, n, new); return str(new if new else n)
    return (f or '') + re.sub(r'\d{1,5}', one, spec)
txt2 = re.sub(r"(?:\b([A-Za-z_]+\.rs)|(?<=[`(]))(:\d{1,5}(?:[–-]\d{1,5})?(?:,\s*\d{1,5})*)", sub_des, txt)
print('\n'.join(out))
print(f"{len(out)} refs; changed-line {sum(o.startswith('CHANGED') for o in out)}; text differs {sum(o.startswith('DIFF') for o in out)}")
if WRITE:
    open(MAP, 'w').write(html2); open(DES, 'w').write(txt2); print('written')
