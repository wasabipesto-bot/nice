#!/usr/bin/env python3
"""L41: the walk counters (NICE_EXP_JOIN_ROUNDS=1: plane-rounds in and_count) per level. python3 ctr41.py DIR.
Logs DIR/ctr_L{lv}_{e17_b62,e16_b60}.log; useful lane-rounds = the fields' exact survivors."""
import re, sys, os
D = sys.argv[1]
exact = {'e17_b62': 1020844021499, 'e16_b60': 460847952346}
def surv(path):
    if not os.path.exists(path): return None
    m = re.search(r'JOIN THROUGHPUT.*?survivors=(\d+)', open(path, errors='replace').read())
    return int(m.group(1)) if m else None
print('| field | level | plane-rounds | vs level 0 | lane-rounds (32 per plane-round) | useful (survivors) | lane utilisation |')
print('|---|---|---|---|---|---|---|')
for f in exact:
    base = surv(f'{D}/ctr_L0_{f}.log')
    for lv in (0, 3, 4):
        R = surv(f'{D}/ctr_L{lv}_{f}.log')
        if R is None: print(f'| {f} | {lv} | missing |'); continue
        rel = f'×{R / base:.6f} ({R - base:+d})' if base else '-'
        print(f'| {f} | {lv} | {R:,} | {rel} | {32 * R:.4e} | {exact[f]:,} | {100 * exact[f] / (32 * R):.1f} % |')
