#!/usr/bin/env python3
"""Brute-force soundness test of instant_check.cert/empty at small bases: every interval that contains a nice
number must not be proved empty."""
import sys; sys.path.insert(0, "/home/claude/projects/nice/scratchpad/2026-10-research-program/T28/raw")
import random, instant_check as ic
random.seed(1)
bad = tested = hits = 0
for b in range(5, 25):
    ic.B = b
    nice = []
    lo = 1
    while ic.nd(lo*lo) + ic.nd(lo**3) < b: lo += 1
    hi = lo
    while ic.nd(hi*hi) + ic.nd(hi**3) <= b: hi += 1
    for n in range(lo, hi):
        if ic.nd(n*n) + ic.nd(n**3) != b: continue
        d = ic.digits_of(n*n) + ic.digits_of(n**3)
        if len(set(d)) == b: nice.append(n)
    if not nice: continue
    for n in nice:
        for _ in range(200):
            a = random.randint(max(lo, n - random.choice([1, 10, 1000, 10**6])), n); e = random.randint(n, min(hi - 1, n + random.choice([1, 10, 1000, 10**6])))
            if ic.nd(a*a) + ic.nd(a**3) != b or ic.nd(e*e) + ic.nd(e**3) != b: continue
            tested += 1; hits += 1
            p, why, _, _ = ic.empty(a, e, 2000)
            if p: bad += 1; print("UNSOUND", b, n, a, e, why)
    print(b, len(nice), "nice numbers", flush=True)
print("intervals containing a nice number tested:", tested, "wrongly proved empty:", bad)
