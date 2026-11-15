#!/usr/bin/env python3
"""Check instant_check's digit extraction at base 62 on random sub-intervals of real b62 fields: every sampled n
(incl. the endpoints) has the claimed common digits of n^j at positions >= c and a digit in [lo, hi] at c-1."""
import json, random
B = 62; random.seed(7)
F = json.load(open('/home/claude/projects/nice/scratchpad/2026-10-research-program/T28/raw/fields_b62.json'))
bad = checks = 0
for _ in range(3000):
    f = random.choice(F); s, e = int(f['range_start']), int(f['range_end']) - 1
    w = 10 ** random.randint(0, 17); a = random.randint(s, e); b_ = min(e, a + random.randint(0, w))
    for j in (2, 3):
        A, E = a ** j, b_ ** j; c = 0; p = 1
        while A // p != E // p: c += 1; p *= B
        top = A // p; lo = hi = None
        if c: lo, hi = (A // (p // B)) % B, (E // (p // B)) % B
        for n in [a, b_] + [random.randint(a, b_) for _ in range(20)]:
            N = n ** j; checks += 1
            if N // p != top: bad += 1
            if c and not (lo <= (N // (p // B)) % B <= hi): bad += 1
print("checks", checks, "violations", bad)
