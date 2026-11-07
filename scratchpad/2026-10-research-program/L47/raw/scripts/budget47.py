#!/usr/bin/env python3
"""L47: the check kernel's per-survivor budget by category (current SASS), the calibration against L45's measured
check time, and the reworked kernels' op-count models. Reads the simulated survivors (surv/*.jsonl) via warpsim."""
import sys, os, collections, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sasscost import PRO, SQ_EXIT, EPI, CU_SETUP, SQ, CU, S
from warpsim import load, lane_info

def cat_pass(T, nl, zeros, neg, msd):
    """A pass split into: division (the limb loop), digits (chunk extraction + masks + dup), overhead."""
    div = collections.Counter(); dig = collections.Counter(); ovh = collections.Counter()
    ovh += T['head'] + T['mid'] + T['after'] + T['trim0'] + T['trimend'] + T['br'] + T['tail']
    if nl >= 4:
        ovh += T['pre4']
        for _ in range(nl // 4): div += T['loop4']
    for i in range(nl & 3): div += S(T['rem'][i])
    for _ in range(zeros): ovh += T['trim_z']
    if neg:
        ovh += T['ms0'] + T['msend']
        if msd >= 1: dig += T['msd1']
        for _ in range(msd - 1): dig += T['msdn']
    else:
        ovh += T['trim_nz']; dig += T['inter']
    return div, dig, ovh

def main(tag, files, secs, checks, mhz):
    meta, Sv = load(files)
    random.Random(5).shuffle(Sv)
    infos = [lane_info(r, meta) for r in Sv]
    W = [infos[32 * i: 32 * i + 32] for i in range(len(infos) // 32)]
    cats = collections.defaultdict(collections.Counter)
    for w in W:
        cats['prologue: loads, n, n^2 (binary), top limb'] += PRO
        cats['exit + epilogue (popcount, loop)'] += SQ_EXIT + EPI
        ps = w[0]['cur_sq_passes']
        npass = max((l['cur_sq_dead'] or len(ps)) for l in w)
        for p in ps[:npass]:
            d, g, o = cat_pass(SQ, *p)
            cats['n^2 scan: long division (12/limb)'] += d; cats['n^2 scan: chunk digits + masks + dup'] += g
            cats['n^2 scan: pass overhead (setup, trim, tail)'] += o
        live = [l for l in w if l['cur_sq_dead'] is None]
        if live:
            cats['n^3: multiply + setup'] += CU_SETUP
            cps = w[0]['cur_cu_passes']
            nc = max((l['cur_cu_dead'] or len(cps)) for l in live)
            for p in cps[:nc]:
                d, g, o = cat_pass(CU, *p)
                cats['n^3 scan: long division'] += d; cats['n^3 scan: digits + masks'] += g; cats['n^3 scan: pass overhead'] += o
    nw = len(W)
    tot = collections.Counter()
    for c in cats.values(): tot += c
    print(f'== {tag}: {len(infos)} simulated survivors, {nw} warps (32 survivors per warp-iteration)')
    print(f"{'category':48s} {'instr/warp-it':>13s} {'per survivor':>12s} {'share':>6s}  FMA   ALU   MIO  CBU")
    for k, c in cats.items():
        print(f"{k:48s} {c['n']/nw:13.1f} {c['n']/nw/32:12.2f} {c['n']/tot['n']:6.1%} {c['FMA']/nw:5.0f} {c['ALU']/nw:5.0f} {c['MIO']/nw:5.0f} {c['CBU']/nw:4.0f}")
    print(f"{'total':48s} {tot['n']/nw:13.1f} {tot['n']/nw/32:12.2f}        {tot['FMA']/nw:5.0f} {tot['ALU']/nw:5.0f} {tot['MIO']/nw:5.0f} {tot['CBU']/nw:4.0f}")
    issue = tot['n'] / nw; fma2 = 2 * tot['FMA'] / nw; alu2 = 2 * tot['ALU'] / nw
    fmaw = (2 * (tot['FMA'] - tot['wide']) + 4 * tot['wide']) / nw
    cyc = secs * mhz * 1e6 * 272 / (checks / 32)
    print(f'bounds per warp-iteration (SMSP cycles): issue {issue:.0f}, 2*ALU {alu2:.0f}, 2*FMA {fma2:.0f} (wide at 4: {fmaw:.0f})')
    print(f'measured (L45): {secs} s for {checks:.4g} checks at {mhz} MHz = {secs/checks*1e12:.1f} ps/check = {cyc:.0f} SMSP-cycles '
          f'per warp-iteration -> {issue/cyc:.3f} issued per cycle per SMSP')
    return issue, cyc

if __name__ == '__main__':
    R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'surv')
    main('b62 1e17', [f'{R}/b62_e17_s1.jsonl.gz', f'{R}/b62_e17_s2.jsonl.gz'], 9.140, 62_584_252_554, 1538)
    main('b60 1e16', [f'{R}/b60_e16_s1.jsonl.gz', f'{R}/b60_e16_s2.jsonl.gz'], 2.217, 30_871_838_404 / 2, 1490)
