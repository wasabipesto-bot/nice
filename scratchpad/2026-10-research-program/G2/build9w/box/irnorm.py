#!/usr/bin/env python3
"""irnorm.py DIR...: for every CubeCL IR listing (*.ir.txt, written beside each SPIR-V module by
CUBECL_DEBUG_SPIRV; the optimised IR the SPIR-V is emitted from), the kernel name and an md5 of the listing
with each run of consecutive phi lines sorted (cubecl-opt emits a block's phis in hash order, which differs
between two runs of the same binary). Sorted output: equal output = the same optimised programs."""
import glob, hashlib, os, re, sys
rows = []
for d in sys.argv[1:]:
    for f in glob.glob(os.path.join(d, "*.ir.txt")):
        name = re.sub(r"_0x[0-9a-f]+\.ir\.txt$", "", os.path.basename(f))
        out, run = [], []
        for l in open(f).read().split("\n") + [None]:
            if l is not None and " = phi [" in l:
                run.append(l.strip()); continue
            out.extend(sorted(run)); run = []
            if l is not None and l.strip():
                out.append(l)
        rows.append((os.path.basename(d.rstrip("/")), name, hashlib.md5("\n".join(out).encode()).hexdigest()))
for r in sorted(rows):
    print(*r)
