#!/usr/bin/env python3
"""steps.py DUMP_DIR PIP...: per width, the dynamic counts of phase 3b from a dump's rounds table: list entries,
lane slots, and loop steps (cube-level iterations of the 3b loop) for a step of S entries (S = probe streams x
entries per lane: W64 h2 32; W128 h1 32, h2 64; W256 h1 64, h2 128). Wave64 wave-iterations = 4 x steps."""
import sys, struct, array
d = sys.argv[1]
for pip in sys.argv[2:]:
    for wd in (64, 128, 256):
        f = open(f"{d}/s{pip}_w{wd}.bin", 'rb')
        h = array.array('I'); h.frombytes(f.read(32))
        ninst, nround = h[2], h[3]
        f.seek(32 + ninst * 32)
        r = array.array('I'); r.frombytes(f.read(nround * 32))
        nl = r[4::8]; nch = r[1::8]
        ent = sum(nl); ls = sum(a * b for a, b in zip(nl, nch))
        out = [f"s{pip} w{wd}: rounds {nround} entries {ent} lane-slots {ls}"]
        for S in (32, 64, 128):
            out.append(f"steps(S={S}) {sum((x + S - 1) // S for x in nl)}")
        print(' | '.join(out))
