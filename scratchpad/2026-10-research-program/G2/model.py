#!/usr/bin/env python3
"""G2 count + cost model. Counts per admissible n; GPU unit costs calibrated to today's main
(N22 field profile, N1.G1 tile costs); CPU costs from this directory's prototype and N1.C1.

Run: python3 model.py   (pure Python, < 1 s)
Tags in output: [M] measured (here or cited), [D] derived, [G] guess.
"""
import math

# ---------------------------------------------------------------- exact base facts
def base_range(b):
    k = b // 5
    def cr(v, r):
        x = int(round(v ** (1.0 / r)))
        while x ** r < v: x += 1
        while x > 0 and (x - 1) ** r >= v: x -= 1
        return x
    m = b % 5
    if m == 0: return cr(b ** (3 * k - 1), 3), b ** k
    if m == 2: return b ** k, cr(b ** (3 * k + 1), 3)
    if m == 3: return cr(b ** (3 * k + 1), 3), cr(b ** (2 * k + 1), 2)
    if m == 4: return cr(b ** (2 * k + 1), 2), cr(b ** (3 * k + 2), 3)

def roots(b):
    m = b - 1; t = b * (b - 1) // 2 % m
    return [r for r in range(m) if (r * r + r ** 3) % m == t]

def P(b, m):
    return math.prod(1 - i / b for i in range(int(m)))

BASES = [58, 60, 62, 64]
INFO = {}
for b in BASES:
    s, e = base_range(b)
    W = e - s
    L = len(str(int(0))) if False else 0
    x = e - 1; L = 0
    while x: x //= b; L += 1
    R = len(roots(b))
    INFO[b] = dict(W=W, L=L, R=R, A=W * R / (b - 1))

# ---------------------------------------------------------------- measured inputs
# P_T(f0) and P_T(f0+1) (top certificate pass rates, positions >= k), prototype `ptop` [M] raw/ptop.txt
PT = {58: {3: .1113, 4: .1972, 5: .3161, 6: .4653}, 60: {3: .1035, 4: .1852, 5: .3008, 6: .4400},
      62: {3: .0713, 4: .1237, 5: .2129, 6: .3288}, 64: {3: .0626, 4: .1146, 5: .1966, 6: .3036}}
CT = {58: {3: 15.7, 4: 13.7, 5: 11.7}, 60: {3: 16.1, 4: 14.1, 5: 12.1},
      62: {3: 17.4, 4: 15.5, 5: 13.5}, 64: {3: 18.4, 4: 16.4, 5: 14.4}}  # mean cert digits [M]
BOT_CORR = 0.95  # measured bottoms / P(2k) b^k at b62 k9, k10 (0.950, 0.952) [M]
# AND pass rate (survivors / pairs) measured on real units [M]; others from the digit model, scaled
PASS_M = {(62, 4, 9): 5499060 / 2657848222, (62, 4, 10): 18566 / 21324896}

# today's main, GPU (RTX 3080 ~285 W), N22 table, one 1e17 field [M]; field/base-mean ratio from
# survivors per adm on that field vs N1.C1's 10-location base mean [D]
TODAY = {
    62: dict(field_s=58.1, adm_field=1e17 * 2 / 61, surv_field=1.097114812011e12,
             checks_field=6.6862268894e10, mean=dict(pairs=6.7e-3, surv=2.5e-4, checks=1.5e-5),
             shares={'tops (FD kernel)': 15.2, 'prefilter': 14.2, 'AND': 7.1, 'walk': 3.9,
                     'check': 3.9, 'join base': 4.4, 'bucket (bottoms)': 3.2,
                     'upload+host': 2.7, 'other': 2.9, 'copy': 0.6}),
    64: dict(field_s=92.8, adm_field=1e17 * 8 / 63, surv_field=3.092989872066e12,
             checks_field=1.91683594021e11, mean=dict(pairs=3.5e-3, surv=1.5e-4, checks=9.6e-6),
             shares={'tops (FD kernel)': 12.1, 'prefilter': 24.1, 'AND': 13.5, 'walk': 10.3,
                     'check': 10.3, 'join base': 6.8, 'bucket+upload+host+other': 15.7}),
}

# GPU unit costs [D] (see NOTES §3 for each derivation)
GPU = dict(
    c_top=0.17e-9,       # s per tested top (FD kernel), today's b62 field: 15.2 s / ~8.9e10
    c_bvisit=5e-12,      # s per bottom extension (bucket kernel 3.2 s / ~6.3e11 candidates)
    c_inc=(9e-12, 12e-12, 15e-12),  # s per (bottom, 64-top chunk): 8 table lookups (u64 slice op
                         # 0.64-0.9 ps each, N1.G1) + per-entry base 3.5-8 ps
    c_surv=17e-12,       # s per AND survivor (walk 5.6 + prefilter 11.7, N1.G1)
    c_check=58e-12,      # s per full check (today 3.9 s / 6.69e10)
    pf_pass=0.06,        # prefilter pass rate (checks/survivors today) [M]
    other=0.05,          # launches/upload/host as a fraction of the total [G]
)
# CPU (one EPYC-Rome thread, ivory) [M] here and N1.C1
CPU = dict(c_inc=7.0e-9, c_pair_scalar=0.27e-9, today_s_per_adm={62: 1.55e-11 / 1.09, 64: 6.81e-12 / 1.12},
           n1_two_level={62: 2.65e-12, 64: 3.5e-12})


def today_table(b):
    t = TODAY[b]
    ratio = (t['surv_field'] / t['adm_field']) / t['mean']['surv']
    per_adm_field = t['field_s'] / t['adm_field']
    return ratio, per_adm_field, per_adm_field / ratio


def g2_counts(b, f0, k):
    I = INFO[b]; W, A, R = I['W'], I['A'], I['R']
    pt, ptp = PT[b][f0], PT[b][f0 + 1]
    pb = P(b, 2 * k) * BOT_CORR
    c = {}
    c['tops_tested'] = W / b ** f0 * ptp / A          # children of certified parents, once per base
    c['tops'] = W / b ** f0 * pt / A
    # shared bottom tree: depth j nodes b^j P(2j); visits at depth j = b * nodes(j-1)
    c['bot_visits'] = sum(b ** j * P(b, 2 * (j - 1)) * BOT_CORR for j in range(1, k + 1)) / A
    c['bot_stored'] = b ** (k - 1) * P(b, 2 * (k - 1)) * BOT_CORR / A   # deepest level in registers
    c['bottoms'] = b ** k * pb / A
    c['pairs'] = pt * pb
    tgrp = W / b ** k * pt / (b - 1)
    c['T_grp'] = tgrp
    c['incidences'] = b ** k * pb * R * math.ceil(max(tgrp, 1e-9) / 64) / A if tgrp >= 1 else \
        b ** k * pb * R * (1 - math.exp(-tgrp)) / A
    pr = PASS_M.get((b, f0, k))
    if pr is None:
        cT = CT[b][f0]
        pr = P(b, cT + 2 * k) / (P(b, cT) * P(b, 2 * k))
        # scale by the measured/model ratio at b62 k9
        cT62 = CT[62][4]
        pr *= PASS_M[(62, 4, 9)] / (P(62, cT62 + 18) / (P(62, cT62) * P(62, 18)))
    c['pass'] = pr
    c['surv'] = c['pairs'] * pr
    return c


def g2_gpu(b, f0, k, kappa=1.0, which=1):
    c = g2_counts(b, f0, k)
    g = GPU
    parts = {
        'tops': c['tops_tested'] * g['c_top'],
        'bottoms': c['bot_visits'] * g['c_bvisit'],
        'AND (4R incidences)': c['incidences'] * g['c_inc'][which] * kappa,
        'survivors': c['surv'] * g['c_surv'],
        'checks': c['surv'] * g['pf_pass'] * g['c_check'],
    }
    tot = sum(parts.values()) / (1 - g['other'])
    parts['other'] = tot * g['other']
    return c, parts, tot


def main():
    print("== base facts [M exact]")
    for b in BASES:
        I = INFO[b]
        print(f"b{b}: L={I['L']} W={I['W']:.3e} roots={I['R']} A={I['A']:.3e}")
    print()
    print("== Amdahl table: today's main, GPU, per admissible n (field profile N22, base mean scaled) [M/D]")
    for b in (62, 64):
        ratio, fld, mean = today_table(b)
        t = TODAY[b]
        print(f"b{b}: field {fld*1e15:.2f} fs/adm, field/mean (survivors) {ratio:.2f} -> base mean {mean*1e15:.2f} fs/adm;"
              f" x10 budget {mean*1e14:.3f} fs")
        tot = sum(t['shares'].values())
        for name, s in t['shares'].items():
            print(f"   {name:28s} {s/tot*100:5.1f} %  {s/t['adm_field']/ratio*1e15:6.2f} fs/adm (mean)")
    print()
    print("== G2 counts per admissible n (transversal shape, shared bottom tree) [D from M]")
    hdr = f"{'b':>3} {'f0':>2} {'k':>2} {'tops_tested':>11} {'bot_visits':>10} {'bot_stored':>10} {'pairs':>9} {'T_grp':>8} {'incid.':>9} {'pass':>8} {'surv':>9}"
    print(hdr)
    for b in BASES:
        for f0, k in [(3, 9), (4, 9), (4, 10), (5, 10), (4, 11), (5, 11)]:
            c = g2_counts(b, f0, k)
            print(f"{b:>3} {f0:>2} {k:>2} {c['tops_tested']:11.3e} {c['bot_visits']:10.3e} {c['bot_stored']:10.3e} "
                  f"{c['pairs']:9.3e} {c['T_grp']:8.1f} {c['incidences']:9.3e} {c['pass']:8.2e} {c['surv']:9.3e}")
    print()
    print("== G2 on the GPU (4R AND, word-level survivor test), fs per admissible n; ratio vs today's base mean")
    for b in (62, 64):
        _, _, mean = today_table(b)
        for f0, k in [(3, 9), (4, 9), (4, 10), (5, 10), (5, 11)]:
            for kappa in (1.0, 0.76):
                row = []
                for which in (0, 1, 2):
                    c, parts, tot = g2_gpu(b, f0, k, kappa, which)
                    row.append(mean / tot)
                c, parts, tot = g2_gpu(b, f0, k, kappa, 1)
                ps = ' '.join(f"{n.split()[0]}={v*1e15:.3f}" for n, v in parts.items())
                print(f"b{b} (f0 {f0}, k {k}) kappa {kappa:.2f}: total {tot*1e15:.3f} fs  x{row[1]:.2f} "
                      f"(c_inc 9..15 ps: x{row[0]:.2f}..x{row[2]:.2f})  [{ps}]")
    print()
    print("== Ceiling: AND term alone (everything else free), best shape, kappa 1 / measured 0.76")
    for b in (62, 64):
        _, _, mean = today_table(b)
        best = None
        for f0 in (3, 4, 5):
            for k in (8, 9, 10, 11):
                c = g2_counts(b, f0, k)
                for kappa in (1.0, 0.76):
                    a = c['incidences'] * GPU['c_inc'][0] * kappa
                    if best is None or a < best[0]:
                        best = (a, f0, k, kappa)
        a, f0, k, kappa = best
        print(f"b{b}: min AND-only cost {a*1e15:.3f} fs at (f0 {f0}, k {k}, kappa {kappa}) with c_inc 9 ps"
              f" -> ceiling x{mean/a:.1f} even if tops, bottoms, survivors, checks and overhead were free")
    print()
    print("== CPU (one thread) [M here + N1.C1]")
    for b, (f0, k) in [(62, (4, 9)), (64, (4, 9))]:
        c = g2_counts(b, f0, k)
        n1 = CPU['n1_two_level'][b]
        and_n1 = c['pairs'] * 0.27e-9
        g2 = n1 - min(and_n1, n1 * 0.8) + c['incidences'] * CPU['c_inc']
        print(f"b{b}: today {CPU['today_s_per_adm'][b]:.3e} s/adm, N1 two-level {n1:.3e}, G2 (N1 with the AND"
              f" replaced by 4R at {CPU['c_inc']*1e9:.1f} ns/incidence) {g2:.3e} -> x{CPU['today_s_per_adm'][b]/g2:.1f}")


if __name__ == '__main__':
    main()
