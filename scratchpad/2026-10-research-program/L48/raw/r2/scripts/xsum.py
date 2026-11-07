#!/usr/bin/env python3
"""L48: one line per exactness run (chain_x.sh logs). python3 xsum.py DIR TAG..."""
import re, sys, glob
D = sys.argv[1]
def rd(f):
    try: return open(f, errors='replace').read()
    except FileNotFoundError: return ''
def ok(t): return 'ok' if 'test result: ok. 1 passed' in t else ('FAIL' if 'test result' in t else 'missing')
print('| run | #240 FD test | CPU reference | #235 certificates | dense b58 1e15 | dense b62 1e16 | whole b42 | 1e14 compare b57/60/62/64 | unit |')
print('|---|---|---|---|---|---|---|---|---|')
for tag in sys.argv[2:]:
    fd = rd(f'{D}/x_{tag}_topfd.log'); m = re.search(r'top_kernel on (\d+) fields, (\d+) batches \((\d+) with a clipped block\), (\d+) tops', fd)
    fdc = f'{ok(fd)}: {m.group(1)} fields, {m.group(2)} batches, {int(m.group(4)):,} tops' if m else ok(fd)
    ref = ok(rd(f'{D}/x_{tag}_ref.log'))
    ce = rd(f'{D}/x_{tag}_cert.log'); m = re.search(r'(\d+) intervals, (\d+) kept; (\d+) of the powers scanned above c0, (\d+) of them with the carry', ce)
    cec = f'{ok(ce)}: {int(m.group(1)):,} / {int(m.group(2)):,} / {int(m.group(3)):,} / {int(m.group(4)):,}' if m else ok(ce)
    ds = []
    for f in ['dense58', 'dense62']:
        t = rd(f'{D}/x_{tag}_{f}.log'); m = re.search(r'(\d+) per launch.*?(\d+) re-run; survivors (\d+) checked (\d+)', t)
        ds.append(f'{ok(t)}: {int(m.group(3)):,} / {int(m.group(4)):,}, {m.group(1)}/launch, {m.group(2)} re-run' if m else ok(t))
    wh = rd(f'{D}/x_{tag}_whole.log'); m = re.search(r'(\d+) partitions, (\d+) join survivors, (\d+) checked, hits \[\]', wh)
    whc = f'{ok(wh)}: {int(m.group(2)):,} / {int(m.group(3)):,}, no hits' if m else ok(wh)
    cm = rd(f'{D}/cmp_{tag}_e14.log')
    cnt = re.findall(r'base=(\d+) fields=1 in_flight=2 .*?survivors=(\d+) checked=(\d+) found=(\d+)', cm)
    stride = len(re.findall(r'STRIDE base=\d+ .*found=0', cm))
    cmc = ('ok' if 'test result: ok' in cm else 'FAIL') + f' (stride ×{stride}): ' + '; '.join(f'{int(s):,} / {int(c):,}' for b, s, c, f in cnt)
    un = rd(f'{D}/x_{tag}_unit.log'); unc = ', '.join(re.findall(r'test result: (ok. \d+ passed; \d+ failed)', un))
    print(f'| {tag} | {fdc} | {ref} | {cec} | {ds[0]} | {ds[1]} | {whc} | {cmc} | {unc} |')
