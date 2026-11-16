"""E3 exchange rate: expected nice numbers per AND-unit (model) for the generic flat join at
b62/b64/b65/b68/b69 and for the best ramified slices, with λ from the program's model
(fresh-eyes NOTES §1) and the slice's p_nice taken as 0.5× the range's (measured 0.33-0.6)."""
from common import nice_range, ndig
from e3_model import generic, family
lam = {62: 4.3e-4, 64: 8.5e-4, 65: 3.2e-4, 68: 3.1e-4, 69: 2.9e-4}
pf = {65: 13, 68: 17, 69: 23}
for b in (62, 64, 65, 68, 69):
    lo, hi = nice_range(b); L = ndig(lo, b); N = hi - lo
    g = generic(b, L, N)
    cost = g[0] * N
    print(f'b{b}: generic λ {lam[b]:.1e}, cost {cost:.2e} AND-units, λ per unit {lam[b]/cost:.2e}')
    if b in pf:
        p = pf[b]
        for j in range(1, L):
            f = family(b, p, L, N, j)
            if f is None or f[3] < 1e3: break
            lam_s = lam[b] * (f[3] / N) * 0.5
            print(f'   slice {p}^{j}: λ {lam_s:.1e}, cost {f[0]*f[3]:.2e}, λ per unit {lam_s/(f[0]*f[3]):.2e}')
