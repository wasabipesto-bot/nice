#!/usr/bin/env python3
"""model_rdna4.py: price the CubeCL G2 kernel (W = 64, fill 1024) on the RX 9070 XT from ACO's per-loop instruction
counts (RADV 26.0.8, GFX1201, drm-shim; g2out/aco_w64_xp*/ *.aco.txt via aco/loops.py) and the kernel's dynamic loop
counts for super-unit 712012851 (g2_cubecl --model 1024). Issue/LDS-bound per phase, divided by an efficiency.
python3 -I model_rdna4.py"""
CU, SIMD, F = 64, 128, 3.1e9          # RX 9070 XT: 64 CUs, 2 SIMD32 each; ~3.1 GHz at 300 W (N13.2 / N21.2 / N22)
PASS = 2                              # wave64 VALU: two passes on a SIMD32 (1.5 = some dual issue)
LDS_BPC = 128                         # LDS bytes per clock per CU
ADM = 4.4679e12                       # admissible n of the super-unit
# dynamic counts (cube-level, g2_cubecl --model 1024) and waves per cube
p1, rounds, a3, b3, setup = 262528, 36148, 73355, 460954, 32256
WAVES = 4
import sys
FIX = '--fixed' in sys.argv
# per-iteration VALU cycles (ACO vcyc): before the fixes (g2out/aco_w64_xp1) / after (g2out/acoF_cm1: top digits once
# per super-unit, common masks inside the transpose (+17 VALU + 2 v64 per task), 12-byte record loads)
SETUP, P1, XP, CM, B3 = (6, 74, 88 + 19 + 17 + 4, 0, 217) if FIX else (453, 62, 88 + 19, 1, 210)
# --tune (2026-11-18, g2out/tune/aco_*_full, head of g2-cubecl-local): --tdig 0 default (setup 453 again), phase 1
# with u16 slots (82), transpose + u16 read (~131), 3a from per-digit masks (52 VALU, 21 LDS), 3b 173 VALU / 46 SALU
TUNE = '--tune' in sys.argv
A3 = (223, 37, 36 * 256)
if TUNE:
    SETUP, P1, XP, CM, B3 = 453, int(next((a.split("=")[1] for a in sys.argv if a.startswith("--p1=")), 58)), int(next((a.split("=")[1] for a in sys.argv if a.startswith("--xp=")), 104)), 0, int(next((a.split('=')[1] for a in sys.argv if a.startswith('--b3=')), 173))
    A3 = (52, 6, 21 * 256)
# per wave-iteration: (vcyc = valu + 4 q + 2 v64 [ACO's full-rate units], salu, lds_bytes)
cost = {
  # loop 0 (probe digits): only the first wave of a segment is active (segments ~59 probes)
  'setup (probe digits)':      (setup * 1,        (SETUP, 7, 256)),
  # loop 1 (children, ordered compaction): 256 parents per cube step
  'phase 1 (children)':        (p1 * WAVES,       (P1, 32, 4 * 256)),
  # phase 2, shuffle transpose (xpose 1): 4 tasks per wave per round; per task ~88 VALU incl. 19 v64 (static diff
  # of the unrolled code against the ballot build), 2 x 8-byte stores
  'phase 2 (transpose, xp1)':  (rounds * WAVES * 4, (XP, 12, 2 * 256)),
  # common masks: loop 2, 4 iterations per wave per round
  'common masks':              (rounds * WAVES * 4 * CM, (23, 9, 2 * 256)),
  # 3a: loop 3 (mode 2), ceil(nprobe/256) iterations per unit and round, all 4 waves
  '3a (probe list)':           (a3 * WAVES,       A3),
  # 3b: loop 4 (mode 2, with the survivor records), one step = 2 entries x 64 lanes
  '3b (64-pair words + records)': (b3 * WAVES,    (B3, 46 if TUNE else 56, 34 * 512 + 2 * 256 + 2 * 1024)),
}
alt_xp0 = (rounds * WAVES * 4, (64 * 7, 64 * 5, 64 * 512))   # ballot transpose: per v ~7 VALU, 5 SALU, one 8-byte store
def secs(n, c):
    vcyc, salu, lds = c
    t_v = n * vcyc * PASS / (SIMD * F)
    t_s = n * salu / (SIMD * F)
    t_l = n * lds / (CU * LDS_BPC * F)
    return max(t_v, t_s, t_l), t_v, t_s, t_l
tot = 0
print(f"{'phase':32s} {'bound ms':>9s} {'VALU':>7s} {'SALU':>7s} {'LDS':>7s}")
for k, (n, c) in cost.items():
    b, v, s_, l = secs(n, c); tot += b
    print(f"{k:32s} {b*1e3:9.3f} {v*1e3:7.3f} {s_*1e3:7.3f} {l*1e3:7.3f}")
b0 = secs(*alt_xp0)[0]
print(f"{'(phase 2 by ballots, xp0)':32s} {b0*1e3:9.3f}")
print(f"kernel bound (xp1): {tot*1e3:.3f} ms = {tot/ADM*1e15:.4f} fs per admissible n")
# CUDA reference (RTX 3080, BENCH.md v10): kernel full 4.566 ms, prep 0.450 ms
print("(tuned kernel)" if TUNE else "(fixed kernel)" if FIX else "(before the fixes)")
for eff in (0.95, 0.75, 0.55):
    k = tot / eff
    for prep in ((0.3e-3, 0.6e-3) if FIX or TUNE else (0.45e-3, 0.9e-3)):
        e2e = k + prep
        print(f"eff {eff:.2f} prep {prep*1e3:.2f} ms: kernel {k*1e3:.2f} ms, end-to-end {e2e*1e3:.2f} ms = {e2e/ADM*1e15:.3f} fs")
