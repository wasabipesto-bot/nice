#!/usr/bin/env python3
"""L40: walk counters (NICE_EXP_JOIN_ROUNDS modes 1-3) -> rounds per group / chunk and lane utilisation.
python3 ctr.py DIR. Logs DIR/ctr_{MR,GR}_m{1,2,3}_{e17_b62,e16_b60}.log; the exact survivors (= useful lane-rounds,
pass bits in range) are the fields' known counts."""
import re, sys
D = sys.argv[1]
exact = {'e17_b62': 1020844021499, 'e16_b60': 460847952346}
def surv(path):
    m = re.search(r'JOIN THROUGHPUT.*?survivors=(\d+)', open(path, errors='replace').read())
    return int(m.group(1)) if m else None
rows = {}
for t in ['MR', 'GR']:
    for f in exact:
        rows[(t, f)] = {m: surv(f'{D}/ctr_{t}_m{m}_{f}.log') for m in (1, 2, 3)}
print('| field | side | plane-rounds | plane-chunks | plane-groups | rounds per chunk | rounds per group | lane-rounds (32 per plane-round) | useful lane-rounds (survivors) | lane utilisation |')
print('|---|---|---|---|---|---|---|---|---|---|')
for f in exact:
    for t, name in (('MR', 'base af21136'), ('GR', 'group walk')):
        r = rows[(t, f)]
        if None in r.values():
            print(f'| {f} | {name} | missing |'); continue
        R, C, G = r[1], r[2], r[3]
        print(f'| {f} | {name} | {R:.4e} | {C:.4e} | {G:.4e} | {R / C:.2f} | {R / G:.2f} | {32 * R:.4e} | {exact[f]:.4e} | {100 * exact[f] / (32 * R):.1f} % |')
    a, b = rows[('MR', f)][1], rows[('GR', f)][1]
    if a and b: print(f'| {f} | group / base | ×{b / a:.3f} rounds | | | | | | | |')
