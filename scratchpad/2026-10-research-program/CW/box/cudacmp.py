#!/usr/bin/env python3
"""cudacmp.py G2_LOG MICRO_LOG: CubeCL's CUDA source of g2_kernel's phase-3b loop (the `while (true)` after the
1048576 ablation test) against the microbenchmark's w64 kernel's (the first w3b_kernel, its 3b loop = the last
`while (true)` with ballots): operation counts per loop body, as a structural comparison."""
import re, sys
def kernel(fn, name, nth=0):
    L = open(fn).read().split('\n')
    starts = [i for i, l in enumerate(L) if '__global__' in l and name in l]
    s = starts[nth]; e = next((i for i in range(s + 1, len(L)) if '__global__' in L[i]), len(L))
    return L[s:e]
def loop_at(L, i):
    d = 0; out = []
    for j in range(i, len(L)):
        d += L[j].count('{') - L[j].count('}'); out.append(L[j])
        if d == 0 and j > i: break
    return out
def stats(lines):
    t = '\n'.join(lines)
    return {'shared loads': len(re.findall(r'= shared_memory_\d+\[', t)), 'OR': t.count(' | '), 'AND': t.count(' & '),
            'SHR': t.count(' >> '), 'SHL': t.count(' << '), 'ballot': t.count('__ballot_sync'), 'popc': t.count('__popc'),
            'select': t.count(' ? '), 'atomic': t.count('atomicAdd'), 'global stores': len(re.findall(r'buffer_\d+\[[^\]]*\] = ', t)),
            'shfl': t.count('__shfl'), 'source lines': len(lines)}
g = kernel(sys.argv[1], 'g2_kernel')
ia = next(i for i, l in enumerate(g) if '1048576' in l)
gl = loop_at(g, next(i for i in range(ia, len(g)) if 'while (true)' in g[i]))
m = kernel(sys.argv[2], 'w3b_kernel', 0)
ws = [i for i, l in enumerate(m) if 'while (true)' in l]
ml = [loop_at(m, i) for i in ws]
ml = [x for x in ml if '__ballot_sync' in '\n'.join(x)]
inner = min(ml, key=len)
print('| loop | ' + ' | '.join(stats(gl).keys()) + ' |')
print('|---' * (len(stats(gl)) + 1) + '|')
for name, lp in (('g2_kernel phase 3b', gl), ('microbenchmark w64 phase 3b', inner)):
    print(f'| {name} | ' + ' | '.join(str(v) for v in stats(lp).values()) + ' |')
