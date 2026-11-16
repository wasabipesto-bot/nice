"""E1 (brief Q2): how much of each output digit is determined by partial views of n.
For base b (exhaustive range), every output digit d_p of n^2 / n^3, every view = digits of n
on a subset S of positions (|S| <= L-2, so prefixes, suffixes, prefix+suffix, scattered),
report determinacy D = 1 - H(d_p | view)/H(d_p), Miller-Madow corrected, and the same with
the view shuffled (null). Prints, per output position, the best view of each size and the
best non-(prefix-or-suffix-certified) result.
"""
import sys, itertools, numpy as np
from common import nice_range, ndig

def H_cond(y, x, ycard):
    # conditional entropy H(y|x) in bits, Miller-Madow corrected
    key = x.astype(np.int64) * ycard + y
    _, cnt = np.unique(key, return_counts=True)
    _, xcnt = np.unique(x, return_counts=True)
    N = len(y)
    hxy = -(cnt / N * np.log2(cnt / N)).sum() + (len(cnt) - 1) / (2 * N * np.log(2))
    hx = -(xcnt / N * np.log2(xcnt / N)).sum() + (len(xcnt) - 1) / (2 * N * np.log(2))
    return hxy - hx

def main(b, maxn=None, maxsize=None):
    import random
    from common import digits
    lo, hi = nice_range(b)
    if maxn and hi - lo > maxn:
        random.seed(1); ns = sorted(random.sample(range(lo, hi), maxn))
    else:
        ns = list(range(lo, hi))
    L = ndig(lo, b); L2 = ndig(lo * lo, b); L3 = ndig(lo ** 3, b)
    D1 = np.array([digits(v, b, L) for v in ns], dtype=np.int64)
    D2 = np.array([digits(v * v, b, L2) for v in ns], dtype=np.int64)
    D3 = np.array([digits(v ** 3, b, L3) for v in ns], dtype=np.int64)
    n = D1[:, 0]
    nd = [D1[:, i] for i in range(L)]
    outs = [('sq', p, D2[:, p]) for p in range(L2)] + [('cu', p, D3[:, p]) for p in range(L3)]
    print(f'base {b}: L={L} sq {L2} cu {L3} digits, N={len(n)}')
    rng = np.random.default_rng(7)
    res = []
    for size in range(1, (maxsize or L - 2) + 1):
        for S in itertools.combinations(range(L), size):
            x = np.zeros(len(n), dtype=np.int64)
            for i in S: x = x * b + nd[i].astype(np.int64)
            xs = rng.permutation(x)
            kind = 'pre' if S == tuple(range(L - size, L)) else 'suf' if S == tuple(range(size)) else \
                   'p+s' if all(i in S for i in range(min(S)+0, 0)) else 'mix'
            # classify: prefix part + suffix part?
            top = 0
            while L - 1 - top in S: top += 1
            bot = 0
            while bot in S: bot += 1
            kind = 'ends' if top + bot == size else 'scattered'
            for (w, p, y) in outs:
                h0 = H_cond(y, np.zeros_like(y), b)
                h = H_cond(y, x, b); hn = H_cond(y, xs, b)
                res.append((w, p, S, kind, top, bot, 1 - h / h0, 1 - hn / h0))
    # report
    D = {(r[0], r[1], r[2]): r[6] - r[7] for r in res}  # null-corrected
    def ends_of(S):
        top = 0
        while L - 1 - top in S: top += 1
        bot = 0
        while bot in S: bot += 1
        return tuple(sorted(set(range(bot)) | set(range(L - top, L))))
    print('size | certified(D>.99) | partial D in (.1,.99) | best scattered gain D(S)-D(ends(S)) [pos, S]')
    print('max D over all views, per output position:', ' '.join(f"{w}{p}:{max(D[(w,p,S)] for S in {k[2] for k in D}):.2f}" for (w,p,_) in outs))
    for size in range(1, (maxsize or L - 2) + 1):
        views = [S for S in itertools.combinations(range(L), size)]
        for S in views:
            E = ends_of(S)
            cert = [(w, p) for (w, p, _) in outs if D[(w, p, S)] > .99]
            part = [(w, p, round(D[(w, p, S)], 2)) for (w, p, _) in outs if .1 < D[(w, p, S)] <= .99]
            gains = []
            for (w, p, _) in outs:
                d0 = D[(w, p, E)] if E else 0.0
                gains.append((D[(w, p, S)] - d0, w, p))
            g = max(gains)
            print(f'{size} S={S} ends={E} cert={len(cert)} partial={part} maxgain={g[0]:.3f}@{g[1]}{g[2]}')
    return res

if __name__ == '__main__':
    main(int(sys.argv[1]), int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] != '0' else None, int(sys.argv[3]) if len(sys.argv) > 3 else None)
