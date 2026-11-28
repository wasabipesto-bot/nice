#!/usr/bin/env python3
"""banks.py: LDS bank-conflict model of phase 3b's slice reads (ds_read_b64, wave64) per layout and lane mapping.
Assumed hardware (not measured; RDNA4's LDS is not documented at this level): 32 banks of 4 bytes (128 B/clk per CU),
a wave64 ds_read_b64 served 16 lanes at a time, a group's cost = the largest number of distinct dwords on one bank
(same dword = broadcast). Probes: synthetic, 18 distinct digits drawn uniformly from 0..64, ascending (base 65); the
per-read digit index k is the same for all lanes. Prints mean clocks per 16-lane group (1.0 = conflict-free).
B65 ACO study, 2026-11-28."""
import random
random.seed(1)
SROW = 67
def cost(addrs):  # addrs: per lane a dword address of the 8-byte read
    c = 0
    for g in range(4):
        banks = {}
        for a in addrs[16 * g:16 * g + 16]:
            for d in (a, a + 1):
                banks.setdefault(d % 32, set()).add(d)
        c += max(len(s) for s in banks.values())
    return c / 4
def probe(): return sorted(random.sample(range(65), 18))
def run(name, lanes, layout, nchunks_per_lane):
    tot = n = 0
    for _ in range(3000):
        P = {}
        for k in range(18):
            for h in range(nchunks_per_lane):
                addrs = []
                for t in range(64):
                    st, c = lanes(t, h)
                    if st not in P: P[st] = probe()
                    addrs.append(layout(P[st][k], c))
                tot += cost(addrs); n += 1
        P.clear()
    print(f"{name:58s} {tot / n:.2f}")
cm = lambda v, c: (v + c * SROW) * 2          # chunk-major, odd stride (today)
dm = lambda v, c: (v * 16 + c) * 2            # digit-major
run("today: lane = chunk t%16, 4 streams, chunk-major", lambda t, h: ((t // 16, h), t % 16), cm, 1)
run("2 chunks/lane (q, q+8), 8 streams/wave, chunk-major", lambda t, h: (t // 8, t % 8 + 8 * h), cm, 2)
run("4 chunks/lane (q+4k), 16 streams/wave, chunk-major", lambda t, h: (t // 4, t % 4 + 4 * h), cm, 4)
run("4 chunks/lane (t%16 ^ 4k), 16 streams/wave, digit-major", lambda t, h: (t // 4, (t % 16) ^ (4 * h)), dm, 4)
# phase 2 stores (W 64): one task = one chunk q, lane = digit v, 8 bytes
for name, lay in (("phase-2 store, chunk-major (today)", cm), ("phase-2 store, digit-major", dm)):
    print(f"{name:58s} {cost([lay(v, 5) for v in range(64)]):.2f}")
print(f"{'phase-2 store, digit-major, 4 tasks rotated per lane':58s} {cost([dm(v, 1 + 4 * ((v + 0) % 4)) for v in range(64)]):.2f}")
