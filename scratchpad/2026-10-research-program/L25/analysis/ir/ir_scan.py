#!/usr/bin/env python3
"""Scan clang -O2 LLVM IR of naga MSL for constant udiv/urem that come from
dividing a half-width right shift by a constant (the Apple M4 trigger).

LLVM's InstCombine folds `udiv (lshr X, 16), K` into `udiv X, K << 16`, so a
hit is either form:
  * divisor (unsigned) = K * 2^16 with K odd-part > 1 (i32), or K * 2^32 (i64);
  * dividend = `lshr i32 X, 16`, or `trunc (lshr i64 Y, >= 32)`.
urem by such a constant is reported too. Constants print signed in IR, so
they are read back as unsigned of the operand width."""
import re, sys

def is_pow2(k):
    return k & (k - 1) == 0

for path in sys.argv[1:]:
    defs, fn, hits, ndiv = {}, None, [], 0
    for ln in open(path).read().splitlines():
        m = re.match(r'define .*@(\w+)\(', ln)
        if m:
            fn, defs = m.group(1), {}
            continue
        m = re.match(r'\s*(%[\w.]+) = (.*)$', ln)
        if not m:
            continue
        v, rhs = m.groups()
        defs[v] = rhs
        dm = re.match(r'(udiv|urem)(?: exact)? (i16|i32|i64) (%[\w.]+), (-?\d+)$', rhs)
        if not dm:
            continue
        op, ty, a, k = dm.groups()
        w = int(ty[1:])
        k = int(k) % (1 << w)
        ndiv += 1
        if is_pow2(k):
            continue
        why = []
        if w == 16:
            why.append('narrowed to i16 (a 16-bit value from a wider shift)')
        half = w // 2
        if w > 16 and k % (1 << half) == 0 and not is_pow2(k >> half):
            why.append(f'divisor = {k >> half} << {half} (folded half-width shift)')
        d = defs.get(a, '')
        sm = re.match(r'lshr (?:exact )?(i32|i64) (%[\w.]+), (\d+)', d)
        if sm and int(sm.group(3)) == (16 if sm.group(1) == 'i32' else 32):
            why.append(f'dividend = {d}')
        tm = re.match(r'trunc (?:nuw |nsw )*i64 (%[\w.]+) to i32', d)
        if tm:
            im = re.match(r'lshr (?:exact )?i64 (%[\w.]+), (\d+)', defs.get(tm.group(1), ''))
            if im and int(im.group(2)) >= 32:
                why.append(f'dividend = trunc(lshr i64 by {im.group(2)})')
        if why:
            hits.append((fn, v, f'{op} {ty} {a}, {k}', '; '.join(why)))
    print(f'## {path}: const udiv/urem {ndiv}, half-shift-derived {len(hits)}')
    for h in hits[:400]:
        print(f'   {h[1]} = {h[2]}   [{h[3]}]')
