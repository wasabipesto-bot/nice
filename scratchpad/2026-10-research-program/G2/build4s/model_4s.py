#!/usr/bin/env python3
"""model_4s.py [--tag base|c1|c2|...]: the library path's base-64 slice on the RX 9070 XT, stage by stage, PREDICTED.

Method (G2/TUNE-RESULTS.md, G2/port/model_rdna4.py): issue-bound time from ACO's per-wave-iteration VALU cycles
(GFX1201, W = 64; G2/build4s/preflight_*.md) x the slice's dynamic counts, at the card's operating point under this
kind of kernel (2.85 GHz at the 304 W cap, WINDOW-RESULTS.md), wave64 = two passes on a SIMD32, divided by an
efficiency; anchored on what the card MEASURED for the prototype (kernel 3.035 ms, preparation 0.425 ms, per
launch component, pipelined) and cross-checked against the RTX 3080's measured stage times for the library path
(BUILD-NOTES.md 10.6) scaled by the two cards' integer issue ratio. Each stage is a band [lo, hi]; the ratio is
against the card's main, 4.707 fs per admissible n (WINDOW-RESULTS.md, 10 fields). Nothing here is measured on
the card. Step 4S, 2026-11-19."""
import sys, random

F = 2.85e9            # operating point under G2 (measured: 2,850-2,870 MHz at 304 W)
SIMD = 128            # 64 CUs x 2 SIMD32
PASS = 2              # wave64 VALU on a SIMD32
ADM = 4.4679e12       # admissible n per slice
MAIN_FS = 4.707       # card's main, fs per admissible n (measured, 10 fields)
EFF = 0.77            # the prototype kernel's measured / issue-bound on the card (3.04 ms vs 2.34 ms at 2.85 GHz)
ISSUE_3080 = (68 * 64 * 1.553e9)   # RTX 3080 INT32 lane-ops/s at its measured mean SM clock under the 240 W cap
ISSUE_CARD = SIMD * 32 * F
R3080 = ISSUE_CARD / ISSUE_3080      # ~1.72

def t_issue(waveiters, vcyc):
    return waveiters * vcyc * PASS / (SIMD * F) * 1e3   # ms

# --- per-record survivor bits (assumption: 1 + geometric extra, mean = 11,768,560 / 10,929,765 words = 1.0767,
# slice 712012851, CPU reference). E[max over the 64 lanes of a plane] by simulation.
P_EXTRA = 1 - 1 / 1.0767
def rec_bits(rng):
    k = 1
    while rng.random() < P_EXTRA:
        k += 1
    return k
def emax(per_lane, lanes=64, n=20000, seed=7):
    rng = random.Random(seed)
    s = 0
    for _ in range(n):
        s += max(sum(rec_bits(rng) for _ in range(per_lane)) for _ in range(lanes))
    return s / n
def emax_sep(lanes=64, n=20000, seed=7):   # max(a) + max(b): the two loops of the base form
    rng = random.Random(seed)
    s = 0
    for _ in range(n):
        s += max(rec_bits(rng) for _ in range(lanes)) + max(rec_bits(rng) for _ in range(lanes))
    return s / n

tag = next((a.split('=')[1] for a in sys.argv if a.startswith('--tag=')), 'c2')
# ACO vcyc per wave-iteration (W 64; preflight_<tag>.md); the expansion's: (inner loop, iterations per take,
# outer overhead per take, kept-bit write loops per take)
SCATTER3 = {'base': 1317, 'c1': 956}.get(tag, 956)
EXP = {
    'base': (290, emax_sep(), 712 - 2 * 290 - 2 * 24, 2 * 0.9 * 24),
    'c1':   (290, emax_sep(), 712 - 2 * 290 - 2 * 24, 2 * 0.9 * 24),
    'c2':   (306, emax(2), 434 - 306 - 2 * 24, 2 * 0.9 * 24),
    'c3':   (240, emax(2), 368 - 240 - 2 * 24, 2 * 0.9 * 24),
    'c4':   (197, emax(2), 325 - 197 - 2 * 24, 2 * 0.9 * 24),
}
EXP['head'] = EXP['c4']
EXP.update({k: v for k, v in [(a.split('=')[0][2:], tuple(float(x) for x in a.split('=')[1].split(','))) for a in sys.argv if a.startswith('--exp_')]})
inner, iters, outer, puts = EXP.get(tag, EXP['c2'])

RECORDS = 10.93e6
TAKES = RECORDS / 128 + 16128 * 0.5     # takes of 2 x 64 records; ~16k plane-private partial slabs, half a take each
stages = {}
# tops: tops1 (406k valid parents, grid-stride 262,144 threads -> 6,341 wave-iterations of 1,657 vcyc), tops5 per 64
# slices (32,768 waves x 1,476), tscan (one cube, ~12 us: scan16 measured 29 us at 1.57 GHz), tops2, tdigz2 (3,731
# waves x 457), toprec2, 6 launches and 3 small uploads; hi: the 3080's measured 0.413 ms / R3080
lo = t_issue(6341, 1657) + t_issue(32768, 1476) / 64 + 0.012 + 0.010 + t_issue(3731, 457) + 0.003 + 0.010 + 0.015
stages['tops (6 kernels)'] = (lo, max(lo, 0.413 / R3080))
# parents: the prototype's preparation measured on the card at its operating point, 0.425 ms = tdig 0.010 + hist
# 0.19 + scan 0.016 + scatter 0.042 + sort 0.166; here hist2 +10 % (229 -> 251 vcyc) and scatter3's children count
sc = t_issue(1.0425e6 / 64, SCATTER3)
lo = 0.19 * 251 / 229 + 0.016 + max(0.042, sc) + 0.166
hi = 0.19 * 251 / 229 + 0.016 + 0.042 + sc + 0.166
stages['parents (hist2, scan16, scatter3, hsort)'] = (lo, hi)
# main kernel: the prototype's full kernel with records, measured 3.035 ms (D, pipelined, operating point), + the
# child lists the library writes in phase 1 (33.7M x 4 B = 135 MB: issue +4 VALU cycles per phase-1 step, 0.02 ms,
# if the writes hide under the kernel's ~45 GB/s average traffic; 0.25 ms at the 550 GB/s the records' writes
# reached if they do not), + accounts (+1.7 % on the 3080) and the 4,032 empty second instances
stages['main kernel'] = (3.035 + 0.03 + 0.02, 3.035 + 0.25 + 0.06)
# expansion: issue-bound per take (above) / EFF .. / 1.0, floor at the records' read (175 MB at 640 GB/s)
iss = t_issue(TAKES, inner * iters + outer + puts)
stages['expansion + prefilter'] = (max(iss, 0.27), max(iss / EFF, 0.27))
# check: production's check kernel on ~338k entries (5,280 waves x 1,118 vcyc + launch); hi: the 3080's 0.144 / R3080
lo = t_issue(5280, 1118) + 0.003
stages['check (production)'] = (lo / 1.0, max(lo / EFF, 0.144 / R3080))
# per batch and per slice: done kernel, 4 small uploads per batch, the group's sync (0.12 ms / 16 slices)
stages['done, uploads, sync'] = (0.02, 0.05)

if __name__ == '__main__':
    print(f"model_4s --tag={tag}: expansion inner {inner} vcyc x {iters:.2f} iterations per take + {outer:.0f} + {puts:.0f}; scatter3 {SCATTER3} vcyc; PREDICTED")
    print(f"{'stage':42s} {'lo ms':>7s} {'hi ms':>7s} {'mid':>7s}")
    L = H = 0
    for k, (a, b) in stages.items():
        L += a; H += b
        print(f"{k:42s} {a:7.3f} {b:7.3f} {(a + b) / 2:7.3f}")
    M = (L + H) / 2
    print(f"{'slice':42s} {L:7.3f} {H:7.3f} {M:7.3f}")
    for name, ms in (('lo', L), ('mid', M), ('hi', H)):
        fs = ms * 1e-3 / ADM * 1e15
        print(f"  {name}: {fs:.3f} fs per admissible n -> x{MAIN_FS / fs:.2f} against main ({MAIN_FS} fs); with main +-1.2 % drift x{MAIN_FS * 0.988 / fs:.2f}-{MAIN_FS * 1.012 / fs:.2f}")
    print(f"  E[max] bits per lane per take: 2 records in one loop {emax(2):.2f}, two loops {emax_sep():.2f}, 4 records {emax(4):.2f} (per 256 records)")
