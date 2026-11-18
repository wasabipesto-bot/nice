#!/usr/bin/env python3
"""NM: expected by-product numbers (variant A) = checked survivors x P(j repeats | checked).

P(j | checked): the uniform-middle model of hist.py given the digits known at the check
(K: measured histogram at b62/b64, the geometry sample of model.py at b58/b60), times
the residue factor from model.py's DP (root-class share at j over R/(b-1): the digit-sum
constraint), times the measured/model calibration in the tail (hist.py: 1.07-1.11).
Checked survivors per field: production telemetry (frontier) and the CPU sample (spread).
"""
import random, sys
sys.path.insert(0, __file__.rsplit("/", 1)[0])
from model import base_range, nd, known_positions
from hist import model as cond_model

# root-class share at j / (R/(b-1)), from raw/model_b*.txt (DP, exact digit sums)
RES = {
    58: {1: 0.0026 / (4 / 57), 2: 0.0724 / (4 / 57), 3: 0.0701 / (4 / 57)},
    60: {1: 0.0011 / (2 / 59), 2: 0.0350 / (2 / 59), 3: 0.0338 / (2 / 59)},
    62: {1: 0.0011 / (2 / 61), 2: 0.0338 / (2 / 61), 3: 0.0327 / (2 / 61)},
    64: {1: 0.0045 / (8 / 63), 2: 0.1304 / (8 / 63), 3: 0.1268 / (8 / 63)},
}

def k_hist_geometry(b, samples=3000):
    lo, hi = base_range(b)
    l, s2, s3 = nd(lo, b), nd(lo * lo, b), nd(lo ** 3, b)
    r = random.Random(7); h = {}
    for _ in range(samples):
        n = r.randrange(lo, hi)
        k = len(known_positions(n, b, l, s2, s3, lo, hi))
        h[k] = h.get(k, 0) + 1
    return h

def pj(b, kh):
    tot = sum(kh.values()); out = [0.0] * 65
    for k, c in kh.items():
        for j, p in enumerate(cond_model(b, k)):
            out[j] += p * c / tot
    return out

def main():
    # K histograms measured at b62/b64 (hist.py output, raw/hist2.txt) are passed in via argv
    # as "b:k=c,k=c,..."; others from geometry.
    import re
    kmeas = {}
    for path in sys.argv[1:]:
        for line in open(path):
            m = re.match(r"RUN b(\d+) .* tol 64 .* kreps (\S+)", line)
            if not m: continue
            kh = kmeas.setdefault(int(m[1]), {})
            for t in m[2].split(","):
                k, r, c = (int(x) for x in t.split(":"))
                kh[k] = kh.get(k, 0) + c
    CAL = 1.08
    for b in (58, 60, 62, 64):
        kh = kmeas.get(b) or k_hist_geometry(b)
        p = pj(b, kh)
        print(f"b{b}: P(j|checked) x residue x {CAL}:", ", ".join(f"j{j} {p[j]*RES[b][j]*CAL:.3e}" for j in (1, 2, 3)))

if __name__ == "__main__":
    main()
