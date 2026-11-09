#!/usr/bin/env python3
"""ptxof.py PTX_DIR NAME OUTDIR: write every NAME entry's PTX image from a CubeCL PTX cache dir to OUTDIR/<i>_<md5>.ptx."""
import sys, os, glob, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cbor_min import entries
root, name, out = sys.argv[1:4]; os.makedirs(out, exist_ok=True)
for chunk in sorted(glob.glob(f'{root}/cuda/*/ptx/chunk*.cbor')):
    for i, (s, e, ent) in enumerate(entries(open(chunk, 'rb').read())):
        v = ent['value']
        if name not in v['entrypoint_name']: continue
        img = bytes((x & 0xFF) for x in v['ptx']).rstrip(b'\0')
        h = hashlib.md5(img + b'\0').hexdigest()[:8]
        open(f'{out}/{i}_{h}.ptx', 'wb').write(img); print(f'{out}/{i}_{h}.ptx')
