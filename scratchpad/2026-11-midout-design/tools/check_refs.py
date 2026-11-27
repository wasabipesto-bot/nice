#!/usr/bin/env python3
"""Check every file:line reference in the interactive map: the line must contain the named identifier.
Middle-out refs are read from the dev/mo-mode worktree (the head the map names in its sub-title); refs marked 'main' from
`git show origin/main:<path>` (974d7194). Read-only. Usage: python3 tools/check_refs.py interactive/midout-map.html"""
import re, subprocess, sys, os
html = open(sys.argv[1]).read()
WT = os.path.expanduser('~/projects/nice/.worktrees/mo-mode')
REPO = os.path.expanduser('~/projects/nice')
head = subprocess.run(['git', '-C', WT, 'rev-parse', '--short=8', 'HEAD'], capture_output=True, text=True).stdout.strip()
main = subprocess.run(['git', '-C', REPO, 'rev-parse', '--short=8', 'origin/main'], capture_output=True, text=True).stdout.strip()
print('worktree head', head, '| origin/main', main)
consts = dict(re.findall(r"\b([A-Z]{1,2})='([^']+)'", html.split('const X1')[0]))
pat = re.compile(r"\[(?:([A-Z]{1,2})|'([^']+)'),(\d+),'((?:[^'\\]|\\.)*)'(?:,'(main)')?\]")
cache = {}
def lines(path, repo):
    key = (path, repo)
    if key not in cache:
        if repo == 'main':
            out = subprocess.run(['git', '-C', REPO, 'show', 'origin/main:' + path], capture_output=True, text=True).stdout
        else:
            out = open(os.path.join(WT, path)).read()
        cache[key] = out.split('\n')
    return cache[key]
bad = n = 0
for c, lit, ln, ident, repo in pat.findall(html):
    path = consts[c] if c else lit
    ln = int(ln); n += 1
    L = lines(path, repo)
    text = L[ln - 1] if 0 < ln <= len(L) else ''
    ok = ident in text
    bad += not ok
    print(('ok  ' if ok else 'BAD ') + f"{'main' if repo else 'mo'}:{path}:{ln} [{ident}]  | {text.strip()[:90]}")
print(f'{n} refs, {bad} bad')
sys.exit(1 if bad else 0)
