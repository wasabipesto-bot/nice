#!/usr/bin/env python3
"""project.py LOGDIR: whole-base b62 projection for the transversal shapes from the calibration (cal_*) and the
tile harness (tgrid*, twalk*). Provenance: [M] measured on the box, [D] derived, [A] assumed/given by the brief."""
import re, sys, glob, os, statistics as st
D = sys.argv[1]
def kv(s): return {m.group(1): m.group(2) for m in re.finditer(r'(\w+)=([^ |]+)', s)}
# ---------- calibration [M]
cal = {}
for p in glob.glob(f'{D}/cal_*_r*.log'):
    mode = re.match(r'cal_(\w)_r', os.path.basename(p)).group(1); txt = open(p).read()
    t = kv(txt[txt.index('JOIN THROUGHPUT'):].splitlines()[0])
    d = {'per_field': float(t['per_field'])}
    pl = [l for l in txt.splitlines() if 'GPU_PROFILE' in l]
    if pl: d.update({k: float(v) for k, v in kv(pl[-1][pl[-1].index('GPU_PROFILE'):]).items() if re.match(r'^[0-9.e+-]+$', v)})
    cal.setdefault(mode, []).append(d)
med = lambda m, k: st.median(x[k] for x in cal[m])
F = med('T', 'per_field')
parts = {k: med('c', k) for k in ('top', 'bucket', 'join', 'check', 'upload', 'inputs', 'read', 'unattributed')}
S = F / sum(parts.values())               # profiled seconds -> unprofiled field seconds [D]
c = cal['c'][0]; pairs_f, surv_f, nbp, slices, parts_n = c['pairs'], c['survivors'], c['ntlay'] * 0 + 1071229, c['slices'], c['partitions']
dense_f = med('a', 'join'); survp_f = med('c', 'join') - dense_f
NF, NADM = 95430, 3.13e20                 # [A] fields per base, admissible n per base
today = {'dense': dense_f, 'survivor path': survp_f, 'tops': parts['top'], 'check': parts['check'], 'bucket/bottoms': parts['bucket'],
         'other (setup, inputs, reads)': parts['upload'] + parts['inputs'] + parts['read'] + parts['unattributed']}
today = {k: v * S * NF for k, v in today.items()}
T0 = sum(today.values())
ps_dense_prod = dense_f / pairs_f * 1e12
ps_surv_pair_prod = survp_f / pairs_f * 1e12
pass_prod = surv_f / pairs_f
print(f'[M] today (c0c357a) per field {F:.2f} s -> base {T0:.4e} s ({T0/86400/365:.2f} card-years on this 340 W 3080); profiled->unprofiled x{S:.3f}')
print(f'[M] production: pairs/field {pairs_f:.4e}, AND survivors {surv_f:.4e} (pass {100*pass_prod:.2f} %), dense {ps_dense_prod:.4f} ps/pair, survivor path {ps_surv_pair_prod:.4f} ps/pair = {survp_f/surv_f*1e12:.2f} ps/survivor (profiled seconds)')
print('[D] today per base:', {k: f'{v:.3e} s ({100*v/T0:.1f} %)' for k, v in today.items()})
# ---------- harness [M]
R = {}
for p in glob.glob(f'{D}/t*_L*.log'):
    lay = re.search(r'_L(\d+)', os.path.basename(p)).group(1)
    for l in open(p):
        if l.startswith('N1 round='):
            d = kv(l); R.setdefault((lay, d['cfg']), []).append(d)
def h(lay, cfg): return st.median(float(d['ps_pair_mean']) for d in R[(lay, cfg)])
def hw(lay, cfg):  # walk extra ps/pair (walk - dense, same process and round)
    a = {(d['round']): float(d['secs_mean']) for d in R[(lay, cfg)]}
    v = [(float(d['secs_mean']) - a[d['round']]) / float(d['pairs']) * 1e12 for d in R[(lay, cfg + '_walk')] if d['round'] in a]
    return st.median(v), float(R[(lay, cfg + '_walk')][0]['pass'])
def wfit(lay, o, s, wn):
    pts = [hw(lay, f'{o}_B{db}_T{dt}_{s}_{wn}') for (db, dt) in ((12, 15), (12, 17), (18, 14), (18, 15), (20, 15))]
    xs = [p for _, p in pts]; ys = [y for y, _ in pts]
    mx, my = st.mean(xs), st.mean(ys); b = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / sum((x - mx) ** 2 for x in xs)
    return my - b * mx, b, pts
cal5, cal1 = h('5', 'T_B12_T17_Sp_u32'), h('1', 'T_B12_T17_Sp_u32')
print(f'[M] harness at today\'s mean shape (471 x 336, D_B 12, u32): L5 {cal5:.4f} ({100*(cal5/ps_dense_prod-1):+.1f} % vs production), L1 {cal1:.4f} ({100*(cal1/ps_dense_prod-1):+.1f} %)')
# base / AND split (T2's no-AND mode) [M]
def hb(lay, cfg):
    full = st.median(float(d['ps_pair_mean']) for d in R[(lay, cfg)] if d.get('noand') == '0')
    base = st.median(float(d['ps_pair_mean']) for d in R[(lay, cfg + '_noand')])
    return full, base, full - base
prod_base = med('z', 'join') / pairs_f * 1e12; prod_and = ps_dense_prod - prod_base
_, hb0, ha0 = hb('1', 'T_B12_T17_Sp_u32')
kB, kA = prod_base / hb0, prod_and / ha0
print(f'[M] production split: base {prod_base:.4f} + AND {prod_and:.4f}; harness L1 at 471 x 336: base {hb0:.4f} + AND {ha0:.4f} -> kB {kB:.3f}, kA {kA:.3f}')
a0, b0, pts0 = wfit('1', 'T', 'S0', 'u32')
w_prod_fit = a0 + b0 * pass_prod
kw = ps_surv_pair_prod / w_prod_fit
print(f'[M/D] walk fit (L1, today orientation, 2,000 x 350, u32): {a0:.4f} + {b0:.3f} x pass ps/pair; at production pass {100*pass_prod:.2f} % -> {w_prod_fit:.4f} against production {ps_surv_pair_prod:.4f} ps/pair (kw {kw:.3f})')
for (o, s_, wn) in (('T', 'S1', 'u32'), ('T', 'S1', 'u64a2'), ('R', 'S1', 'u32'), ('R', 'S1', 'u64a2')):
    a, b, pts = wfit('1', o, s_, wn)
    print(f'     walk fit L1 {o} {s_} {wn}: {a:.4f} + {b:.3f} x pass; points ' + ', '.join(f'{100*p:.3f} %: {y:.3f}' for y, p in pts))
# ---------- projection
SHAPES = {'f0 4, k 9': dict(pairs=8.0e-3, surv=2.7e-5, tops=1.4e14, tile='S1'), 'f0 3, k 9': dict(pairs=4.3e-3, surv=1.3e-5, tops=5e15, tile='S3')}
TOPS_TODAY = 8.9e10 * NF                  # [A] tested tops per base at today's shape (L51/NOTES count behind 0.21 ns)
c_ext = parts['bucket'] * S / (nbp * parts_n * slices)   # [D] s per bottom extension (today's bucket kernel)
c_top = today['tops'] / TOPS_TODAY
print(f'[D] bottom extension {c_ext*1e12:.1f} ps (today\'s bucket kernel per bpre entry, partition and slice); top test {c_top*1e9:.3f} ns')
VAR = [('today, u32', 'T', 'u32'), ('today, u64 AG 2', 'T', 'u64a2'), ('today, u64 AG 4', 'T', 'u64a4'),
       ('reverse, u32', 'R', 'u32'), ('reverse, u64 AG 2', 'R', 'u64a2'), ('reverse, u64 AG 4', 'R', 'u64a4')]
OTHER = float(os.environ.get('OTHER', 0.02))   # [A] per-unit overhead, share of today's base
CHILD = float(os.environ.get('CHILD', 1.0))    # [E] f0 3 top test cost relative to a full FD test (step 4)
print(f'\nprojection: other {100*OTHER:.0f} % of today, f0 3 top test x{CHILD}')
print('| shape | D_B | D_T | variant | harness ps/pair (L1) | dense ps/pair: split / same-layout / raw | walk ps/pair | dense s | survivor s | tops s | check s | bottoms s | other s | total s (split) | speedup split | same-layout | raw |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
for sh, n in SHAPES.items():
    P = n['pairs'] * NADM; SV = n['surv'] * NADM; pnew = SV / P
    for db, dt in ((18, 17), (18, 15), (20, 15)):
        for vn, o, wn in VAR:
            cfg = f'{o}_B{db}_T{dt}_{n["tile"]}_{wn}'
            if ('1', cfg) not in R: continue
            hn = h('1', cfg)
            bcfg = f'{o}_B{db}_T17_S1_{wn}'      # base/AND split measured at 1,460 x 14,750, D_T 17
            if ('1', bcfg + '_noand') in R and n['tile'] == 'S1':
                fb, bb, ab = hb('1', bcfg); bfrac = bb / fb
            else:
                fb, bb, ab = hb('1', f'{o}_B{db}_T17_S1_{wn}') if ('1', f'{o}_B{db}_T17_S1_{wn}_noand') in R else (1, 0.35, 0.65); bfrac = bb / fb
            ps_split = hn * (bfrac * kB + (1 - bfrac) * kA)
            ps_same = hn * ps_dense_prod / cal1
            ps_raw = hn
            wo = o; wwn = 'u64a2' if wn != 'u32' else 'u32'
            a, b, _ = wfit('1', wo, 'S1', wwn)
            wp = (a + b * pnew) * kw
            surv = P * wp * S * 1e-12
            # f0 3 with CHILD < 1: the f0 4 parents get a full test, their children the cheaper one (step 4)
            tops = c_top * (n['tops'] if (CHILD >= 1 or not sh.startswith('f0 3')) else 1.4e14 + 5e15 * CHILD)
            check = today['check'] / 10
            bott = 1.5e15 * c_ext
            other = OTHER * T0
            rest = surv + tops + check + bott + other
            tots = [P * x * S * 1e-12 + rest for x in (ps_split, ps_same, ps_raw)]
            dense = P * ps_split * S * 1e-12
            print(f'| {sh} | {db} | {dt} | {vn} | {hn:.3f} | {ps_split:.3f} / {ps_same:.3f} / {ps_raw:.3f} | {wp:.3f} | ' + ' | '.join(f'{x:.2e}' for x in (dense, surv, tops, check, bott, other)) + f' | {tots[0]:.3e} | **×{T0/tots[0]:.2f}** | ×{T0/tots[1]:.2f} | ×{T0/tots[2]:.2f} |')
