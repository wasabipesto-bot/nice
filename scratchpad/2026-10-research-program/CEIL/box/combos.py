#!/usr/bin/env python3
"""combos.py: Q2 orders combined with Q4's sharing (lockstep) against today's kernel, from q6c raw files.
Usage: combos.py <base> files...   (maxpop 17 at base 64, 18 at base 65)"""
import sys, os
sys.argv, files = sys.argv[:2], sys.argv[2:]
src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'analyze.py')).read().split('\ndef main')[0]
exec(src)
b = sys.argv[1]
mp = 18 if b == '65' else 17
runs = [parse(f)[0] for f in files]
c = tot(runs, 'code')
base_kernel = mp * c['lane16']
print(f'base {b}, {len(runs)} slice(s), maxpop {mp}; today kernel work = lane slots x {mp} = {base_kernel}')
print('| variant | work, no sharing (lane x maxpop + ext) | shared, wave of 4 (lockstep) | shared, wave of 2 (lockstep) | today lockstep wave 4 / wave 2 |')
print('|---|---|---|---|---|')
t4 = c['q4w4_17'] * mp / 17
t2 = c['q4w2_17'] * mp / 17
for n in ['code', 'lex', 'lorder_ext', 'hyb3_cell', 'hyb5_cell']:
    d = tot(runs, n)
    if d is None:
        continue
    plain = (mp * d['lane16'] + d['wext16']) / base_kernel
    w4 = d['q4w4_trie'] / base_kernel
    w2 = d['q4w2_trie'] / base_kernel
    print(f"| {n} | {plain:.4f} (x{1/plain:.3f}) | {w4:.4f} (x{1/w4:.3f}); vs lockstep today {d['q4w4_trie']/t4:.4f} (x{t4/d['q4w4_trie']:.3f}) | "
          f"{w2:.4f} (x{1/w2:.3f}); vs lockstep today {d['q4w2_trie']/t2:.4f} (x{t2/d['q4w2_trie']:.3f}) | {t4/base_kernel:.4f} / {t2/base_kernel:.4f} |")
