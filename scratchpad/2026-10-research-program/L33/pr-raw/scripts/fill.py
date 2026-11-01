#!/usr/bin/env python3
"""Fill PR-BODY.md's placeholders from md.py --pr. python3 fill.py BOXDIR PR-BODY.md"""
import subprocess, sys, re
D, P = sys.argv[1], sys.argv[2]
out = subprocess.run([sys.executable, __file__.replace('fill.py', 'md.py'), D, '--pr'], capture_output=True, text=True).stdout
lines = out.splitlines()
tab = '\n'.join(l for l in lines[:6] if l.startswith('|'))
bul = [l for l in lines if l.startswith('- ')]
nm_score = [l for l in lines if l.startswith('NiceMark score')][0]
nm_tab = '\n'.join(l for l in lines if l.startswith('|') and ('scenario' in l or 'msd' in l or l.startswith('|---|---|---|---|---|---|') and l.count('|') == 7))
pf = [re.search(r'per_field ratio ×([0-9.]+)', b).group(1) for b in bul]
s = open(P).read()
s = s.replace('TABLE_FIELDS', tab)
s = s.replace('PERFIELD_LINE', f'The harness\'s wall time per field (`per_field`) gives the same picture: ×{pf[0]}, ×{pf[1]}, ×{pf[2]} and ×{pf[3]}. Layouts were identical in both trees (5 partitions per launch at b62 1e17; 13, 4 and 6 at b62, b60 and b64 1e16).')
m = re.match(r'NiceMark score: #235 (\d+) \(([^;]+); spread ([0-9.]+ %)\) -> PR (\d+) \(([^;]+); spread ([0-9.]+ %)\): ×([0-9.]+); per round (.*)$', nm_score)
s = s.replace('TABLE_NM', f'- Score: {m.group(1)} → {m.group(4)}, **×{m.group(7)}**. Rounds: {m.group(2)} against {m.group(5)} (per round {m.group(8)}).\n- Scenarios (median rates):\n\n' + nm_tab)
b62 = [b for b in bul if b.startswith('- b62 1e16')][0]
sv = re.search(r'survivors #235 ([0-9,–]+) \| PR ([0-9,–]+);', b62)
s = s.replace('COUNTS_PLACEHOLDER', f'b62 1e16 survivors: {sv.group(1)} on #235, {sv.group(2)} with this PR')
open(P, 'w').write(s)
print(out)
