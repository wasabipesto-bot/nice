#!/usr/bin/env python3
"""u64count.py LOG [LOG2]: per (kernel, base) in a CubeCL debug log, the
number of source lines naming u64 (WGSL `u64`), and the total lines. With
two logs, side by side, and whether each kernel's source is identical.
--show KERNEL@BASE prints the u64 lines of that block from the last log."""
import re, sys, hashlib
def blocks(path):
    text = open(path, errors="replace").read()
    out = {}
    for blk in re.findall(r"\[START_KERNEL_COMPILATION\](.*?)\[END_KERNEL_COMPILATION\]", text, re.S):
        name = re.search(r"^name: \S+?::(\w+)<", blk, re.M)
        base = re.search(r"^\s+base: (\d+),", blk, re.M)
        src = blk.split("\nsource:", 1)[-1]
        key = (name.group(1) if name else "?", int(base.group(1)) if base else None)
        out.setdefault(key, []).append(src)
    return out
args = [a for a in sys.argv[1:] if not a.startswith("--")]
show = [sys.argv[i + 1] for i, a in enumerate(sys.argv) if a == "--show"]
args = [a for a in args if a not in show]
logs = [blocks(p) for p in args]
keys = sorted(set().union(*logs), key=lambda k: (k[0], k[1] or 0))
pat = re.compile(r"\bu64\b|\bulong\b|unsigned long")
print("kernel@base | " + " | ".join(f"log{i+1}: variants, u64 lines, lines" for i in range(len(logs))) + (" | identical" if len(logs) == 2 else ""))
for k in keys:
    row = []
    hs = []
    for lg in logs:
        srcs = lg.get(k, [])
        if not srcs:
            row.append("-"); hs.append(None); continue
        u = [sum(1 for l in s.splitlines() if pat.search(l)) for s in srcs]
        n = [len(s.splitlines()) for s in srcs]
        row.append(f"{len(srcs)}, {u}, {n}")
        hs.append(sorted(hashlib.sha256(s.encode()).hexdigest()[:12] for s in srcs))
    ident = ""
    if len(logs) == 2:
        ident = " | " + ("yes" if hs[0] == hs[1] and hs[0] is not None else "no")
    print(f"{k[0]}@{k[1]} | " + " | ".join(row) + ident)
for sk in show:
    name, _, b = sk.partition("@")
    srcs = logs[-1].get((name, int(b) if b else None), [])
    for s in srcs[:1]:
        print(f"--- u64 lines of {sk} (last log, first variant):")
        for l in s.splitlines():
            if pat.search(l):
                print("   ", l.strip())
