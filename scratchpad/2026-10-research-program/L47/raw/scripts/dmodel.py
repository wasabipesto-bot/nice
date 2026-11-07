#!/usr/bin/env python3
"""L47: op-count model of the proposed check (design D, base-b^2 direct) and of the roadmap's form (B, B+C), per
warp-iteration, with an L41-style pipe split, and the time/field estimates. Counts are [E]: an instruction per
operation as nvcc emits the current kernel's equivalents (sasscost.py); the prototype's codegen gate checks them.

D per survivor: n's base-b^2 limbs from (P, word 6 = P mod b^5, r0); n^2 = schoolbook over base-b^2 limbs (products
< 2^24, sums < 2^27: u32); normalise (q = mul_hi(x, ceil(2^40/b^2)) >> 8, exact for x < 2^28); split each limb into
two digits (y*ceil(2^18/b) >> 18); OR 1<<d into a 64-bit mask; the low g digits of n^3 from the truncated product
(n^2 mod b^g)(n mod b^g); gate: popcount == s2 + g; the rest of n^3 only if a lane passed; nice iff popcount == b."""
import math

def d_counts(L, s2, s3, g):
    nl = math.ceil(L / 2); q2 = math.ceil(s2 / 2); q3 = math.ceil(s3 / 2); gl = g // 2
    c = {}
    # A loop + loads (list 2 words, record words 0, 1, 6; work-counter grab amortised)
    c['loop + loads'] = dict(ALU=3, FMA=2, MEM=5, CBU=2)
    c['H = (P - w6) >> v * inv'] = dict(ALU=3, FMA=1)
    ndiv = nl - 2   # r0 -> 2 limbs + digit; w6 -> 2.5 limbs; H -> the rest: one magic division per limb boundary
    c["n's base-b^2 limbs"] = dict(ALU=ndiv + 2, FMA=2 * ndiv + 3)
    npair = nl * (nl + 1) // 2
    c['n^2 products'] = dict(ALU=nl - 1, FMA=npair)
    top_div = 0 if s2 % 2 else 0   # the top limb never divides (it is below b^2)
    c['n^2 normalise'] = dict(ALU=2 * (q2 - 1) - 1 + 1, FMA=2 * (q2 - 1))
    full = s2 // 2   # limbs holding two digits
    c['n^2 digit split'] = dict(ALU=full, FMA=2 * full)
    c['n^2 masks'] = dict(ALU=3 * s2)
    gp = sum(min(k + 1, nl) for k in range(gl))
    c[f'n^3 low {g} digits'] = dict(ALU=(2 * gl - 1) + gl + 3 * g, FMA=gp + 2 * gl + 2 * gl)
    c['gate'] = dict(ALU=2, XU=2, CBU=3)
    rest_p = q2 * nl - gp
    rl = q3 - gl
    full3 = s3 // 2 - gl
    cube = dict(ALU=2 * (rl - 1) + 1 + full3 + 3 * (s3 - g) + 2, FMA=rest_p + 2 * (rl - 1) + 2 * full3, XU=2, CBU=3)
    return c, cube

def tot(d):
    return sum(d.values())

def add(a, b, f=1.0):
    out = dict(a)
    for k, v in b.items(): out[k] = out.get(k, 0) + f * v
    return out

if __name__ == '__main__':
    # P(warp runs the rest of n^3) from warpsim.txt (2,500 warps each)
    PW = {('b62', 8): 0.1988, ('b62', 10): 0.0460, ('b62', 12): 0.0080,
          ('b60', 8): 0.2008, ('b60', 10): 0.0468, ('b60', 12): 0.0060}
    shapes = {'b62': (13, 25, 37), 'b60': (12, 24, 36)}
    CUR = {'b62': (1045.5, 469, 349, 1955), 'b60': (1049.5, 467, 352, 1863)}  # issue, ALU, FMA, measured cycles
    for tag, (L, s2, s3) in shapes.items():
        print(f'== {tag}: L={L} s2={s2} s3={s3}; current kernel {CUR[tag][0]} issued / warp-iteration, measured {CUR[tag][3]} SMSP-cycles')
        for g in (8, 10, 12):
            c, cube = d_counts(L, s2, s3, g)
            common = {}
            for v in c.values(): common = add(common, v)
            pw = PW[(tag, g)]
            exp = add(common, cube, pw)
            issue = tot(exp); alu2 = 2 * exp.get('ALU', 0); fma2 = 2 * exp.get('FMA', 0)
            bound = max(issue, alu2, fma2)
            print(f'  D g={g:2d}: common {tot(common):.0f} (ALU {common["ALU"]}, FMA {common["FMA"]}), rest of n^3 {tot(cube):.0f} x P(warp) {pw}'
                  f' -> issue {issue:.0f}, 2*ALU {alu2:.0f}, 2*FMA {fma2:.0f}; bound {bound:.0f} = {bound/CUR[tag][0]:.3f} of the current issue count')
            if g == 10:
                for k, v in c.items(): print(f'      {k:28s} {tot(v):4.0f}  {v}')
                print(f'      {"rest of n^3 (if a lane passes)":28s} {tot(cube):4.0f}  {cube}')
