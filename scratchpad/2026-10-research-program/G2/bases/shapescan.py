#!/usr/bin/env python3
"""Shape scan (digit model + measured P_T, raw/ptop.txt) priced with v10's measured b64 unit costs. [D]
Only for choosing which shapes to measure; the reported counts come from the prototype (su/sample)."""
import math, re
from facts import facts
def P(b, m): return math.prod(1 - i / b for i in range(int(m)))
PT = {}
for line in open('raw/ptop.txt'):
    m_ = re.match(r'PTOP b(\d+) f0 (\d+) k (\d+) .* P_T ([\d.]+) ', line)
    if m_: PT[(int(m_[1]), int(m_[2]))] = float(m_[4])
F = {b: facts(b) for b in (64, 65, 68, 69, 70)}
# v10 unit costs (BENCH.md, b64): ps
C = dict(root=48.6, child=18.5, kept=32.0, top=104.0, surv=25.0)
corr = 7.544e-6 * F[64]['A'] / (64 ** 10 * P(64, 20))   # measured children / digit model at b64 (4,10)
print(f"bottom correction (measured/P(2k)) at b64 k10: {corr:.3f}")
for b in (64, 65, 68, 69, 70):
    f = F[b]; A, W, R = f['A'], f['W'], f['R']
    rows = []
    for f0 in (3, 4, 5):
        for k in (9, 10, 11, 12):
            pt = PT.get((b, f0)) or PT.get((b, 4)) * 0  # only measured f0
            if not pt: continue
            pb = P(b, 2 * k) * corr
            nsu = b ** (k - 1 - f0)
            roots = b ** f0 * P(b, 2 * f0) * corr * nsu / A
            children = b ** k * pb / A
            tops = (b - 1) / (R * b ** f0)
            pairs = pt * pb
            # chunks per class group per unit: children per unit / (b-1) / 64
            per_grp = b ** f0 * pb / (b - 1)
            flat = pairs / per_grp * math.ceil(per_grp / 64) if per_grp > 0 else 0
            kept = 0.49 * flat
            surv = pairs * 2.634e-6 / 3.5746e-3 * (P(b, 0) if False else 1)  # pass rate held at b64's (guess-level)
            cost = {'prep': roots * C['root'], 'bottom': children * C['child'], 'words': kept * C['kept'],
                    'tops': tops * C['top'], 'surv': surv * C['surv']}
            tot = sum(cost.values()) * 1e3  # ps -> fs
            rows.append((tot, f0, k, cost, per_grp))
    rows.sort()
    for tot, f0, k, cost, g in rows[:5]:
        print(f"b{b} (f0 {f0}, k {k}): {tot:.3f} fs/adm  " + ' '.join(f"{n}={v*1e3:.3f}" for n, v in cost.items()) + f"  children/class group/unit {g:.0f}")
