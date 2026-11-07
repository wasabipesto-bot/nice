#!/usr/bin/env python3
"""L47: per-warp instruction model of the check kernel on simulated join survivors (joinsim.py output).

Designs:
  CUR  the kernel as compiled (post-#241 SASS, sasscost.py): binary n^2, chunk scan from digit 0 by long division
       (b^5 per pass), n^2 tested against itself only, n^3 built and scanned iff a lane passed n^2.
  B    the roadmap's form: the n^2 scan starts at digit 8 of floor(n^2/b^8) (exact division), seeded with the
       16 known low digits L; B+C also seeds the top's certified digits and stops below them.
  D    base-b^2 direct (this scoping's proposal): n in base-b^2 limbs, n^2 = schoolbook in base b^2, every digit
       from the carry normalisation, no division of a long number; gate on n^2's digits + the low g digits of
       n^3 (truncated product), the rest of n^3 only if a lane passes the gate.
Warp = 32 consecutive survivors (list order is unrelated to digit patterns). SIMT: a warp issues the union of
its lanes' paths, i.e. the longest pass sequence of n^2, and the cube if any lane needs it."""
import json, sys, os, collections, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sasscost import PRO, SQ_EXIT, EPI, CU_SETUP, SQ, CU, pass_cost

def limbs(x):
    return (x.bit_length() + 31) // 32

def load(paths):
    meta = None; S = []
    for p in paths:
        for line in open(p):
            d = json.loads(line)
            if 'meta' in d: meta = d['meta']
            elif 'n' in d: S.append(d)
    return meta, S

def digs(x, b, n):
    out = []
    for _ in range(n):
        out.append(x % b); x //= b
    return out

def scan_passes(X, b, cd=5):
    """The kernel's pass sequence over X: (nl, zeros, ends_negative, ms_digits) per pass."""
    out = []
    while X > 0:
        nl = limbs(X)
        q, r = divmod(X, b ** cd)
        if q == 0:
            nd = 0; t = r
            while t: t //= b; nd += 1
            out.append((nl, nl, True, nd))
        else:
            out.append((nl, nl - limbs(q), False, 0))
        X = q
    return out

def first_dup_chunk(ds, seen, start, cd=5):
    """ds: digits LSB first, scanned from index `start` in chunks of cd; returns the 1-based chunk index where a
    duplicate (vs seen or earlier scanned digits) first appears, or None."""
    s = set(seen)
    i = start; ch = 0
    while i < len(ds):
        ch += 1; dup = False
        for j in range(i, min(i + cd, len(ds))):
            if ds[j] in s: dup = True
            s.add(ds[j])
        if dup: return ch
        i += cd
    return None

def lane_info(rec, meta):
    b = meta['b']; s2 = meta['s2']; s3 = meta['s3']
    n = int(rec['n']); n2 = n * n; n3 = n2 * n
    D2 = digs(n2, b, s2); D3 = digs(n3, b, s3)
    L = set(D2[:8]) | set(D3[:8]); assert len(L) == 16
    M = rec['M']; F = rec['F']
    C = {d for d in range(64) if (M >> d) & 1 and not (F >> d) & 1}
    c2, c3 = rec['c2'], rec['c3']
    assert set(D2[c2:]) | set(D3[c3:]) == C, 'certified digits'
    nice = len(set(D2) | set(D3)) == b
    info = dict(nice=nice)
    # CUR: n^2 from digit 0, self only
    info['cur_sq_dead'] = first_dup_chunk(D2, [], 0)
    info['cur_sq_passes'] = scan_passes(n2, b)
    if info['cur_sq_dead'] is None:
        info['cur_cu_dead'] = first_dup_chunk(D3, D2, 0)
    info['cur_cu_passes'] = scan_passes(n3, b)
    # B: n^2 from digit 8 seeded with L; n^3 from digit 8 seeded with L + n^2
    q2 = n2 // b ** 8; q3 = n3 // b ** 8
    info['B_sq_dead'] = first_dup_chunk(D2, L, 8)
    info['B_sq_passes'] = scan_passes(q2, b)
    if info['B_sq_dead'] is None:
        info['B_cu_dead'] = first_dup_chunk(D3, L | set(D2), 8)
    info['B_cu_passes'] = scan_passes(q3, b)
    # B+C: n^2 positions 8..c2-1 seeded with L|C; n^3 positions 8..c3-1 seeded with L|C|n^2 mid
    info['BC_sq_dead'] = first_dup_chunk(D2[:c2], L | C, 8)
    info['BC_sq_passes'] = scan_passes(q2 % b ** (c2 - 8), b) if c2 > 8 else []
    if info['BC_sq_dead'] is None:
        info['BC_cu_dead'] = first_dup_chunk(D3[:c3], L | C | set(D2[8:c2]), 8)
    info['BC_cu_passes'] = scan_passes(q3 % b ** (c3 - 8), b)
    # D: gate = n^2 all distinct and the low g digits of n^3 distinct from them (g = 8, 10, 12, 14)
    sq_ok = len(set(D2)) == s2
    for g in (8, 10, 12, 14, 16):
        info[f'D_gate{g}'] = sq_ok and len(set(D2) | set(D3[:g])) == s2 + g
    # D+C: also the top's certified n^3 digits (record mask) in the gate
    for g in (8, 12):
        info[f'DC_gate{g}'] = sq_ok and len(set(D2) | set(D3[:g]) | (C - set(D2))) == s2 + g + len(set(D3[c3:]))
    info['c2'] = c2; info['c3'] = c3; info['nC'] = len(C)
    return info

def tot(c):
    return c['n']

def warp_cost_cur(lanes):
    c = PRO + SQ_EXIT + EPI
    passes = lanes[0]['cur_sq_passes']
    npass = max((l['cur_sq_dead'] or len(passes)) for l in lanes)
    for p in passes[:npass]: c += pass_cost(SQ, *p)
    live = [l for l in lanes if l['cur_sq_dead'] is None]
    if live:
        cps = lanes[0]['cur_cu_passes']
        nc = max((l['cur_cu_dead'] or len(cps)) for l in live)
        c += CU_SETUP
        for p in cps[:nc]: c += pass_cost(CU, *p)
    return c, bool(live), npass

def main():
    meta, S = load(sys.argv[1:])
    b = meta['b']
    random.Random(5).shuffle(S)
    infos = [lane_info(r, meta) for r in S]
    nw = len(infos) // 32
    W = [infos[32 * i: 32 * i + 32] for i in range(nw)]
    print(f"== b{b} L={meta['L']} s2={meta['s2']} s3={meta['s3']}: {len(infos)} survivors, {nw} warps")
    # lane-level statistics
    sq_dead = collections.Counter(i['cur_sq_dead'] for i in infos)
    print('CUR lane death pass (n^2 vs itself; None = passes n^2):', sorted(sq_dead.items(), key=lambda x: (x[0] is None, x[0] or 0)))
    print('CUR n^2 pass limb counts:', [p[0] for p in infos[0]['cur_sq_passes']], ' n^3:', [p[0] for p in infos[0]['cur_cu_passes']])
    uni = collections.Counter(tuple(i['cur_sq_passes']) for i in infos)
    print('CUR n^2 pass-shape variants:', len(uni), 'most common share', max(uni.values()) / len(infos))
    p_sq = sum(1 for i in infos if i['cur_sq_dead'] is None) / len(infos)
    print(f'CUR P(lane passes n^2) = {p_sq:.4f}; nice lanes: {sum(i["nice"] for i in infos)}')
    # warp-level, current
    agg = collections.Counter(); cube_w = 0; npass_hist = collections.Counter()
    for w in W:
        c, cube, npass = warp_cost_cur(w)
        agg += c; cube_w += cube; npass_hist[npass] += 1
    print(f"CUR per warp-iteration: {agg['n']/nw:.1f} instr (FMA {agg['FMA']/nw:.1f}, wide {agg['wide']/nw:.1f}, ALU {agg['ALU']/nw:.1f}, "
          f"MIO {agg['MIO']/nw:.1f}, CBU {agg['CBU']/nw:.1f}); per check {agg['n']/nw/32:.2f}; cube in {cube_w/nw:.3f} of warps; "
          f"n^2 passes {dict(sorted(npass_hist.items()))}")
    # B / B+C: lane death and warp passes
    for tag in ('B', 'BC'):
        dead = collections.Counter(i[f'{tag}_sq_dead'] for i in infos)
        live = sum(1 for i in infos if i[f'{tag}_sq_dead'] is None) / len(infos)
        wp = collections.Counter(); wc = 0; agg = collections.Counter()
        for w in W:
            ps = w[0][f'{tag}_sq_passes']
            npass = max((l[f'{tag}_sq_dead'] or len(ps)) for l in w)
            wp[npass] += 1
            for p in ps[:npass]: agg += pass_cost(SQ, *p)
            lv = [l for l in w if l[f'{tag}_sq_dead'] is None]
            if lv:
                wc += 1
                cps = w[0][f'{tag}_cu_passes']
                nc = max((l[f'{tag}_cu_dead'] or len(cps)) for l in lv)
                agg += CU_SETUP
                for p in cps[:nc]: agg += pass_cost(CU, *p)
        print(f"{tag}: lane death chunk {dict(sorted(dead.items(), key=lambda x: (x[0] is None, x[0] or 0)))}; P(lane passes n^2 part) {live:.5f}; "
              f"warp passes {dict(sorted(wp.items()))}; cube in {wc/nw:.4f} of warps; scan+cube instr per warp {agg['n']/nw:.1f} "
              f"(FMA {agg['FMA']/nw:.1f} ALU {agg['ALU']/nw:.1f}); Q2 pass limbs {[p[0] for p in infos[0][f'{tag}_sq_passes']]}")
    for g in (8, 10, 12, 14, 16):
        pl = sum(i[f'D_gate{g}'] for i in infos) / len(infos)
        pw = sum(any(l[f'D_gate{g}'] for l in w) for w in W) / nw
        print(f"D gate g={g}: P(lane passes) {pl:.5f}, P(warp has a lane past the gate) {pw:.4f}")
    for g in (8, 12):
        pl = sum(i[f'DC_gate{g}'] for i in infos) / len(infos)
        pw = sum(any(l[f'DC_gate{g}'] for l in w) for w in W) / nw
        print(f"D+C gate g={g}: P(lane passes) {pl:.5f}, P(warp) {pw:.4f}")
    print('c2 dist', dict(collections.Counter(i['c2'] for i in infos)), 'c3 dist', dict(collections.Counter(i['c3'] for i in infos)),
          'mean |C|', sum(i['nC'] for i in infos) / len(infos))

if __name__ == '__main__':
    main()
