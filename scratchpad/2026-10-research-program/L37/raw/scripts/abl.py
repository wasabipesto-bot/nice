#!/usr/bin/env python3
"""L37: join-kernel breakdown by ablation. python3 abl.py DIR (copy of the box's /root/l37/logs).
Modes (NICE_EXP_JOIN_ABL / TMIN, profile on): c full, a AND only, b walk without prefilter/stage, p walk + prefilter
without stage, z no AND, d full with TMIN huge (per-top AND); u = full with and_count = the walk's lane-rounds."""
import re, sys, glob, os, statistics as st
D = sys.argv[1] if len(sys.argv) > 1 else 'box'
med = st.median
KEYS = ['setup', 'device_wall', 'upload', 'inputs', 'top', 'bucket', 'join', 'check', 'read', 'probe', 'unattributed',
        'pairs', 'padded_pairs', 'survivors', 'checked', 'tops', 'listed', 'size']
def prof(path):
    """Per-field GPU_PROFILE dicts of the timed fields (size > 1e14)."""
    out = []
    for line in open(path, errors='replace'):
        if 'GPU_PROFILE' not in line:
            continue
        d = {}
        for k in KEYS:
            m = re.search(r'\b' + k + r'=([0-9.e+]+)\b', line)
            if m:
                d[k] = float(m.group(1))
        if d.get('size', 0) > 1e14:
            out.append(d)
    return out
def smi(path):
    mhz = []
    if not os.path.exists(path):
        return None
    for line in open(path, errors='replace'):
        p = [x.strip() for x in line.split(',')]
        try:
            if len(p) >= 8 and float(p[6].split()[0]) >= 90:
                mhz.append(float(p[1].split()[0]))
        except ValueError:
            pass
    return st.mean(mhz) if mhz else None
MODES = [('c', 'full (main)'), ('a', 'AND only'), ('b', 'walk, no prefilter/stage'), ('p', 'walk + prefilter, no stage'),
         ('z', 'no AND'), ('d', 'full, per-top AND (TMIN huge)')]
for fld, label in [('e17_b62', 'b62 1e17 (1 field)'), ('e16_b60', 'b60 1e16 (2 fields)')]:
    print(f'== {label}: per-field seconds (profiled), medians over rounds; rounds in brackets')
    R = {}
    for tag, name in MODES:
        runs = []
        for f in sorted(glob.glob(f'{D}/abl_{tag}_{fld}_r*.log')):
            p = prof(f)
            if not p:
                continue
            n = len(p)
            runs.append({k: sum(x.get(k, 0) for x in p) / n for k in KEYS} | {'mhz': smi(f[:-4] + '.smi'), 'f': os.path.basename(f)})
        R[tag] = runs
        if runs:
            j = [r['join'] for r in runs]; w = [r['device_wall'] for r in runs]
            print(f'  {tag} {name:32s} join {med(j):8.3f} ({", ".join(f"{x:.2f}" for x in j)})  device_wall {med(w):8.3f}  '
                  f'top {med([r["top"] for r in runs]):.2f} check {med([r["check"] for r in runs]):.2f}  '
                  f'survivors/field {runs[0]["survivors"]:.4g} checked {runs[0]["checked"]:.4g}  MHz {", ".join(f"{r["mhz"]:.0f}" if r["mhz"] else "-" for r in runs)}')
    if not all(R.get(t) for t in 'cabpz'):
        print('  (incomplete)'); continue
    J = {t: med([r['join'] for r in R[t]]) for t in R if R[t]}
    c = R['c']; field = med([r['device_wall'] - r['probe'] for r in c])
    parts = [('base (no AND: loads, copy, barriers)', J['z']), ('AND (a - z)', J['a'] - J['z']),
             ('walk: rounds + residue test (b - a)', J['b'] - J['a']), ('prefilter walk_pf (p - b)', J['p'] - J['b']),
             ('stage + flush (c - p)', J['c'] - J['p'])]
    print(f'  breakdown of the join ({J["c"]:.3f} s/field; field device {field:.3f} s excl. probe):')
    for name, v in parts:
        print(f'    {name:40s} {v:8.3f} s  {100 * v / J["c"]:5.1f} % of join  {100 * v / field:5.1f} % of field')
    # per-round paired differences
    for (name, t1, t0) in [('AND', 'a', 'z'), ('walk', 'b', 'a'), ('prefilter', 'p', 'b'), ('stage', 'c', 'p')]:
        diffs = [r1['join'] - r0['join'] for r1, r0 in zip(R[t1], R[t0])]
        print(f'      {name} per round: {", ".join(f"{x:.2f}" for x in diffs)}')
    if R.get('d'):
        print(f'  per-top AND (TMIN huge) join {J["d"]:.3f} vs {J["c"]:.3f}: #239 saves {J["d"] - J["c"]:.3f} s/field '
              f'({100 * (J["d"] - J["c"]) / J["d"]:.1f} % of the per-top join), field device {med([r["device_wall"] - r["probe"] for r in R["d"]]):.3f}')
    s_and = R['a'][0]['survivors']; s_rng = c[0]['survivors']; pairs = c[0]['pairs']; padded = c[0]['padded_pairs']
    print(f'  pairs {pairs:.4g} padded {padded:.4g}; AND pass bits (mode a) {s_and:.4g} = {100 * s_and / pairs:.2f} % of pairs; '
          f'in range (survivors) {s_rng:.4g} = {100 * s_rng / s_and:.1f} % of pass bits; prefilter passes {c[0]["checked"]:.4g} = {100 * c[0]["checked"] / s_rng:.2f} % of survivors')
    u = glob.glob(f'{D}/abl_u_{fld}.log')
    if u:
        pu = prof(u[0])
        if pu:
            lr = sum(x['survivors'] for x in pu) / len(pu)
            print(f'  walk lane-rounds (mode u) {lr:.4g}/field = {lr / 32:.4g} plane-rounds; useful lane-rounds (pass bits) {s_and:.4g} '
                  f'-> lane utilisation {100 * s_and / lr:.1f} %; in-range lanes {100 * s_rng / lr:.1f} %; '
                  f'plane-rounds per (plane, slot, chunk) = {lr / (padded / 32):.2f} (padded lanes x chunks = {padded / 32:.4g}); '
                  f'pass bits per lane-chunk {s_and / (padded / 32):.3f}')
