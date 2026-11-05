#!/usr/bin/env python3
"""L40: walk counters on the 1e14 set (ctr14_{MR,GR}_m{1,2,3}_e14_b{57,62}.log, 3 fields each, totals)."""
import re, sys
D = sys.argv[1]
exact = {'b57': 13041966398, 'b62': 4229527892}
def surv(p):
    m = re.search(r'JOIN THROUGHPUT.*?survivors=(\d+)', open(p, errors='replace').read()); return int(m.group(1))
print('| 1e14 field (3 fields) | side | plane-rounds | plane-chunks | plane-groups | chunks per group | rounds per chunk | rounds per group | lane utilisation |')
print('|---|---|---|---|---|---|---|---|---|')
for b in exact:
    for t, n in (('MR', 'base'), ('GR', 'group walk (P)'), ('QR', 'the PR (Q)')):
        R, C, G = (surv(f'{D}/ctr14_{t}_m{m}_e14_{b}.log') for m in (1, 2, 3))
        print(f'| {b} | {n} | {R:.4e} | {C:.4e} | {G:.4e} | {C / G:.2f} | {R / C:.2f} | {R / G:.2f} | {100 * exact[b] / (32 * R):.1f} % |')
