#!/usr/bin/env python3
"""Work unit above 64: padded virtual coordinate per base and shape. [D exact arithmetic + central G2 cost]"""
import math
from facts import facts
COST = {64: 1.24, 65: 3.09, 68: 1.61, 69: 1.34, 70: 1.00}  # central G2 fs/adm (raw/price_out.txt)
for b, f0, k in [(64, 4, 10), (65, 4, 10), (68, 4, 10), (69, 4, 10), (70, 4, 11)]:
    f = facts(b); s, e, W = f['s'], f['e'], f['W']
    h0, h1 = s // b ** k, (e - 1) // b ** k
    Hn = h1 - h0 + 1
    V = Hn * b ** k              # padded coordinate span
    pad = V - W
    nsu = b ** (k - 1 - f0)
    blk = Hn * b ** (f0 + 1)     # n-coordinates per super-unit
    adm_su = W / nsu * f['R'] / (b - 1)
    ms = adm_su * COST[b] * 1e-15 * 1e3
    print(f"b{b} ({f0},{k}): leads h in [{h0},{h1}] Hn={Hn} | v span Hn*b^k = {V:.6e} vs W {W:.6e}: padding {pad:.3e} n "
          f"({pad/W*100:.4f} %) | v max start+V = 2^{math.log2(s+V):.3f} (true end 2^{math.log2(e):.3f}) | super-units {nsu:.4e}, "
          f"{blk:.4e} v per super-unit (not a power of 2 or 10: {blk}), adm/SU {adm_su:.3e}, ~{ms:.2f} ms per SU on a 3080 (central)")
