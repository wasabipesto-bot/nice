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
# per wave-iteration: (vcyc = valu + 4 q + 2 v64 [ACO's full-rate units], salu, lds_bytes)
cost = {
  # loop 0 (probe digits): only the first wave of a segment is active (segments ~59 probes)
  'setup (probe digits)':      (setup * 1,        (453, 7, 256)),
  # loop 1 (children, ordered compaction): 256 parents per cube step
  'phase 1 (children)':        (p1 * WAVES,       (62, 32, 4 * 256)),
  # phase 2, shuffle transpose (xpose 1): 4 tasks per wave per round; per task ~88 VALU incl. 19 v64 (static diff
  # of the unrolled code against the ballot build), 2 x 8-byte stores
  'phase 2 (transpose, xp1)':  (rounds * WAVES * 4, (88 + 19, 12, 2 * 256)),
  # common masks: loop 2, 4 iterations per wave per round
  'common masks':              (rounds * WAVES * 4, (23, 9, 2 * 256)),
  # 3a: loop 3 (mode 2), ceil(nprobe/256) iterations per unit and round, all 4 waves
  '3a (probe list)':           (a3 * WAVES,       (223, 37, 36 * 256)),
  # 3b: loop 4 (mode 2, with the survivor records), one step = 2 entries x 64 lanes
  '3b (64-pair words + records)': (b3 * WAVES,    (210, 56, 34 * 512 + 2 * 256 + 2 * 1024)),
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
for eff in (0.95, 0.75, 0.55):
    k = tot / eff
    for prep in (0.45e-3, 0.9e-3):
        e2e = k + prep
        print(f"eff {eff:.2f} prep {prep*1e3:.2f} ms: kernel {k*1e3:.2f} ms, end-to-end {e2e*1e3:.2f} ms = {e2e/ADM*1e15:.3f} fs")
