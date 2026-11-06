#!/usr/bin/env python3
"""L45: build a pinned PTX cache: every entry of BASE's cache, with the join_kernel entries replaced by JOINFROM's
entries of the same key (so two pins differ in the join kernel's PTX only); with --directive '.minnctapersm 6' (or
'.maxnreg 40') that directive is added to each join kernel's entry (after its .maxntid line) instead, which makes the
driver's JIT allocate for that occupancy (CubeCL emits only __launch_bounds__(256)).
python3 pin.py [--directive D] OUT BASE_DIR [JOINFROM_DIR]   (dirs = /root/l45/ptx/<run>)"""
import glob, os, sys, shutil, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cbor_min import entries, enc, key_raw
args = sys.argv[1:]; directive = None
if args[0] == '--directive': directive = args[1]; args = args[2:]
out, base = args[0], args[1]; jf = args[2] if len(args) > 2 else base
bdir = glob.glob(f'{base}/cuda/*/ptx')[0]; jdir = glob.glob(f'{jf}/cuda/*/ptx')[0]
rel = os.path.relpath(bdir, base)
jd = open(f'{jdir}/chunk0.cbor', 'rb').read()
J = {v['key']: jd[s:e] for s, e, v in entries(jd) if 'join_kernel' in v['value']['entrypoint_name']}
bd = open(f'{bdir}/chunk0.cbor', 'rb').read()
outb = b''; rep = 0; n = 0
for s, e, v in entries(bd):
    raw = bd[s:e]
    if 'join_kernel' in v['value']['entrypoint_name']:
        if v['key'] in J and jf != base:
            raw = J[v['key']]; rep += 1
        if directive:
            val = v['value']
            ptx = bytes((x & 0xFF) for x in val['ptx'])
            ptx2, k = re.subn(rb'(\.maxntid[^\n]*\n)', lambda m: m.group(1) + directive.encode() + b'\n', ptx, count=1)
            assert k == 1, 'no .maxntid line'
            arr = [b if b < 128 else b - 256 for b in ptx2]  # c_char = i8
            val2 = {'entrypoint_name': val['entrypoint_name'], 'shared_mem_bytes': val['shared_mem_bytes'], 'ptx': arr}
            kr = key_raw(bd, s)
            raw = bytes([0xA2]) + enc('key') + kr + enc('value') + enc(val2); rep += 1
    outb += raw; n += 1
od = f'{out}/{rel}'; shutil.rmtree(out, ignore_errors=True); os.makedirs(od)
open(f'{od}/chunk0.cbor', 'wb').write(outb)
shutil.copy(f'{bdir}/toc.json.log', f'{od}/toc.json.log')
chk = entries(outb); assert len(chk) == n
for (s, e, v), (s0, e0, v0) in zip(chk, entries(bd)):
    assert v['key'] == v0['key'] and v['value']['entrypoint_name'] == v0['value']['entrypoint_name']
print(f'pinned {out}: {n} entries, {rep} join entries changed ({"from " + jf if jf != base else ""}{" directive " + directive if directive else ""}; base {base})')
