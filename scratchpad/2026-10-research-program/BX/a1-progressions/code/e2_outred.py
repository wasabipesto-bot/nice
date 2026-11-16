"""E2 (brief Q3 in general form): hidden redundancy among OUTPUT digits.
If some set S of output digits predicts another output digit q (beyond the prefix/suffix structure),
prescribing outputs first could certify more than 2 digits per digit of n. Measure null-corrected
D(d_q | d_p) for all pairs and D(d_q | d_p, d_r) for all triples, base b exhaustive (b <= 23).
Report every (S -> q) with D > thr, classified by whether q is a 'middle' digit."""
import sys, itertools, numpy as np
from common import nice_range, ndig
from e1_entropy import H_cond
b = int(sys.argv[1]); thr = float(sys.argv[2]) if len(sys.argv) > 2 else 0.05
lo, hi = nice_range(b); L = ndig(lo, b); L2 = ndig(lo*lo, b); L3 = ndig(lo**3, b)
n = np.arange(lo, hi, dtype=np.uint64); sq = n*n; cu = sq*n
outs = [(f'sq{p}', ((sq // np.uint64(b)**np.uint64(p)) % np.uint64(b)).astype(np.int64)) for p in range(L2)] + \
       [(f'cu{p}', ((cu // np.uint64(b)**np.uint64(p)) % np.uint64(b)).astype(np.int64)) for p in range(L3)]
rng = np.random.default_rng(5)
h0 = {name: H_cond(y, np.zeros_like(y), b) for name, y in outs}
def D(y, x, name):
    return (H_cond(y, rng.permutation(x), b) - H_cond(y, x, b)) / h0[name]
print(f'base {b} L={L} N={len(n)}; pairs/triples with D > {thr}')
# middle = positions whose best single n-view of <= L-2 digits has D < 0.05 (from E1): use rule:
mid = set([f'sq{p}' for p in range(3, L2-3)] + [f'cu{p}' for p in range(3, L3-3)])
best1 = {}
for (pn, yp), (qn, yq) in itertools.permutations(outs, 2):
    d = D(yq, yp, qn)
    best1[qn] = max(best1.get(qn, (-1, '')), (d, pn))
    if d > thr: print(f'pair  {pn} -> {qn}: D={d:.3f}', '(middle target)' if qn in mid else '')
print('best single predictor per target:', ' '.join(f'{q}:{d:.2f}<-{p}' for q, (d, p) in best1.items()))
# triples: target middle digits only, predictors any two output digits
cnt = 0; top = []
for qn, yq in outs:
    if qn not in mid: continue
    for (pn, yp), (rn, yr) in itertools.combinations([o for o in outs if o[0] != qn], 2):
        x = yp * b + yr
        d = D(yq, x, qn); cnt += 1
        top.append((d, pn, rn, qn))
top.sort(reverse=True)
print(f'{cnt} triples onto middle targets; top 15:')
for t in top[:15]: print(f'  ({t[1]},{t[2]}) -> {t[3]}: D={t[0]:.3f}')
