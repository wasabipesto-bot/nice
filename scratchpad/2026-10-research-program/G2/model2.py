#!/usr/bin/env python3
"""G2 model v2: GPU cost per admissible n of the candidate structures, from counts MEASURED on real
b62/b64 units by the prototype (raw/unit_*.txt, raw/cluster_*.txt, raw/pipe_*.txt) and GPU unit
costs derived from today's main (N22, N1.G1). Three cost scenarios (opt / central / pess).

Run: python3 model2.py  (pure Python)
"""

# ---------------------------------------------------------------- today's main, GPU, base mean [D]
# b62: N22 field 58.1 s / 3.279e15 adm = 17.72 fs, field/mean survivors ratio 1.34 -> 13.2 fs.
# b64: N22 field 92.8 s / 1.270e16 adm = 7.31 fs; mean by survivors ratio 1.62 -> 4.5 fs;
#      upper end: B64.1's measured 10-field base mean on c0c357a (6.46 fs, RTX 3080 300 W) / x1.049
#      (#250+#251) / x1.13 (#254, FD tops at pow2 bases) = 5.4 fs, before the later merges.
# (b62 cross-check: MU260.1 main 0711b16 = 49.8 s per real b62 1e17 field = 15.2 fs field basis.)
TODAY = {62: (13.2e-15, 13.2e-15), 64: (4.5e-15, 5.4e-15)}

# ---------------------------------------------------------------- measured counts per admissible n [M]
# flat = (probe, 64-chunk) incidences without skipping; kept = after the chunk-common test.
# BD = bottom-driven (tops in chunks, 4R tables per top chunk); TD = top-driven (bottoms in chunks).
# kept_cl = probe-weighted presence trie (raw/cluster_w_*.txt) where measured, else the plain trie.
# kept_par = flat chunks in the parents' order, weights pooled over the unit's tops (raw/sorted_td_pooled.txt).
M = {
    # (b, f0, k): dict
    (62, 4, 9): dict(pairs=7.78e-3, surv=1.61e-5, bottoms=2.66e-6,
                     BD=dict(flat=1.240e-4, kept_gen=0.852 * 1.240e-4, kept_cl=9.164e-5, probes_per_chunk=14750),
                     TD=dict(flat=1.218e-4, kept_gen=None, kept_cl=6.238e-5, probes_per_chunk=2 * 1460)),
    (62, 4, 10): dict(pairs=3.87e-3, surv=3.33e-6, bottoms=8.12e-5,
                      BD=dict(flat=1.623e-4, kept_gen=1.623e-4, kept_cl=1.623e-4, probes_per_chunk=7300),
                      TD=dict(flat=6.077e-5, kept_gen=0.767 * 6.077e-5, kept_cl=2.734e-5, kept_par=3.533e-5, probes_per_chunk=2 * 24)),
    (62, 5, 10): dict(pairs=6.31e-3, surv=1.61e-5, bottoms=8.11e-5,
                      BD=dict(flat=1.622e-4, kept_gen=1.622e-4, kept_cl=1.622e-4, probes_per_chunk=4.5e5),
                      TD=dict(flat=9.855e-5, kept_gen=None, kept_cl=3.789e-5, probes_per_chunk=2 * 39)),
    (64, 4, 9): dict(pairs=7.08e-3, surv=1.26e-5, bottoms=2.33e-7,
                     BD=dict(flat=1.115e-4, kept_gen=0.690 * 1.115e-4, kept_cl=6.630e-5, probes_per_chunk=16500),
                     TD=dict(flat=1.108e-4, kept_gen=None, kept_cl=6.044e-5, probes_per_chunk=8 * 3800)),
    (64, 4, 10): dict(pairs=3.52e-3, surv=2.61e-6, bottoms=7.54e-6,
                      BD=dict(flat=7.661e-5, kept_gen=0.89 * 7.661e-5, kept_cl=7.145e-5, probes_per_chunk=8300),
                      TD=dict(flat=5.517e-5, kept_gen=0.724 * 5.517e-5, kept_cl=2.419e-5, kept_par=2.693e-5, probes_per_chunk=8 * 58)),
}
# model counts for the shared trees (raw/model_out.txt) [D]
VISITS = {(62, 9): 5.07e-6, (62, 10): 1.70e-4, (64, 9): 4.73e-7, (64, 10): 1.67e-5}
TOPS_TESTED = {(62, 4): 4.39e-7, (62, 5): 1.10e-8, (64, 4): 9.23e-8, (64, 5): 2.23e-9}
TOP_POP = {(62, 4): 15.5, (62, 5): 13.5, (64, 4): 16.4, (64, 5): 14.4}   # mean top cert digits [M]

# ---------------------------------------------------------------- GPU unit costs (opt, central, pess)
S = ['opt', 'central', 'pess']
C = dict(
    lookup=(0.5e-12, 0.7e-12, 0.9e-12),     # one u64 LDS lookup + OR, chip-wide [D: N1.G1 10-14 fs/digit/pair x64; LDS peak]
    inc_base=(2e-12, 4e-12, 7e-12),         # per incidence: probe load/ballot/loop [D: join base 0.11-0.26 ps/pair x64 / reuse]
    skip=(0.5e-12, 1e-12, 1.5e-12),         # one common-mask test per chunk [G]
    table=2048,                             # 4R table entries per chunk (8 x 256), each one LDS store [exact]
    visit=(0.3e-12, 1e-12, 5e-12),          # bottom child test (affine digits in registers .. today's bucket kernel) [D/G]
    bchunk=(2e-12, 4e-12, 8e-12),           # per bottom: transpose into slices / chunk append [G]
    bsort=(5e-12, 15e-12, 30e-12),          # per bottom: cluster sort (radix on a 64-bit key) [G]
    top=(0.17e-9, 0.17e-9, 0.17e-9),        # per tested top (FD kernel today) [D]
    surv=(14e-12, 17e-12, 20e-12),          # per AND survivor, prefilter+walk above the floor [P N1.G1]
    check=(58e-12 * 0.06,) * 3,             # full check per survivor x prefilter pass rate [P]
    other=(0.03, 0.05, 0.10),               # launches, host, upload as a fraction of the total [G]
)


def cost(b, f0, k, orient, clustered, si):
    m = M[(b, f0, k)]
    o = m[orient]
    c = {key: (v[si] if isinstance(v, tuple) else v) for key, v in C.items()}
    if clustered == 'par':
        kept = o.get('kept_par')
    else:
        kept = o['kept_cl'] if clustered else o['kept_gen']
    if kept is None:
        return None
    # incidence cost: 4R (8 lookups + table build amortised) or bit-sliced (popcount of the probe)
    if orient == 'BD':
        per_inc_lookups = 8 + c['table'] / o['probes_per_chunk']
    else:
        per_inc_lookups = min(TOP_POP[(b, f0)], 8 + c['table'] / o['probes_per_chunk'])
    parts = {}
    parts['AND'] = kept * (per_inc_lookups * c['lookup'] + c['inc_base'])
    parts['skip tests'] = (o['flat'] * 1.4 if clustered is True else o['flat']) * c['skip']  # trie leaves ~1.4x flat
    parts['bottom gen'] = VISITS[(b, k)] * c['visit']
    if orient == 'TD':
        sort = c['bsort'] / b if clustered == 'par' else (c['bsort'] if clustered else 0)  # parent order shared by b sibling units
        parts['bottom chunking'] = m['bottoms'] * (c['bchunk'] + sort)
    parts['tops'] = TOPS_TESTED[(b, f0)] * c['top']
    parts['survivors'] = m['surv'] * (c['surv'] + c['check'])
    tot = sum(parts.values()) / (1 - c['other'])
    parts['other'] = tot * c['other']
    return tot, parts


def main():
    print("G2 model v2 — fs per admissible n on the RTX 3080 class card; ratio vs today's main base mean")
    print("(b64 ratios given against both ends of the baseline: 4.5 fs / 5.4 fs)\n")
    best = {}
    for (b, f0, k) in M:
        for orient in ('BD', 'TD'):
            for cl in (False, True, 'par'):
                row = []
                for si in range(3):
                    r = cost(b, f0, k, orient, cl, si)
                    if r is None:
                        break
                    row.append(r)
                if not row:
                    continue
                tot = [r[0] for r in row]
                lo, hi = TODAY[b]
                rat = [lo / t for t in tot]
                rat_hi = [hi / t for t in tot]
                parts = row[1][1]
                ps = ', '.join(f"{n} {v*1e15:.3f}" for n, v in parts.items())
                tag = f"b{b} ({f0},{k}) {orient}{' parent-sorted' if cl == 'par' else (' clustered' if cl else ' gen-order')}"
                extra = f" | vs 5.4 fs: x{rat_hi[0]:.1f}/x{rat_hi[1]:.1f}/x{rat_hi[2]:.1f}" if b == 64 else ""
                print(f"{tag:32s} total {tot[1]*1e15:6.3f} fs  x{rat[0]:.1f} / x{rat[1]:.1f} / x{rat[2]:.1f} (opt/central/pess){extra}")
                print(f"{'':32s} central parts: {ps}")
                key = b
                if key not in best or rat[1] > best[key][0]:
                    best[key] = (rat[1], tag, rat, rat_hi)
    print()
    for b, (r, tag, rat, rat_hi) in best.items():
        s = f"best central at b{b}: {tag}: x{rat[1]:.1f} (range x{rat[2]:.1f}..x{rat[0]:.1f})"
        if b == 64:
            s += f"; against the 5.4 fs baseline x{rat_hi[1]:.1f} (x{rat_hi[2]:.1f}..x{rat_hi[0]:.1f})"
        print(s)
    print()
    # ceiling: AND term alone at the most favourable measured incidence count and optimistic unit cost
    print("Ceiling (only the AND, everything else free, optimistic unit cost):")
    for b in (62, 64):
        cand = []
        for (bb, f0, k), m in M.items():
            if bb != b:
                continue
            for orient in ('BD', 'TD'):
                kept = m[orient]['kept_cl']
                lk = 8 if orient == 'BD' else min(TOP_POP[(b, f0)], 8 + 2048 / m[orient]['probes_per_chunk'])
                cand.append((kept * (lk * C['lookup'][0] + C['inc_base'][0]), f0, k, orient))
        a, f0, k, orient = min(cand)
        print(f"  b{b}: {a*1e15:.3f} fs at ({f0},{k}) {orient} -> x{TODAY[b][0]/a:.1f} (x{TODAY[b][1]/a:.1f} vs the higher baseline)")


if __name__ == '__main__':
    main()


def work_unit():
    """Bottom lists are rebuilt once per batch of the leading range; a batch is a fraction w of the
    base. Bottom-side terms scale with 1/w; top groups shrink with w (BD needs >= 64 tops per class
    group for full chunks; TD falls back to bit-sliced probes when tables do not amortise)."""
    print("\nWork unit: central cost when the bottom lists are shared only within a batch of the leading range")
    W = {62: 9.543e21, 64: 3.778e22}
    for (b, f0, k, orient, cl) in [(62, 4, 9, 'TD', True), (62, 4, 9, 'BD', False), (64, 4, 10, 'TD', False)]:
        for inv_w in (1, 10, 50, 200, 1000):
            m = M[(b, f0, k)]
            o = dict(m[orient])
            # fewer probes per chunk / smaller top groups when the batch is narrower
            mm = dict(m)
            o['probes_per_chunk'] = max(1.0, o['probes_per_chunk'] / (inv_w if orient == 'TD' else 1))
            if orient == 'BD':
                tgrp = (1460 if (b, k) == (62, 9) else 58) / inv_w
                fill = min(1.0, tgrp / 64)
                o['flat'] = o['flat'] / fill if fill < 1 else o['flat']
                o['kept_gen'] = o['kept_gen'] / fill if fill < 1 else o['kept_gen']
            mm[orient] = o
            M[('w', b, f0, k)] = mm
            saveV = VISITS[(b, k)]
            VISITS[(b, k)] = saveV * inv_w
            saveB = m['bottoms']
            mm['bottoms'] = saveB * inv_w
            M[(b, f0, k)] = mm
            tot, parts = cost(b, f0, k, orient, cl, 1)
            M[(b, f0, k)] = m
            VISITS[(b, k)] = saveV
            batch_n = W[b] / inv_w
            today_fields = batch_n / 1e17
            print(f"  b{b} ({f0},{k}) {orient}{' cl' if cl else ''} batch = 1/{inv_w} of the base ({batch_n:.1e} n, {today_fields:,.0f} of today's 1e17 fields):"
                  f" {tot*1e15:.3f} fs -> x{TODAY[b][0]/tot:.1f}")


if __name__ == '__main__':
    work_unit()
