#!/usr/bin/env python3
"""L45: write the join_kernel images of a pinned / run PTX cache to OUTDIR/join_<key>.ptx (in compile order, with
their keys listed in OUTDIR/keys.txt).  python3 extract_ptx.py PTX_DIR OUTDIR"""
import glob, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cbor_min import entries
root, out = sys.argv[1:3]; os.makedirs(out, exist_ok=True)
d = open(glob.glob(f'{root}/cuda/*/ptx/chunk0.cbor')[0], 'rb').read()
with open(f'{out}/keys.txt', 'w') as kf:
    for s, e, v in entries(d):
        if 'join_kernel' in v['value']['entrypoint_name']:
            img = bytes((x & 0xFF) for x in v['value']['ptx']).rstrip(b'\0')
            open(f'{out}/join_{v["key"]}.ptx', 'wb').write(img); kf.write(f'{v["key"]}\n')
            print('wrote', v['key'], len(img))
