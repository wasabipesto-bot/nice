"""E5 (brief Q1/Q3 prototype with honest counts): for a fixed top T (t digits, u = L - t free low digits
m), compare
  (a) the bottom tree on m (prune on repeated / top-masked low digits of n^2, n^3), ops = nodes;
  (b) prescribe-and-solve: enumerate allowed tuples for w uncertified "window" digits just under the top
      certificate (n^2 window, n^3 window, or both alternately), an oracle returns all m with that tuple
      (unit cost per call + per output; oracle realised by an index, i.e. the most generous lattice);
  (c) hybrid: tree to depth d, then prescription of w window digits per node.
Success set S = m whose low-u digits of n^2, n^3, the windows and the top certificate are all distinct.
Every method must output a superset of S; ops reported per top, averaged over random tops."""
import sys, random, itertools
from collections import defaultdict
from common import nice_range, ndig, digits
b, t, NT = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
lo, hi = nice_range(b); L = ndig(lo, b); u = L - t; B = b ** u
L2, L3 = ndig(lo * lo, b), ndig(lo ** 3, b)
def cert(T):
    a, z = T * B, T * B + B - 1
    a = max(a, lo); z = min(z, hi - 1)
    if a > z: return None
    out = {}
    for w, e, LL in (('sq', 2, L2), ('cu', 3, L3)):
        A, Z = a ** e, z ** e
        for p in range(LL):
            if A // b ** p == Z // b ** p: out[(w, p)] = (A // b ** p) % b
    return out
random.seed(8)
tot = defaultdict(float); done = 0; tries = 0
while done < NT and tries < 50 * NT:
    tries += 1
    T = random.randrange(lo // B, hi // B + 1)
    C = cert(T)
    if C is None or len(set(C.values())) != len(C): continue
    mask = set(C.values())
    p2 = min(p for (w, p) in C if w == 'sq'); p3 = min(p for (w, p) in C if w == 'cu')
    win2 = list(range(p2 - 1, max(u, 2 * u) - 1, -1))   # uncertified n^2 positions below the cert, top first
    win3 = list(range(p3 - 1, max(u, L + 2 * u) - 1, -1))
    wins = []
    for i in range(max(len(win2), len(win3))):
        if i < len(win2): wins.append(('sq', win2[i]))
        if i < len(win3): wins.append(('cu', win3[i]))
    # per-m data
    data = []
    for m in range(B):
        n = T * B + m
        if not (lo <= n < hi): continue
        d2, d3 = digits(n * n, b, L2), digits(n ** 3, b, L3)
        low = d2[:u] + d3[:u]
        wv = tuple(d2[p] if w == 'sq' else d3[p] for (w, p) in wins)
        data.append((m, low, wv))
    S = sum(1 for (m, low, wv) in data if len(set(low) | set(wv) | mask) == len(low) + len(wv) + len(mask))
    # (a) tree
    nodes = 0; level = [0]
    for d in range(u):
        new = []
        for r in level:
            for dig in range(b):
                rr = r + dig * b ** d; nodes += 1
                x2 = digits(rr * rr % b ** (d + 1), b, d + 1); x3 = digits(rr ** 3 % b ** (d + 1), b, d + 1)
                s = x2 + x3
                if len(set(s)) == len(s) and not (set(s) & mask): new.append(rr)
        level = new
    tot['tree_nodes'] += nodes; tot['tree_leaves'] += len(level)
    # (b) pure prescription of the first w window digits (alternating n^2 / n^3 windows)
    for w in range(1, min(len(wins), 2 * u + 2) + 1):
        idx = defaultdict(list)
        for (m, low, wv) in data: idx[wv[:w]].append(m)
        A = b - len(mask); calls = 1
        for i in range(w): calls *= (A - i)
        outs = sum(len(ms) for v, ms in idx.items() if len(set(v)) == w and not (set(v) & mask))
        tot[f'presc_w{w}_calls'] += calls; tot[f'presc_w{w}_outs'] += outs
    tot['S'] += S; done += 1
print(f'b{b} L={L} t={t} u={u} B={B}, {done} tops; per top averages:')
print(f'  survivors |S| = {tot["S"]/done:.1f}')
print(f'  (a) bottom tree: nodes {tot["tree_nodes"]/done:.0f}, leaves (then window check) {tot["tree_leaves"]/done:.0f}')
for w in range(1, 2 * u + 3):
    if f'presc_w{w}_calls' in tot:
        c, o = tot[f'presc_w{w}_calls'] / done, tot[f'presc_w{w}_outs'] / done
        print(f'  (b) prescribe w={w} window digits: calls {c:.0f} + outputs {o:.0f} = {c+o:.0f}')
