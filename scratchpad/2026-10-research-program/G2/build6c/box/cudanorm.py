#!/usr/bin/env python3
"""cudanorm.py LOG OUTDIR: split a CUBECL_DEBUG_LOG of CubeCL's CUDA compiler into one file per kernel source
(from its `extern "C" __global__` line to the next kernel's) and normalise what CubeCL varies between two
compilations of the same kernel IR: profiling lines (`| ... |`) dropped; local and shared-memory names renamed
V0, V1, ... in order of first use in the body (CubeCL numbers them from an IR counter and emits declarations in
hash order); shared-memory offsets dropped (CubeCL places the arrays in hash order; each is a multiple of 128
bytes); the declaration lines then sorted. Two kernels with equal output are the same program up to the names of
their variables and the placement of their shared arrays. Prints one md5 per kernel."""
import hashlib, os, re, sys
log, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
lines = [l for l in open(log).read().split("\n") if not l.startswith("|")]
starts = [i for i, l in enumerate(lines) if 'extern "C" __global__' in l]
decl = re.compile(r"^\s*(const\s+)?[A-Za-z_][A-Za-z0-9_]*\s+[lv]_[A-Za-z0-9_]+(\[[0-9]+\])?;\s*$")
smdecl = re.compile(r"^\s*\w+ \*(shared_memory_\d+) = reinterpret_cast<\w+\*>\(&dynamic_shared_mem\[\d+\]\);\s*$")
smcomment = re.compile(r"^\s*// Shared array size")
ident = re.compile(r"\b(l_[A-Za-z]*_?\d+|shared_memory_\d+)\b")
seen = {}
for j, s in enumerate(starts):
    e = starts[j + 1] if j + 1 < len(starts) else len(lines)
    blk = lines[s:e]
    name = re.search(r"(\w+)\s*\($", blk[0].rstrip()).group(1)
    decls = [l for l in blk if decl.match(l) or smdecl.match(l) or smcomment.match(l)]
    body = [l for l in blk if not (decl.match(l) or smdecl.match(l) or smcomment.match(l))]
    ren = {}
    for l in body:
        for m in ident.finditer(l):
            ren.setdefault(m.group(1), f"V{len(ren)}")
    sub = lambda l: ident.sub(lambda m: ren.get(m.group(1), "UNUSED_" + m.group(1)), l)
    decls = sorted(re.sub(r"\[\d+\]\);", "[OFF]);", sub(l)) for l in decls)
    text = "\n".join(decls + ["// ---- body"] + [sub(l) for l in body])
    k = seen.get(name, 0); seen[name] = k + 1
    fn = f"{name}_{k}.cu"
    open(os.path.join(out, fn), "w").write(text)
    print(hashlib.md5(text.encode()).hexdigest(), fn)
