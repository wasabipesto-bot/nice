import sys
import os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kernel_sim import band, ndig
def adversarial(b, l):
    bb = b; top = bb**l - 1; low = bb**(l-1)
    def alt(first):
        a = 0
        for i in range(l):
            d = b - 1 if (i + first) % 2 == 0 else 0
            a = a * bb + (1 if (i == 0 and d == 0) else d)
        return a
    v = [('top', top), ('low', low), ('low+1', low+1), ('alt0', alt(0)), ('alt1', alt(1))]
    for i in range(l):
        v.append((f'top-(b-1)b^{i}', top - (b-1)*bb**i)); v.append((f'low+b^{i}-1', low + bb**i - 1))
    for f in (3, 8):
        if f < l:
            w = bb**f; v.append((f'top/w*w f{f}', top//w*w)); v.append((f'low/w*w+w-1 f{f}', low//w*w + w - 1))
    return [(n, x) for n, x in v if low <= x <= top and x < 1 << 96]
for (b, l, s2, s3) in [(42,9,17,25),(50,10,20,30),(57,12,23,34),(60,12,24,36),(62,13,25,37),(64,13,26,38)]:
    lo, hi = band(b, s2, s3, l)
    kept = [n for n, x in adversarial(b, l) if lo <= x < hi and x // b**3 < 1 << 64]
    names = sorted(set(n.split('^')[0] if '^' in n else n for n in kept))
    print(f"b{b}: band [{lo}, {hi}); adversarial kept {len(kept)}/{len(adversarial(b,l))}: {names}; hi-1 kept: {any(x == hi-1 for n,x in adversarial(b,l))}")
# H max in windows (wide)
for (b, s, e, k2) in [(57,30000000000000000000,30000000000000300000,6),(58,114041927169846138720,114041927169846438720,6),(60,1573714731429953349518,1573714731429953649518,6),(64,52125117810081128433988,52125117810081128733988,6)]:
    l = ndig(e-1, b)
    print(f"b{b} window: real H max 2^{((e-1)//b**k2).bit_length()}, synthetic H bound b^(l-k2) = 2^{(b**(l-k2)).bit_length()-1:.0f}+")
